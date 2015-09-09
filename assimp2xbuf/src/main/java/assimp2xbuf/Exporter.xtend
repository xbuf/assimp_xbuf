package assimp2xbuf

import assimp.Assimp
import assimp.Assimp.aiBone
import assimp.Assimp.aiColor3D
import assimp.Assimp.aiColor4D
import assimp.Assimp.aiFace
import assimp.Assimp.aiMaterial
import assimp.Assimp.aiMatrix4x4
import assimp.Assimp.aiMesh
import assimp.Assimp.aiNode
import assimp.Assimp.aiQuaternion
import assimp.Assimp.aiScene
import assimp.Assimp.aiString
import assimp.Assimp.aiVector3D
import assimp.Assimp.aiVertexWeight
import com.google.protobuf.ExtensionRegistry
import java.nio.file.FileSystems
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.util.ArrayList
import java.util.Collection
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Optional
import java.util.TreeMap
import java.util.UUID
import org.bytedeco.javacpp.FloatPointer
import org.bytedeco.javacpp.IntPointer
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory
import xbuf.Datas.Bone
import xbuf.Datas.Color
import xbuf.Datas.Data
import xbuf.Datas.IndexArray
import xbuf.Datas.Material
import xbuf.Datas.Mesh
import xbuf.Datas.Mesh.Primitive
import xbuf.Datas.Quaternion
import xbuf.Datas.Relation
import xbuf.Datas.Skeleton
import xbuf.Datas.Skin
import xbuf.Datas.TObject
import xbuf.Datas.Texture
import xbuf.Datas.Transform
import xbuf.Datas.Vec3
import xbuf.Datas.VertexArray
import xbuf_ext.AnimationsKf
import xbuf_ext.CustomParams

import static assimp.aiShadingMode.*
import static assimp.aiTextureType.*

//TODO transform to the correct convention yup, zforward, 1 unit == 1 meter
//TODO UV /textcoords in a 2D FloatBuffer
//TODO ensure normal are unitlength (idem for tangent, bitangent)
//TODO Xbuf support multi color per vertex
//TODO Xbuf support displacement Map, HeightMap, LightMap, see aiTextureType_XXXX
//TODO Xbuf assign Material to Mesh
//TODO inverse the roughnessMap (from shininessMap)
//tuto about animation: [Tutorial 38 - Skeletal Animation With Assimp](http://ogldev.atspace.co.uk/www/tutorial38/tutorial38.html)
class Exporter {
    val log = LoggerFactory.getLogger(this.getClass)
    
    @FinalFieldsConstructor
    static class ResultsTmp {
        public val Data.Builder out
        public val meshes = new HashMap<Integer, Mesh.Builder>()
        public val skins = new HashMap<Integer, BonesInfluence[]>()
        public val materials = new HashMap<Integer, Material.Builder>()
    }

    @FinalFieldsConstructor
    static class BoneInfluence {
        public val String boneName
        public val float weight
    }
    
    static class BonesInfluence {
        val list = new ArrayList<BoneInfluence>(6)
        def add(String boneName, float weight) {
            list.add(new BoneInfluence(boneName, weight))
        }
        
        def influences() {
            list.sortBy[v| -v.weight]
        }
    }

	static def String newId() {
        UUID.randomUUID.toString
    }    

    public var textureInPathTransform = [ AssetPath v | v ]
    public var textureOutPathTransform = [ AssetPath v | v ]

    def String findMeshId(int i) { "_mesh_" + i}
    def String findMaterialId(int i) { "_material_" + i}
    
    new(){
    	setupExtensionRegistry(ExtensionRegistry.newInstance())
	}

	protected def ExtensionRegistry setupExtensionRegistry(ExtensionRegistry r) {
		CustomParams.registerAllExtensions(r)
		AnimationsKf.registerAllExtensions(r)
		r
    }

    def export(aiScene scene, Data.Builder out) {
    	val eanim = new Exporter4Animation()
        val resTmp = new ResultsTmp(out)
        export(resTmp, scene)
        eanim.exportAnimations(resTmp, scene)
    	out
    }

	def export(ResultsTmp resTmp, aiScene scene) {
        exportMaterials(resTmp, scene)
        val nodeNameSkeletons = exportSkeletons(resTmp, scene)
        exportMeshes(resTmp, scene)
	    exportNodes(resTmp, scene, scene.mRootNode(), nodeNameSkeletons)
	    resTmp
	}

    def String exportNodes(ResultsTmp resTmp, aiScene scene, aiNode node, Collection<Pair<String, Skeleton.Builder>> nodeNameSkeletons) {
        val obj = toTObject(node)
        val nbMeshes = node.mNumMeshes
        for(var i = 0; i < nbMeshes; i++){
            val m = resTmp.meshes.get(i)
            if (m == null) {
                log.warn("mesh {} not found", i)
            } else {
                log.debug("-- export mesh: " + m.name)
              	m.vertexArraysList.forEach[va|
              		log.debug("---- export vertexarray: " + va.attrib.name)
              	]
                resTmp.out.addRelations(newRelation(Mesh, m.id, TObject, obj.id, null))
            }
        }
        val nbChildren = node.mNumChildren
        // apply node, children,...
        for(var i = 0; i < nbChildren; i++){
            val child = node.mChildren.get(aiNode, i)
            val childName = child.mName.toString
            val skeletons = nodeNameSkeletons.filter[v| v.key == childName]
            if (skeletons.isEmpty) {
                val childId = exportNodes(resTmp, scene, child, nodeNameSkeletons)
                resTmp.out.addRelations(newRelation(TObject, obj.id, TObject, childId, null))
            }
        }
        // apply skeleton (require to already have link children+meshes
        for(var i = 0; i < nbChildren; i++){
            val child = node.mChildren.get(aiNode, i)
            val childName = child.mName.toString
            val skeletons = nodeNameSkeletons.filter[v| v.key == childName]
            if (!skeletons.isEmpty) {
                skeletons.forEach[v|
                    //target skeleton bone to skin if available
                    resTmp.out.addRelations(newRelation(Skeleton, v.value.id, TObject, obj.id, null))
                    setupSkins(node, v.value.bonesList, resTmp)
                ]
            }
        }
        resTmp.out.addTobjects(obj)
        obj.id
    }

    def exportMeshes(ResultsTmp resTmp, aiScene scene) {
        if (!scene.HasMeshes()) return;
        for(var i =  scene.mNumMeshes - 1; i >= 0; i--){
            val m = scene.mMeshes.get(aiMesh, i)
            val mdest = Mesh.newBuilder()
            mdest.name = m.mName.toString
            mdest.id = findMeshId(i)
            val nbVertices = m.mNumVertices()
            addVertexArrayV3(mdest, VertexArray.Attrib.position, m.mVertices, nbVertices)
            addVertexArrayV3(mdest, VertexArray.Attrib.normal, m.mNormals, nbVertices)
            addVertexArrayV3(mdest, VertexArray.Attrib.tangent, m.mTangents, nbVertices)
            addVertexArrayV3(mdest, VertexArray.Attrib.bitangent, m.mBitangents, nbVertices)
            val nbMaxTextCoord = Math.min(VertexArray.Attrib.texcoord9_VALUE - VertexArray.Attrib.texcoord_VALUE, Assimp.AI_MAX_NUMBER_OF_TEXTURECOORDS)
            for(var j = 0; j < nbMaxTextCoord; j++) {
            	val tc = m.mTextureCoords.get(aiVector3D, j)
            	if (tc != null) {
		            addVertexArrayV3(mdest, VertexArray.Attrib.valueOf(VertexArray.Attrib.texcoord_VALUE + j), tc, nbVertices)
            	}
            }
            val nbMaxColor = Math.min(1, Assimp.AI_MAX_NUMBER_OF_COLOR_SETS)
            for(var j = 0; j < nbMaxColor; j++) {
            	val tc = m.mColors.get(aiColor4D, j)
            	if (tc != null) {
		            addVertexArrayColor(mdest, VertexArray.Attrib.valueOf(VertexArray.Attrib.color_VALUE + j), tc, nbVertices)
            	}
            }
//            addVertexArrayColor(mdest, VertexArray.Attrib.color, m.mColors, nbVertices)
            //TODO bones, color,...
            val ia = IndexArray.newBuilder()
            ia.intsBuilder.step = 3
            for(var j = 0; j < m.mNumFaces; j++) {
                val aiFace faces = m.mFaces.position(j)
                val nb = faces.mNumIndices
                if (nb == 3) {
                    ia.intsBuilder.addValues(faces.mIndices.get(0))
                    ia.intsBuilder.addValues(faces.mIndices.get(1))
                    ia.intsBuilder.addValues(faces.mIndices.get(2))
    //TODO            } else if (nb == 4) {
                } else {
                    log.warn("only support faces triangle (3 vertices): {}", nb)
                }
            }
            mdest.addIndexArrays(ia)
            //TODO add checker about size, ...
            mdest.primitive = Primitive.triangles
            resTmp.meshes.put(i, mdest)
            val boneInfluences = extractBonesInfluences(m)
            log.debug("prepare skin of mesh #{}, with nb boneInfluences : {}", i, boneInfluences.size)
            resTmp.skins.put(i, boneInfluences)
            resTmp.out.addMeshes(mdest)
            resTmp.out.addRelations(newRelation(Material, findMaterialId(m.mMaterialIndex), Mesh, mdest.id, null))
        }
    }

    def VertexArray.Builder addVertexArrayV3(Mesh.Builder mdest, VertexArray.Attrib attrib, aiVector3D list, int length) {
        val lg = if (length == -1) list.limit else length
        if (lg > 0 && list != null) {
            val va = VertexArray.newBuilder()
            va.floatsBuilder.step = 3
            for(var j = 0; j < lg; j++) {
                val aiVector3D v3 = list.position(j)
                va.floatsBuilder.addValues(v3.x)
                va.floatsBuilder.addValues(v3.y)
                va.floatsBuilder.addValues(v3.z)
            }
            va.attrib = attrib
            mdest.addVertexArrays(va)
            va
        } else null
    }

    def VertexArray.Builder addVertexArrayColor(Mesh.Builder mdest, VertexArray.Attrib attrib, aiColor4D list, int length) {
        val lg = if (length == -1) list.limit else length
        if (lg > 0) {
            val va = VertexArray.newBuilder()
            va.floatsBuilder.step = 4
            for(var j = 0; j < lg; j++) {
                val aiColor4D v4 = list.position(j)
                va.floatsBuilder.addValues(v4.r)
                va.floatsBuilder.addValues(v4.g)
                va.floatsBuilder.addValues(v4.b)
                va.floatsBuilder.addValues(v4.a)
            }
            va.attrib = attrib
            mdest.addVertexArrays(va)
            va
        } else null
    }

    def Relation.Builder newRelation(Class<?> typ1, String ref1, Class<?> typ2, String ref2, String label) {
        if (typ1.simpleName <= typ2.simpleName) {
            log.debug("link {}({}) to {}({})", typ1.simpleName, ref1, typ2.simpleName, ref2)
            newRelation(ref1, ref2, label)
        } else {
            log.debug("link {}({}) to {}({})", typ2.simpleName, ref2, typ1.simpleName, ref1)
            newRelation(ref2, ref1, label)
        }                
    }
  
    def Relation.Builder newRelation(String ref1, String ref2, String label) {
        val out = Relation.newBuilder()
        out.ref1 = ref1
        out.ref2 = ref2
        if (label != null) out.label = label
        out
    }

    def TObject.Builder toTObject(aiNode in) {
        val out = TObject.newBuilder()
        out.id = newId() //TODO find a better id
        out.name = in.mName.toString()
        out.transform = toTransform(in.mTransformation)
        out
    }

    def Transform.Builder toTransform(aiMatrix4x4 in) {
        val out = Transform.newBuilder()
        val t = new aiVector3D()
        val r = new aiQuaternion()
        var s = new aiVector3D()
        in.Decompose(s,r,t)
        out.translation = toVec3(t)
        out.rotation = toQuaternion(r)
        out.scale = toVec3(s)
        out
    }

    def Vec3.Builder toVec3(aiVector3D in) {
        val out = Vec3.newBuilder()
        out.x = in.x
        out.y = in.y
        out.z = in.z
        out
    }

    def Quaternion.Builder toQuaternion(aiQuaternion in) {
        val out = Quaternion.newBuilder()
        out.w = in.w
        out.x = in.x
        out.y = in.y
        out.z = in.z
        out
    }

    def exportMaterials(ResultsTmp resTmp, aiScene scene) {
        if (!scene.HasMaterials()) return;
    	for(var i = 0; i < scene.mNumMaterials ; i++){
            val m = scene.mMaterials.get(aiMaterial, i)
            val mdest = Material.newBuilder()
            mdest.id = findMaterialId(i)
            val s = new aiString()
            if (m.Get(aiMaterial.AI_MATKEY_NAME, 0, 0, s) == Assimp.AI_SUCCESS) {
				mdest.name = s.toString()
            }
            log.debug("export material: ({}, {}) ", mdest.id, mdest.name)
            readColor3D(m, aiMaterial.AI_MATKEY_COLOR_DIFFUSE).map[v| mdest.color = v]
            readTexture(m, aiTextureType_DIFFUSE).map[v| mdest.colorMap = v]
            readColor3D(m, aiMaterial.AI_MATKEY_COLOR_EMISSIVE).map[v| mdest.emission = v]
            readTexture(m, aiTextureType_EMISSIVE).map[v| mdest.emissionMap = v]
            readColor3D(m, aiMaterial.AI_MATKEY_COLOR_SPECULAR).map[v| mdest.specular = v]
            readTexture(m, aiTextureType_SPECULAR).map[v| mdest.specularMap = v]
            readFloat(m, aiMaterial.AI_MATKEY_OPACITY, 1.0f).map[v| mdest.opacity = v]
            readTexture(m, aiTextureType_OPACITY).map[v| mdest.opacityMap = v]
            readFloat(m, aiMaterial.AI_MATKEY_SHININESS_STRENGTH, 1.0f).map[v| mdest.specularPower = v]
            readFloat(m, aiMaterial.AI_MATKEY_SHININESS, 0.0f).map[v| mdest.roughness = 1.0f - v]
            //mdest.roughnessMap = readTexture(m, aiTextureType_SHININESS).map[v|  = v]
            //mdest.metalness = readFloat(m, aiMaterial.AI_MATKEY_REFRACTI, 1.0f).map[v| = v]
            readTexture(m, aiTextureType_NORMALS).map[v| mdest.normalMap = v]
            mdest.shadeless = false
            readInt(m, aiMaterial.AI_MATKEY_SHADING_MODEL).map[v|
            	mdest.shadeless = (v == aiShadingMode_Flat || v == aiShadingMode_NoShading)
            	//TODO set the mdest.familly
            ]
            resTmp.materials.put(i, mdest)
            resTmp.out.addMaterials(mdest)
    	}
    }

    val c3tmp = new aiColor3D()
    def Optional<Color.Builder> readColor3D(aiMaterial src, String key) {
        if (src.Get(key, 0, 0, c3tmp) == Assimp.AI_SUCCESS) {
			val cdest = Color.newBuilder()
			cdest.a = 1.0f
			cdest.r = c3tmp.r
			cdest.g = c3tmp.g
			cdest.b = c3tmp.b
  			log.debug("add color : {}", cdest)
			Optional.of(cdest)
        } else Optional.empty
    }

    val floattmp = new FloatPointer()
    def Optional<Float> readFloat(aiMaterial src, String key, float defaultValue) {
        if (src.Get(key, 0, 0, floattmp) == Assimp.AI_SUCCESS) {
			Optional.of(floattmp.get)
        } else Optional.empty // Optional.of(defaultValue)
    }

    val inttmp = new IntPointer()
    def Optional<Integer> readInt(aiMaterial src, String key) {
        if (src.Get(key, 0, 0, inttmp) == Assimp.AI_SUCCESS) {
			Optional.of(inttmp.get)
        } else Optional.empty // Optional.of(defaultValue)
    }

    val stringtmp = new aiString()
	def Optional<Texture.Builder> readTexture(aiMaterial src, int type) {
		if (src.GetTextureCount(type) > 0) {
			if (src.GetTextureCount(type) > 1) {
				log.warn("more than one texture, only Keep the first");
			}
			if (src.GetTexture(type, 0, stringtmp, null, null, null, null, null) == Assimp.AI_SUCCESS) {
				val tex = Texture.newBuilder()
				tex.id = newId()
				val inr = stringtmp.toString().replace('\\', '/')
				val in = textureInPathTransform.apply(new AssetPath(inr, FileSystems.getDefault().getPath(inr)))
				if (Files.isReadable(in.path)) {
					val out = textureOutPathTransform.apply(in)
					if (in.path != out.path) {
						Files.createDirectories(out.path.parent)
						Files.copy(in.path, out.path, StandardCopyOption.REPLACE_EXISTING)
					}
					tex.name = out.path.fileName.toString
					tex.rpath = out.rpath
					log.debug("add texture : {}", tex.rpath)
					Optional.of(tex)
				} else {
					log.debug("texture not found : {}", in.path)
					Optional.empty
				}
			} else
				Optional.empty
		} else
			Optional.empty
	}
    
    def exportSkeletons(ResultsTmp resTmp, aiScene scene) {
        if (scene.mRootNode == null) {
            new HashSet<Pair<String, Skeleton.Builder>>()
        } else {
            val rboneNames = findRBoneNames(scene)
            extractSkeleton(resTmp, scene.mRootNode, rboneNames)
        }
    }

    def findRBoneNames(aiScene scene) {
        val nodes = collectAllNodes(scene.mRootNode, new HashMap<String, aiNode>())
        val rboneNames = new HashSet<String>()
        for(var j =  scene.mNumMeshes - 1; j >= 0; j--){
            val mesh = scene.mMeshes.get(aiMesh, j)
            for(var i = 0; i < mesh.mNumBones; i++) {
                val bone = mesh.mBones.get(aiBone, i)
                val name = bone.mName.toString()
                if (!rboneNames.contains(name)) {
                    rboneNames.add(name)
                    //addChildren(nodes, name, necessityMap)
                    addParentWithoutMeshes(nodes.get(name), rboneNames)
                }
            }
        }
        rboneNames
    }
    def Map<String, aiNode> collectAllNodes(aiNode node, Map<String, aiNode> collector){
        collector.put(node.mName.toString, node)
        val nbChildren = node.mNumChildren
        for(var i = 0; i < nbChildren; i++){
            collectAllNodes(node.mChildren.get(aiNode, i), collector)
        }
        collector
    }    
    
    def Collection<Pair<String, Skeleton.Builder>> extractSkeleton(ResultsTmp resTmp, aiNode node, Collection<String> rboneNames) {
        val back = new HashSet<Pair<String, Skeleton.Builder>>()
        val name = node.mName.toString
        if (rboneNames.contains(name)) {
            val skeleton = toSkeleton(node)
            resTmp.out.addSkeletons(skeleton)
            back.add(new Pair(name, skeleton))            
        } else {
            val nbChildren = node.mNumChildren
            for(var i = 0; i < nbChildren; i++){
                back.addAll(extractSkeleton(resTmp, node.mChildren.get(aiNode, i), rboneNames))
            }
        }
        back
    }
    
    def toSkeleton(aiNode node) {
        val skeleton = Skeleton.newBuilder()
        skeleton.id = newId()
        appendBoneToSkeleton(skeleton, node)
        skeleton
    }
    
    def Bone.Builder appendBoneToSkeleton(Skeleton.Builder skeleton, aiNode node) {
        val bone = toBone(node)
        skeleton.addBones(bone)
        val nbChildren = node.mNumChildren
        for(var i = 0; i < nbChildren; i++){
            val child = appendBoneToSkeleton(skeleton, node.mChildren.get(aiNode, i))
            skeleton.addBonesGraph(newRelation(bone.id, child.id, null))
        }
        bone
    }
    
    def Bone.Builder toBone(aiNode in) {
        val out = Bone.newBuilder()
        out.id = newId() //TODO find a better id
        out.name = in.mName.toString()
        out.transform = toTransform(in.mTransformation)
        out
    }

    def void addParentWithoutMeshes(aiNode node, Collection<String> collector) {
        val parent = node.mParent
        val name = parent.mName.toString
        if ((parent.mNumMeshes == 0) && !collector.contains(name) && !hasChildrenWithMeshes(parent)){
            collector.add(name)
            addParentWithoutMeshes(parent, collector)
        }
    }
    
    def hasChildrenWithMeshes(aiNode node) {
        var res = false
        val nbChildren = node.mNumChildren
        for(var i = 0; i < nbChildren; i++){
            res = res || (node.mChildren.get(aiNode, i).mNumMeshes > 0)
        }
        res
    }

    def extractBonesInfluences(aiMesh mesh)  {
         val influences = <BonesInfluence>newArrayOfSize(mesh.mNumVertices)
         val nbBones = mesh.mNumBones
         for(var i=0; i < nbBones; i++){
             val bone = mesh.mBones.get(aiBone, i)
             val name = bone.mName.toString
             val nbinfluence = bone.mNumWeights
             for(var j = 0; j < nbinfluence; j++) {
                //TODO influences
                val vweight = bone.mWeights.position(j) as aiVertexWeight
                var lweights = influences.get(vweight.mVertexId)
                if (lweights == null) {
                    lweights = new BonesInfluence()
                    influences.set(vweight.mVertexId, lweights)
                }
                lweights.add(name, vweight.mWeight)
             }
         }
         influences
    }

    def makeBoneIndexes(List<Bone> bones) {
        val b = new HashMap<String, Integer>()
        for(var i = 0; i < bones.size; i++) {
            b.put(bones.get(i).name, i)
        }
        new TreeMap(b)
    }

    def setupSkins(aiNode node, List<Bone> bones, ResultsTmp resTmp) {
        val boneIndexes = makeBoneIndexes(bones)
        setupSkinOnNodes(node, boneIndexes, resTmp)
    }
    
    def void setupSkinOnNodes(aiNode node, Map<String, Integer> boneIndexes, ResultsTmp resTmp) {
        for(var i = 0; i < node.mNumChildren; i++) {
            setupSkinOnNodes(node.mChildren.get(aiNode, i), boneIndexes, resTmp)
        }
        if (node.mNumMeshes != 0) {
            setupSkinOnMeshes(node, boneIndexes, resTmp)
        }
    }

    def setupSkinOnMeshes(aiNode node, Map<String, Integer> boneIndexes, ResultsTmp resTmp) {
        log.debug("try to setupSkins for nb mesh : {}", node.mNumMeshes)       
        for (var i = 0; i < node.mNumMeshes; i++) {
            val numMesh = node.mMeshes.position(i)
            val mesh = resTmp.meshes.get(numMesh)
            val boneInfluences = resTmp.skins.get(numMesh)
            if (boneInfluences != null && boneInfluences.size > 0) {
                log.debug("export skin on mesh : {}", mesh.id)
                val floats = mesh.vertexArraysList.get(0).floats
                val nbVertices = floats.valuesCount / floats.step
                if (nbVertices != boneInfluences.size) {
                    log.warn("number of vertices({}) != number of boneInfluences({})", nbVertices, boneInfluences.size)
                } else {
                    val skin = Skin.newBuilder()
                    for(var vertexI = 0; vertexI < nbVertices; vertexI++) {
                        val boneInfluence = boneInfluences.get(vertexI)?.influences()
                        val lg = if (boneInfluence != null) boneInfluence.size else 0
                        skin.addBoneCount(lg)
                        for(var boneI = 0; boneI < lg; boneI++) {
                            val influence = boneInfluence.get(boneI)
                            skin.addBoneIndex(boneIndexes.get(influence.boneName))
                            skin.addBoneWeight(influence.weight)
                        }
                    }
                    mesh.skin = skin 
                }
            }
        }
    }
    

    
}

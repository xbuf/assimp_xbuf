package assimp2xbuf

import assimp.Assimp.aiNode
import assimp.Assimp.aiScene
import assimp.Assimp.aiMesh
import assimp.Assimp.aiFace
import assimp.Assimp.aiMaterial
import assimp.Assimp.aiMatrix4x4
import assimp.Assimp.aiVector3D
import assimp.Assimp.aiQuaternion
import assimp.Assimp.aiColor3D
import assimp.Assimp.aiColor4D
import assimp.Assimp.aiString
import xbuf.Datas.Data
import xbuf.Datas.TObject
import xbuf.Datas.Transform
import xbuf.Datas.Vec3
import xbuf.Datas.Quaternion
import xbuf.Datas.Relation
import java.util.UUID
import xbuf.Datas.Geometry
import xbuf.Datas.Mesh
import xbuf.Datas.VertexArray
import xbuf.Datas.IndexArray
import xbuf.Datas.Mesh.Primitive
import java.util.HashMap
import assimp.Assimp
import xbuf.Datas.Material
import xbuf.Datas.Color
import org.bytedeco.javacpp.FloatPointer
import xbuf.Datas.Texture
import static assimp.aiTextureType.*
import java.util.Optional
import java.nio.file.FileSystems
import java.nio.file.Files
import java.nio.file.StandardCopyOption

//TODO transform to the correct convention yup, zforward, 1 unit == 1 meter
//TODO UV /textcoords in a 2D FloatBuffer
//TODO ensure normal are unitlength (idem for tangent, bitangent)
//TODO Xbuf support multi color per vertex
//TODO Xbuf support displacement Map, HeightMap, LightMap, see aiTextureType_XXXX
//TODO Xbuf assign Material to Mesh
//TODO inverse the roughnessMap (from shininessMap)
class Exporter {
    
    static class ResultsTmp {
        val out = Data.newBuilder()
        val meshes = new HashMap<Integer, Mesh.Builder>()
        val materials = new HashMap<Integer, Material.Builder>()
    }
    
    public var inputDir = FileSystems.getDefault().getPath(System.getProperty("user.dir"))
    public var outputDir = FileSystems.getDefault().getPath(System.getProperty("user.dir"))
    
    def String newId() {
        UUID.randomUUID.toString
    }
    
    def String findMeshId(int i) { "_mesh_" + i}
    def String findMaterialId(int i) { "_material_" + i}
    
    def export(aiScene scene) {
        export(new ResultsTmp(), scene).out
    }
    
	def export(ResultsTmp resTmp, aiScene scene) {
        exportMaterials(resTmp, scene)
        exportMeshes(resTmp, scene)
	    exportNodes(resTmp, scene, scene.mRootNode())
	    resTmp
	}

    def String exportNodes(ResultsTmp resTmp, aiScene scene, aiNode node) {
        val obj = toTObject(node)
        resTmp.out.addTobjects(obj)
        if (node.mNumMeshes > 0) {
            val geo = exportGeometry(resTmp, scene, node)    
            resTmp.out.addRelations(newRelation(geo.id, obj.id, null))
            println("export geometry: " + geo.id + " .. " + geo.name )
            geo.meshesList.forEach[m|
            	println("-- export mesh: " + m.name)
            	m.vertexArraysList.forEach[va|
            		println("---- export vertexarray: " + va.attrib.name)
            	]
            ]
        }
        val nbChildren = node.mNumChildren
        for(var i = 0; i < nbChildren; i++){
            val childId = exportNodes(resTmp, scene, node.mChildren.get(aiNode, i))
            resTmp.out.addRelations(newRelation(obj.id, childId, null))
        }
        obj.id
    }
 
    def exportGeometry(ResultsTmp resTmp, aiScene scene, aiNode node) {
        val geo = Geometry.newBuilder()
        geo.id = newId()
        geo.name = "__geo_" + node.mName.toString()
        node.mMeshes.forEach[i|
            val m = resTmp.meshes.get(i)
            if (m == null) {
                println("mesh ${i} not found")
            } else {
                geo.addMeshes(m)     
            }
        ]
        resTmp.out.addGeometries(geo)
        geo
    }
    
    def exportMeshes(ResultsTmp resTmp, aiScene scene) {
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
            println("<<< " + nbVertices + " .. " + mdest.name + " .. " + m.mNumFaces)
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
                    println("WARNING only support faces triange(3): " + nb)
                }
            }
            mdest.addIndexArrays(ia)
            //TODO add checker about size, ...
            mdest.primitive = Primitive.triangles
            resTmp.meshes.put(i, mdest)
            resTmp.out.addRelations(newRelation(findMaterialId(m.mMaterialIndex), mdest.id, null))
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
    	for(var i =  scene.mNumMaterials - 1; i >= 0; i--){
            val m = scene.mMaterials.get(aiMaterial, i)
            val mdest = Material.newBuilder()
            mdest.id = findMaterialId(i)
            val s = new aiString()
            if (m.Get(aiMaterial.AI_MATKEY_NAME, 0, 0, s) == Assimp.AI_SUCCESS) {
				mdest.name = s.toString()
            }
            println("export material:" + mdest.id + " .. " + mdest.name)
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
  			println("add color : " + cdest)
			Optional.of(cdest) 
        } else Optional.empty
    }
    
    val floattmp = new FloatPointer()
    def Optional<Float> readFloat(aiMaterial src, String key, float defaultValue) {
        if (src.Get(key, 0, 0, floattmp) == Assimp.AI_SUCCESS) {
			Optional.of(floattmp.get)
        } else Optional.empty // Optional.of(defaultValue)
    }

    val stringtmp = new aiString()
    def Optional<Texture.Builder> readTexture(aiMaterial src, int type) {
    	if (src.GetTextureCount(type) > 0) {
    		if (src.GetTextureCount(type) > 1) {
    			println("warning more than one texture, only Keep the first");
    		}
    		if (src.GetTexture(type, 0, stringtmp, null, null, null, null, null) == Assimp.AI_SUCCESS) {
    			val tex = Texture.newBuilder()
    			tex.id = newId()
    			val path = inputDir.resolve(FileSystems.getDefault().getPath(stringtmp.toString().replace('\\', '/').replace("_d.tga", ".tga").replace("_local.tga", "_h.tga")))
    			if (Files.isReadable(path)) {
    				val rpath = "Textures/" + path.fileName
    				val dest = outputDir.resolve(rpath)
    				Files.createDirectories(dest.parent)
    				Files.copy(path, dest, StandardCopyOption.REPLACE_EXISTING)
	    			tex.name = path.fileName.toString
	    			tex.rpath = rpath
	    			println("add texture : " + tex.rpath)
	    			Optional.of(tex)
    			} else {
	    			println("texture not found : " + path)
    				Optional.empty
   				}
			} else Optional.empty
        } else Optional.empty
    }
    
}
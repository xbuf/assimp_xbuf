package assimp2xbuf

import assimp.Assimp.aiNode
import assimp.Assimp.aiScene
import assimp.Assimp.aiMesh
import assimp.Assimp.aiFace
import assimp.Assimp.aiMatrix4x4
import assimp.Assimp.aiVector3D
import assimp.Assimp.aiQuaternion
import assimp.Assimp.aiColor4D
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
import org.bytedeco.javacpp.PointerPointer
import xbuf.Datas.IndexArray
import xbuf.Datas.UintBuffer
import xbuf.Datas.Mesh.Primitive
import java.util.HashMap

class Exporter {
    
    static class ResultsTmp {
        val out = Data.newBuilder()
        val meshes = new HashMap<Integer, Mesh.Builder>()
    }
    
    def String newId() {
        UUID.randomUUID.toString
    }
    
    def String findMeshId(int i) { "_mesh_" + i}
    
    def export(aiScene scene) {
        export(new ResultsTmp(), scene).out
    }
    
	def export(ResultsTmp resTmp, aiScene scene) {
        exportMeshes(resTmp, scene)
	    exportNodes(resTmp, scene, scene.mRootNode())
	    resTmp
	}

    def String exportNodes(ResultsTmp resTmp, aiScene scene, aiNode node) {
        val obj = toTObject(node)
        resTmp.out.addTobjects(obj)
        if (node.mNumMeshes > 0) {
            val geo = exportGeometry(resTmp, scene, node)    
            resTmp.out.addRelations(newRelation(obj.id, geo.id, null))
        }
        val nbChildren = node.mNumChildren
        for(var i = 0; i <nbChildren; i++){
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
                geo.meshesBuilderList.add(m)        
            }
        ]
        geo
    }
    
    def exportMeshes(ResultsTmp resTmp, aiScene scene) {
        for(var i =  scene.mNumMeshes - 1; i >= 0; i--){
            val m = scene.mMeshes.get(aiMesh, i)
            val mdest = Mesh.newBuilder()
            mdest.name = m.mName.toString
            mdest.id = findMeshId(i)
            val nbVertices = m.mNumVertices()           
//            addVertexArrayV3(mdest, VertexArray.Attrib.position, m.mVertices, nbVertices)
//            addVertexArrayV3(mdest, VertexArray.Attrib.normal, m.mNormals, nbVertices) //-1 or numVertices
//            addVertexArrayV3(mdest, VertexArray.Attrib.tangent, m.mTangents, nbVertices)
//            addVertexArrayV3(mdest, VertexArray.Attrib.bitangent, m.mBitangents, nbVertices)
//            addVertexArrayV3(mdest, VertexArray.Attrib.texcoord, m.mTextureCoords, nbVertices)
//            addVertexArrayColor(mdest, VertexArray.Attrib.color, m.mColors, nbVertices)
            //TODO bones, color,...
            
            val ia = IndexArray.newBuilder()
            for(var j = 0; j < m.mNumFaces; j++) {
                val faces = m.mFaces.get(aiFace, j)
                val nb = faces.mNumIndices
                if (nb == 3) {
                    for(var k = 0; k < nb; k++)
                      println(faces.mIndices.get(k))
                    //ia.intsBuilder.addAllValues()
    //TODO            } else if (nb == 4) {
                } else {
                    println("WARNING only support faces triange(3): " + nb)
                }
            }
            mdest.addIndexArrays(ia)
            //TODO add checker about size, ...
            mdest.primitive = Primitive.triangles
            //resTmp.meshes.put(i, mdest)
        }
    }
    
    def VertexArray.Builder addVertexArrayV3(Mesh.Builder mdest, VertexArray.Attrib attrib, PointerPointer<aiVector3D> list, int length) {
        val lg = if (length == -1) list.limit else length
        if (lg > 0) {
            val va = VertexArray.newBuilder()
            va.floatsBuilder.step = 3
            for(var j = 0; j < lg; j++) {
                val v3 = list.get(aiVector3D, j)
                va.floatsBuilder.addValues(v3.x)
                va.floatsBuilder.addValues(v3.y)
                va.floatsBuilder.addValues(v3.z)
            }
            va.attrib = attrib
            mdest.addVertexArrays(va)
            va
        } else null
    }
    
    def VertexArray.Builder addVertexArrayColor(Mesh.Builder mdest, VertexArray.Attrib attrib, PointerPointer<aiColor4D> list, int length) {
        val lg = if (length == -1) list.limit else length
        if (lg > 0) {
            val va = VertexArray.newBuilder()
            va.floatsBuilder.step = 4
            for(var j = 0; j < lg; j++) {
                val v4 = list.get(aiColor4D, j)
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
}
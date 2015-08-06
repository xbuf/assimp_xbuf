package assimp2xbuf

import assimp.Assimp.Importer

import static assimp.aiPostProcessSteps.*
import java.io.File
import java.nio.file.FileSystems
import java.nio.file.Files
import xbuf.Datas.Data
import java.util.LinkedList
import xbuf.Datas.TObject
import xbuf.Datas.Vec3
import java.util.HashMap
import java.util.HashSet
import java.util.ArrayList
import xbuf.Datas.Bone
import xbuf.Datas.Skeleton

class Main {
	def static void main(String[] args) {
		//val inputPath = System.getProperty("user.home") + "/work/xbuf/samples/assimp/models/Collada/duck.dae"
    val inputPath = System.getProperty("user.home") + "/work/xbuf/samples/assimp/models-nonbsd/MD5/Bob.md5mesh"
		val inputDir = FileSystems.getDefault().getPath(inputPath).parent

		//val doom3Root = System.getProperty("user.home") + "/work/xbuf/samples/doom3"
		//val inputPath = doom3Root + "/models/md5/monsters/hellknight/hellknight.md5mesh"
		//val inputDir = FileSystems.getDefault().getPath(doom3Root)

    val outputDir = FileSystems.getDefault().getPath(System.getProperty("user.dir"))
		val outputFile = outputDir.resolve(FileSystems.getDefault().getPath(new File(inputPath).name + ".xbuf"))


		//val outputPath = args.get(0)
		//val inputPath = args.get(1)

		if (!new File(inputPath).exists) {
		    System.err.println("file not found : " + inputPath)
		    return
		}

		val importer = new Importer()
		val scene = importer.ReadFile(inputPath,
			0.bitwiseOr(aiProcess_CalcTangentSpace)
		    //.bitwiseOr(aiProcess_FlipWindingOrder)
		    .bitwiseOr(aiProcess_GenUVCoords)
		    .bitwiseOr(aiProcess_GenSmoothNormals)
		    .bitwiseOr(aiProcess_OptimizeGraph)
		    .bitwiseOr(aiProcess_OptimizeMeshes)
		    //.bitwiseOr(aiProcess_FlipUVs)
		    .bitwiseOr(aiProcess_Triangulate)
		    .bitwiseOr(aiProcess_JoinIdenticalVertices)
		    .bitwiseOr(aiProcess_SortByPType)
		)

		// If the import failed, report it
		if( scene != null) {
		    val exporter = new Exporter()
			exporter.textureInPathTransform = [ AssetPath v |
				// HACK for texture from DOOM3
				val str = v.rpath.replace("_d.tga", ".tga").replace("_local.tga", "_h.tga")
				new AssetPath(str, inputDir.resolve(str))
			]
			exporter.textureOutPathTransform = [ AssetPath v |
				val rpath = "Textures/" + v.path.fileName
				new AssetPath(rpath, outputDir.resolve(rpath))
			]
			val out = exporter.export(scene)
			rescale(out, 0.05f)
			val output = Files.newOutputStream(outputFile)
			out.build().writeTo(output)
			output.close()
            System.out.printf("nb materials:  %s\n", out.materialsCount);
            System.out.printf("nb meshes:  %s\n", out.meshesCount);
            System.out.printf("nb relations:  %s\n", out.relationsCount);
            System.out.printf("nb skeletons: %s\n", out.skeletonsCount);
            System.out.printf("nb tobjects:  %s\n", out.tobjectsCount);
		} else {
			System.out.printf("empty scene !!")
		}
	}
	
	static def aabb(Data.Builder data){
	    
	}
	
	static def rescale(Data.Builder data, float coeff) {
	    val tobjects = new HashMap<String, TObject.Builder>()
	    val leafIds = new HashSet<String>()
	    for(tobj: data.tobjectsList) {
	        val nobj = TObject.newBuilder(tobj)
	        nobj.transformBuilder.translation = mult(nobj.transformBuilder.translation, coeff)
	        tobjects.put(nobj.id, nobj)
	        leafIds.add(nobj.id)
	    }
	    for(rel: data.relationsList) {
	        if (leafIds.contains(rel.ref1)) {
    	        val ref1IsParent = tobjects.containsKey(rel.ref1) && tobjects.containsKey(rel.ref2)
    	        if (ref1IsParent) leafIds.remove(rel.ref1)
    	    }
	    }
	    for(leafId: leafIds) {
	        val nobj = tobjects.get(leafId)
	        nobj.transformBuilder.scale = mult(nobj.transformBuilder.scale, coeff)
	    }
	    data.clearTobjects()
	    data.addAllTobjects(tobjects.values.map[it.build()])
	    //data.tobjectsList.clear()
	    //data.tobjectsBuilderList = tobjects.values.toList
	    //data.tobjectsBuilderList.addAll(tobjects.values)
	    
        val nskeletons = new ArrayList<Skeleton.Builder>(data.skeletonsCount)
        for(skeleton: data.skeletonsList) {
            val nskeleton = Skeleton.newBuilder(skeleton)
            val nbones = new ArrayList<Bone.Builder>(skeleton.bonesCount)
            for(bone: skeleton.bonesList) {
                val nbone = Bone.newBuilder(bone)
                nbone.transformBuilder.translation = mult(nbone.transformBuilder.translation, coeff)
                nbones.add(nbone)
            }
            nskeleton.clearBones()
            nskeleton.addAllBones(nbones.map[it.build()])
            nskeletons.add(nskeleton)
        }
        data.clearSkeletons()
        data.addAllSkeletons(nskeletons.map[it.build()])
	}

    static def mult(Vec3 v3, float coeff) {	
        val nv3 = Vec3.newBuilder()
        nv3.x = v3.x * coeff
        nv3.y = v3.y * coeff
        nv3.z = v3.z * coeff
        nv3
    }
}

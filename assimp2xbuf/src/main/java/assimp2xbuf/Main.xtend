package assimp2xbuf

import assimp.Assimp.Importer
import java.io.FileOutputStream

import static assimp.aiPostProcessSteps.*
import java.io.File

class Main {
	def static void main(String[] args) {
		val outputPath ="hellknight.xbuf"
		//val inputPath ="/home/dwayne/work/xbuf/samples/doom3/models/md5/monsters/hellknight/hellknight.md5mesh"
        val inputPath ="/Users/davidb/Downloads/assimp-3.1.1/test/models-nonbsd/MD5/Bob.md5mesh"

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
		    //.bitwiseOr(aiProcess_GenUVCoords)
		    //.bitwiseOr(aiProcess_FlipUVs)
		    .bitwiseOr(aiProcess_Triangulate)
		    .bitwiseOr(aiProcess_JoinIdenticalVertices)
		    .bitwiseOr(aiProcess_SortByPType)
		)
  
		// If the import failed, report it
		if( scene != null) {
		    val exporter = new Exporter()
            val out = exporter.export(scene)
            val output = new FileOutputStream(outputPath)
            out.build().writeTo(output)
            output.close()
	  		System.out.printf("HasAnimations %s\n", scene.HasAnimations());
  			System.out.printf("HasCameras %s\n", scene.HasCameras());
  			System.out.printf("HasMaterials %s\n", scene.HasMaterials());
			//System.out.printf("Print Nodes");
  			//printNode(scene.mRootNode(),"|");
  		} else {
  		    System.out.printf("empty scene !!")
  		}
	}
}
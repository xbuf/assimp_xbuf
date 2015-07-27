package assimp2xbuf

import assimp.Assimp.Importer
import java.io.FileOutputStream
import xbuf.Datas

import static assimp.aiPostProcessSteps.*

class Main {
	def static void main(String[] args) {
		val outputPath ="hellknight.xbuf"
		val inputPath ="/home/dwayne/work/xbuf/samples/doom3/models/md5/monsters/hellknight/hellknight.md5mesh"

		//val outputPath = args.get(0)
		//val inputPath = args.get(1)
		
		val importer = new Importer()
		val scene = importer.ReadFile( inputPath,
			0.bitwiseOr(aiProcess_CalcTangentSpace)
		    .bitwiseOr(aiProcess_FlipWindingOrder)
		    .bitwiseOr(aiProcess_GenUVCoords)
		    //.bitwiseOr(aiProcess_FlipUVs)
		    .bitwiseOr(aiProcess_Triangulate)
		    .bitwiseOr(aiProcess_JoinIdenticalVertices)
		    .bitwiseOr(aiProcess_SortByPType)
		)
  
		// If the import failed, report it
		if( scene != null) {
	  		System.out.printf("HasAnimations %s\n", scene.HasAnimations());
  			System.out.printf("HasCameras %s\n", scene.HasCameras());
  			System.out.printf("HasMaterials %s\n", scene.HasMaterials());
			//System.out.printf("Print Nodes");
  			//printNode(scene.mRootNode(),"|");
  		}
		  
		val data = Datas.Data.newBuilder();
		//data.addTobjects()
		  
		val output = new FileOutputStream(outputPath);
    	data.build().writeTo(output);
		output.close();
		  
		  
	}
}
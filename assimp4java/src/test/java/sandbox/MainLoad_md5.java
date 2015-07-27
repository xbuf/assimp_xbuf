package sandbox;

import assimp.Assimp.*;
import static assimp.aiPostProcessSteps.*;

import org.bytedeco.javacpp.PointerPointer;

public class MainLoad_md5 {
	public static void main(String[] args) {
		Importer importer = new Importer();
		aiScene scene = importer.ReadFile( "/home/dwayne/work/xbuf/samples/doom3/models/md5/monsters/hellknight/hellknight.md5mesh", 
		        aiProcess_CalcTangentSpace       |
		        aiProcess_FlipWindingOrder       |
		        aiProcess_GenUVCoords            |
		        //aiProcess_FlipUVs                |
		        aiProcess_Triangulate            |
		        aiProcess_JoinIdenticalVertices  |
		        aiProcess_SortByPType);
		  
		  // If the import failed, report it
		  if( scene != null) {
			  System.out.printf("HasAnimations %s\n", scene.HasAnimations());
			  System.out.printf("HasCameras %s\n", scene.HasCameras());
			  System.out.printf("HasMaterials %s\n", scene.HasMaterials());
			  System.out.printf("Print Nodes");
			  printNode(scene.mRootNode(),"|");
		  }
	}
	
	public static void printNode(aiNode n, String prefix) {
		System.out.printf("%s %s\n", prefix, n.mName());
		int nb = n.mNumChildren();
		if (nb > 0) {
			String prefix2 = prefix+ "--";
			PointerPointer<aiNode> children = n.mChildren();
			for(int i = 0; i < nb; i++) {
				printNode(children.get(aiNode.class, i), prefix2);
			}
		}
	}
}

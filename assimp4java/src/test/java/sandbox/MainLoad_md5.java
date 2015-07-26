package sandbox;

import assimp.Assimp.*;
import static assimp.aiPostProcessSteps.*;

public class MainLoad_md5 {
	public static void main(String[] args) {
		Importer importer = new Importer();
		aiScene scene = importer.ReadFile( "/home/dwayne/work/xbuf/samples/doom3/models/md5/monsters/hellknight/hellknight.md5mesh", 
		        aiProcess_CalcTangentSpace       | 
		        aiProcess_Triangulate            |
		        aiProcess_JoinIdenticalVertices  |
		        aiProcess_SortByPType);
		  
		  // If the import failed, report it
		  if( scene != null) {
			  System.out.printf("HasAnimations %s\n", scene.HasAnimations());
			  System.out.printf("HasCameras %s\n", scene.HasCameras());
			  System.out.printf("HasMaterials %s\n", scene.HasMaterials());
		  }
	}
}

package assimp2xbuf

import assimp.Assimp.Importer

import static assimp.aiPostProcessSteps.*
import java.io.File
import java.nio.file.FileSystems
import java.nio.file.Files

class Main {
	def static void main(String[] args) {
		//val inputPath = System.getProperty("user.home") + "/work/xbuf/samples/assimp/models/Collada/duck.dae"
        //val inputPath ="/Users/davidb/Downloads/assimp-3.1.1/test/models-nonbsd/MD5/Bob.md5mesh"
		//val inputDir = FileSystems.getDefault().getPath(inputPath).parent
		val doom3Root = System.getProperty("user.home") + "/work/xbuf/samples/doom3"
		val inputPath = doom3Root + "/models/md5/monsters/hellknight/hellknight.md5mesh"
		val inputDir = FileSystems.getDefault().getPath(doom3Root)

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
			val output = Files.newOutputStream(outputFile)
			out.build().writeTo(output)
			output.close()
			System.out.printf("HasAnimations %s\n", scene.HasAnimations());
			System.out.printf("HasCameras %s\n", scene.HasCameras());
			System.out.printf("HasMaterials %s\n", scene.HasMaterials());
		// System.out.printf("Print Nodes");
		// printNode(scene.mRootNode(),"|");
		} else {
			System.out.printf("empty scene !!")
		}
	}
}

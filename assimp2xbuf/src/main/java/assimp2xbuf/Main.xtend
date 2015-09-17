package assimp2xbuf

import assimp.Assimp.Importer
import com.beust.jcommander.JCommander
import com.beust.jcommander.Parameter
import com.beust.jcommander.ParameterException
import java.nio.file.FileSystems
import java.nio.file.Files
import java.util.ArrayList
import java.util.List
import xbuf.Datas.Data
import xbuf.Skeletons.Skeleton
import xbuf_ext.AnimationsKf.AnimationKF
import xbuf_tools.AABBTools
import xbuf_tools.DataTools

import static assimp.aiPostProcessSteps.*

class Main {
    static def main(String[] args) {
        var args0 = args
        if (args.isEmpty) {
            //args0 = #["--height", "0.2", System.getProperty("user.home") + "/work/xbuf/samples2/assimp/models/Collada/duck.dae"
//            args0 = #[
//            	"--height", "1.7"
//                ,System.getProperty("user.home") + "/work/xbuf/samples/assimp/models-nonbsd/MD5/Bob.md5mesh"
//                //,System.getProperty("user.home") + "/work/xbuf/samples/assimp/models-nonbsd/MD5/Bob.md5anim"
//            ]
            //args0 = #[System.getProperty("user.home") + "/work/xbuf/samples/bitgem/micro_bat_lp/models/micro_bat_mobile.fbx"
            //args0 = #[System.getProperty("user.home") + "/work/xbuf/samples/bitgem/micro_bat_lp/models/micro_bat_mobile.dae"
    
            val doom3Root = System.getProperty("user.home") + "/work/xbuf/samples/doom3"
            args0 = #["--height", "2.7"
            	,"--inputdir", doom3Root
            	, doom3Root + "/models/md5/monsters/hellknight/hellknight.md5mesh"
           	]
        }        
        val options = new Options()
        val jc = new JCommander(options)
        try {
            jc.parse(args0)
            if (options.help) {
                jc.usage()
            } else {
                run(options)
            }
        } catch(ParameterException exc) {
            jc.usage()
            System.err.println(exc.getMessage())
            System.exit(-2)
        } catch(Exception exc) {
            exc.printStackTrace()
            System.exit(-1)
        }
    }

    static class Options {
        @Parameter(names = #["-h", "-?", "--help"], help = true)
        private var boolean help

        @Parameter(description = "input files")
        private var List<String> inputFiles = new ArrayList<String>()

        @Parameter(names=#["--inputdir"], description = "input directory for additional files(eg texture, sound, ...)")
        private var List<String> inputDirs = new ArrayList<String>()

        @Parameter(names = #["--outputfile", "-o"], description = "output xbuf file")
        private var String outputFile = ""

        @Parameter(names = #["--outputdir","-d"], description = "output directory for non-xbuf files (eg images)")
        private var String outputDir = System.getProperty("user.dir")

        @Parameter(names = #["--height"], description = "height of the models in meters (the unit of xbuf)")
        private var float height = 1.0f
    }
    
	def static void run(Options options) {
		val inputPaths = options.inputFiles.map[p|
        	FileSystems.getDefault().getPath(p)
        ].filter[p|
            val f = p.toFile
        	val exists = f.exists && f.isFile && f.canRead
			if (!exists) {
		    	System.err.println("file not found : " + p)
		    }
			exists
		].toList
		if (inputPaths.empty) {
		    System.err.println("file(s) not found: nothing to do")
		    return
		}

        val inputDirs = options.inputDirs.map[p|
            FileSystems.getDefault().getPath(p)
        ].filter[p|
            val f = p.toFile
            val exists = f.exists && f.isDirectory && f.canRead 
            if (!exists) {
                System.err.println("directory not found : " + p)
            }
            exists
        ].toList
        inputDirs.addAll(inputPaths.map[p| p.parent])

        val outputDir = FileSystems.getDefault().getPath(options.outputDir)
        val of = if (options.outputFile.isNullOrEmpty) inputPaths.get(0).last + ".xbuf" else options.outputFile
		val outputFile = outputDir.resolve(FileSystems.getDefault().getPath(of))

		val importer = new Importer()
		val scenes = inputPaths.map[p|
			val scene = importer.ReadFile(p.toString,
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
			if (scene == null) {
				System.out.printf("empty scene !! for " + p)
			}
			scene
		].filter[it != null]

		// If the import failed, report it
		if( !scenes.empty) {
		    val exporter = new Exporter()
			exporter.textureInPathTransform = [ AssetPath v |
				// HACK for texture from DOOM3
				val str = v.rpath.replace("_d.tga", ".tga").replace("_local.tga", "_h.tga")
				var found = inputDirs.findFirst[d|
					d.resolve(str).toFile.exists
				]
				if (found == null) {
					found = inputDirs.get(0)
				}
				new AssetPath(str, found.resolve(str))
			]
			exporter.textureOutPathTransform = [ AssetPath v |
				val rpath = "Textures/" + v.path.fileName
				new AssetPath(rpath, outputDir.resolve(rpath))
			]
			val out = scenes.fold(Data.newBuilder())[acc, scene| exporter.export(scene, acc)]
			val aabb = DataTools.aabbAll(out)
			val coeff = options.height / AABBTools.dimension(aabb).y
			//val coeff = 0.05f
			DataTools.rescale(out, coeff)
			linkAnimationsToSkeleton(out, exporter)
			val output = Files.newOutputStream(outputFile)
			out.build().writeTo(output)
			output.close()
            System.out.printf("nb materials:     %s\n", out.materialsCount);
            System.out.printf("nb meshes:        %s\n", out.meshesCount);
            System.out.printf("nb relations:     %s\n", out.relationsCount);
            System.out.printf("nb skeletons:     %s\n", out.skeletonsCount);
            System.out.printf("nb tobjects:      %s\n", out.tobjectsCount);
            System.out.printf("nb animationKfs:  %s\n", out.animationsKfCount);
            System.out.printf("rescale coeff:    %s (%s -> %s)\n", coeff, AABBTools.dimension(aabb).y, options.height);
            System.out.printf("output file:      %s\n", outputFile)
            System.out.printf("output dir:       %s\n", outputDir)
		}
	}

    static def linkAnimationsToSkeleton(Data.Builder data, Exporter exporter) {
        if (data.skeletonsCount == 1) {
            val skeleton = data.getSkeletons(0)
            for (anim: data.animationsKfList) {
                //TODO check if animation is compatible with skeleton
                data.addRelations(exporter.newRelation(AnimationKF, anim.id, Skeleton, skeleton.id, null))
            }
        }
    }
}

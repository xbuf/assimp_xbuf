package assimp;

import org.bytedeco.javacpp.*;
import org.bytedeco.javacpp.annotation.*;

@Properties({
	@Platform(value="linux-x86_64", include="javacpp-code.h", link = "assimp"),
	@Platform(value="windows-x86_64", include="javacpp-code.h", link = "assimp"),
	@Platform(value="windows-x86_32", include="javacpp-code.h", link = "assimp"),
	@Platform(value="macosx-x86_64", include="javacpp-code.h", link = "assimp")
})
// "link" tells javacpp which original library should be linked (if not specified, "Abc" will be used)
public class Assimp {
	static { Loader.load(); }

	public static final int AI_MAX_NUMBER_OF_TEXTURECOORDS = 0x8;
	public static final int AI_MAX_NUMBER_OF_COLOR_SETS = 0x8;
	public static final int AI_SUCCESS = 0x0;
	public static final int AI_FAILURE = -0x1;
	public static final int AI_OUTOFMEMORY = -0x3;
	
	@Namespace("Assimp") // Namespace where all c++ code must reside
	public static class Importer extends Pointer {
		static { Loader.load(); }
	    public Importer() { allocate(); }
	    public native void allocate();
		public native @Const aiScene ReadFile(String pFile, int pFlags);
	}
	
	public static class aiScene extends Pointer{
		static { Loader.load(); }
	    public native boolean HasAnimations();
	    public native boolean HasCameras();
	    public native boolean HasLights();
	    public native boolean HasMaterials();
	    public native boolean HasMeshes();
	    public native boolean HasTextures();
		@MemberGetter public native @Cast("aiMesh**") PointerPointer<aiMesh> mMeshes();
		@MemberGetter public native int mNumMeshes();
		@MemberGetter public native @Cast("aiMaterial**") PointerPointer<aiMaterial> mMaterials();
		@MemberGetter public native int mNumMaterials();
	    @MemberGetter public native aiNode mRootNode();
		@MemberGetter public native @Cast("aiAnimation**") PointerPointer<aiAnimation> mAnimations();
		@MemberGetter public native int mNumAnimations();
	}
	
	public static class aiNode extends Pointer {
		static { Loader.load(); }
		public native aiNode FindNode(String name);
		@MemberGetter public native @Cast("aiNode**") PointerPointer<aiNode> mChildren();
		@MemberGetter public native @Cast("unsigned int*") int[] mMeshes();
		@MemberGetter public native @ByVal aiString mName();
		@MemberGetter public native int mNumChildren();
		@MemberGetter public native int mNumMeshes();
		@MemberGetter public native aiNode mParent();
		//@MemberGetter public native @ByVal aiMatrix4x4t<Float> mTransformation();
		@MemberGetter public native @ByVal aiMatrix4x4 mTransformation();
	}
	
	public static class aiString extends Pointer{
		static { Loader.load(); }
	    public aiString() { allocate(); }
	    public native void allocate();
	    
		public native String C_Str();
		@Override public String toString(){ return C_Str(); }
	}
	public static class aiMatrix4x4 extends Pointer {
		static { Loader.load(); }
		@MemberGetter public native @ByVal float a1();
		@MemberGetter public native @ByVal float a2();
		@MemberGetter public native @ByVal float a3();
		@MemberGetter public native @ByVal float a4();
		@MemberGetter public native @ByVal float b1();
		@MemberGetter public native @ByVal float b2();
		@MemberGetter public native @ByVal float b3();
		@MemberGetter public native @ByVal float b4();
		@MemberGetter public native @ByVal float c1();
		@MemberGetter public native @ByVal float c2();
		@MemberGetter public native @ByVal float c3();
		@MemberGetter public native @ByVal float c4();
		@MemberGetter public native @ByVal float d1();
		@MemberGetter public native @ByVal float d2();
		@MemberGetter public native @ByVal float d3();
		@MemberGetter public native @ByVal float d4();
		public native void Decompose(@ByRef aiVector3D scaling, @ByRef aiQuaternion rotation, @ByRef aiVector3D position); 
	}
	
	public static class aiVector3D extends Pointer {
		static { Loader.load(); }
	    public aiVector3D() { allocate(); }
	    public native void allocate();

	    @MemberGetter public native @ByVal float x();
		@MemberGetter public native @ByVal float y();
		@MemberGetter public native @ByVal float z();
	}
	
	public static class aiQuaternion extends Pointer{
		static { Loader.load(); }
	    public aiQuaternion() { allocate(); }
	    public native void allocate();

	    @MemberGetter public native @ByVal float w();
		@MemberGetter public native @ByVal float x();
		@MemberGetter public native @ByVal float y();
		@MemberGetter public native @ByVal float z();		
	}
	
	public static class aiColor3D extends Pointer {
		static { Loader.load(); }
	    public aiColor3D() { allocate(); }
	    public native void allocate();
		@MemberGetter public native @ByVal float b();
		@MemberGetter public native @ByVal float g();
		@MemberGetter public native @ByVal float r();
	}
	
	public static class aiColor4D extends Pointer {
		static { Loader.load(); }
	    public aiColor4D() { allocate(); }
	    public native void allocate();
		@MemberGetter public native @ByVal float a();
		@MemberGetter public native @ByVal float b();
		@MemberGetter public native @ByVal float g();
		@MemberGetter public native @ByVal float r();
	}
	
	public static class aiMesh extends Pointer {
		static { Loader.load(); }
		public native @Cast("unsigned int") int GetNumColorChannels();	
		public native @Cast("unsigned int") int GetNumUVChannels();
		public native boolean HasBones();
		public native boolean HasFaces();
		public native boolean HasNormals();
		public native boolean HasPositions();
		public native boolean HasTangentsAndBitangents();
		public native boolean HasTextureCoords(@Cast("unsigned int") int pIndex);
		public native boolean HasVertexColors(@Cast("unsigned int") int pIndex);
		@MemberGetter public native @Cast("aiVector3D*") aiVector3D mBitangents();
		@MemberGetter public native @Cast("aiBone**") PointerPointer<aiBone> mBones();
		@MemberGetter public native @Cast("aiColor4D**") PointerPointer<aiColor4D> mColors();// [AI_MAX_NUMBER_OF_COLOR_SETS]
		@MemberGetter public native @Cast("aiFace*") aiFace mFaces();
		@MemberGetter public native @Cast("unsigned int") int mMaterialIndex();
		@MemberGetter public native @ByVal aiString mName();
		@MemberGetter public native @Cast("aiVector3D*") aiVector3D mNormals();
		@MemberGetter public native @Cast("unsigned int") int mNumBones();
		@MemberGetter public native @Cast("unsigned int") int mNumFaces();
		@MemberGetter public native @Cast("unsigned int*") int[] mNumUVComponents();// [AI_MAX_NUMBER_OF_TEXTURECOORDS]
		@MemberGetter public native @Cast("unsigned int") int mNumVertices();
		@MemberGetter public native @Cast("unsigned int") int mPrimitiveTypes();
		@MemberGetter public native @Cast("aiVector3D*") aiVector3D mTangents();
		@MemberGetter public native @Cast("aiVector3D**") PointerPointer<aiVector3D> mTextureCoords(); //[AI_MAX_NUMBER_OF_TEXTURECOORDS]
		@MemberGetter public native @Cast("aiVector3D*") aiVector3D mVertices();
	}
	
	public static class aiFace extends Pointer {
		static { Loader.load(); }
		@MemberGetter public native @Cast("unsigned int*") IntPointer mIndices();
	 	@MemberGetter public native @Cast("unsigned int") int mNumIndices();
	}

	public static class aiBone extends Pointer {
		static { Loader.load(); }
		@MemberGetter public native @ByVal aiString mName();
		@MemberGetter public native @Cast("unsigned int") int mNumWeights();
		@MemberGetter public native @ByVal aiMatrix4x4 mOffsetMatrix();
		@MemberGetter public native @Cast("aiVertexWeight*") aiVertexWeight mWeights();
	}

	public static class aiVertexWeight extends Pointer {
		static { Loader.load(); }
		@MemberGetter public native @Cast("unsigned int")int mVertexId();
		@MemberGetter public native float mWeight();
	}

	public static class aiMaterial extends Pointer {
		static { Loader.load(); }
		// aiReturn Get(const char* pKey,unsigned int type, unsigned int idx, int& pOut) const;
		public static final String AI_MATKEY_NAME = "?mat.name"; //,0,0
		public static final String AI_MATKEY_TWOSIDED = "$mat.twosided"; //,0,0
		public static final String AI_MATKEY_SHADING_MODEL ="$mat.shadingm"; //,0,0
		public static final String AI_MATKEY_ENABLE_WIREFRAME ="$mat.wireframe"; //,0,0
		public static final String AI_MATKEY_BLEND_FUNC ="$mat.blend"; //,0,0
		public static final String AI_MATKEY_OPACITY ="$mat.opacity"; //,0,0
		public static final String AI_MATKEY_BUMPSCALING ="$mat.bumpscaling"; //,0,0
		public static final String AI_MATKEY_SHININESS ="$mat.shininess"; //,0,0
		public static final String AI_MATKEY_REFLECTIVITY ="$mat.reflectivity"; //,0,0
		public static final String AI_MATKEY_SHININESS_STRENGTH ="$mat.shinpercent"; //,0,0
		public static final String AI_MATKEY_REFRACTI ="$mat.refracti"; //,0,0
		public static final String AI_MATKEY_COLOR_DIFFUSE ="$clr.diffuse"; //,0,0
		public static final String AI_MATKEY_COLOR_AMBIENT ="$clr.ambient"; //,0,0
		public static final String AI_MATKEY_COLOR_SPECULAR ="$clr.specular"; //,0,0
		public static final String AI_MATKEY_COLOR_EMISSIVE ="$clr.emissive"; //,0,0
		public static final String AI_MATKEY_COLOR_TRANSPARENT ="$clr.transparent"; //,0,0
		public static final String AI_MATKEY_COLOR_REFLECTIVE ="$clr.reflective"; //,0,0
		public static final String AI_MATKEY_GLOBAL_BACKGROUND_IMAGE ="?bg.global"; //,0,0

		public native int Get(String pKey, int type, int idx, IntPointer pOut);
		public native int Get(String pKey, int type, int idx, FloatPointer pOut);
		public native int Get(String pKey, int type, int idx, @ByRef aiString pOut);
		public native int Get(String pKey, int type, int idx, @ByRef aiColor3D pOut);
		public native int Get(String pKey, int type, int idx, @ByRef aiColor4D pOut);

		/**
		 * @param type aiTextureType
		 * @return
		 */
		public native int GetTextureCount(@Cast("aiTextureType")int type);
		public native int GetTexture(@Cast("aiTextureType")int	type,
				int index,
				aiString path,
				@Cast("aiTextureMapping*") Pointer mapping,
				@Cast("unsigned int*") Pointer uvindex,
				@Cast("float *") Pointer blend,
				@Cast("aiTextureOp *") Pointer op,
				@Cast("aiTextureMapMode *") Pointer mapmode); 	
	}
	public static class aiAnimation extends Pointer {
		static { Loader.load(); }
		@MemberGetter public native @ByVal aiString mName();
		@MemberGetter public native @Cast("aiNodeAnim**") PointerPointer<aiNodeAnim> mChannels();
		@MemberGetter public native @Cast("unsigned int") int mNumChannels();
		@MemberGetter public native double mDuration();
		@MemberGetter public native double mTicksPerSecond();
//		@MemberGetter public native @Cast("aiMeshAnim**") PointerPointer<aiMeshAnim> mMeshChannels();
//		@MemberGetter public native @Cast("unsigned int") int mNumMeshChannels();
	}
	public static class aiNodeAnim extends Pointer {
		static { Loader.load(); }
		@MemberGetter public native @ByVal aiString mNodeName();
		@MemberGetter public native @Cast("unsigned int") int mNumPositionKeys();
		@MemberGetter public native @Cast("unsigned int") int mNumRotationKeys();
		@MemberGetter public native @Cast("unsigned int") int mNumScalingKeys();
		@MemberGetter public native aiVectorKey mPositionKeys();
		@MemberGetter public native aiQuatKey mRotationKeys();
		@MemberGetter public native aiVectorKey mScalingKeys();
		@MemberGetter public native @Cast("aiAnimBehaviour") int mPostState();
		@MemberGetter public native @Cast("aiAnimBehaviour") int mPreState();
	}
	public static class aiVectorKey extends Pointer {
		static { Loader.load(); }
		@MemberGetter public native double mTime();
		@MemberGetter public native @ByVal aiVector3D mValue();
	}
	public static class aiQuatKey extends Pointer {
		static { Loader.load(); }
		@MemberGetter public native double mTime();
		@MemberGetter public native @ByVal aiQuaternion mValue();
	}
	public static class aiMeshAnim extends Pointer {
	static { Loader.load(); }
}
//	public static class aiMeshAnim extends Pointer {
//		static { Loader.load(); }
//	}
}



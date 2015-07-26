package assimp;

import java.nio.ByteBuffer;
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

	@Namespace("Assimp") // Namespace where all c++ code must reside
	public static class Importer extends Pointer {
		static { Loader.load(); }
	    public Importer() {
	        allocate();
	    }

	    public native void allocate();
		public native @Const aiScene ReadFile(String pFile, int pFlags);
		// public native void Startup(int maxConnections, SocketDescriptor socketDescriptors, int socketDescriptorCount, int   threadPriority);
		// public native void SetMaximumIncomingConnections(int maxConnections);
		// public native Packet Receive();
		// public native int Send(BitStream bitStream, @Cast("PacketPriority") int priority, @Cast("PacketReliability") int reliability, char orderingChannel, @ByVal AddressOrGUID systemIdentifier, boolean broadcast, int forceReceiptNumber);
		// public final  int Send(byte k, byte[] b, PacketPriority.E priority, PacketReliability.E reliability, char orderingChannel, AddressOrGUID systemIdentifier, boolean broadcast, int forceReceiptNumber) {
		//   BitStream bsOut = new BitStream();
		//   bsOut.Write(k);
		//   bsOut.WriteAlignedBytes(new BytePointer(b), b.length);
		//   return Send(bsOut, priority.ordinal(),reliability.ordinal(), orderingChannel, systemIdentifier, broadcast, forceReceiptNumber);
		// }
		// public native void DeallocatePacket(Packet v);
		// public native /*@ByVal @Cast("ConnectionAttemptResult")*/int Connect(String host, int remotePort, String passwordData, int passwordDataLength); //, PublicKey publicKey, int connectionSocketIndex, int sendConnectionAttemptCount/*=12*/, int timeBetweenSendConnectionAttemptsMS/*=500*/, RakNet::TimeMS timeoutTime=0 );
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
	    @MemberGetter public native aiNode mRootNode();
	}
	
	public static class aiNode extends Pointer {
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
		public native String C_Str();
		@Override public String toString(){ return C_Str(); }
	}
	public static class aiMatrix4x4 extends Pointer {
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
		//public native void Decompose(aiVector3 scaling, aiQuaternion rotation, aiVector3 position); 
	}
	
	public static class aiVector3D extends Pointer {
		
	}
//	
//	public static class aiQuaternion extends Pointer{
//		
//	}

	public static class aiMesh extends Pointer {
		
	}
	
	/*
	public static class aiMatrix4x4t<T> extends Pointer {
		@MemberGetter public native @ByVal T a1();
		@MemberGetter public native @ByVal T a2();
		@MemberGetter public native @ByVal T a3();
		@MemberGetter public native @ByVal T a4();
		@MemberGetter public native @ByVal T b1();
		@MemberGetter public native @ByVal T b2();
		@MemberGetter public native @ByVal T b3();
		@MemberGetter public native @ByVal T b4();
		@MemberGetter public native @ByVal T c1();
		@MemberGetter public native @ByVal T c2();
		@MemberGetter public native @ByVal T c3();
		@MemberGetter public native @ByVal T c4();
		@MemberGetter public native @ByVal T d1();
		@MemberGetter public native @ByVal T d2();
		@MemberGetter public native @ByVal T d3();
		@MemberGetter public native @ByVal T d4();
		
		public native void Decompose(aiVector3t<T> scaling, aiQuaterniont<T> rotation, aiVector3t<T> position); 
		
	}

	public static class aiVector3t<T> extends Pointer {
		
	}
	
	public static class aiQuaterniont<T> extends Pointer{
		
	}
*/
}



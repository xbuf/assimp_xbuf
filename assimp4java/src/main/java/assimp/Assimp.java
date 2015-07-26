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
	}
}



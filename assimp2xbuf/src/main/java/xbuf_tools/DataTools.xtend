package xbuf_tools

import java.util.ArrayList
import java.util.HashMap
import java.util.HashSet
import xbuf.Datas.Data
import xbuf.Skeletons.Bone
import xbuf.Skeletons.Skeleton
import xbuf.Tobjects.TObject
import xbuf_ext.AnimationsKf.AnimationKF
import xbuf_ext.AnimationsKf.Clip
import xbuf_ext.AnimationsKf.SampledTransform

import static xbuf_tools.Vec3Tools.mult
import org.joml.Matrix4f

class DataTools {
	static def aabbAll(Data.Builder data) {
		val roots = TObjectTools.findRoots(data)
		AABBTools.compute(roots, new Matrix4f().identity(), data)
	}

	static def rescale(Data.Builder data, float coeff) {
		rescaleTobjects(data, coeff)
		rescaleSkeletons(data, coeff)
		rescaleAnimationsKf(data, coeff)
		data
	}

	static def rescaleTobjects(Data.Builder data, float coeff) {
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
    }
    
    static def rescaleSkeletons(Data.Builder data, float coeff) {
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
    
    static def rescaleAnimationsKf(Data.Builder data, float coeff) {
        val nanims = new ArrayList<AnimationKF.Builder>(data.animationsKfCount)
        for(anim: data.animationsKfList) {
            val nanim = AnimationKF.newBuilder(anim)
            val nclips = new ArrayList<Clip.Builder>(anim.clipsCount)
            for(clip: anim.clipsList) {
                val nclip = Clip.newBuilder(clip)
                val nsampled = SampledTransform.newBuilder(clip.sampledTransform)
                val xs = nsampled.translationXList.map[v|v * coeff].toList
                nsampled.clearTranslationX()
                nsampled.addAllTranslationX(xs)
                val ys = nsampled.translationYList.map[v|v * coeff].toList
                nsampled.clearTranslationY()
                nsampled.addAllTranslationY(ys)
                val zs = nsampled.translationZList.map[v|v * coeff].toList
                nsampled.clearTranslationZ()
                nsampled.addAllTranslationZ(zs)
                nclip.sampledTransform = nsampled
                nclips.add(nclip)
            }
            nanim.clearClips()
            nanim.addAllClips(nclips.map[it.build()])
            nanims.add(nanim)
        }
        data.clearAnimationsKf()
        data.addAllAnimationsKf(nanims.map[it.build()])
    }
}
package assimp2xbuf

import assimp.Assimp.aiAnimation
import assimp.Assimp.aiNodeAnim
import assimp.Assimp.aiQuatKey
import assimp.Assimp.aiScene
import assimp.Assimp.aiVectorKey
import assimp2xbuf.Exporter.ResultsTmp
import org.joml.Quaternionf
import org.joml.Vector3f
import xbuf_ext.AnimationsKf.AnimationKF
import xbuf_ext.AnimationsKf.AnimationKF.TargetKind
import xbuf_ext.AnimationsKf.Clip
import xbuf_ext.AnimationsKf.SampledTransform

class Exporter4Animation {
    def void exportAnimations(ResultsTmp resTmp, aiScene scene) {
        println("nb anim " + scene.HasAnimations() + " .. " + scene.mNumAnimations)
        if (!scene.HasAnimations()) return;   
        for (var i = 0; i < scene.mNumAnimations; i++) {
            val a = scene.mAnimations.get(aiAnimation, i)
            val adest = AnimationKF.newBuilder()
            adest.id = Exporter.newId()
            adest.name = a.mName.toString
            adest.duration = (1000 * a.mDuration / a.mTicksPerSecond) as int
            adest.targetKind = TargetKind.skeleton // TODO set the correct value
            for (var j = 0; j < a.mNumChannels; j++) {
                val c = a.mChannels.get(aiNodeAnim, j)
                val sampled = SampledTransform.newBuilder()
                sampled.boneName = c.mNodeName.toString
                
                var iPos = new Vec3k() 
                var iRot = new Quatk()
                var iSca = new Vec3k()
                iSca.onKey.set(1,1,1)

                val keys = findAtKeys(c)
                var prevk = -1
                for (k : keys) {
                    // ignore duplicate
                    if (prevk != k) {
                        prevk = k
                        sampled.addAt((k / a.mTicksPerSecond) as int)
                        if (c.mNumPositionKeys > 0) {
                            interpolate(k, c.mNumPositionKeys, c.mPositionKeys, iPos)
                            sampled.addTranslationX(iPos.interpolated.x)
                            sampled.addTranslationY(iPos.interpolated.y)
                            sampled.addTranslationZ(iPos.interpolated.z)
                        }
                        if (c.mNumRotationKeys > 0) {
                            interpolate(k, c.mNumRotationKeys, c.mRotationKeys, iRot)
                            sampled.addRotationX(iRot.interpolated.x)
                            sampled.addRotationY(iRot.interpolated.y)
                            sampled.addRotationZ(iRot.interpolated.z)
                            sampled.addRotationW(iRot.interpolated.w)
                        }
                        if (c.mNumScalingKeys > 0) {
                            interpolate(k, c.mNumScalingKeys, c.mScalingKeys, iSca)
                            sampled.addScaleX(iSca.interpolated.x)
                            sampled.addScaleY(iSca.interpolated.y)
                            sampled.addScaleZ(iSca.interpolated.z)
                        }
                    }
                }
                val cdest = Clip.newBuilder()
                cdest.sampledTransform = sampled
                if (sampled.atCount >1) {
                    adest.addClips(cdest)
                }
            }
            if (adest.clipsCount > 0) {
                //resTmp.out.getExtension(AnimationsKf.animationsKf).add(adest.build())
                resTmp.out.addAnimationsKf(adest.build())
            }
        }
    }

    def findAtKeys(aiNodeAnim c) {
        val keys = newIntArrayOfSize(1 + c.mNumPositionKeys + c.mNumRotationKeys + c.mNumScalingKeys)
        keys.set(0, 0)
        var i = 1
        for (var k = 0; k < c.mNumPositionKeys; k++) {
            keys.set(i + k, ((c.mPositionKeys.position(k) as aiVectorKey).mTime * 1000) as int)
        }
        i += c.mNumPositionKeys
        for (var k = 0; k < c.mNumRotationKeys; k++) {
            keys.set(i + k, ((c.mRotationKeys.position(k) as aiQuatKey).mTime * 1000) as int)
        }
        i += c.mNumRotationKeys
        for (var k = 0; k < c.mNumScalingKeys; k++) {
            keys.set(i + k, ((c.mScalingKeys.position(k) as aiVectorKey).mTime * 1000) as int)
        }
        keys.sort.toList
    }

	static class Vec3k{
		public val onKey = new Vector3f()
		public val interpolated = new Vector3f()
		public var key = -1
	}
	
	static class Quatk{
		public val onKey = new Quaternionf().identity()
		public val interpolated = new Quaternionf().identity()
		public var key = -1
	}

	def interpolate(int at, int lg, aiVectorKey keys, Vec3k current) {
        val i = Math.min(current.key + 1, lg - 1)
        val ki = (keys.position(i) as aiVectorKey)
        val kt = ki.mTime * 1000
        if (kt == at) {
            current.key = i
            current.onKey.set(ki.mValue.x, ki.mValue.y, ki.mValue.z)
            current.interpolated.set(ki.mValue.x, ki.mValue.y, ki.mValue.z)
        } else if (kt > at) {
            val ratio = if (i == 0) {
                ((at - 0) as float) / ((kt - 0f) as float)
            } else {
                val kp = (keys.position(i) as aiVectorKey)
                val kpt = kp.mTime * 1000
                ((at - kpt) as float) / ((kt - kpt) as float)
            }
            current.onKey.lerp(new Vector3f(ki.mValue.x, ki.mValue.y, ki.mValue.z), ratio, current.interpolated)
        } else {
        	//nothing
	        // throw new IllegalStateException("kt > at")
        }
	}

	def interpolate(int at, int lg, aiQuatKey keys, Quatk current) {
        val i = Math.min(current.key + 1, lg - 1)
        val ki = (keys.position(i) as aiQuatKey)
        val kt = ki.mTime * 1000
        if (kt == at) {
            current.key = i
            current.onKey.set(ki.mValue.x, ki.mValue.y, ki.mValue.z, ki.mValue.w)
            current.interpolated.set(ki.mValue.x, ki.mValue.y, ki.mValue.z, ki.mValue.w)
        } else if (kt > at) {
            val ratio = if (i == 0) {
                ((at - 0) as float) / ((kt - 0f) as float)
            } else {
                val kp = (keys.position(i) as aiQuatKey)
                val kpt = kp.mTime * 1000
                ((at - kpt) as float) / ((kt - kpt) as float)
            }
            current.onKey.slerp(new Quaternionf(ki.mValue.x, ki.mValue.y, ki.mValue.z, ki.mValue.w), ratio, current.interpolated)
        } else {
        	//nothing
	        // throw new IllegalStateException("kt > at")
        }
	}
}
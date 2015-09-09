package assimp2xbuf

import assimp.Assimp.aiAnimation
import assimp.Assimp.aiNodeAnim
import assimp.Assimp.aiQuatKey
import assimp.Assimp.aiScene
import assimp.Assimp.aiVectorKey
import assimp2xbuf.Exporter.ResultsTmp
import xbuf_ext.AnimationsKf.AnimationKF
import xbuf_ext.AnimationsKf.AnimationKF.TargetKind
import xbuf_ext.AnimationsKf.Clip
import xbuf_ext.AnimationsKf.SampledTransform
import org.eclipse.xtend.lib.annotations.Data
import xbuf_ext.AnimationsKf

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
                var iPos = new V5k(0, 0, 0, 0, -1)
                var iRot = new V5k(0, 0, 0, 1, -1)
                var iSca = new V5k(1, 1, 1, 1, -1)
                val keys = findAtKeys(c)
                var prevk = -1
                for (k : keys) {
                    // ignore duplicate
                    if (prevk != k) {
                        prevk = k
                        sampled.addAt(k)
                        if (c.mNumPositionKeys > 0) {
                            iPos = interpolateVect3(k, c.mNumPositionKeys, c.mPositionKeys, iPos)
                            sampled.addTranslationX(iPos.x)
                            sampled.addTranslationY(iPos.y)
                            sampled.addTranslationZ(iPos.z)
                        }
                        if (c.mNumRotationKeys > 0) {
                            iSca = interpolateQuat(k, c.mNumRotationKeys, c.mRotationKeys, iSca)
                            sampled.addRotationX(iRot.x)
                            sampled.addRotationY(iRot.y)
                            sampled.addRotationZ(iRot.z)
                            sampled.addRotationW(iRot.w)
                        }
                        if (c.mNumScalingKeys > 0) {
                            iSca = interpolateVect3(k, c.mNumScalingKeys, c.mScalingKeys, iSca)
                            sampled.addScaleX(iSca.x)
                            sampled.addScaleY(iSca.y)
                            sampled.addScaleZ(iSca.z)
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
                resTmp.out.addExtension(AnimationsKf.animationsKf, adest.build())
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

    @Data
    static class V5k {
        val float x
        val float y
        val float z
        val float w
        val int i
    }

    def V5k interpolateVect3(int at, int lg, aiVectorKey keys, V5k previous) {
        val i = Math.min(previous.i + 1, lg - 1)
        val ki = (keys.position(i) as aiVectorKey)
        val kt = ki.mTime * 1000
        val kv = new V5k(ki.mValue.x, ki.mValue.y, ki.mValue.z, 0, i)
        if (kt == at) {
            kv
        } else if (kt > at) {
            if (i == 0) {
                val ratio = ((at - 0) as float) / ((kt - 0f) as float)
                linear(ratio, previous, kv)
            } else {
                val kp = (keys.position(i) as aiVectorKey)
                val kpt = kp.mTime * 1000
                val kpv = new V5k(kp.mValue.x, kp.mValue.y, kp.mValue.z, 0, i)
                val ratio = ((at - kpt) as float) / ((kt - kpt) as float)
                linear(ratio, kpv, kv)
            }
        } else {
            kv
        // throw new IllegalStateException("kt > at")
        }
    }

    def V5k interpolateQuat(int at, int lg, aiQuatKey keys, V5k previous) {
        val i = Math.min(previous.i + 1, lg - 1)
        val ki = (keys.position(i) as aiQuatKey)
        val kt = ki.mTime * 1000
        val kv = new V5k(ki.mValue.x, ki.mValue.y, ki.mValue.z, ki.mValue.w, i)
        if (kt == at) {
            kv
        } else if (kt > at) {
            if (i == 0) {
                val ratio = ((at - 0) as float) / ((kt - 0f) as float)
                linear(ratio, previous, kv)
            } else {
                val kp = (keys.position(i) as aiVectorKey)
                val kpt = kp.mTime * 1000
                val kpv = new V5k(kp.mValue.x, kp.mValue.y, kp.mValue.z, 0, i)
                val ratio = ((at - kpt) as float) / ((kt - kpt) as float)
                linear(ratio, kpv, kv)
            }
        } else {
            kv
        // throw new IllegalStateException("kt > at")
        }
    }

    def linear(float ratio, float p0, float p1) {
        p0 + ratio * (p1 - p0)
    }

    def linear(float ratio, V5k p0, V5k p1) {
        new V5k(
            linear(ratio, p0.x, p1.x),
            linear(ratio, p0.y, p1.y),
            linear(ratio, p0.z, p1.z),
            linear(ratio, p0.w, p1.w),
            p0.i
        )
    }
}
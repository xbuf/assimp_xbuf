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
                        sampled.addAt((k / a.mTicksPerSecond) as int)
                        if (c.mNumPositionKeys > 0) {
                            iPos = interpolateVect3(k, c.mNumPositionKeys, c.mPositionKeys, iPos)
                            sampled.addTranslationX(iPos.x)
                            sampled.addTranslationY(iPos.y)
                            sampled.addTranslationZ(iPos.z)
                            println(k + "\tiPos\t" + iPos)
                        }
                        if (c.mNumRotationKeys > 0) {
                            iRot = interpolateQuat(k, c.mNumRotationKeys, c.mRotationKeys, iRot)
                            sampled.addRotationX(iRot.x)
                            sampled.addRotationY(iRot.y)
                            sampled.addRotationZ(iRot.z)
                            sampled.addRotationW(iRot.w)
                            println(k + "\tiRot\t" + iRot)
                        }
                        if (c.mNumScalingKeys > 0) {
                            iSca = interpolateVect3(k, c.mNumScalingKeys, c.mScalingKeys, iSca)
                            sampled.addScaleX(iSca.x)
                            sampled.addScaleY(iSca.y)
                            sampled.addScaleZ(iSca.z)
                            println(k + "\tiSca\t" + iSca)
                        }
                    }
                }
                val cdest = Clip.newBuilder()
                cdest.sampledTransform = sampled
                if (sampled.atCount >1) {
                    adest.addClips(cdest)
                    println("added sampled for " + sampled.boneName)
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
                slerp(ratio, previous, kv)
            } else {
                val kp = (keys.position(i) as aiVectorKey)
                val kpt = kp.mTime * 1000
                val kpv = new V5k(kp.mValue.x, kp.mValue.y, kp.mValue.z, 0, i)
                val ratio = ((at - kpt) as float) / ((kt - kpt) as float)
                slerp(ratio, kpv, kv)
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
    
    // copied from jMonkeyEngine3
    def slerp(float t, V5k q1, V5k q2) {
        // Create a local quaternion to store the interpolated quaternion
        if (q1.x == q2.x && q1.y == q2.y && q1.z == q2.z && q1.w == q2.w) {
            return q1;
        }

        var result = (q1.x * q2.x) + (q1.y * q2.y) + (q1.z * q2.z)
                + (q1.w * q2.w);

        val q2r = if (result < 0.0f) {
            // Negate the second quaternion and the result of the dot product
            result = -result
            new V5k(-q2.x, -q2.y, -q2.z, -q2.w, q2.i)
        } else { q2}

        // Set the first and second scale for the interpolation
        var scale0 = 1 - t;
        var scale1 = t;

        // Check if the angle between the 2 quaternions was big enough to
        // warrant such calculations
        if ((1 - result) > 0.1f) {// Get the angle between the 2 quaternions,
            // and then store the sin() of that angle
            val theta = Math.acos(result);
            val invSinTheta = 1f / Math.sin(theta);

            // Calculate the scale for q1 and q2, according to the angle and
            // it's sine value
            scale0 = (Math.sin((1 - t) * theta) * invSinTheta) as float
            scale1 = (Math.sin((t * theta)) * invSinTheta) as float
        }

        // Calculate the x, y, z and w values for the quaternion by using a
        // special
        // form of linear interpolation for quaternions.
        new V5k(
            (scale0 * q1.x) + (scale1 * q2r.x),
            (scale0 * q1.y) + (scale1 * q2r.y),
            (scale0 * q1.z) + (scale1 * q2r.z),
            (scale0 * q1.w) + (scale1 * q2r.w),
            q1.i
        )
    }
}
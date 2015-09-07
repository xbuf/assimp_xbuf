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

class Exporter4Animation {
    def exportAnimations(ResultsTmp resTmp, aiScene scene) {
    	for(var i = 0; i < scene.mNumAnimations; i++){
    		val a = scene.mAnimations.get(aiAnimation, i)
            val adest = AnimationKF.newBuilder()
            adest.id = Exporter.newId()
            adest.name = a.mName.toString
            adest.duration = (1000 * a.mDuration / a.mTicksPerSecond) as int
            adest.targetKind = TargetKind.skeleton //TODO set the correct value
            for (var j = 0; j < a.mNumChannels; j++) {
            	val c = a.mChannels.get(aiNodeAnim, j)
            	val sampled = SampledTransform.newBuilder()
            	sampled.boneName = c.mNodeName.toString
            	var at = 0
            	var iPos = 0
            	var iRot = 0
            	var iSca = 0
            	while((iPos + 1) < c.mNumPositionKeys && (iRot + 1) < c.mNumRotationKeys && (iSca + 1) < c.mNumScalingKeys){
            		
            	}
            	
            	val cdest = Clip.newBuilder()
            	cdest.sampledTransform = sampled
            	adest.addClips(cdest)	
            }
    	}
    }
    
    def findAtKeys(aiNodeAnim c) {
    	val keys = newIntArrayOfSize(c.mNumPositionKeys + c.mNumRotationKeys + c.mNumScalingKeys)
    	for(var k = 0; k < c.mNumPositionKeys; k++) {
    		keys.set(k, ((c.mPositionKeys.position(k) as aiVectorKey).mTime * 1000) as int)
    	}
    	for(var k = 0; k < c.mNumRotationKeys; k++) {
    		keys.set(k, ((c.mRotationKeys.position(k) as aiQuatKey).mTime * 1000) as int)
    	}
    	for(var k = 0; k < c.mNumScalingKeys; k++) {
    		keys.set(k, ((c.mScalingKeys.position(k) as aiVectorKey).mTime * 1000) as int)
    	}
    	keys.sort.toList
    } 	
}
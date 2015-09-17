package xbuf_tools

import org.joml.Matrix4f
import org.joml.Quaternionf
import xbuf.Primitives.TransformOrBuilder
import org.joml.Vector3f

class TransformTools {
	static def toMatrix4f(TransformOrBuilder t) {
    	(new Matrix4f().identity()
			.scale(t.scale.x, t.scale.y, t.scale.z)
			.rotate(new Quaternionf(t.rotation.x, t.rotation.y, t.rotation.z, t.rotation.w))
			.translate(t.translation.x, t.translation.y, t.translation.z)
		)
    }
    
	static def toMatrix4f(TransformOrBuilder t, Matrix4f space) {
		new Matrix4f(space).mul(toMatrix4f(t))
    }
    
    static def toPoint(TransformOrBuilder t, Matrix4f space) {
		val tm = toMatrix4f(t, space)
		tm.transformPoint(new Vector3f(0))
    }
}
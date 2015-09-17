package xbuf_tools

import xbuf.Primitives.Vec3

class Vec3Tools {
	 static def mult(Vec3 v3, float coeff) {	
        val nv3 = Vec3.newBuilder()
        nv3.x = v3.x * coeff
        nv3.y = v3.y * coeff
        nv3.z = v3.z * coeff
        nv3
    }
}
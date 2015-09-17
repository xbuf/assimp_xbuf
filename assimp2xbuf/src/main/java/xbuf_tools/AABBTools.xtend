package xbuf_tools

import org.joml.Matrix4f
import org.joml.Vector3f
import xbuf.Datas.Data
import xbuf.Meshes.Mesh
import xbuf.Meshes.VertexArray
import xbuf.Tobjects.TObject

import static xbuf_tools.TObjectTools.*
import static xbuf_tools.TransformTools.*

class AABBTools {
	static def single(AABB v, Vector3f p0) {
		v.min.set(p0)
		v.max.set(p0)
		v
	}

	static def dimension(AABB v) {
		val r = new Vector3f(v.min).mul(-1)
		r.add(v.max)
	}

	static def AABB compute(Iterable<TObject> tobjects, Matrix4f space, Data.Builder data) {
		val aabb = new AABB()
		if (!tobjects.empty) {
			single(aabb, toPoint(tobjects.get(0).transform, space))
			tobjects.forEach[v|
				include(aabb, v, space, data, true)
			]
		}
		aabb
    }
 
	static def AABB include(AABB v, Vector3f p) {
		v.min.min(p)
		v.max.max(p)
		v
	}
	
	static def AABB include(AABB aabb, TObject tobject, Matrix4f space, Data.Builder data, boolean recursive) {
		val tm = toMatrix4f(tobject.transform, space)
		val p = tm.transformPoint(new Vector3f(0))
		include(aabb, p)
		findMeshesOf(tobject, data).forEach[v|
			include(aabb, v, tm, data)
		]
		if (recursive) {
			findChildrenTObjectOf(tobject, data).forEach[v|
				include(aabb, v, tm, data, true)
			]
		}
	   	aabb
    }
    
	static def AABB include(AABB aabb, Mesh mesh, Matrix4f space, Data.Builder data) {
		val floats = mesh.vertexArraysList.findFirst[it.attrib == VertexArray.Attrib.position]?.floats
		if (floats != null) {
			val step = Math.max(3, floats.step)
			val v = new Vector3f()
			for(var i = 0; i< floats.valuesCount; i= i + step) {
				v.set(floats.valuesList.get(i), floats.valuesList.get(i+1), floats.valuesList.get(i+2))
				include(aabb, space.transformPoint(v))
			}
		}
	   	aabb
    }
}
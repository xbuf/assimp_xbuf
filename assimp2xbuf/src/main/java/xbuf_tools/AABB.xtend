package xbuf_tools

import org.joml.Vector3f
import org.eclipse.xtend.lib.annotations.Data

@Data
class AABB {
	public val Vector3f min = new Vector3f()
	public val Vector3f max = new Vector3f()
}

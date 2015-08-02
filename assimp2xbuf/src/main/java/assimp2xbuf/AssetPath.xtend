package assimp2xbuf

import java.nio.file.Path
import org.eclipse.xtend.lib.annotations.Data

@Data class AssetPath {
  /** relative path of the asset, value stored into xbuf */
  String rpath
  /** full local path of the asset */
  Path path
}

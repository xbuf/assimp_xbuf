WIP WIP WIP


# assimp_xbuf

A set of libs, tools to use [Assimp (Open Asset Import Library)](http://assimp.sourceforge.net) with [xbuf](http://xbuf.org).

I’m not enough skilled to provide the importer/exporter for xbuf to assimp, But I can try to create some tools and lib to help xbuf’s users to use assimp.

## assimp4xbuf

(Empty)

A commandline tool and a java library to convert a asset read via assimp into xbuf (file or object).

License: CC0-1

## assimp4java

A java library to be able to read asset files with Assimp. The library can be used with xbuf (zero dependency to xbuf stuff).
At the end the library should be able to support at least “features” supported by assimp and xbuf.
[javacpp](https://github.com/bytedeco/javacpp) is used for the C++ binding.

The existing alternative is [jassimp (Java binding for assimp)](https://github.com/assimp/assimp/tree/master/port/jassimp), that is part of the assimp source.

License: CC0-1

## assimp_lib

A package (jar) that include native library of assimp.

License: BSD 3 Clause - same as [assimp license](http://assimp.sourceforge.net/main_license.html))

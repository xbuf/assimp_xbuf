package xbuf_tools

import xbuf.Datas.DataOrBuilder
import xbuf.Tobjects.TObject

class TObjectTools {
	static def findMeshesOf(TObject tobject, DataOrBuilder data) {
		data.relationsList.stream.map[v|
			if (v.ref2 == tobject.id) {
				data.meshesList.findFirst[it.id == v.ref1]
			} else {
				null
			}
		].filter[it != null]
    }

	static def findChildrenTObjectOf(TObject tobject, DataOrBuilder data) {
		data.relationsList.stream.map[v|
			if (v.ref1 == tobject.id) {
				data.tobjectsList.findFirst[it.id == v.ref2]
			} else {
				null
			}
		].filter[it != null]
    }
    
	static def findRoots(DataOrBuilder data) {
		val tobjectIds = data.tobjectsList.map[v|v.id].toSet
		val orphanIds = tobjectIds.clone.toSet
		data.relationsList.forEach[v|
			if (tobjectIds.contains(v.ref1) && tobjectIds.contains(v.ref2)) {
				orphanIds.remove(v.ref2)
			}
		]
		data.tobjectsList.filter[v| orphanIds.contains(v.id)]
    }
}
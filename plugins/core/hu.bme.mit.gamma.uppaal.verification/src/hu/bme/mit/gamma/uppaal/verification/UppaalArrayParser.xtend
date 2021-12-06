package hu.bme.mit.gamma.uppaal.verification

import hu.bme.mit.gamma.theta.verification.XstsArrayParser
import hu.bme.mit.gamma.expression.util.IndexHierarchy

class UppaalArrayParser implements XstsArrayParser {
	// Singleton
	public static final UppaalArrayParser INSTANCE = new UppaalArrayParser
	protected new() {}
	//
	
	
	override parseArray(String id, String value) {
		val indexHierarchy = new IndexHierarchy
		
		val leftSquareBracketIndex = id.indexOf("[")
		if (leftSquareBracketIndex > 0) {
			var indexes = id.substring(leftSquareBracketIndex) // [0][1][2]
			indexes = indexes.substring(1, indexes.length - 1) // 0][1][2]
			val indexArray = indexes.split("\\]\\[")
			for (index : indexArray) {
				val integerIndex = Integer.parseInt(index)
				indexHierarchy.add(integerIndex)
			}
		}
		
		// Valid - if it is not an array, we return an empty indexHierarchy
		return #[indexHierarchy -> value]
	}
	
}
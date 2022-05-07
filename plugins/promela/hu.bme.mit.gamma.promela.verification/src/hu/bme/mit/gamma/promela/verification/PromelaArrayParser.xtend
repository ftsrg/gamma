package hu.bme.mit.gamma.promela.verification

import hu.bme.mit.gamma.expression.util.IndexHierarchy
import hu.bme.mit.gamma.theta.verification.XstsArrayParser
import hu.bme.mit.gamma.xsts.promela.transformation.util.Namings
import java.util.List
import java.util.regex.Pattern

class PromelaArrayParser implements XstsArrayParser{
	// Singleton
	public static final PromelaArrayParser INSTANCE = new PromelaArrayParser
	protected new() {}

	override List<Pair<IndexHierarchy, String>> parseArray(String id, String value) {
		if (value.isArray) { // If value is an array, it contains at least 1 " = "
			var values = newArrayList
			val arrayElements = value.split(Pattern.quote("|"))
			for (element : arrayElements) {
				val splitPair = element.split(" = ")
				val splitAccess = splitPair.get(0)
				val splitValue = splitPair.get(1)
				val access = splitAccess.replaceFirst(id, "") // ArrayAccess
				val splitIndices = access.split(Namings.arrayFieldAccess) // [0] [1] ...
				var indexHierarchy = new IndexHierarchy
				for (splitIndex : splitIndices) {
					val parsedIndex = Integer.parseInt(splitIndex.unwrap) // unwrap index [0] -> 0
					indexHierarchy.add(parsedIndex)
				}
				values += indexHierarchy -> splitValue
			}
			return values
		}
		return #[new IndexHierarchy -> value]
	}

	protected def boolean isArray(String value) {
		return value.contains(" = ")
	}

	protected def unwrap(String index) {
		return index.substring(1, index.length - 1)
	}
}
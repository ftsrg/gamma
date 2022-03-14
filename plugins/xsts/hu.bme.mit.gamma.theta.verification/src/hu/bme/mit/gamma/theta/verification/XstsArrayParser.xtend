package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.expression.util.IndexHierarchy
import java.util.List

interface XstsArrayParser {
	
	def List<Pair<IndexHierarchy, String>> parseArray(String id, String value)
	
}
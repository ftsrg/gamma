package hu.bme.mit.gamma.nuxmv.verification

import hu.bme.mit.gamma.expression.util.IndexHierarchy
import hu.bme.mit.gamma.theta.verification.XstsArrayParser

class NuxmvArrayParser implements XstsArrayParser {
	// Singleton
	public static final NuxmvArrayParser INSTANCE = new NuxmvArrayParser
	protected new() {}
	//
	
	override parseArray(String id, String value) {
		if (value.array) { // If value is an array, it contains at least 1 " = "
			// TODO
		}
		else {
			return #[new IndexHierarchy -> value]
		}
	}
	
	protected def boolean isArray(String value) {
		return false // TODO
	}
	
}
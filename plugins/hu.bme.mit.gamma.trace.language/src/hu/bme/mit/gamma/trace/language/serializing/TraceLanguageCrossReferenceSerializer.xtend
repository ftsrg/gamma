package hu.bme.mit.gamma.trace.language.serializing

import hu.bme.mit.gamma.language.util.serialization.GammaLanguageCrossReferenceSerializer
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.statechart.model.Package

class TraceLanguageCrossReferenceSerializer extends GammaLanguageCrossReferenceSerializer {
	
	override getContext() {
		return ExecutionTrace
	}
	
	override getTarget() {
		return Package
	}
	
}
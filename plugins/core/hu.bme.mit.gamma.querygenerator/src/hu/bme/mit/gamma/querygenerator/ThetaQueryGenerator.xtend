package hu.bme.mit.gamma.querygenerator

import hu.bme.mit.gamma.statechart.model.Package
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope
import hu.bme.mit.gamma.querygenerator.operators.TemporalOperator

class ThetaQueryGenerator extends AbstractQueryGenerator {
	
	new(Package gammaPackage) {
		val resourceSet = gammaPackage.eResource.resourceSet
		this.engine = ViatraQueryEngine.on(new EMFScope(resourceSet))
	}
	
	override protected getTargetStateName(String stateName) {
	}
	
	override protected getTargetVariableName(String variableName) {
	}
	
	override protected getTargetOutEventName(String portEventName) {
	}
	
	override protected getTargetOutEventParameterName(String portEventParameterName) {
	}
	
	override parseRegularQuery(String text, TemporalOperator operator) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override parseLeadsToQuery(String first, String second) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
}
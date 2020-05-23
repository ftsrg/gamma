package hu.bme.mit.gamma.querygenerator

import hu.bme.mit.gamma.statechart.model.Package
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope
import hu.bme.mit.gamma.querygenerator.operators.TemporalOperator
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.Region
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.expression.model.ParameterDeclaration

class ThetaQueryGenerator extends AbstractQueryGenerator {
	
	new(Package gammaPackage) {
		val resourceSet = gammaPackage.eResource.resourceSet
		this.engine = ViatraQueryEngine.on(new EMFScope(resourceSet))
	}
	
	override parseRegularQuery(String text, TemporalOperator operator) {
		return text.parseIdentifiers
	}
	
	override parseLeadsToQuery(String first, String second) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override protected getTargetStateName(SynchronousComponentInstance instance, Region parentRegion, State state) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override protected getTargetVariableName(VariableDeclaration variable, SynchronousComponentInstance instance) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override protected getTargetOutEventName(Event event, Port port, SynchronousComponentInstance instance) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override protected getTargetOutEventParameterName(Event event, Port port, ParameterDeclaration parameter, SynchronousComponentInstance instance) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	
}
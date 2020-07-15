package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State

abstract interface AbstractReferenceSerializer {
	
	def String getId(State state, Region parentRegion, ComponentInstanceReference instance)	
	def String getId(VariableDeclaration variable, ComponentInstanceReference instance)	
	def String getId(Event event, Port port, ComponentInstanceReference instance)	
	def String getId(Event event, Port port, ParameterDeclaration parameter, ComponentInstanceReference instance)
	
}
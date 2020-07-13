package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State

abstract interface AbstractReferenceSerializer {
	
	def String getId(State state, Region parentRegion, SynchronousComponentInstance instance)	
	def String getId(VariableDeclaration variable, SynchronousComponentInstance instance)	
	def String getId(Event event, Port port, SynchronousComponentInstance instance)	
	def String getId(Event event, Port port, ParameterDeclaration parameter, SynchronousComponentInstance instance)
	
}
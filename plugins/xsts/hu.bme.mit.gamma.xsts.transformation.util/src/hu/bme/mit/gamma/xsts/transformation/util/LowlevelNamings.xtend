package hu.bme.mit.gamma.xsts.transformation.util

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class LowlevelNamings {
	
	static def String getName(StatechartDefinition statechart) '''«statechart.name»'''
	static def String getStateName(State state) '''«state.name»'''
	static def String getRegionName(Region region) '''«region.name»'''
	static def String getInputName(Event event, Port port) '''«port.name»_«event.name»_In'''
	static def String getOutputName(Event event, Port port) '''«port.name»_«event.name»_Out'''
	static def String getInName(ParameterDeclaration parameterDeclaration, Port port) '''«parameterDeclaration.containingEvent.getInputName(port)»_«parameterDeclaration.name»'''
	static def String getOutName(ParameterDeclaration parameterDeclaration, Port port) '''«parameterDeclaration.containingEvent.getOutputName(port)»_«parameterDeclaration.name»'''
	static def String getComponentParameterName(ParameterDeclaration parameter) '''«parameter.name»'''
	static def String getName(TimeoutDeclaration timeout) '''«timeout.name»'''
	static def String getName(VariableDeclaration variable) '''«variable.name»'''
	static def String getName(TypeDeclaration type) '''«type.name»'''
	
}
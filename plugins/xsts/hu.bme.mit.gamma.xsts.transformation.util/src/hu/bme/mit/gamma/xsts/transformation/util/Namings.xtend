package hu.bme.mit.gamma.xsts.transformation.util

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.model.interface_.Event

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class Namings {
	
	// Low-level
	
	static def String getInputName(Event event, Port port) '''«port.name»_«event.name»_In'''
	static def String getOutputName(Event event, Port port) '''«port.name»_«event.name»_Out'''
	static def String getInName(ParameterDeclaration parameterDeclaration, Port port) '''«parameterDeclaration.containingEvent.getInputName(port)»_«parameterDeclaration.name»'''
	static def String getOutName(ParameterDeclaration parameterDeclaration, Port port) '''«parameterDeclaration.containingEvent.getOutputName(port)»_«parameterDeclaration.name»'''
	
	// XSTS
	
	static def String getName(VariableDeclaration variable) '''«variable.name»'''
	static def String getName(TypeDeclaration type) '''«type.name»'''

	// XSTS customization
	
	static def String customizeName(VariableDeclaration variable, ComponentInstance instance) '''«getName(variable)»_«instance.name»'''
	static def String customizeName(TypeDeclaration type, Component component) '''«getName(type)»_«component.name»'''
	static def String customizeInName(ParameterDeclaration parameterDeclaration, Port port, ComponentInstance instance) '''«parameterDeclaration.getInName(port)»_«instance.name»'''
	static def String customizeOutName(ParameterDeclaration parameterDeclaration, Port port, ComponentInstance instance) '''«parameterDeclaration.getOutName(port)»_«instance.name»'''
	static def String customizeInputName(Event event, Port port, ComponentInstance instance) '''«event.getInputName(port)»_«instance.name»'''
	static def String customizeOutputName(Event event, Port port, ComponentInstance instance) '''«event.getOutputName(port)»_«instance.name»'''
	
}
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
	static def String getName(ParameterDeclaration parameterDeclaration, Port port) '''«port.name»_«parameterDeclaration.containingEvent.name»_«parameterDeclaration.name»'''
	
	// XSTS
	
	static def String getName(VariableDeclaration variable) '''«variable.name»'''
	static def String getName(TypeDeclaration type) '''«type.name»'''

	// XSTS customization
	
	static def String customizeName(VariableDeclaration variable, ComponentInstance instance) '''«getName(variable)»_«instance.name»'''
	static def String customizeName(TypeDeclaration type, Component component) '''«getName(type)»_«component.name»'''
	
}
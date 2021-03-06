package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import java.util.List

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class Namings {
	
	def static String getFQN(List<ComponentInstance> instances) '''«FOR instance : instances SEPARATOR '_'»«instance.name»«ENDFOR»'''
	def static String getFQN(ComponentInstanceReference instance) '''«instance.componentInstanceHierarchy.FQN»'''
	def static String getFQN(ComponentInstance instance) '''«instance.componentInstanceChain.FQN»'''
	
}
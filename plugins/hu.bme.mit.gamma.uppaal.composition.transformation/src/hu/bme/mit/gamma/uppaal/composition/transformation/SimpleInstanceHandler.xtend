package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import java.util.Collection

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class SimpleInstanceHandler {
	
	def getNewSimpleInstances(Component newType) {
		return newType.allSimpleInstances
	}
	
	def getNewSimpleInstances(Collection<? extends ComponentInstance> includedOriginalInstances,
			Collection<? extends ComponentInstance> excludedOriginalInstances, Component newType) {
		// Include - exclude
		val oldInstances = newArrayList
		oldInstances += includedOriginalInstances.allSimpleInstances
		oldInstances -= excludedOriginalInstances.allSimpleInstances
		return oldInstances.getNewSimpleInstances(newType)
	}
	
	def getNewSimpleInstances(Collection<? extends ComponentInstance> originalInstances, Component newType) {
		val oldInstances = originalInstances.allSimpleInstances
		val newInstances = newType.allSimpleInstances
		val accpedtedNewInstances = newArrayList
		for (newInstance : newInstances) {
			if (oldInstances.exists[it.instanceEquals(newInstance)]) {
				accpedtedNewInstances += newInstance
			}
		}
		return accpedtedNewInstances
	}
	
	def getNewAsynchronousSimpleInstances(AsynchronousComponentInstance original, Component newType) {
		return newType.allAsynchronousSimpleInstances
			.filter[original.instanceEquals(it)].toList
	}
	
	private def instanceEquals(ComponentInstance original, ComponentInstance copy) {
		// TODO better equality check (helper equals does not work as the original statecharts have been optimized)
		return copy.name == original.name /* Flat composite */ ||
			copy.name.endsWith("_" + original.name) /* Hierarchical composite */
	}
	
}
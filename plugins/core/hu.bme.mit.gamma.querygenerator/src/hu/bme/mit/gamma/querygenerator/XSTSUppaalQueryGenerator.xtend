package hu.bme.mit.gamma.querygenerator

import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State

import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class XSTSUppaalQueryGenerator extends ThetaQueryGenerator {
	
		
	new(Package gammaPackage) {
		super(gammaPackage)
	}
	
		
	def protected getSingleTargetStateName(int index, Region parentRegion, SynchronousComponentInstance instance) {
		return '''«parentRegion.customizeName(instance)» == «index»'''
	}
	
	override getSourceState(String targetStateName) {
		for (match : instanceStates) {
			val parentRegion = match.parentRegion
			val instance = match.instance
			val state = match.state
			val stateIndex = parentRegion.stateNodes.filter(State).toList.indexOf(state) + 1 /* + 1 for __Inactive__ */
			val name = getSingleTargetStateName(stateIndex, parentRegion, instance)
			if (name.equals(targetStateName)) {
				return new Pair(match.state, match.instance)
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
}
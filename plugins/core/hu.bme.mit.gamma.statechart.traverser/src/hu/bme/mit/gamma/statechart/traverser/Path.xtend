package hu.bme.mit.gamma.statechart.traverser

import hu.bme.mit.gamma.statechart.model.Transition
import java.util.List

class Path {
	
	List<Transition> transitions = newArrayList
	
	new(Transition transition) {
		this.transitions += transition
	}
	
	new(List<Transition> transitions) {
		this.transitions += transitions
	}
	
	new(Path path) {
		this.transitions += path.getTransitions
	}
	
	def last() {
		return transitions.last
	}
	
	def extend(Transition transition) {
		transitions += transition
	}
	
	def getTransitions() {
		return transitions
	}
	
	override toString() '''
		«IF !transitions.empty»«transitions.head.sourceState.name»«ENDIF»«FOR transition : transitions» -> «transition.targetState.name»«ENDFOR»
	'''
	
}
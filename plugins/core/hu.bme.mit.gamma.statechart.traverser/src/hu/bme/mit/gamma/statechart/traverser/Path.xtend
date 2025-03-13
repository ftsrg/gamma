/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.traverser

import hu.bme.mit.gamma.statechart.statechart.Transition
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
		return transitions.lastOrNull
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
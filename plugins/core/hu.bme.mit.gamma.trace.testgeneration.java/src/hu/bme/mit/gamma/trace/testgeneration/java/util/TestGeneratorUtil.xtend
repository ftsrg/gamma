/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.testgeneration.java.util

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration
import hu.bme.mit.gamma.trace.model.InstanceVariableState
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.testgeneration.java.ExpressionSerializer
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.transformation.util.annotations.AnnotationNamings

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class TestGeneratorUtil {
	// Resources
	protected final Component component
	
	protected final String[] NOT_HANDLED_STATE_NAME_PATTERNS = #['LocalReactionState[0-9]*','FinalState[0-9]*']

	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE

	new(Component component) {
		this.component = component
	}
	
	def CharSequence getFullContainmentHierarchy(ComponentInstanceReferenceExpression instanceReference) {
		val instanceNames = newArrayList
		if (instanceReference !== null) {
			val instances = instanceReference.componentInstanceChain
			if (component.unfolded) {
				// If only a single instance is given, we explore the containment chain
				if (instances.size == 1) {
					val instance = instances.remove(0) // So the original list becomes empty
					instances += instance.componentInstanceChain
				}
				
				var ComponentInstance previousInstance = null
				for (instance : instances) {
					val instanceName = instance.name
					if (previousInstance === null) {
						instanceNames += instanceName
					}
					else {
						instanceNames += instanceName.substring(previousInstance.name.length + 1) // "_" is counted too
					}
					previousInstance = instance
				}
			}
			else {
				// Original component instance references
				instanceNames += instances.map[it.name]
			}
		}
		return '''«FOR instanceName : instanceNames SEPARATOR '.'»getComponent("«instanceName»")«ENDFOR»'''
	}
	
	def filterAsserts(Step step) {
		val asserts = newArrayList
		for (assertion : step.asserts) {
			val lowermostAssert = assertion.lowermostAssert
			if (lowermostAssert instanceof InstanceStateConfiguration) {
				if (lowermostAssert.state.handled) {
					asserts += assertion
				}
			}
			else if (lowermostAssert instanceof InstanceVariableState) {
				if (lowermostAssert.variableReference.variableDeclaration.handled) {
					asserts += assertion
				}
			}
			else {
				asserts += assertion
			}
		}
		return asserts
	}
	
	/**
	 * Returns whether the given Gamma State is a state that is not present in Yakindu.
	 */
	protected def boolean isHandled(State state) {
		val stateName = state.name
		for (notHandledStateNamePattern : NOT_HANDLED_STATE_NAME_PATTERNS) {
			if (stateName.matches(notHandledStateNamePattern)) {
				return false
			}
		}
		return true
	}
	
	protected def boolean isHandled(Declaration declaration) {
		// Not perfect as other variables can be named liked this, but works 99,99% of the time
		val name = declaration.name
		if (name.startsWith(AnnotationNamings.PREFIX) &&
				name.endsWith(AnnotationNamings.POSTFIX) ||
				component.allSimpleInstances.map[it.type].filter(StatechartDefinition)
					.map[it.transitions].flatten.exists[it.id == name] /*Transition id*/) {
			return false
		}
		return true
	}
	
	def String getPortOfAssert(RaiseEventAct assert) '''
		"«assert.port.name»"
	'''
	
	
	def String getEventOfAssert(RaiseEventAct assert) '''
		"«assert.event.name»"
	'''
	
	def String getParamsOfAssert(RaiseEventAct assert) '''
		new Object[] {«FOR parameter : assert.arguments BEFORE " " SEPARATOR ", " AFTER " "»«parameter.serialize»«ENDFOR»}
	'''

}

/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.language.validation

import hu.bme.mit.gamma.statechart.model.RealizationMode
import hu.bme.mit.gamma.statechart.model.StatechartModelPackage
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.interface_.EventDeclaration
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.InstanceSchedule
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TracePackage
import org.eclipse.xtext.validation.Check
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponent
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import org.eclipse.xtext.EcoreUtil2
import hu.bme.mit.gamma.trace.model.InstanceVariableState
import hu.bme.mit.gamma.trace.model.InstanceState
import hu.bme.mit.gamma.constraint.model.ConstraintModelPackage
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class TraceLanguageValidator extends AbstractTraceLanguageValidator {
	
	@Check
	def checkParameters(ExecutionTrace executionTrace) {
		val type = executionTrace.component
		if (executionTrace.getArguments().size() != type.getParameterDeclarations().size()) {
			error("The number of arguments is wrong.", ConstraintModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS)
		}
	}
	
	@Check
	def checkRaiseEventAct(RaiseEventAct raiseEventAct) {
		val step = raiseEventAct.eContainer as Step
		val realizationMode = raiseEventAct.port.interfaceRealization.realizationMode
		val event = raiseEventAct.event
		val eventDirection = (event.eContainer as EventDeclaration).direction
		if (step.actions.contains(raiseEventAct)) {
			// It should be an in event
			if (realizationMode == RealizationMode.PROVIDED && eventDirection == EventDirection.OUT ||
				realizationMode == RealizationMode.REQUIRED && eventDirection == EventDirection.IN) {
				error("This event is an out-event of the component.", StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT)
			}			
		}
		if (step.outEvents.contains(raiseEventAct)) {
			// It should be an out event
			if (realizationMode == RealizationMode.PROVIDED && eventDirection == EventDirection.IN ||
				realizationMode == RealizationMode.REQUIRED && eventDirection == EventDirection.OUT) {
				error("This event is an in-event of the component.", StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT)
			}			
		}
		if (event.parameterDeclarations.empty && !raiseEventAct.arguments.empty) {
			error("This event type has no parameter.", StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT)
		}
		if (!event.parameterDeclarations.empty && raiseEventAct.arguments.empty) {
			error("This event type must have a parameter.", StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT)
		}
	}
	
	@Check
	def checkInstanceState(InstanceState instanceState) {
		val container = instanceState.eContainer
		if (container instanceof Step) {
			if (container.instanceStates.contains(instanceState)) {
				val instance = instanceState.instance
				val type = instance.type
				if (!(type instanceof StatechartDefinition)) {
					error("This is not a statechart instance.", TracePackage.Literals.INSTANCE_STATE__INSTANCE)
				}
			}
		}
	}
	
	@Check
	def checkInstanceStateConfiguration(InstanceStateConfiguration configuration) {
		val instance = configuration.instance
		val type = instance.type
		if (type instanceof StatechartDefinition) {
			val state = configuration.state
			val states =  EcoreUtil2.getAllContentsOfType(type, hu.bme.mit.gamma.statechart.model.State)
			if (!states.contains(state)) {
				error("This is not a valid state in the specified statechart.", TracePackage.Literals.INSTANCE_STATE_CONFIGURATION__STATE)
			}
		}
	}
	
	@Check
	def checkInstanceVariableState(InstanceVariableState variableState) {
		val instance = variableState.instance
		val type = instance.type
		if (type instanceof StatechartDefinition) {
			val variable = variableState.declaration
			val variables = type.variableDeclarations
			if (!variables.contains(variable)) {
				error("This is not a valid variable in the specified statechart.", ConstraintModelPackage.Literals.REFERENCE_EXPRESSION__DECLARATION)
			}
		}
	}
	
	@Check
	def checkInstanceSchedule(InstanceSchedule schedule) {
		val executionTrace = schedule.eContainer.eContainer as ExecutionTrace
		val component = executionTrace.component
		if (component !== null) {
			if (!(component instanceof AsynchronousCompositeComponent)) {
				error("Instance scheduling is valid only if the component is an asynchronous composite component.",
					TracePackage.Literals.INSTANCE_SCHEDULE__SCHEDULED_INSTANCE)
			}
		}
	}
	
	@Check
	def checkInstanceSchedule(ComponentSchedule schedule) {
		val step = schedule.eContainer as Step
		val executionTrace = step.eContainer as ExecutionTrace
		val component = executionTrace.component
		if (component !== null) {
			if (!(component instanceof SynchronousComponent || component instanceof AsynchronousAdapter)) {
				error("Component scheduling is valid only if the component is a synchronous component or synchronous component wrapper.",
					step, TracePackage.Literals.STEP__ACTIONS, step.actions.indexOf(schedule))
			}
		}
	}
	
}

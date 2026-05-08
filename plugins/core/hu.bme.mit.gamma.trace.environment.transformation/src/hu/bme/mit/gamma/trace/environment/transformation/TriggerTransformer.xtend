/********************************************************************************
 * Copyright (c) 2018-2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.environment.transformation

import hu.bme.mit.gamma.expression.model.NotExpression
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.TimeUnit
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.UnaryType
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.trace.environment.transformation.TraceToEnvironmentModelTransformer.Namings
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class TriggerTransformer {
	//
	protected final Trace trace
	
	protected final extension Namings namings
	
	protected final boolean CONSIDER_NONDETERMINISTIC_BEHAVIOR = true // Works only for sync models, or async models with only one event raised at a time
	
	protected extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	
	protected extension StatechartModelFactory statechartModelFactory = StatechartModelFactory.eINSTANCE
	protected extension InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	//
	
	new(Trace trace, Namings namings) {
		this.trace = trace
		this.namings = namings
	}
	
	//
	
	def dispatch transformTrigger(TimeElapse act, Transition transition) {
		val elapsedTime = act.elapsedTime.clone
		
		val timeoutDeclaration = statechartModelFactory.createTimeoutDeclaration => [
			it.name = timeoutDeclarationName
		]
		val statechart = transition.containingStatechart
		statechart.timeoutDeclarations += timeoutDeclaration
	
		val source = transition.sourceState as State
		
		val setTimeoutActions = source.entryActions.filter(SetTimeoutAction)
		if (!setTimeoutActions.empty) {
			val setTimeoutAction = setTimeoutActions.head
			val value = setTimeoutAction.time.value
			setTimeoutAction.time.value = value.wrapIntoAddExpression(elapsedTime)
					.evaluateInteger.toIntegerLiteral
		}
		else {
			source.entryActions += createSetTimeoutAction => [
				it.timeoutDeclaration = timeoutDeclaration
				it.time = createTimeSpecification => [
					it.value = elapsedTime
					it.unit = TimeUnit.MILLISECOND
				]
			]
		}
		transition.extendTrigger(
			createEventTrigger => [
				it.eventReference = createTimeoutEventReference => [
					it.timeout = timeoutDeclaration
				]
			]
		)
		
		return transition
	}
	
	def dispatch transformTrigger(RaiseEventAct act, Transition transition) {
		val componentPort = act.port
		val environmentPort = trace.getComponentEnvironmentPort(componentPort)
		val event = act.event
		val arguments = act.arguments
		
		transition.effects += createRaiseEventAction => [
			it.port = environmentPort
			it.event = event
			for (argument : arguments) {
				it.arguments += argument.clone
			}
		]
		
		return transition
	}
	
	def dispatch transformTrigger(ComponentSchedule act, Transition transition) {
		if (transition.sourceState instanceof State) {
			if (CONSIDER_NONDETERMINISTIC_BEHAVIOR) {
				// Works only for sync models, or async models with only one event raised at a time
				val step = act.containingStep
				val previousStep = step.previousStep
				
				val asserts = previousStep.asserts.map[it.getSelfAndAllContentsOfType(RaiseEventAct)].flatten
				val triggersAndGuards = asserts.map[it.transformAssert]
				for (triggerAndGuard : triggersAndGuards) {
					val trigger = triggerAndGuard.key
					val guard = triggerAndGuard.value
					transition.extendTrigger(trigger)
					transition.extendGuard(guard)
				}
			}
			if (transition.trigger === null) {
				// The old transition has to have a trigger
				transition.trigger = createOnCycleTrigger
			}
		}
		
		val target = transition.targetState
		val region = target.parentRegion
		val newTarget = createState => [
			it.name = stateName
		]
		region.stateNodes += newTarget
		
		val newTransition = target.createTransition(newTarget)
		
		return newTransition
	}
	
	//
	
	def transformAssert(RaiseEventAct raise) {
		val container = raise.eContainer
		val isNegated = container instanceof NotExpression && container.eContainer instanceof Step
		checkArgument(container instanceof Step || isNegated)
		
		val componentPort = raise.port
		val environmentPort = trace.getComponentEnvironmentPort(componentPort)
		val event = raise.event
		val arguments = raise.arguments
		
		val eventTrigger = environmentPort.createEventTrigger(event)
		
		val trigger = (isNegated) ? eventTrigger.createUnaryTrigger(UnaryType.NOT) : eventTrigger
		
		val guards = arguments.map[
						environmentPort.createEventParameterReference(
							event.parameterDeclarations.get(it.index))
								.createEqualityExpression(it.clone)]
								.wrapIntoAddExpression
		
		return trigger -> guards
	}
	
}
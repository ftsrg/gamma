/********************************************************************************
 * Copyright (c) 2020-2022 Contributors to the Gamma project
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.trace.generator.util

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.scenario.statechart.util.ScenarioStatechartUtil
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.trace.model.Act
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Reset
import hu.bme.mit.gamma.trace.model.Schedule
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List

class ExecutionTraceBackAnnotator {

	protected final extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	protected final extension TraceModelFactory traceFactory = TraceModelFactory.eINSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE

	protected final TraceUtil traceUtil = TraceUtil.INSTANCE
	protected final ScenarioStatechartUtil scenarioStatechartUtil = ScenarioStatechartUtil.INSTANCE

	protected List<Port> ports = null
	protected List<ExecutionTrace> traces = null
	protected List<ExecutionTrace> result = null
	protected boolean removeNotneededInteractions = true
	val boolean isNegativeTest
	
	protected boolean createOriginalActsAndAssertsBasedOnActs

	new(List<ExecutionTrace> _traces, Component original) {
		this.result = newArrayList
		this.traces = _traces
		this.ports = original.ports
		this.isNegativeTest = false
	}

	new(List<ExecutionTrace> _traces, Component original, boolean removeNotneededInteractions,
			boolean createOriginalActsAndAssertsBasedOnActs, boolean isNegativeTest) {
		this.result = newArrayList
		this.traces = _traces
		this.ports = original.ports
		this.removeNotneededInteractions = removeNotneededInteractions
		this.createOriginalActsAndAssertsBasedOnActs = createOriginalActsAndAssertsBasedOnActs
		this.isNegativeTest = isNegativeTest
	}

	def execute() {
		result += traces
		for (resultTrace : result) {
			if (removeNotneededInteractions) {
				resultTrace.removeNotNeededInteractions
			}
			if (createOriginalActsAndAssertsBasedOnActs) {
				resultTrace.createOriginalActsAndAsserts
			}
			/* The actions need to be removed from the step, if it is a 'send' step after a 'receive' step.
			 * This is necessary, to avoid two schedules between receiving the last interactions and asserting to the output.  
			 * 'Send' after 'send' steps should no tbe modified, since there needs to be a schedule between the first assertions and the assertions of the sendos step.			 * 
			 */
			resultTrace.removeActionsWhenSendAfterReceive
		}
		return result
	}

	def removeActionsWhenSendAfterReceive(ExecutionTrace trace) {
		for (var i = 0; i < trace.steps.size; i++) {
			val startingStep = trace.steps.get(i)
			if (startingStep.isReceive) {
				if (i + 1 == trace.steps.size) {
					return
				}
				val next = trace.steps.get(i+1)
				if (next.isSend) {
					if (next.actions.findFirst[!(it instanceof Schedule || it instanceof TimeElapse)] === null){
						next.actions.clear
					} else {
						throw new IllegalArgumentException('''Step number «i» contains both actions other then schedules and time elapse and asserts.''')
					}
				}
			}
		}
	}

	// TODO extract into derived feature class
	def protected boolean isSend(Step step) {
		return step.actions.filter(RaiseEventAct).empty && !step.asserts.filter(RaiseEventAct).empty
	}

	def protected boolean isReceive(Step step) {
		return !step.actions.filter(RaiseEventAct).empty && step.asserts.filter(RaiseEventAct).empty
	}

	def protected boolean isWait(Step step) {
		return step.actions.filter(RaiseEventAct).empty && step.asserts.filter(RaiseEventAct).empty
	}

	def createOriginalActsAndAsserts(ExecutionTrace trace) {
		for (step : trace.steps) {
			val actions = <Act>newArrayList
			val asserts = <Expression>newArrayList
			for (action : step.actions) {
				if (action instanceof RaiseEventAct) {
					val portName = action.port.getName
					if (scenarioStatechartUtil.isTurnedOut(action.port)) {
						var asser = createRaiseEventAct
						asser.port = getPort(scenarioStatechartUtil.getTurnedOutPortName(action.port))
						asser.event = getEvent(asser.port, action.event.name)
						for (argument : action.arguments) {
							asser.arguments += argument.clone
						}
						asserts += asser
					}
					else {
						var reAct = createRaiseEventAct
						reAct.port = getPort(portName)
						reAct.event = getEvent(reAct.port, action.event.name)
						for (argument : action.arguments) {
							reAct.arguments += argument.clone
						}
						actions += reAct
					}
				}
				else if (action instanceof Reset ||
						action instanceof TimeElapse || action instanceof Schedule) {
					actions += action
				}
			}
			if (step == trace.steps.get(0)){
				for (raise : step.asserts.filter(RaiseEventAct).filter[!scenarioStatechartUtil.isTurnedOut(it.port)]){
					var asser = createRaiseEventAct
					asser.port = getPort(raise.port.name)
					asser.event = getEvent(asser.port, raise.event.name)
					for (argument : raise.arguments) {
						asser.arguments += argument.clone
					}
					asserts += asser
				}
			}
			step.actions.clear
			step.actions += actions
			
			asserts += step.asserts.filter(ComponentInstanceStateReferenceExpression)
			step.asserts.clear
			step.asserts += asserts
		}
	}

	def getPort(String name) {
		for (port : ports) {
			if (port.name == name) {
				return port
			}
		}
		return null
	}

	def getEvent(Port port, String name) {
		for (eventDeclaration : port.interfaceRealization.interface.events) {
			if (eventDeclaration.event.name == name) {
				return eventDeclaration.event
			}
		}
		return null
	}

	def removeNotNeededInteractions(ExecutionTrace trace) {
		for (step : trace.steps) {
			if (step != trace.steps.get(0)) {
				if (!step.asserts.filter(RaiseEventAct).filter[scenarioStatechartUtil.isTurnedOut(it.port)].empty) {
					var notNeeded = newArrayList
					for (act : step.actions) {
						if (!isInteractionPairPresent(step, act)) {
							notNeeded += act
						}
					}
					step.actions -= notNeeded
				}
			}
		}
	}

	def boolean isInteractionPairPresent(Step step, Act act) {
		if (act instanceof RaiseEventAct) {
			val port = act.port
			val eventName = act.event.name
			for (asser : step.asserts) {
				if (asser instanceof RaiseEventAction) {
					val tmpPort = asser.port
					val tmpEventName = asser.event.name
					if (tmpEventName == eventName &&
						(port.name == scenarioStatechartUtil.getTurnedOutPortName(tmpPort) ||
							scenarioStatechartUtil.getTurnedOutPortName(port) == tmpPort.name)) {
						return true
					}
				}
			}
		}
		else if (act instanceof Reset || act instanceof TimeElapse ||
				act instanceof Schedule) {
			return true
		}
		return false
	}

}

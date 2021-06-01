/********************************************************************************
 * Copyright (c) 2020-2021 Contributors to the Gamma project
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.trace.generator

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.trace.model.Act
import hu.bme.mit.gamma.trace.model.Assert
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Reset
import hu.bme.mit.gamma.trace.model.Schedule
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.scenario.statechart.util.ScenarioStatechartUtil
import java.util.List

class ExecutionTraceBackAnnotator {

	protected final extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	protected final extension TraceModelFactory traceFactory = TraceModelFactory.eINSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE

	val TraceUtil traceUtil = TraceUtil.INSTANCE
	val ScenarioStatechartUtil scenarioStatechartUtil = ScenarioStatechartUtil.INSTANCE

	List<Port> ports = null;
	List<ExecutionTrace> traces = null;
	List<ExecutionTrace> result = null;
	boolean removeNotneededInteractions = true;

	boolean createOriginalActsAndAssertsBasedOnActs

	new(List<ExecutionTrace> _traces, Component original) {
		this.result = newArrayList
		this.traces = _traces
		this.ports = original.ports
	}

	new(List<ExecutionTrace> _traces, Component original, boolean removeNotneededInteractions,
		boolean createOriginalActsAndAssertsBasedOnActs) {
		this.result = newArrayList
		this.traces = _traces
		this.ports = original.ports
		this.removeNotneededInteractions = removeNotneededInteractions
		this.createOriginalActsAndAssertsBasedOnActs = createOriginalActsAndAssertsBasedOnActs
	}

	def execute() {
		for (var i = 0; i < traces.size; i++) {
			val t = traces.get(i)
			if (!result.exists[traceUtil.isCoveredByStates(t, it)].booleanValue) {
				result += t
			}
		}
		for (t : result) {
			if (removeNotneededInteractions) {
				t.removeNotNeededInteractions
			}
			if (createOriginalActsAndAssertsBasedOnActs) {
				t.createOriginalActsAndAsserts
			}
			t.removeScheduelingWhenSendAfterReceive
		}
		return result
	}

	def removeScheduelingWhenSendAfterReceive(ExecutionTrace trace) {
		for (var i = 0; i < trace.steps.size; i++) {
			val startingStep = trace.steps.get(i)
			if (startingStep.isReceive) {
				var j = i + 1
				while (j < trace.steps.size && trace.steps.get(j).isWait) {
					j++
				}
				if (j == trace.steps.size) {
					return
				}
				val nextNonWait = trace.steps.get(j)
				if (nextNonWait.isSend) {
					nextNonWait.actions.remove(nextNonWait.actions.filter(Schedule).head)
				}
				return
			}
		}
	}

	def protected boolean isSend(Step step) {
		return step.actions.filter(RaiseEventAct).empty && !(step.asserts.filter(RaiseEventAct).empty)
	}

	def protected boolean isReceive(Step step) {
		return !(step.actions.filter(RaiseEventAct).empty) && step.asserts.filter(RaiseEventAct).empty
	}

	def protected boolean isWait(Step step) {
		return step.actions.filter(RaiseEventAct).empty && step.asserts.filter(RaiseEventAct).empty
	}

	def createOriginalActsAndAsserts(ExecutionTrace et) {
		for (s : et.steps) {
			val actions = <Act>newArrayList
			val asserts = <Assert>newArrayList
			for (a : s.actions) {
				if (a instanceof RaiseEventAct) {
					val portName = a.port.getName
					if (scenarioStatechartUtil.isTurnedOut(a.port)) {
						var asser = createRaiseEventAct
						asser.port = getPort(portName.substring(0, portName.length - 8))
						asser.event = getEvent(asser.port, a.event.name)
						for (argument : a.arguments) {
							asser.arguments += argument.clone
						}
						asserts += asser
					} else {
						var reAct = createRaiseEventAct
						reAct.port = getPort(portName)
						reAct.event = getEvent(reAct.port, a.event.name)
						for (argument : a.arguments) {
							reAct.arguments += argument.clone
						}
						actions += reAct
					}
				} else if (a instanceof Reset) {
					actions += a
				} else if (a instanceof TimeElapse) {
					actions += a
				} else if (a instanceof Schedule) {
					actions += a
				}
			}
			s.actions.clear
			s.actions += actions
			s.asserts.clear
			s.asserts += asserts
		}
	}

	def getPort(String name) {
		for (p : ports)
			if (p.name == name)
				return p
		return null
	}

	def getEvent(Port port, String name) {
		for (e : port.interfaceRealization.interface.events)
			if (e.event.name == name)
				return e.event
		return null
	}

	def removeNotNeededInteractions(ExecutionTrace trace) {
		for (step : trace.steps) {
			var notNeeded = newArrayList
			for (act : step.actions) {
				if (!isInteractionPairPresent(step, act)) {
					notNeeded += act
				}
			}
			step.actions.removeAll(notNeeded)
		}
	}

	def boolean isInteractionPairPresent(Step step, Act a) {
		if (a instanceof RaiseEventAct) {
			val port = a.port
			val eventName = a.event.name
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
		} else if (a instanceof Reset) {
			return true
		} else if (a instanceof TimeElapse) {
			return true
		} else if (a instanceof Schedule) {
			return true
		}
		return false
	}

}

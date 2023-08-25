/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util.reducer

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.property.model.AtomicFormula
import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.property.util.PropertyUtil
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.transformation.util.UnfoldingTraceability
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Collection
import java.util.logging.Level
import java.util.logging.Logger

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class CoveredPropertyReducer {
	
	protected final Collection<StateFormula> formulas
	protected final Collection<ExecutionTrace> traces
	
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	
	protected final extension PropertyUtil propertyUtil = PropertyUtil.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension UnfoldingTraceability traceability = UnfoldingTraceability.INSTANCE
	//
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	new(Collection<StateFormula> formulas, ExecutionTrace trace) {
		this(formulas, #[trace])
	}
	
	new(Collection<StateFormula> formulas, Collection<ExecutionTrace> traces) {
		this.formulas = formulas
		this.traces = traces
	}
	
	def execute() {
		val unnecessaryFormulas = newArrayList
		for (formula : formulas) {
			val egLessFormula = formula.egLessFormula
			if (egLessFormula !== null) {
				if (egLessFormula instanceof AtomicFormula) {
					var isUnnecessary = false
					for (var i = 0; i < traces.size && !isUnnecessary; i++)  {
						val trace = traces.get(i)
						val steps = trace.steps
						for (var j = 0; j < steps.size && !isUnnecessary; j++) {
							// New formula is cloned for each step
							val clonedFormula = egLessFormula.clone
							val step = steps.get(j)
							for (instanceStateExpression : clonedFormula
									.getAllContentsOfType(ComponentInstanceElementReferenceExpression)) {
								val evaluation = instanceStateExpression.evaluate(step)
								evaluation.replace(instanceStateExpression)
							}
							// No transient variables in traces (as they are also default)
							// Resettable variable cannot be removed, think of
							// transition-pair coverage
							val expression = clonedFormula.expression
							val evaluation = expression.definitelyTrueExpression
							if (evaluation) {
								isUnnecessary = true
								unnecessaryFormulas += formula
							}
						}
					}
				}
			}
		}
		return unnecessaryFormulas
	}
	
	protected def dispatch evaluate(ComponentInstanceEventParameterReferenceExpression expression, Step step) {
		val topComponentPort = expression.port.boundTopComponentPort
		val event = expression.event
		val parameter = expression.parameterDeclaration
		val parameterIndex = parameter.index
		
		for (raiseEventAct : step.outEvents) {
			val raisedPort = raiseEventAct.port
			val rasiedEvent = raiseEventAct.event
			val arguments = raiseEventAct.arguments
			
			if (topComponentPort.helperEquals(raisedPort) && event.helperEquals(rasiedEvent)) {
				return arguments.get(parameterIndex).clone
			}
		}
		// EventParameterReferenceExpressions too
		for (eventParameterReference : step.eventParameterReferences) {
			val referencedPort = eventParameterReference.port
			val referencedEvent = eventParameterReference.event
			
			if (topComponentPort.helperEquals(referencedPort) && event.helperEquals(referencedEvent)) {
				val value = eventParameterReference.otherOperandIfContainedByEquality
				if (value === null) {
					return expression.clone // Cannot evaluate it, returning the unknown reference
				}
				return value.clone
			}
		}
		
		return createFalseExpression
	}
	
	protected def dispatch evaluate(ComponentInstanceEventReferenceExpression expression, Step step) {
		val topComponentPort = expression.port.boundTopComponentPort
		val event = expression.event
		
		for (raiseEventAct : step.outEvents) {
			val raisedPort = raiseEventAct.port
			val rasiedEvent = raiseEventAct.event
			
			if (topComponentPort.helperEquals(raisedPort) && event.helperEquals(rasiedEvent)) {
				return createTrueExpression
			}
		}
		return createFalseExpression
	}
	
	protected def dispatch evaluate(ComponentInstanceStateReferenceExpression expression, Step step) {
		val instance = expression.instance
		val state = expression.state
		
		for (stateConfiguration : step.instanceStateConfigurations) {
			val stateInstance = stateConfiguration.instance.lastInstance // Only one expected
			val stateVariable = stateConfiguration.state
			
			if (traceability.contains(instance, stateInstance) && state.helperEquals(stateVariable)) {
				return createTrueExpression
			}
		}
		return createFalseExpression
	}
	
	protected def dispatch evaluate(ComponentInstanceVariableReferenceExpression expression, Step step) {
		val instance = expression.instance
		val variable = expression.variableDeclaration
		
		for (variableReference : step.instanceVariableStates) {
			val stateInstance = variableReference.instance.lastInstance // Only one expected
			val stateVariable = variableReference.variableDeclaration
			
			if (traceability.contains(instance, stateInstance) && variable.helperEquals(stateVariable)) {
				val value = variableReference.otherOperandIfContainedByEquality
				if (value === null) {
					return expression.clone // Cannot evaluate it, returning the unknown reference
				}
				return value.clone
			}
		}
		val isInjected = variable.injected
		if (isInjected) { // Not correct in every sense (e.g., resettable variables), but we do not distinguish between different values here
			// This can happen if we run model checking as optimize&verify
			logger.log(Level.WARNING, '''Not found variable for injected variable: «variable.name»''')
			return variable.defaultExpression
		}
		throw new IllegalStateException('''Not found variable: «variable.name»''')
		// Maybe Theta did not return the necessary variables, that is why they cannot be found in the trace
		// (This is a known Theta-bug). On the other hand, UPPAAL always returns all variables
	}
		
}
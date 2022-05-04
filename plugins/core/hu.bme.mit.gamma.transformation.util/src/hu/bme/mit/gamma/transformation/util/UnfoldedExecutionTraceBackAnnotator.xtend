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
package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.trace.model.Assert
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.trace.model.Cycle
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration
import hu.bme.mit.gamma.trace.model.InstanceVariableState
import hu.bme.mit.gamma.trace.model.MultiaryAssert
import hu.bme.mit.gamma.trace.model.NegatedAssert
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Reset
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List
import java.util.logging.Level
import java.util.logging.Logger

import static com.google.common.base.Preconditions.checkArgument
import static com.google.common.base.Preconditions.checkNotNull

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class UnfoldedExecutionTraceBackAnnotator {
	
	protected final ExecutionTrace trace
	protected final Component originalTopComponent
	
	//
	
	protected final List<Assert> dummyAsserts = newArrayList
	
	protected final extension TraceModelFactory traceModelFactory = TraceModelFactory.eINSTANCE
	protected final extension UnfoldingTraceability traceability = UnfoldingTraceability.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	new(ExecutionTrace trace, Component originalTopComponent) {
		checkNotNull(originalTopComponent)
		checkArgument(!originalTopComponent.statechart,
			"The original component cannot be a statechart")
		this.trace = trace
		this.originalTopComponent = originalTopComponent
	}
	
	def execute() {
		val originalExecutionTrace = createExecutionTrace => [
			it.import = originalTopComponent.containingPackage
			it.annotations += trace.annotations.map[it.clone] // References not expected
			it.name = trace.name
			it.component = originalTopComponent
			it.arguments += trace.arguments.map[it.transformExpression]
		]
		
		val steps = trace.steps
		for (step : steps) {
			originalExecutionTrace.steps += step.transformStep
		}
		
		// Potential cycle at the end
		val cycle = trace.cycle
		if (cycle !== null) {
			originalExecutionTrace.cycle = cycle.transformCycle		
		}
		
		// There are injected variables that cannot be back-annotated
		removeDummyAsserts
		
		return originalExecutionTrace
	}
	
	
	// Step
	
	protected def transformStep(Step step) {
		val newStep = createStep
		
		for (act : step.actions) {
			newStep.actions += act.transformAct
		}
		
		for (assert : step.asserts) {
			newStep.asserts += assert.transformAssert
		}
		
		return newStep
	}
	
	protected def transformCycle(Cycle cycle) {
		val newCycle = createCycle
		
		for (step : cycle.steps) {
			newCycle.steps += step.transformStep
		}
		
		return newCycle
	}
	
	// Acts
	
	protected def dispatch transformAct(RaiseEventAct act) {
		return createRaiseEventAct => [
			it.port = originalTopComponent.getOriginalPort(act.port)
			// Works if the interfaces/types are loaded into different resources
			// even when resource set and URI type (absolute/platform) must match
			it.event = originalTopComponent.getOriginalEvent(act.event)
			it.arguments += act.arguments
					.map[it.transformExpression]
		]
	}
	
	protected def dispatch transformAct(Reset act) {
		return createReset
	}
	
	protected def dispatch transformAct(ComponentSchedule act) {
		return createComponentSchedule
	}
	
	protected def dispatch transformAct(TimeElapse act) {
		return createTimeElapse => [
			it.elapsedTime = act.elapsedTime
		]
	}
	
	// Asserts
	
	protected def dispatch Assert transformAssert(InstanceStateConfiguration assert) {
		val instance = assert.instance.lastInstance as SynchronousComponentInstance
		val originalInstance = instance.getOriginalSimpleInstanceReference(originalTopComponent)
		val originalState = originalInstance.getOriginalState(assert.state)
		return createInstanceStateConfiguration => [
			it.instance = originalInstance
			it.state = originalState
			it.region = it.state.parentRegion
		]
	}
	
	protected def dispatch Assert transformAssert(InstanceVariableState assert) {
		val variableReference = assert.variableReference
		val instance = variableReference.instance.lastInstance as SynchronousComponentInstance
		val variable = variableReference.variableDeclaration
		val originalInstance = instance.getOriginalSimpleInstanceReference(originalTopComponent)
		val originalVariable = try {
			originalInstance.getOriginalVariable(variable)
		} catch (IllegalArgumentException e) {
			logger.log(Level.INFO, "Not found original variable for " + variable)
			null
		}
		val variableState = createInstanceVariableState => [
			it.variableReference = statechartUtil.createVariableReference(
				originalInstance, originalVariable)
			it.value = assert.value.transformExpression
		]
		if (originalVariable === null) {
			dummyAsserts += variableState
		}
		return variableState
	}
	
	protected def dispatch Assert transformAssert(RaiseEventAct assert) {
		return assert.transformAct as RaiseEventAct // Same as act
	}
	
	protected def dispatch Assert transformAssert(MultiaryAssert assert) {
		val multiaryAssert = assert.eClass.create as MultiaryAssert
		for (operand : assert.asserts) {
			multiaryAssert.asserts += operand.transformAssert
		}
		return multiaryAssert
	}
	
	protected def dispatch Assert transformAssert(NegatedAssert act) {
		return createNegatedAssert => [
			it.negatedAssert = act.negatedAssert.transformAssert
		]
	}
	
	//
	
	protected def transformExpression(Expression value) {
		val clonedValue = value.clone
		
		val typeReferences = clonedValue.getSelfAndAllContentsOfType(TypeReference)
		for (typeReference : typeReferences) {
			val typeDeclaration = typeReference.reference
			val originalTypeDeclaration = originalTopComponent
					.getOriginalTypeDeclaration(typeDeclaration)
			typeReference.reference = originalTypeDeclaration
		}
		// Enum literal setting in addition to the type reference setting
		if (clonedValue instanceof EnumerationLiteralExpression) {
			val enumLiteral = clonedValue.reference
			val originalEnumLiteral = originalTopComponent
					.getOriginalEnumLiteral(enumLiteral)
			clonedValue.reference = originalEnumLiteral
		}
		
		return clonedValue
	}
	
	//
	
	protected def removeDummyAsserts() {
		dummyAsserts.removeContainmentChains(Assert)
		dummyAsserts.clear
	}
	
}
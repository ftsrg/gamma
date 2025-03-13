/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.MultiaryExpression
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.UnaryExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.trace.model.Cycle
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.InstanceSchedule
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Reset
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List
import java.util.logging.Logger

import static com.google.common.base.Preconditions.checkArgument
import static com.google.common.base.Preconditions.checkNotNull

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class UnfoldedExecutionTraceBackAnnotator {
	
	protected final ExecutionTrace trace
	protected final Component originalTopComponent
	
	//
	
	protected final List<Expression> dummyAsserts = newArrayList
	
	protected final InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	protected final CompositeModelFactory compositeModelFactory = CompositeModelFactory.eINSTANCE
	protected final ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension TraceModelFactory traceModelFactory = TraceModelFactory.eINSTANCE
	protected final extension UnfoldingTraceability traceability = UnfoldingTraceability.INSTANCE
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
					.map[it.transformAssert]
		]
	}
	
	protected def dispatch transformAct(Reset act) {
		return createReset
	}
	
	protected def dispatch transformAct(ComponentSchedule act) {
		return createComponentSchedule
	}
	
	protected def dispatch transformAct(InstanceSchedule act) {
		val instanceReference = act.instanceReference
		val instance = instanceReference.componentInstance
		
		val oldInstanceReference = instance.getOriginalScheduledInstanceReference(originalTopComponent)
		
		return createInstanceSchedule => [
			it.instanceReference = oldInstanceReference
		]
	}
	
	protected def dispatch transformAct(TimeElapse act) {
		return createTimeElapse => [
			it.elapsedTime = act.elapsedTime.clone
		]
	}
	
	// Asserts
	
	protected def dispatch Expression transformAssert(ComponentInstanceStateReferenceExpression assert) {
		try {
			val instance = assert.instance.lastInstance as SynchronousComponentInstance
			val originalInstance = instance.getOriginalSimpleInstanceReference(originalTopComponent)
				val originalState = originalInstance.getOriginalState(assert.state)
			return compositeModelFactory.createComponentInstanceStateReferenceExpression => [
				it.instance = originalInstance
				it.state = originalState
				it.region = it.state.parentRegion
			]
		} catch (IllegalArgumentException e) {
			val message = e.message.trim
			if (message.startsWith("Not found state")) {
				logger.warning(message)
				val trueExpression = expressionModelFactory.createTrueExpression
				dummyAsserts += trueExpression
				return trueExpression
			}
			throw e
		}
	}
	
	protected def dispatch Expression transformAssert(ComponentInstanceVariableReferenceExpression assert) {
		val instance = assert.instance.lastInstance as SynchronousComponentInstance
		val variable = assert.variableDeclaration
		val originalInstance = instance.getOriginalSimpleInstanceReference(originalTopComponent)
		val originalVariable = try {
			originalInstance.getOriginalVariable(variable)
		} catch (IllegalArgumentException e) {
			logger.info("Not found original variable for " + variable)
			null
		}
		val variableState = statechartUtil.createVariableReference(
				originalInstance, originalVariable)
		if (originalVariable === null) {
			dummyAsserts += variableState
		}
		return variableState
	}
	
	protected def dispatch Expression transformAssert(RaiseEventAct assert) {
		return assert.transformAct as RaiseEventAct // Same as act
	}
	
	protected def dispatch Expression transformAssert(EventParameterReferenceExpression assert) {
		return interfaceModelFactory.createEventParameterReferenceExpression => [
			it.port = originalTopComponent.getOriginalPort(assert.port)
			// Works if the interfaces/types are loaded into different resources
			// even when resource set and URI type (absolute/platform) must match
			it.event = originalTopComponent.getOriginalEvent(assert.event)
			it.parameter = it.event.parameterDeclarations.get(assert.parameter.index)
		]
	}
	
	protected def dispatch Expression transformAssert(MultiaryExpression assert) {
		val multiaryAssert = expressionModelFactory.create(assert.eClass) as MultiaryExpression
		
		for (operand : assert.operands) {
			multiaryAssert.operands += operand.transformAssert
		}
		
		return multiaryAssert
	}
	
	protected def dispatch Expression transformAssert(BinaryExpression assert) {
		val binaryAssert = expressionModelFactory.create(assert.eClass) as BinaryExpression
		
		binaryAssert.leftOperand = assert.leftOperand.transformAssert
		binaryAssert.rightOperand = assert.rightOperand.transformAssert
		
		return binaryAssert
	}
	
	protected def dispatch Expression transformAssert(UnaryExpression assert) {
		val unaryAssert = expressionModelFactory.create(assert.eClass) as UnaryExpression
		
		unaryAssert.operand = assert.operand.transformAssert
		
		return unaryAssert
	}
	
	protected def dispatch Expression transformAssert(Expression assert) {
		return assert.transformExpression
	}
	
	//
	
	protected def Expression transformExpression(Expression value) {
		val clonedValue = value.clone
		
		// Type declarations
		val typeDeclarations = newHashSet
		
		val typeReferences = clonedValue.getSelfAndAllContentsOfType(TypeReference)
		typeDeclarations += typeReferences.map[it.reference]
		val recordLiterals = clonedValue.getSelfAndAllContentsOfType(RecordLiteralExpression)
		typeDeclarations += recordLiterals.map[it.typeDeclaration]
		
		for (typeDeclaration : typeDeclarations) {
			val originalTypeDeclaration = originalTopComponent
					.getOriginalTypeDeclaration(typeDeclaration)
			//
			typeReferences.filter[it.reference === typeDeclaration]
					.forEach[it.reference = originalTypeDeclaration]
			recordLiterals.filter[it.typeDeclaration === typeDeclaration]
					.forEach[it.typeDeclaration = originalTypeDeclaration]
		}
		
		// Record fields
		for (recordLiteral : recordLiterals) {
			val recordType = recordLiteral.typeDeclaration.typeDefinition as RecordTypeDefinition
			for (fieldAssignment : recordLiteral.fieldAssignments) {
				val field = fieldAssignment.reference.fieldDeclaration
				val originalField = recordType.fieldDeclarations.findFirst[it.name == field.name] // TODO getOriginalFieldDeclaration
				fieldAssignment.reference = originalField.createReferenceExpression
				fieldAssignment.value = fieldAssignment.value.transformExpression
			}
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
		dummyAsserts.removeContainmentChains(Expression)
		dummyAsserts.clear
	}
	
}
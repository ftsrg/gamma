/********************************************************************************
 * Copyright (c) 2018-2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.DefaultExpression
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.EquivalenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.expression.model.FunctionDeclaration
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.InequalityExpression
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression
import hu.bme.mit.gamma.expression.model.MultiaryExpression
import hu.bme.mit.gamma.expression.model.NullaryExpression
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.RecordAccessExpression
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.UnaryExpression
import hu.bme.mit.gamma.expression.model.ValueDeclaration
import hu.bme.mit.gamma.expression.util.ArgumentInliner
import hu.bme.mit.gamma.expression.util.ComplexTypeUtil
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.EventReference
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification
import hu.bme.mit.gamma.statechart.interface_.TimeUnit
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection
import hu.bme.mit.gamma.statechart.lowlevel.model.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference
import hu.bme.mit.gamma.statechart.statechart.ClockTickReference
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.statechart.statechart.StateReferenceExpression
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration
import hu.bme.mit.gamma.statechart.statechart.TimeoutEventReference
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List
import java.util.logging.Logger

import static com.google.common.base.Preconditions.checkState

import static extension com.google.common.collect.Iterables.getOnlyElement
import static extension hu.bme.mit.gamma.action.derivedfeatures.ActionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ExpressionTransformer {
	// Auxiliary object
	protected final extension TypeTransformer typeTransformer
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension ComplexTypeUtil complexTypeUtil = ComplexTypeUtil.INSTANCE
	protected final extension ArgumentInliner argumentInliner = ArgumentInliner.INSTANCE
	protected final Logger logger = Logger.getLogger("GammaLogger")
	// Expression factory
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final StatechartModelFactory statechartModelFactory = StatechartModelFactory.eINSTANCE
	// Trace needed for variable mappings
	protected final Trace trace
	protected final boolean FUNCTION_INLINING
	protected final boolean ADD_RETURN_GUARDS
	protected final int MAX_RECURSION_DEPTH
	protected final TimeUnit BASE_TIME_UNIT
	
	protected int currentRecursionDepth // For lambdas
	
	new() {
		this(new Trace) // For ad-hoc expression transformations
	}
	
	new(Trace trace) {
		this(trace, true, true, 7, null)
	}
	
	new(Trace trace, boolean functionInlining, boolean addReturnGuards, int maxRecursionDepth) {
		this(trace, functionInlining, addReturnGuards, maxRecursionDepth, null)
	}
	
	new(Trace trace, boolean functionInlining, boolean addReturnGuards, int maxRecursionDepth, TimeUnit baseTimeUnit) {
		this.trace = trace
		this.FUNCTION_INLINING = functionInlining
		this.MAX_RECURSION_DEPTH = maxRecursionDepth
		this.BASE_TIME_UNIT = baseTimeUnit
		this.ADD_RETURN_GUARDS = addReturnGuards
		this.currentRecursionDepth = maxRecursionDepth
		this.typeTransformer = new TypeTransformer(trace)
	}
	
	// One expression is expected to be returned
	
	def Expression transformSimpleExpression(Expression expression) {
		return expression.transformExpression.onlyElement
	}
	
	// Multiple expressions can be returned
	
	def dispatch List<Expression> transformExpression(NullaryExpression expression) {
		return #[ expression.clone ]
	}
	
	def dispatch List<Expression> transformExpression(DefaultExpression expression) {
		return #[ createTrueExpression ]
	}
	
	def dispatch List<Expression> transformExpression(UnaryExpression expression) {
		return #[
			create(expression.eClass) as UnaryExpression => [
				it.operand = expression.operand.transformSimpleExpression
			]
		]
	}
	
	def dispatch List<Expression> transformExpression(BinaryExpression expression) {
		return #[
			create(expression.eClass) as BinaryExpression => [
				it.leftOperand = expression.leftOperand.transformSimpleExpression
				it.rightOperand = expression.rightOperand.transformSimpleExpression
			]
		]
	}
	
	def dispatch List<Expression> transformExpression(EquivalenceExpression expression) {
		val expressions = <Expression>newArrayList
		
		val lowlevelLhs = expression.leftOperand.transformExpression
		val lowlevelRhs = expression.rightOperand.transformExpression
		val size = lowlevelLhs.size
		checkState(lowlevelLhs.size == lowlevelRhs.size)
		
		for (var i = 0; i < size; i++) {
			val lhs = lowlevelLhs.get(i)
			val rhs = lowlevelRhs.get(i)
			
			expressions += create(expression.eClass) as EquivalenceExpression => [
				it.leftOperand = lhs
				it.rightOperand = rhs
			]
		}
		
		checkState(expression instanceof EqualityExpression || expression instanceof InequalityExpression, expression)
		
		return #[
			(expression instanceof EqualityExpression) ?
				expressions.wrapIntoAndExpression :
				expressions.wrapIntoOrExpression
		]
	}
	
	def dispatch List<Expression> transformExpression(MultiaryExpression expression) {
		val multiaryExpression = create(expression.eClass) as MultiaryExpression
		for (containedExpression : expression.operands) {
			multiaryExpression.operands += containedExpression.transformSimpleExpression
		}
		return #[ multiaryExpression ]
	}
	
	def dispatch List<Expression> transformExpression(IntegerRangeLiteralExpression expression) {
		return #[
			createIntegerRangeLiteralExpression => [
				it.leftInclusive = expression.leftInclusive
				it.leftOperand = expression.leftOperand.transformSimpleExpression
				it.rightInclusive = expression.rightInclusive
				it.rightOperand = expression.rightOperand.transformSimpleExpression
			]
		]
	}
	
	def dispatch List<Expression> transformExpression(StateReferenceExpression expression) {
		val gammaRegion = expression.region
		val gammaState = expression.state
		return #[
			statechartModelFactory.createStateReferenceExpression => [
				it.region = trace.get(gammaRegion)
				it.state = trace.get(gammaState)
			]
		]
	}
	
	def dispatch List<Expression> transformExpression(IfThenElseExpression expression) {
		return #[
			createIfThenElseExpression => [
				it.condition = expression.condition.transformSimpleExpression
				it.then = expression.then.transformSimpleExpression
				it.^else = expression.^else.transformSimpleExpression
			]
		]
	}
	
	def dispatch List<Expression> transformExpression(EnumerationLiteralExpression expression) {
		val gammaEnumLiteral = expression.reference
		val index = gammaEnumLiteral.index
		val gammaEnumTypeDeclaration = gammaEnumLiteral.typeDeclaration
		checkState(trace.isMapped(gammaEnumTypeDeclaration))
		val lowlevelEnumTypeDeclaration = trace.get(gammaEnumTypeDeclaration)
		val lowlevelEnumTypeDefinition = lowlevelEnumTypeDeclaration.type as EnumerationTypeDefinition
		return #[
			lowlevelEnumTypeDefinition.literals.get(index).createEnumerationLiteralExpression
		]
	}
	
	def dispatch List<Expression> transformExpression(RecordLiteralExpression expression) {
		// Currently the field assignment position has to match the field declaration position
		val result = newArrayList
		
		val sortedRecord = expression.sortedRecordLiteral
		for (assignment : sortedRecord.fieldAssignments) {
			result += assignment.value.transformExpression
		}
		
		return result
	}
	
	def dispatch List<Expression> transformExpression(ArrayLiteralExpression expression) {
		// Currently the field assignment position has to match the field declaration position
		val transformedExpressions = <List<Expression>>newArrayList
		for (operand : expression.operands) {
			transformedExpressions += operand.transformExpression
		}
		val result = <Expression>newArrayList
		val sizeOfTransformedExpressions = transformedExpressions.head.size
		// If sizeOfTransformedExpressions == 1: primitive type or array type, no record, one literal is returned
		// Else there is a wrapped record: array of records is transformed into record of arrays
		// Transforming { [1, 2],  [3, 4], [5, 6] } into { [1, 3, 5],  [2, 4, 6] }
		for (var i = 0; i < sizeOfTransformedExpressions; i++) {
			val arrayLiteral = createArrayLiteralExpression
			result += arrayLiteral
			for (transformedExpression : transformedExpressions) {
				arrayLiteral.operands += transformedExpression.get(i)
			}
		}
		return result
	}
	
	def dispatch List<Expression> transformExpression(EventParameterReferenceExpression expression) {
		return expression.transformReferenceExpression
	}
		
	def dispatch List<Expression> transformExpression(RecordAccessExpression expression) {
		return expression.transformReferenceExpression
	}
	
	def dispatch List<Expression> transformExpression(ArrayAccessExpression expression) {
		return expression.transformReferenceExpression
	}

	def dispatch List<Expression> transformExpression(DirectReferenceExpression expression) {
		return expression.transformReferenceExpression
	}
	
	def dispatch List<Expression> transformExpression(TimeSpecification timeSpecification) {
		return #[
			timeSpecification.timeInMilliseconds.transformSimpleExpression
		]
	}
	
	// Key method: reference expression
	
	def List<Expression> transformReferenceExpression(ReferenceExpression _expression) {
		val expression = _expression.needPreprocessForReferenceExpression ?
				_expression.preprocessReferenceExpression : _expression
		
		val reference = expression.accessReference
		// a[0].b.c[1].d
		val fieldAccess = expression.fieldAccess // .b .c
		val indexes = expression.indexAccess // [0] and [1]
		// It is the callers responsibility to make sure the original expression contains all necessary indexes
		val lowlevelIndexes = indexes.map[it.transformSimpleExpression].toList
		
		val lowlevelVariables = <ValueDeclaration>newArrayList
		
		// If original is not a full access, other potential fields are explored, i.e., fieldAccess can be an extensible field access
		if (reference instanceof DirectReferenceExpression) {
			val declaration = reference.declaration as ValueDeclaration
			if (trace.isForStatementParameterMapped(declaration)) {
				// For statement parameter declaration
				val forLoopParameter = declaration as ParameterDeclaration
				lowlevelVariables += trace.get(forLoopParameter)
			}
			else if (trace.isParMapped(declaration -> fieldAccess)) {
				// Function parameter value
				lowlevelVariables += trace.getAllPar(declaration -> fieldAccess)
			}
			else {
				// Normal value
				lowlevelVariables += trace.getAll(declaration -> fieldAccess)
			}
		}
		else if (reference instanceof EventParameterReferenceExpression) {
			val port = reference.port
			val event = reference.event
			val parameter = reference.parameter
			lowlevelVariables += trace.getAllInParameters(port, event, parameter -> fieldAccess)
		}
		
		// Simple references are returned if indexes are empty
		val lowlevelReferences = <Expression>newArrayList
		lowlevelReferences += lowlevelVariables.map[
				it.index(lowlevelIndexes)]
		
		return lowlevelReferences
	}
	
	protected def needPreprocessForReferenceExpression(ReferenceExpression expression) {
		return expression.isOrContainsTypesTransitively(
					#[ FunctionAccessExpression, ArrayAccessExpression ])
	}
	
	protected def preprocessReferenceExpression(ReferenceExpression expression) {
		val _expression = expression.clone
				.createNotExpression // Dummy container due to 'replace'
		
		// Inline lambdas
		while (_expression.containsTypeTransitively(FunctionAccessExpression)) {
			val functionAccesses = _expression.getAllContentsOfType(FunctionAccessExpression)
			checkState(functionAccesses.map[it.functionDeclaration].forall[it.pure])
			functionAccesses.forEach[it.createInlinedLambaExpression.replace(it)]
		}
		// Inline array literals
		var arrayLiterals = _expression.getAllContentsOfType(ArrayAccessExpression)
		while (arrayLiterals.exists[it.arrayAccessEvaluable]) {
			arrayLiterals.filter[it.arrayAccessEvaluable]
					.forEach[it.evaluateArrayAccess.replace(it)]
			arrayLiterals = _expression.getAllContentsOfType(ArrayAccessExpression)
		}
		// Inline record literals
		var recordAccesses = _expression.getAllContentsOfType(RecordAccessExpression)
		while (recordAccesses.exists[it.recordAccessEvaluable]) {
			recordAccesses.filter[it.recordAccessEvaluable]
					.forEach[it.evaluateRecordAccess.replace(it)]
			recordAccesses = _expression.getAllContentsOfType(RecordAccessExpression)
		}
		
		return _expression.operand // Dummy container
	}
	
	// Function access
	
	def dispatch List<Expression> transformExpression(FunctionAccessExpression expression) {
		val result = <Expression>newArrayList
		if (FUNCTION_INLINING) {
			if (trace.isMapped(expression)) {
				// By now, the procedure call must be inlined by ExpressionPreconditionTransformer
				for (returnVariable : trace.get(expression)) {
					result += returnVariable.createReferenceExpression
				}
			}
			else {
				val function = expression.declaration as FunctionDeclaration
				checkState(function.lambda)
				val type = function.type
				if (currentRecursionDepth <= 0) {
					// We return with a defaultValue
					result += type.initialValueOfType
				}
				else {
					currentRecursionDepth--
					
					var clonedBody = expression.createInlinedLambaExpression
					result += clonedBody.transformExpression // Possible recursion
					
					currentRecursionDepth++
				}
			}
		}
		else {
			if (trace.isMapped(expression)) {
				// Extracted method call
				for (returnVariable : trace.get(expression)) {
					result += returnVariable.createReferenceExpression
				}
			}
			else {
				// Basic method call
				val gammaFunction = expression.functionDeclaration
				val arguments = expression.arguments
				// By now, the procedure must be transformed by ExpressionPreconditionTransformer
				if (!trace.isMapped(gammaFunction)) { // On-the-fly transformation added here
					val extension functionTransformer = new FunctionTransformer(trace, ADD_RETURN_GUARDS)
					gammaFunction.transformAndStoreFunction
				}
				
				val lowlevelFunction = trace.get(gammaFunction)
				val lowlevelArguments = arguments.map[it.transformExpression].flatten.toList
				val lowlevelCall = lowlevelFunction.createFunctionAccessExpression(lowlevelArguments)
				result += lowlevelCall
			}
		}
		return result
	}
	
	def dispatch List<Expression> transformExpression(EventReference expression) {
		return #[
			transformEventReference(expression)
		]
	}
	
	// Previously EventReferenceTransformer
	
	def transformToLowlevelGuard(EventDeclaration lowlevelEvent) {
		return lowlevelEvent.isRaised.createReferenceExpression
	}
	
	def dispatch Expression transformEventReference(AnyPortEventReference reference) {
		val port = reference.port
		val allEvents = trace.getAllLowlevelEvents(port, EventDirection.IN) // Considering only IN events
		val triggerGuards = newLinkedList
		for (event : allEvents) {
			triggerGuards += event.transformToLowlevelGuard
		}
		return triggerGuards.wrapIntoOrExpression
	}
	
	def dispatch Expression transformEventReference(ClockTickReference reference) {
		throw new IllegalArgumentException("Clock references are not yet transformed: " + reference)
	}
	
	def dispatch Expression transformEventReference(PortEventReference reference) {
		val port = reference.port
		val event = reference.event
		val lowlevelEvent = trace.get(port, event, EventDirection.IN)
		return lowlevelEvent.transformToLowlevelGuard
	}
	
	def dispatch Expression transformEventReference(TimeoutEventReference reference) {
		// This rule is based on the restriction that in Gamma, a timeout declaration is set only a SINGLE time
		// Otherwise it would be very hard to transform the timing approach of Gamma in "compile time", as it is
		// not known what the actual value of a timeout declaration is due to possible multiple value assignments.
		// This problem derives from the different approaches to timings: Gamma - time elapses from a certain
		// value to 0, whereas in lowlevel - from 0 to infinity.
		try {
			val timeout = reference.timeout
			val value = timeout.valueOfTimeout
			
			// Trying optimization first 'after 0 s'
			if (value.evaluable && value.evaluateInteger == 0) {
				logger.info("Optimizing 'after 0' timeout trigger")
				return createTrueExpression
			}
			//
			
			// The timeouts are TRUE at start according to semantics, that is why they have to set to the highest value
			val lowlevelTimeoutVar = trace.get(timeout)
			val lowlevelExpression = lowlevelTimeoutVar.expression
			if (lowlevelExpression === null) {
				lowlevelTimeoutVar.expression = value.clone // This is already a low-level expression
			}
			else {
				// Multiple timeouts can be transformed to a single variable (optimization)
				// We need the max initial value, to make sure each one is true at the beginning
				val oldValue = lowlevelExpression
				val newValue = value.clone
				try {
					val evaluatedOldValue = oldValue.evaluateInteger
					val evaluatedNewValue = newValue.evaluateInteger
					if (evaluatedOldValue < evaluatedNewValue) {
						lowlevelTimeoutVar.expression = newValue
					}
				} catch (IllegalArgumentException e) {
					// One expression is a variable: better to do add expression
					lowlevelTimeoutVar.expression = createAddExpression => [
						it.operands += lowlevelTimeoutVar.expression
						it.operands += value.clone
					]
				}
			}
			// [500 <= timeoutClock]
			return createLessEqualExpression => [
				it.leftOperand = value
				it.rightOperand = lowlevelTimeoutVar.createReferenceExpression
			]
		} catch (IllegalArgumentException e) {
			// Timeout declaration is not started, always true
			return createTrueExpression
		}
	}
	
	//
	
	protected def Expression getValueOfTimeout(TimeoutDeclaration timeoutDeclaration) {
		val gammaStatechart = timeoutDeclaration.containingStatechart
		val timeoutSettings = gammaStatechart.getAllContentsOfType(SetTimeoutAction)
		val correctTimeoutSetting = timeoutSettings.filter[it.timeoutDeclaration == timeoutDeclaration]
		val times = correctTimeoutSetting.map[it.time].toList
		if (times.empty) {
			throw new IllegalArgumentException("No value for " + timeoutDeclaration)
		}
		
		checkState(times.allHelperEquals || // Exactly the same (e.g., with variables)
			times.map[it.evaluateNanoseconds.toIntegerLiteral].allHelperEquals, // Same value
			"Not one setting to the same timeout declaration: " + correctTimeoutSetting)
		// Single assignment, expected branch
		return times.head.transform
	}
	
	protected def Expression transform(TimeSpecification time) {
		var smallestTimeUnit = BASE_TIME_UNIT // If null (unset), the caller doesn't care - we try to find the smallest unit
		if (smallestTimeUnit === null) {
			try {
				val _package = time.containingPackage // "Package" and not "component" - to support joint time lapse 
				smallestTimeUnit = _package.smallestTimeUnit // MILLISEC by default in a model
			} catch (Exception e) {}
		}
		return time.value.transform(time.unit, smallestTimeUnit)
	}

	protected def Expression transform(Expression timeValue, TimeUnit timeUnit, TimeUnit base) {
		val plainValue = timeValue.transformSimpleExpression
		val multiplicator = timeUnit.getMultiplicator(base)
		checkState(0 < multiplicator)
		
		if (multiplicator == 1) {
			return plainValue
		}
		return plainValue.wrapIntoMultiply(multiplicator)
	}
	
	//
	
}
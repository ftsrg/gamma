/********************************************************************************
 * Copyright (c) 2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation.util

import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.action.model.ProcedureDeclaration
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.FunctionDeclaration
import hu.bme.mit.gamma.expression.model.LambdaDeclaration
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.TimeUnit
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static hu.bme.mit.gamma.xsts.transformation.util.LowlevelNamings.*

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class FunctionTransformer {
	// 
	protected final Trace trace
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension ActionTransformer actionTransformer
	protected final extension ValueDeclarationTransformer valueDeclarationTransformer
	protected final extension TypeTransformer typeTransformer
	// Auxiliary objects
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	// Factory objects
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActionModelFactory actionFactory = ActionModelFactory.eINSTANCE
	// Transformation parameters
	protected final boolean ADD_RETURN_GUARDS // Checked only if functions are NOT inlined
	
	new(Trace trace) {
		this(trace, true)
	}
	
	new(Trace trace, boolean addReturnGuards) {
		this.trace = trace
		this.actionTransformer = new ActionTransformer(trace, false, addReturnGuards, 0, TimeUnit.NANOSECOND)
		this.expressionTransformer = actionTransformer.expressionTransformer
		this.valueDeclarationTransformer = new ValueDeclarationTransformer(this.trace)
		this.typeTransformer = new TypeTransformer(this.trace)
		this.ADD_RETURN_GUARDS = addReturnGuards
	}
	
	def FunctionDeclaration transformAndStoreFunction(FunctionDeclaration function) {
		val lowlevelFunction = function.transformFunction
		
		if (function.hasContainerOfType(Component)) {
			val gammaComponent = function.containingComponent
			val lowlevelComponent = trace.get(gammaComponent)
			lowlevelComponent.functionDeclarations += lowlevelFunction
		}
		else {
			trace.lowlevelPackage.functionDeclarations += lowlevelFunction
		}
		
		return lowlevelFunction
	}
	
	def FunctionDeclaration transformFunction(FunctionDeclaration function) {
		val type = function.type
		
		val parameters = function.parameterDeclarations
		val lowlevelParameters = parameters.map[it.transformFunctionParameter].flatten.toList
		
		val lowlevelType = type.transformType
		val lowlevelName = getName(function)
		
		val lowlevelFunction =
		if (function instanceof ProcedureDeclaration) {
			val lowlevelProcedure = createProcedureDeclaration
			trace.put(function, lowlevelProcedure) // Here, to support recursion
			
			lowlevelProcedure.type = lowlevelType // Needed here for returning tuple literals
			
			val lowlevelBody = function.body?.transformAction?.wrap // Can be null: declaration
			lowlevelProcedure.body = lowlevelBody
			
			if (ADD_RETURN_GUARDS && lowlevelBody !== null) {
				val extension returnGuardHandler = new ProcedureReturnGuardHandler
				lowlevelBody.createAndSetReturnedDeclarationAndAddReturnGuard
			}
			
			lowlevelProcedure
		}
		else if (function instanceof LambdaDeclaration) {
			val lowlevelLambda = createLambdaDeclaration
			trace.put(function, lowlevelLambda) // Here, to support recursion
			
			lowlevelLambda.type = lowlevelType
			
			val expression = function.expression
			val lowlevelExpressions = (expression !== null) ?
					expression.transformExpression : #[ null ] // Declaration: can be null
			lowlevelLambda.expression = (lowlevelExpressions.size > 1) ?
				lowlevelExpressions.createTupleLiteralExpression(lowlevelType.typeDefinition) :
				lowlevelExpressions.head
			
			lowlevelLambda
		}
		else {
			throw new IllegalArgumentException("Not known function type: " + function)
		}
		
		lowlevelFunction.name = lowlevelName
		lowlevelFunction.parameterDeclarations += lowlevelParameters
		
		return lowlevelFunction
	}
	
}
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

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.expression.model.TupleLiteralExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.model.VoidTypeDefinition
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.FunctionCallAction
import hu.bme.mit.gamma.xsts.model.ProcedureDeclaration
import hu.bme.mit.gamma.xsts.model.ReturnAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import org.eclipse.emf.ecore.EObject

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class FunctionInliner {
	// Singleton
	public static final FunctionInliner INSTANCE =  new FunctionInliner
	protected new() {}
	//
	protected int currentRecursionDepth = 7 // TODO
	//
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	//
	
	def void inlineFunctionAccessExpressions(EObject object) {
		for (functionAccess : object.getAllContentsOfType(FunctionAccessExpression)
					.reject[it.calledFromFunctionDeclaration] /* Recursing handling inside */) {
			functionAccess.inline
		}
	}
	
	def void inline(FunctionAccessExpression expression) {
		val inlined = expression.execute
		val action = inlined.key
		val returnExpression = inlined.value
		
		val actionContainer = expression.getContainerOfType(Action)
		if (actionContainer instanceof FunctionCallAction) {
			action.replace(actionContainer)
		}
		else {
			action.prependToAction(actionContainer)
			checkState(returnExpression !== null, expression.functionDeclaration.name)
			returnExpression.replace(expression)
			
			if (returnExpression instanceof TupleLiteralExpression) {
				returnExpression.inlineTupleAssignmentAction
			}
		}
		
		// Recursion here (not in execute due to containment hierarchy)
		val functionAccessExpressions = newArrayList
		if (action !== null) {
			functionAccessExpressions += action.getSelfAndAllContentsOfType(FunctionAccessExpression)
		}
		if (returnExpression !== null) {
			functionAccessExpressions += returnExpression.getSelfAndAllContentsOfType(FunctionAccessExpression)
		}
		for (functionAccessExpression : functionAccessExpressions.filterNull) {
			currentRecursionDepth--
			
			functionAccessExpression.inline
			
			currentRecursionDepth++
		}
	}
	
	def execute(FunctionAccessExpression expression) {
		val procedure = expression.functionDeclaration
		
		// End of recursion
		if (currentRecursionDepth <= 0) {
			val procedureType = procedure.type.clone
			val xStsAssertion = XSTSModelFactory.eINSTANCE.createEmptyAction // Should be assert(false)?
			val defaultExpression = (procedureType.isVoid) ? null : procedureType.defaultExpression
			return xStsAssertion -> defaultExpression
		}
		//
		
		val arguments = expression.arguments
		val parameterDeclarations = procedure.parameterDeclarations
		val size = arguments.size
		checkState(size == parameterDeclarations.size)
		
		val inlinedActions = <Action>newArrayList
		val EObject clonedBody = procedure.body.clone
		
		val namePostfix = expression.uniqueIndex + "_" + procedure.uniqueIndex + "_" + currentRecursionDepth
		
		// Create local parameter declarations
		for (var i = 0; i < size; i++) {
			val argument = arguments.get(i)
			val parameterDeclaration = parameterDeclarations.get(i)
			
			val parameterType = parameterDeclaration.type.clone
			val name = '''_«parameterDeclaration.name»_«namePostfix»'''
			val localStatement = parameterType.createVariableDeclarationAction(name, argument.clone)
			val localParameterDeclaration = localStatement.variableDeclaration
			
			inlinedActions += localStatement
			localParameterDeclaration.change(parameterDeclaration, clonedBody)
		}
		
		var VariableDeclaration localReturnDeclaration = null
		if (clonedBody instanceof Action) {
			checkState(procedure instanceof ProcedureDeclaration)
			// Rename local declarations
			val declarations = clonedBody.getAllContentsOfType(VariableDeclarationAction)
					.map[it.variableDeclaration]
			for (declaration : declarations) {
				val name = declaration.name
				declaration.name = '''«name»_«namePostfix»'''
				// A default expression is needed, otherwise some uninitialized parts of record can be havoced
				if (declaration.expression === null) {
					declaration.expression = declaration.type.defaultExpression
				}
			}
			
			// Handling return statements
			val returnStatements = clonedBody.getSelfAndAllContentsOfType(ReturnAction)
			if (!returnStatements.empty) {
				val procedureType = procedure.type.clone // typeDefinition is not correct due to record literals
				val localDeclarationPostfix = '''_«procedure.name»_«namePostfix»'''
				// This declaration will store the return value
				val isVoid = procedureType.typeDefinition instanceof VoidTypeDefinition 
				if (!isVoid) {
					val localStatement = procedureType.createVariableDeclarationAction(
						'''_returnValue«localDeclarationPostfix»''')
					localReturnDeclaration = localStatement.variableDeclaration
					inlinedActions += localStatement
				}
				// This declaration will store during execution, whether we have to return
				// Later optimizations will remove these declarations if they are unnecessary
				val localIsReturnedStatement = '''_isReturned«localDeclarationPostfix»'''.createBooleanVariableDeclarationAction
				val localIsReturnedDeclaration = localIsReturnedStatement.variableDeclaration
				inlinedActions += localIsReturnedStatement
				
				val extension returnGuardHandler = new ProcedureReturnGuardHandler(localIsReturnedDeclaration)
				
				for (returnStatement : returnStatements) {
					// Setting the boolean flag: a return is executed
					returnStatement.setReturnedDeclarationAndAddReturnGuard
					
					// Storing the return value
					val returnExpression = returnStatement.expression
					if (returnExpression !== null) {
						val clonedReturnExpression = returnExpression.clone
						val returnAssignment = localReturnDeclaration.createAssignmentAction(clonedReturnExpression)
						returnAssignment.replace(returnStatement)
					}
					else {
						returnStatement.remove
					}
				}
			}
			inlinedActions += clonedBody
		}
		
		val xStsAction = inlinedActions.createSequentialAction
		// No tracing needed
		val returnExpression = (clonedBody instanceof Expression) ? clonedBody :
				localReturnDeclaration?.createReferenceExpression
		return xStsAction -> returnExpression
	}
	
}
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
package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.action.model.ConstantDeclarationStatement
import hu.bme.mit.gamma.action.model.ProcedureDeclaration
import hu.bme.mit.gamma.action.model.ReturnStatement
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.model.VoidTypeDefinition
import hu.bme.mit.gamma.expression.util.FieldHierarchy
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class FunctionInliner {
	//
	protected int currentRecursionDepth
	//
	protected final Trace trace
	protected final extension ActionTransformer actionTransformer
	//
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	//
	
	new(Trace trace, ActionTransformer actionTransformer) {
		this.trace = trace
		this.actionTransformer = actionTransformer
	}
	
	def execute(FunctionAccessExpression expression) {
		val procedure = expression.functionDeclaration as ProcedureDeclaration
		val arguments = expression.arguments
		val parameterDeclarations = procedure.parameterDeclarations
		val size = arguments.size
		checkState(size == parameterDeclarations.size)
		
		val inlinedActions = <Action>newArrayList
		val clonedBlock = procedure.body.clone
		
		val namePostfix = expression.uniqueIndex + "_" + procedure.uniqueIndex + "_" + currentRecursionDepth++
		
		// Rename local declarations
		val declarations = clonedBlock.getAllContentsOfType(VariableDeclarationStatement)
				.map[it.variableDeclaration] + 
			clonedBlock.getAllContentsOfType(ConstantDeclarationStatement).map[it.constantDeclaration]
		for (declaration : declarations) {
			val name = declaration.name
			declaration.name = '''«name»_«namePostfix»'''
			// A default expression is needed, otherwise some uninitialized parts of record can be havoced
			if (declaration.expression === null) {
				declaration.expression = declaration.type.defaultExpression
			}
		}
		
		// Create local parameter declarations
		for (var i = 0; i < size; i++) {
			val argument = arguments.get(i)
			val parameterDeclaration = parameterDeclarations.get(i)
			
			val parameterType = parameterDeclaration.type.clone
			val name = '''_«parameterDeclaration.name»_«namePostfix»'''
			val localStatement = parameterType.createDeclarationStatement(name, argument.clone)
			val localParameterDeclaration = localStatement.variableDeclaration
			
			inlinedActions += localStatement
			localParameterDeclaration.change(parameterDeclaration, clonedBlock)
		}
		
		// Handling return statements
		var VariableDeclaration localReturnDeclaration = null
		val returnStatements = clonedBlock.getSelfAndAllContentsOfType(ReturnStatement)
		if (!returnStatements.empty) {
			val procedureType = procedure.type.clone // typeDefinition is not correct due to record literals
			val localDeclarationPostfix = '''_«procedure.name»_«namePostfix»'''
			// This declaration will store the return value
			val isVoid = procedureType.typeDefinition instanceof VoidTypeDefinition 
			if (!isVoid) {
				val localStatement = procedureType.createDeclarationStatement(
					'''_returnValue«localDeclarationPostfix»''')
				localReturnDeclaration = localStatement.variableDeclaration
				inlinedActions += localStatement
			}
			// This declaration will store during execution, whether we have to return
			// Later optimizations will remove these declarations if they are unnecessary
			val localIsReturnedStatement = '''_isReturned«localDeclarationPostfix»'''.createBooleanDeclarationStatement
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
					val returnAssignment = localReturnDeclaration.createAssignment(clonedReturnExpression)
					returnAssignment.replace(returnStatement)
				}
				else {
					returnStatement.remove
				}
			}
		
		}
		inlinedActions += clonedBlock
		
		// Transforming local parameters, local return declarations and the block
		val lowlevelAction = inlinedActions.transformActions
		if (localReturnDeclaration !== null) {
			// Tracing the function access expression to the return declarations 
			val lowlevelReturnDeclarations = trace.getAll(localReturnDeclaration -> new FieldHierarchy)
			trace.put(expression, lowlevelReturnDeclarations)
		}
		
		return lowlevelAction
	}
	
}
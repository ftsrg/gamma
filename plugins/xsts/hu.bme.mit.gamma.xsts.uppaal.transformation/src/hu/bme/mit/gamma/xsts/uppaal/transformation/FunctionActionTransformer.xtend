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
package hu.bme.mit.gamma.xsts.uppaal.transformation

import hu.bme.mit.gamma.uppaal.util.AssignmentExpressionCreator
import hu.bme.mit.gamma.uppaal.util.NtaBuilder
import hu.bme.mit.gamma.uppaal.util.TypeTransformer
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.LoopAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.transformation.util.MessageQueueUtil
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collection
import uppaal.NTA
import uppaal.declarations.VariableContainer
import uppaal.declarations.VariableDeclaration
import uppaal.statements.Statement
import uppaal.templates.Location

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension java.lang.Math.abs

class FunctionActionTransformer {
	
	protected final NTA nta
	protected final Traceability traceability
	protected final extension NtaBuilder ntaBuilder
	
	protected final Collection<VariableDeclaration> localVariables = newHashSet
	
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension VariableTransformer variableTransformer
	protected final extension AssignmentExpressionCreator assignmentExpressionCreator
	protected final extension TypeTransformer typeTransformer
	
	protected final extension MessageQueueUtil messageQueueUtil = MessageQueueUtil.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	new(NtaBuilder ntaBuilder, Traceability traceability) {
		this.ntaBuilder = ntaBuilder
		this.traceability = traceability
		this.nta = ntaBuilder.nta
		this.variableTransformer = new VariableTransformer(ntaBuilder, traceability)
		this.expressionTransformer = new ExpressionTransformer(traceability)
		this.assignmentExpressionCreator = new AssignmentExpressionCreator(ntaBuilder)
		this.typeTransformer = new TypeTransformer(nta)
	}
	
	// Wrap into a function
	
	def void transformIntoFunction(Action action, Location source, Location finalTarget) {
		localVariables.clear
		
		val uppaalAction = action.transformAction // localVariables are filled now
		val uppaalBlock = uppaalAction.createBlock
		
		uppaalBlock.declarations = localVariables.createLocalDeclarations
		val name = '''action_«action.hashCode.abs»'''
		
		val actionFunction = name.createVoidFunction(uppaalBlock)
		
		nta.globalDeclarations.declaration += actionFunction.createFunctionDeclaration
		
		val lastEdge = source.createEdge(finalTarget)
		lastEdge.update += actionFunction.createFunctionCallExpression
	} 
	
	// Transform action dispatch
	
	protected def dispatch Statement transformAction(EmptyAction action) {
		return null
	}
	
	protected def dispatch Statement transformAction(AssumeAction action) {
		val assumption = action.assumption
		if (assumption.queueExpression) {
			return createEmptyStatement
		}
		
		throw new IllegalArgumentException("Not known assume action")
	}
	
	protected def dispatch Statement transformAction(AssignmentAction action) {
		// UPPAAL does not support 'a = {1, 2, 5}' like assignments
		val assignmentActions = action.extractArrayLiteralAssignments
		val uppaalAssignments = newArrayList
		for (assignmentAction : assignmentActions) {
			val uppaalLhs = assignmentAction.lhs.transform
			val uppaalRhs = assignmentAction.rhs.transform
			uppaalAssignments += uppaalLhs.createAssignmentExpression(uppaalRhs)
		}
		
		val uppaalStatements = uppaalAssignments.createStatements
		
		if (uppaalStatements.size > 1) {
			return uppaalStatements.createBlock
		}
		return uppaalStatements.head
	}
	
	protected def dispatch Statement transformAction(VariableDeclarationAction action) {
		val xStsVariable = action.variableDeclaration
		
		val uppaalVariable = xStsVariable.transformAndTraceVariable
		uppaalVariable.extendNameWithHash // Needed for local declarations
		uppaalVariable.remove // We will use it as a local variable
		localVariables += uppaalVariable
		
		val xStsInitialValue = xStsVariable.initialValue
		val uppaalRhs = xStsInitialValue.transform
		
		return uppaalVariable.createAssignmentExpression(uppaalRhs).createStatement
	}
	
	protected def void extendNameWithHash(VariableContainer uppaalContainer) {
		for (uppaalVariable : uppaalContainer.variable) {
			uppaalVariable.name = '''«uppaalVariable.name»_«uppaalVariable.hashCode.abs»'''
		}
	}
	
	protected def dispatch Statement transformAction(SequentialAction action) {
		val xStsActions = action.actions
		val uppaalStatements = newArrayList
		for (xStsAction : xStsActions) {
			uppaalStatements += xStsAction.transformAction // Might be null
		}
		return uppaalStatements.filterNull
			.createBlock
	}
	
	protected def dispatch Statement transformAction(NonDeterministicAction action) {
		throw new IllegalArgumentException("Nondeterministic actions are not supported: " + action)
	}
	
	protected def dispatch Statement transformAction(IfAction action) {
		val xStsCondition = action.condition
		val xStsThen = action.then
		val xStsElse = action.^else
		
		val uppaalCondition = xStsCondition.transform
		val uppaalThen = xStsThen.transformAction // Might be null
		val uppaalElse = xStsElse.transformAction // Might be null
		
		return uppaalCondition.createIfStatement(uppaalThen, uppaalElse)
	}
	
	protected def dispatch Statement transformAction(LoopAction action) {
		val xStsParameter = action.iterationParameterDeclaration
		val xStsRange = action.range
		val xStsActionInLoop = action.action
		
		val left = xStsRange.left
		val right = xStsRange.right
		
		val uppaalVariable = xStsParameter.transformAndTraceParameter
//		uppaalVariable.extendNameWithHash // Needed for local declarations
		uppaalVariable.remove // We will use it as a local variable
//		localVariables += uppaalVariable
		
		val uppaalLeft = left.transform
		val uppaalRight = right.transform
		uppaalVariable.typeDefinition = uppaalLeft.createRange(uppaalRight)
		
		
		val uppaalLoop = uppaalVariable.createForStatement(null /* Cannot be transformed here */)
		traceability.put(xStsParameter, uppaalLoop) // Messed up loop metamodel parts...
		val uppaalAction = xStsActionInLoop.transformAction
		uppaalLoop.statement = uppaalAction
		
		return uppaalLoop
	}
	
}
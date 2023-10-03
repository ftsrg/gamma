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
package hu.bme.mit.gamma.xsts.uppaal.transformation

import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.uppaal.util.AssignmentExpressionCreator
import hu.bme.mit.gamma.uppaal.util.NtaBuilder
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.LoopAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collection
import uppaal.declarations.VariableContainer
import uppaal.templates.Edge
import uppaal.templates.Location
import uppaal.templates.LocationKind

import static hu.bme.mit.gamma.uppaal.util.XstsNamings.*

import static extension de.uni_paderborn.uppaal.derivedfeatures.UppaalModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension java.lang.Math.*

class CfaActionTransformer {
	
	protected final extension NtaBuilder ntaBuilder
	protected final Traceability traceability
	protected final Collection<VariableContainer> transientVariables = newHashSet
	
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension VariableTransformer variableTransformer
	protected final extension AssignmentExpressionCreator assignmentExpressionCreator
	
	protected final extension HavocHandler havocHandler = HavocHandler.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	new(NtaBuilder ntaBuilder, Traceability traceability) {
		this.ntaBuilder = ntaBuilder
		this.traceability = traceability
		this.variableTransformer = new VariableTransformer(ntaBuilder, traceability)
		this.expressionTransformer = new ExpressionTransformer(traceability)
		this.assignmentExpressionCreator = new AssignmentExpressionCreator(ntaBuilder)
	}
	
	def void transformIntoCfa(Action action, Location source, Location finalTarget) {
		transientVariables.clear
		
		val finishLocation = action.transformAction(source) // transientVariables gets filled
			
		// If there is no merged action, the loop edge is unnecessary
		// E.g., source == finishLocation, source == finalTarget
		if (finishLocation !== finalTarget) {
			val lastEdge = finishLocation.createEdge(finalTarget)
			lastEdge.resetTransientVariables(transientVariables)
		}
	}
	
	// Dispatch
	
	protected def dispatch Location transformAction(EmptyAction action, Location source) {
		return source
	}
	
	protected def dispatch Location transformAction(AssignmentAction action, Location source) {
		// UPPAAL does not support 'a = {1, 2, 5}' like assignments
		val assignmentActions = action.extractArrayLiteralAssignments
		var Location newSource = source
		for (assignmentAction : assignmentActions) {
			val uppaalLhs = assignmentAction.lhs.transform
			val uppaalRhs = assignmentAction.rhs.transform
			newSource = newSource.createUpdateEdge(nextCommittedLocationName,
					uppaalLhs, uppaalRhs)
		}
		
		return newSource
	}
	
	protected def dispatch Location transformAction(HavocAction action, Location source) {
		val xStsDeclaration = action.lhs.declaration
		val xStsVariable = xStsDeclaration as VariableDeclaration
		val uppaalVariable = traceability.get(xStsVariable)
		
		val selectionStruct = xStsVariable.createSelection
		
		val selection = selectionStruct.selection
		val guard = selectionStruct.guard
		
		if (selection === null) {
			return source // We do not do anything
		}
		
		// Optimization - the type of the variable can be set to this selection type
		val type = selection.typeDefinition.clone
		uppaalVariable.typeDefinition = type
		//
		
		val target = source.createUpdateEdge(nextCommittedLocationName,
				uppaalVariable, selection.createIdentifierExpression)
		val edge = target.incomingEdges.head
		edge.selection += selection
		if (guard !== null) {
			edge.addGuard(guard)
		}
		
		return target
	}
	
	protected def dispatch Location transformAction(VariableDeclarationAction action, Location source) {
		val xStsVariable = action.variableDeclaration
		val uppaalVariable = xStsVariable.transformAndTraceVariable
//		uppaalVariable.prefix = DataVariablePrefix.META // Does not work, see XSTS Crossroads
		uppaalVariable.extendNameWithHash // Needed for local declarations
		transientVariables += uppaalVariable
		val xStsInitialValue = xStsVariable.initialValue
		val uppaalRhs = xStsInitialValue?.transform
		
		return source.createUpdateEdge(nextCommittedLocationName, uppaalVariable, uppaalRhs)
	}
	
	protected def void extendNameWithHash(VariableContainer uppaalContainer) {
		for (uppaalVariable : uppaalContainer.variable) {
			uppaalVariable.name = '''«uppaalVariable.name»_«uppaalVariable.hashCode.abs»'''
		}
	}
	
	protected def dispatch Location transformAction(AssumeAction action, Location source) {
		val edge = source.createEdgeCommittedSource(nextCommittedLocationName)
		val uppaalExpression = action.assumption.transform
		edge.guard = uppaalExpression
		
		return edge.target
	}
	
	protected def dispatch Location transformAction(SequentialAction action, Location source) {
		val xStsActions = action.actions
		var actualSource = source
		for (xStsAction : xStsActions) {
			actualSource = xStsAction.transformAction(actualSource)
		}
		
		return actualSource
	}
	
	protected def dispatch Location transformAction(NonDeterministicAction action, Location source) {
		val xStsActions = action.actions
		val targets = newArrayList
		for (xStsAction : xStsActions) {
			targets += xStsAction.transformAction(source)
		}
		val parentTemplate = source.parentTemplate
		val target = parentTemplate.createLocation(LocationKind.COMMITED, nextCommittedLocationName)
		for (choiceTarget : targets) {
			choiceTarget.createEdge(target)
		}
		
		return target
	}
	
	protected def dispatch Location transformAction(IfAction action, Location source) {
//		val clonedAction = action.clone
//		val xStsConditions = clonedAction.conditions
//		val xStsActions = clonedAction.branches
//		
//		// Tracing back to NonDeterministicAction transformation
//		val proxy = xStsConditions.createChoiceActionWithExclusiveBranches(xStsActions)
//		
//		return proxy.transformAction(source)
		
		val condition = action.condition
		
		val positiveCondition = condition.transform
		val negativeCondition = condition.clone
				.createNotExpression.transform
		
		val thenEdge = source.createEdgeCommittedSource(nextCommittedLocationName)
		thenEdge.guard = positiveCondition
		val thenEdgeTarget = thenEdge.target
		
		val thenAction = action.then
		val thenActionTarget = thenAction.transformAction(thenEdgeTarget)
		
		val elseEdge = source.createEdgeCommittedSource(nextCommittedLocationName)
		elseEdge.guard = negativeCondition
		val elseEdgeTarget = elseEdge.target
		
		val elseAction = action.^else
		val elseActionTarget = (elseAction !== null) ? elseAction.transformAction(elseEdgeTarget) : elseEdgeTarget
		
		elseActionTarget.createEdge(thenActionTarget)
		
		return thenActionTarget
	}
	
	protected def dispatch Location transformAction(LoopAction action, Location source) {
		val parameter = action.iterationParameterDeclaration
		val range = action.range
		val actionInLoop = action.action
		
		val left = range.left
		val right = range.right
		
		// Inlineable?
		if (range.evaluable) {
			val leftInt = left.evaluateInteger
			val rightInt = right.evaluateInteger
			
			val body = newArrayList
			for (var i = leftInt; i <= rightInt /* Right is inclusive */; i++) {
				val index = i.toIntegerLiteral
				val clonedBody = actionInLoop.clone
				
				parameter.inlineReferences(index, clonedBody)
				
				body += clonedBody
			}
			val sequentialAction = body.createSequentialAction
			
			return sequentialAction.transformAction(source)
		}
		// Non-inlineable
		val uppaalVariable = parameter.transformAndTraceParameter
		uppaalVariable.extendNameWithHash // Needed for local declarations
		transientVariables += uppaalVariable

		val initEdge = source.createEdgeCommittedSource(nextCommittedLocationName)
		initEdge.update += uppaalVariable.createAssignmentExpression(
				left.transform)
		val loopSource = initEdge.target
		
		// In-loop part
		val inLoopEdge = loopSource.createEdgeCommittedSource(nextCommittedLocationName)
		inLoopEdge.guard = uppaalVariable.createLessEqualityExpression(right.transform)
		val inLoopLocation = inLoopEdge.target
		
		val inLoopEnd = actionInLoop.transformAction(inLoopLocation)
		val iterationCountIncrementEdge = inLoopEnd.createEdge(loopSource)
		iterationCountIncrementEdge.update += uppaalVariable.createIncrementExpression
		
		// Out-loop part
		val outLoopEdge = loopSource.createEdgeCommittedSource(nextCommittedLocationName)
		outLoopEdge.guard = uppaalVariable.createGreaterExpression(right.transform)
		val outLoopLocation = outLoopEdge.target
		
		return outLoopLocation
	}
	
	// Resetting
	
	protected def resetTransientVariables(Edge edge,
			Iterable<? extends VariableContainer> transientVariables) {
		for (transientVariable : transientVariables) {
			edge.update += transientVariable.createResetingAssignmentExpression
		}
	}
	
//	// Variable binding
//	
//	def getVariableBindings() {
//		return variableBindings
//	}
//	
//	@Data
//	static class VariableBindings {
//		
//		Map<VariableContainer, SelectionStruct> variableDomain = newLinkedHashMap
//		Map<VariableContainer, Set<VariableContainer>> boundVariables = newHashMap
//		//
//		protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
//		
//		def put(VariableContainer variable, SelectionStruct selection) {
//			variableDomain += variable -> selection
//		}
//		
//		def get(VariableContainer variable) {
//			return variableDomain.checkAndGet(variable)
//		}
//		
//		def put(VariableContainer variable, VariableContainer boundVariable) {
//			boundVariables.getOrCreateSet(variable) += boundVariable
//			boundVariables.getOrCreateSet(boundVariable) += variable
//		}
//		
//		def clear () {
//			variableDomain.clear
//			boundVariables.clear
//		}
//		
//	}
	
}
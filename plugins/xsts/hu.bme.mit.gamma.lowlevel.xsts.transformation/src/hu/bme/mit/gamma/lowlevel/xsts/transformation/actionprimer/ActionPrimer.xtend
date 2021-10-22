/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.lowlevel.xsts.transformation.actionprimer

import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.MultiaryExpression
import hu.bme.mit.gamma.expression.model.NullaryExpression
import hu.bme.mit.gamma.expression.model.UnaryExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.LoopAction
import hu.bme.mit.gamma.xsts.model.MultiaryAction
import hu.bme.mit.gamma.xsts.model.PrimedVariable
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.model.XTransition
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collection
import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil.Copier

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

abstract class ActionPrimer {
	// Auxiliary objects
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	
	// Model factories
	protected final extension XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory constraintModelFactory = ExpressionModelFactory.eINSTANCE
	// Transformation settings
	protected final boolean inlinePrimedVariables
	
	new(boolean inlinePrimedVariables) {
		this.inlinePrimedVariables = inlinePrimedVariables
	}
	
	def transform(Collection<XTransition> transitions) {
		val primedTransitions = newArrayList
		for (transition : transitions) {
			primedTransitions += transition.transform
		}
		return primedTransitions
	}
	
	def transform(XTransition transition) {
		val action = transition.action
		return createXTransition => [
			it.action = action.transform
		]
	}
	
	def abstract Action transform(Action action);
	
	/**
	 * Updates the given assignment action by priming the variable in the left hand side.
	 * Also, it puts the variable in the primedVariables map and adjust the map of indexes and values.
	 */
	protected def primeVariable(AssignmentAction action,
			Map<VariableDeclaration, List<VariableDeclaration>> primedVariables,
			Map<VariableDeclaration, Integer> indexes, Map<VariableDeclaration, Expression> values) {
		val declaration = action.lhs.referredVariables.iterator.next
		checkState(declaration instanceof VariableDeclaration)
		val variable = declaration as VariableDeclaration
		val originalVariable = variable.originalVariable
		// The inline form of the right hand side
		val rhs = action.rhs.primeExpression(primedVariables, indexes, values)
		// Retrieving the corresponding variable list
		var List<VariableDeclaration> primedVariablesList
		if (primedVariables.containsKey(originalVariable)) {
			primedVariablesList = primedVariables.get(originalVariable)
		}
		else {
			checkState(variable === originalVariable)
			primedVariablesList = newLinkedList(originalVariable) // Original variable is at index 0
			primedVariables.put(originalVariable, primedVariablesList)
		}
		val index = if (indexes.containsKey(originalVariable)) indexes.get(originalVariable) + 1 else 0 + 1
		// + 1, because we want to prime the variable
		// Adjusting the indexes and variable values in the map
		indexes.put(originalVariable, index)
		values.put(originalVariable, rhs.clone)
		if (index < primedVariablesList.size) {
			// Primed variable with the given index already exists
			val primedVariable = primedVariablesList.get(index)
			action => [
				(it.lhs as DirectReferenceExpression).declaration = primedVariable
				it.rhs = rhs
			]
			return
		}
		// New primed variable has to be created
		checkState(primedVariablesList.size == index, primedVariablesList.size + " != " + index)
		val xStsPrimedVariable = createPrimedVariable => [
			it.name = variable.name + "_" + index;
			it.type = variable.type.clone
			it.primedVariable = variable
		]
		// Storing the variables in both the list and the xSTS model
		primedVariablesList += xStsPrimedVariable
		originalVariable.eContainer as XSTS => [
			it.variableDeclarations += xStsPrimedVariable
		]
		// Setting the assignment action with the new primed variable and right hand side
		action => [
			(it.lhs as DirectReferenceExpression).declaration = xStsPrimedVariable
			it.rhs = rhs
		]
	}
	
	protected def dispatch VariableDeclaration getOriginalVariable(VariableDeclaration variable) {
		return variable
	}
	
	protected def dispatch VariableDeclaration getOriginalVariable(PrimedVariable variable) {
		return variable.primedVariable.originalVariable
	}
	
	// Expression primer
	
	protected def dispatch Expression primeExpression(NullaryExpression expression,
			Map<VariableDeclaration, List<VariableDeclaration>> primedVariables,
			Map<VariableDeclaration, Integer> index, Map<VariableDeclaration, Expression> values) {
		return expression
	}
	
	protected def dispatch Expression primeExpression(UnaryExpression expression,
			Map<VariableDeclaration, List<VariableDeclaration>> primedVariables,
			Map<VariableDeclaration, Integer> index, Map<VariableDeclaration, Expression> values) {
		return expression => [
			it.operand = expression.operand.primeExpression(primedVariables, index, values)
		]
	}
	
	protected def dispatch Expression primeExpression(IfThenElseExpression expression,
			Map<VariableDeclaration, List<VariableDeclaration>> primedVariables,
			Map<VariableDeclaration, Integer> index, Map<VariableDeclaration, Expression> values) {
		return expression => [
			it.condition = expression.condition.primeExpression(primedVariables, index, values)
			it.then = expression.then.primeExpression(primedVariables, index, values)
			it.^else = expression.^else.primeExpression(primedVariables, index, values)
		]
	}

	protected def dispatch Expression primeExpression(DirectReferenceExpression expression,
			Map<VariableDeclaration, List<VariableDeclaration>> primedVariables,
			Map<VariableDeclaration, Integer> index, Map<VariableDeclaration, Expression> values) {
		checkState(expression.declaration instanceof VariableDeclaration, expression.declaration)
		val declaration = expression.declaration as VariableDeclaration
		if (values.containsKey(declaration)) {
			// Choice upon setting
			if (inlinePrimedVariables) {
				// In case of inline, we return the actual value of the given variable
				return values.get(declaration).clone
			}
			else {
				// We simply return a reference to the primed variable
				return expression => [
					it.declaration = primedVariables.get(declaration).get(index.get(declaration))
				]
			}
		}
		// Otherwise the variable has not yet been primed, original variable is fine
		return expression => [
			it.declaration = declaration.originalVariable
		]
	}
	
	protected def dispatch Expression primeExpression(BinaryExpression expression,
			Map<VariableDeclaration, List<VariableDeclaration>> primedVariables,
			Map<VariableDeclaration, Integer> index, Map<VariableDeclaration, Expression> values) {
		expression.leftOperand = expression.leftOperand.primeExpression(primedVariables, index, values)
		expression.rightOperand = expression.rightOperand.primeExpression(primedVariables, index, values)
		return expression
	}
	
	protected def dispatch Expression primeExpression(MultiaryExpression expression,
			Map<VariableDeclaration, List<VariableDeclaration>> primedVariables,
			Map<VariableDeclaration, Integer> index, Map<VariableDeclaration, Expression> values) {
		val operands = expression.operands
		for (var i = 0; i < operands.size; i++) {
			operands.set(i, operands.get(i).primeExpression(primedVariables, index, values))
		}
		return expression
	}
	
	// Unnecessary assume actions
	
	protected def dispatch void deleteUnnecessaryAssumeActions(Action action) {
		// No operation
	}
	
	protected def dispatch void deleteUnnecessaryAssumeActions(LoopAction action) {
		val xStsSubaction = action.action
		xStsSubaction.deleteUnnecessaryAssumeActions
	}
	
	protected def dispatch void deleteUnnecessaryAssumeActions(MultiaryAction action) {
		val xStsSubactions = action.actions
		for (var i = 0; i < xStsSubactions.size; i++) {
			val xStsSubaction = xStsSubactions.get(i)
			xStsSubaction.deleteUnnecessaryAssumeActions
		}
	}
	
	protected def dispatch void deleteUnnecessaryAssumeActions(SequentialAction action) {
		val xStsSubactions = action.actions
		for (var i = 0; i < xStsSubactions.size; i++) {
			val xStsSubaction = xStsSubactions.get(i)
			if (xStsSubaction instanceof AssumeAction) {
				if (xStsSubaction.isDefinitelyTrueAssumeAction) {
					if (xStsSubactions.size > 1) {
						// We remove only if the size is greater than 1, as we do not want to
						// eliminate the branch of a NonDeterministicAction completely
						xStsSubactions.remove(i)
						i--
					}
				}
			}
			else {
				xStsSubaction.deleteUnnecessaryAssumeActions
			}
		}
	}
 	
	// Clone
	
	protected def <T extends EObject> T clone(T element) {
		/* A new copier should be used every time, otherwise anomalies happen
		 (references are changed without asking) */
		val copier = new Copier(true, true)
		val clone = copier.copy(element) as T;
		copier.copyReferences();
		return clone;
	}
	
}
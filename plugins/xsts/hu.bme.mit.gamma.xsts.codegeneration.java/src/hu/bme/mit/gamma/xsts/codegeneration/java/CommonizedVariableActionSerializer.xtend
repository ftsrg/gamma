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
package hu.bme.mit.gamma.xsts.codegeneration.java

import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.CompositeAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.LoopAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.ParallelAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.model.XSTS

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

/**
 * Works only if the assume actions are placed only in the first index of a sequential action.
 * (They can be only first subactions in sequential actions.)
 */
class CommonizedVariableActionSerializer extends ActionSerializer {
	
	override serializeInitializingAction(XSTS xSts) '''
		«xSts.initializingAction.serialize»
	'''
	
	override serializeVariableReset(XSTS xSts) '''
		«xSts.variableInitializingTransition.action.serialize»
	'''
	
	override serializeStateConfigurationReset(XSTS xSts) '''
		«xSts.configurationInitializingTransition.action.serialize»
	'''
	
	override serializeEntryEventRaise(XSTS xSts) '''
		«xSts.entryEventTransition.action.serialize»
	'''
	
	// Note that only the first transition is serialized
	override CharSequence serializeChangeState(XSTS xSts) '''
		private void changeState() {
			«xSts.mergedAction.serialize»
		}
	'''
	
	// Action serialization
	
	def dispatch CharSequence serialize(Action action) {
		throw new IllegalArgumentException("Not supported action: " + action)
	}
	
	def dispatch CharSequence serialize(LoopAction action) {
		val name = action.iterationParameterDeclaration.name
		val left = action.range.getLeft(true)
		val right = action.range.getRight(false)
		return '''
			for (int «name» = «left.serialize»; «name» < «right.serialize»; ++«name») {
				«action.action.serialize»
			}
		'''
	}
	
	def dispatch CharSequence serialize(IfAction action) {
		val _else = action.^else
		return '''
			if («action.condition.serialize») {
				«action.then.serialize»
			}
			«IF _else !== null && !(_else instanceof EmptyAction)»
				else {
					«_else.serialize»
				}
			«ENDIF»
		'''
	}
	
	def dispatch CharSequence serialize(NonDeterministicAction action) '''
		«FOR xStsSubaction : action.actions.filter[!it.unnecessaryAction] SEPARATOR ' else ' »
			if («xStsSubaction.condition.serialize») {
				«xStsSubaction.serialize»
			}
		«ENDFOR»
	'''
	
	def dispatch CharSequence serialize(SequentialAction action) '''
		«FOR xStsSubaction : action.actions»«xStsSubaction.serialize»«ENDFOR»
	'''
	
	// Same as sequential
	def dispatch CharSequence serialize(ParallelAction action) '''
		«FOR xStsSubaction : action.actions»«xStsSubaction.serialize»«ENDFOR»
	'''
	
	def dispatch CharSequence serialize(EmptyAction action) ''''''
	
	def dispatch CharSequence serialize(AssumeAction action) ''''''
	
//	def dispatch CharSequence serialize(AssumeAction action) '''
//		assert «action.assumption.serialize»;
//	'''
	
	def dispatch CharSequence serialize(AssignmentAction action) {
		if (action.unnecessaryAction) {
			return ''''''
		}
		return '''
			«action.lhs.serialize» = «action.rhs.serialize»;
		'''
	}
	
	def dispatch CharSequence serialize(VariableDeclarationAction action) {
		val variable = action.variableDeclaration
		val intialValue = (variable.expression !== null) ?
			variable.expression : variable.type.initialValueOfType
		return '''
			«variable.type.serialize» «variable.name» = «intialValue.serialize»;
		'''
	}
	
	// Getting conditions from a non deterministic action point of view
	
	protected def dispatch Expression getCondition(Action action) {
		return createTrueExpression
	}
	
	protected def dispatch Expression getCondition(SequentialAction action) {
		val xStsSubactions = action.actions
		val firstXStsSubaction = xStsSubactions.head
		if (firstXStsSubaction instanceof AssumeAction) {
			return firstXStsSubaction.condition
		}
		val xStsCompositeSubactions = xStsSubactions.filter(CompositeAction)
		if (xStsCompositeSubactions.empty) {
			return createTrueExpression
		}
		return createAndExpression => [
			for (xStsSubaction : action.actions) {
				it.operands += xStsSubaction.condition
			}
		]
	}
	
	// Should not be present, but there are NonDeterministicActions inside NonDeterministicAction
	protected def dispatch Expression getCondition(NonDeterministicAction action) {
		return createOrExpression => [
			for (xStsSubaction : action.actions) {
				it.operands += xStsSubaction.condition
			}
		]
	}
	
	protected def dispatch Expression getCondition(AssumeAction action) {
		return action.assumption.clone
	}
	
	// Optimization: for deleting unnecessary branches
	
	private def dispatch boolean isUnnecessaryAction(Action action) {
		return false;
	}
	
	private def dispatch boolean isUnnecessaryAction(SequentialAction action) {
		return action.actions.forall[it.unnecessaryAction]
	}
	
	private def dispatch boolean isUnnecessaryAction(AssumeAction action) {
		return true
	}
	
	private def dispatch boolean isUnnecessaryAction(AssignmentAction action) {
		val lhs = action.lhs
		if (lhs instanceof DirectReferenceExpression) {
			val lhsDeclaration = lhs.declaration
			val rhs = action.rhs
			if (rhs instanceof DirectReferenceExpression) {
				if (lhsDeclaration.originalVariable == rhs.declaration.originalVariable) {
					return true
				}
			}
		}
		return false
	}
	
}
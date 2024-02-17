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
package hu.bme.mit.gamma.xsts.codegeneration.c.serializer

import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.ClockVariableDeclarationAnnotation
import hu.bme.mit.gamma.expression.model.impl.ArrayAccessExpressionImpl
import hu.bme.mit.gamma.expression.model.impl.ArrayLiteralExpressionImpl
import hu.bme.mit.gamma.expression.model.impl.DirectReferenceExpressionImpl
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.LoopAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.ParallelAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.model.XSTS

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.codegeneration.c.util.GeneratorUtil.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

/**
 * This class provides a serializer for actions in XSTS models.
 */
class ActionSerializer {
	
	/**
	 * The ActionSerializer class provides methods for serializing action-related components.
	 * This class is intended for serialization purposes.
	 */
	public static val ActionSerializer INSTANCE = new ActionSerializer
	
	/**
	 * Constructs a new instance of the ActionSerializer class.
	 * This constructor is marked as protected to prevent direct instantiation.
	 */
	protected new() {
	}
	
	val HavocSerializer havocSerializer = HavocSerializer.INSTANCE
	val ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	val VariableDeclarationSerializer variableDeclarationSerializer = VariableDeclarationSerializer.INSTANCE
	
	/**
	 * Serializes an initializing action.
 	 * 
 	 * @param xSts an XSTS model
  	 * @return a CharSequence that represents the serialized initializing action
  	 */
	def CharSequence serializeInitializingAction(XSTS xSts) {
		return '''«xSts.initializingAction.serialize»'''
	}
	
	/**
 	 * Throws an IllegalArgumentException if the action is not supported.
	 * 
 	 * @param action an action
	 * @return a CharSequence that represents the serialized action
 	 */
	def dispatch CharSequence serialize(Action action) {
		throw new IllegalArgumentException("Not supported action: " + action)
	}
	
	/**
 	 * Serializes an IfAction. Serializes else action only in case
 	 * it is not null or empty.
 	 * 
  	 * @param action an IfAction
	 * @return a CharSequence that represents the serialized IfAction
 	 */
	def dispatch CharSequence serialize(IfAction action) {
		return '''
			if («expressionSerializer.serialize(action.condition)») {
				«action.then.serialize»
			}«IF !action.^else.isNullOrEmptyAction» else {
				«action.^else.serialize»
			}«ENDIF»''';
	}
	
	/**
 	 * Serializes a SequentialAction.
	 * 
	 * @param action a SequentialAction
 	 * @return a CharSequence that represents the serialized SequentialAction
	 */
	def dispatch CharSequence serialize(SequentialAction action) {
		return '''«FOR xstsSubaction : action.actions SEPARATOR System.lineSeparator»«xstsSubaction.serialize»«ENDFOR»'''
	}
	
	/**
	 * Serializes a ParallelAction.
	 * 
	 * @param action a ParallelAction
	 * @return a CharSequence that represents the serialized ParallelAction
	 */
	def dispatch CharSequence serialize(ParallelAction action) {
		return '''«FOR xstsSubaction : action.actions SEPARATOR System.lineSeparator»«xstsSubaction.serialize»«ENDFOR»'''
	}
	
	/**
	 * Serializes a NonDeterministicAction.
	 * 
	 * @param action a NonDeterministicAction
	 * @return a CharSequence that represents the serialized NonDeterministicAction
	 */
	def dispatch CharSequence serialize(NonDeterministicAction action) {
		return '''«FOR xStsSubaction : action.actions.filter[!it.isNullOrEmptyAction] SEPARATOR ' else ' »
			if («expressionSerializer.serialize(xStsSubaction.condition)») {
				«xStsSubaction.serialize»
			}
		«ENDFOR»'''
	}
	
	/**
	 * Serializes a HavocAction.
	 * 
	 * @param action a HavocAction
	 * @return a CharSequence that represents the serialized HavocAction
	 */
	def dispatch CharSequence serialize(HavocAction action) {
		return '''«expressionSerializer.serialize(action.lhs)» = «havocSerializer.serialize(action.lhs)»;'''
	}
	
	/**
	 * Serializes an AssignmentAction.
	 * 
	 * @param action an AssignmentAction
	 * @return a CharSequence that represents the serialized AssignmentAction
	 */
	def dispatch CharSequence serialize(AssignmentAction action) {
		val lhs = action.lhs instanceof ArrayAccessExpressionImpl || action.lhs instanceof DirectReferenceExpressionImpl;
		val rhs = action.rhs instanceof ArrayLiteralExpressionImpl;
		/* in case of arrays we handle things differently */
		if (lhs && rhs)
			return expressionSerializer.serialize(action.lhs, action.rhs as ArrayLiteralExpression)
		return '''«expressionSerializer.serialize(action.lhs)» = «expressionSerializer.serialize(action.rhs)»;'''
	}
	
	/**
	 * Serializes a VariableDeclarationAction.
	 * 
	 * @param action a VariableDeclarationAction
	 * @return a CharSequence that represents the serialized VariableDeclarationAction
	 */
	def dispatch CharSequence serialize(VariableDeclarationAction action) {
		return variableDeclarationSerializer.serialize(action.variableDeclaration)
	}
	
	/**
	 * Serializes an EmptyAction.
	 * 
	 * @param action an EmptyAction
	 * @return a CharSequence that represents the serialized EmptyAction
	 */
	def dispatch CharSequence serialize(EmptyAction action) {
		return '''/* Empty Action */'''
	}
	
	/**
	 * Serializes a LoopAction to its corresponding code representation.
	 *
	 * @param action the LoopAction to be serialized
	 * @return a serialized representation of the LoopAction
	 */
	def dispatch CharSequence serialize(LoopAction action) {
		if (action.action.isNullOrEmptyAction)
			return ''
		val ipd = action.iterationParameterDeclaration
		val left = action.range.getLeft(true)
		val right = action.range.getRight(false)
		val clock = ipd.annotations.exists[it instanceof ClockVariableDeclarationAnnotation]
		return '''
			for («variableDeclarationSerializer.serialize(ipd.type, clock, ipd.name)» «ipd.name» = «expressionSerializer.serialize(left)»; «ipd.name» < «expressionSerializer.serialize(right)»; «ipd.name»++) {
				«action.action.serialize»
			}'''
	}
	
	/**
	 * Serializes a AssumeAction to its corresponding empty code representation.
	 *
	 * @param action the AssumeAction to be serialized
	 * @return a serialized representation of the AssumeAction which is not serialized to C
	 */
	def dispatch CharSequence serialize(AssumeAction action) {
		return ''''''
	}
	
	
}
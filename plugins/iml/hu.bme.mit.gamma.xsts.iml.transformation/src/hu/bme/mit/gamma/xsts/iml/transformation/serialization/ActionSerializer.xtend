/********************************************************************************
 * Copyright (c) 2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.iml.transformation.serialization

import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.xsts.iml.transformation.util.MessageQueueHandler
import hu.bme.mit.gamma.xsts.iml.transformation.util.Namings
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.transformation.util.MessageQueueUtil
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.List

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class ActionSerializer {
	// Singleton
	public static final ActionSerializer INSTANCE = new ActionSerializer
	protected new() {}
	//
	protected final extension MessageQueueHandler queueHandler = MessageQueueHandler.INSTANCE
	protected final extension MessageQueueUtil queueUtil = MessageQueueUtil.INSTANCE
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	//
	
	def serializeActionGlobally(Action action) {
		return action.serialize
				.changeReturnValue
	}
	
	def serializeActionsGlobally(Iterable<? extends Action> actions) {
		return actions.serializeActions
				.changeReturnValue
	}
	
	//
	
	protected def String serialize(Action action) '''
		«action.serializeAction»
		«action.localVariableNamesIfLast»'''
	
	protected def serializeActions(Iterable<? extends Action> actions) {
		val builder = new StringBuilder
		
		for (action : actions) {
			var serializedAction = action.serializeAction.toString
			if (serializedAction.endsWith(localVariableNames)) {
				serializedAction = serializedAction.substring(0, serializedAction.length - localVariableNames.length)
			}
			builder.append(serializedAction)
		}
		builder.append(localVariableNames) // Always?
		
		return builder.toString
	}
	
	//
	
	protected def dispatch serializeAction(Action action) {
		throw new IllegalArgumentException("Not supported action: " + action)
	}
	
	protected def dispatch serializeAction(EmptyAction action) ''''''
	
	// Not the same, but a good run-time check
	protected def dispatch serializeAction(AssumeAction action) '''
		(* let () = assert «action.assumption.serialize» in *)
	'''
	
	protected def dispatch serializeAction(HavocAction action) {
		val variable = action.lhs.declaration as VariableDeclaration
		val rhsString = '''«Namings.ENV_HAVOC_RECORD_IDENTIFIER».«action.serializeFieldName»;'''
		
		val placeHolderRhs = 0.toIntegerLiteral
		val placeHolderRhsString = placeHolderRhs.serialize + ";"
		
		val placeHolderAction = variable.createAssignmentAction(placeHolderRhs)
		val placeHolderActionString = placeHolderAction.serialize
		
		val actionString = placeHolderActionString.replaceFirst(placeHolderRhsString, rhsString)
		
		return actionString
	}
	
	protected def dispatch serializeAction(AssignmentAction action) {
		return #[action].serializeAssignmentActions
	}
	
	//
	def String serializeAssignmentActions(Iterable<? extends Action> actions) {
		val id = actions.head.id
		return '''
			let «id» = { «id» with «FOR action : actions SEPARATOR System.lineSeparator»«
				action.serializeLocalAssignmentAction»«ENDFOR» } in
		'''
	}
	
	private def dispatch serializeLocalAssignmentAction(Action action) {
		throw new IllegalArgumentException("Not supported action: " + action)
	}
	
	private def dispatch serializeLocalAssignmentAction(AssignmentAction action) {
		if (action.queueAction) { // Queue handling
			return action.serializeQueueAction
		}
		return '''«action.lhs.serializeAssignmentAction(action.rhs)»'''
	}
	
	private def dispatch serializeLocalAssignmentAction(VariableDeclarationAction action) {
		val variable = action.variableDeclaration
		if (action.queueAction) { // Queue handling
			return action.serializeQueueAction
		}
		val expression = (variable.expression === null) ? variable.defaultExpression : variable.expression
		return '''«variable.serializeAssignmentAction(expression)»'''
	}
	
	private def serializeAssignmentAction(Expression lhs, Expression rhs) {
		if (lhs instanceof ArrayAccessExpression) {
			val declaration = lhs.declaration
			// a[i][j][k] := 69 -> a2 = (Map.add i (Map.add j (Map.add k 69 (Map.get j (Map.get i a)))) (Map.get i a)) a)
			return '''«declaration.serializeName» = «lhs.serializeArrayAssignmentAction(rhs)»;'''
		}
		else {
			return '''«lhs.declaration.serializeAssignmentAction(rhs)»'''
		}
	}
	
	private def serializeAssignmentAction(Declaration lhs, Expression rhs) '''«
			lhs.serializeName» = «rhs.serialize»;'''
	//
	
	private def String serializeArrayAssignmentAction(ArrayAccessExpression access, Expression value) {
		return access.serializeArrayAssignmentAction(value, newArrayList)
	}
	
	private def String serializeArrayAssignmentAction(ArrayAccessExpression access, Expression value, List<Expression> previousIndexes) {
		val declaration = access.declaration
		val operand = access.operand
		val index = access.index
		
		val actualArray = '''(«FOR previousIndex : previousIndexes.reverseView»Map.get «previousIndex.serialize» «ENDFOR»«declaration.serializeAsRhs»)'''
		previousIndexes += index
		
		val serializedOperand = (operand instanceof ArrayAccessExpression) ? operand.serializeArrayAssignmentAction(value, previousIndexes) : value.serialize
		
		return '''(Map.add «index.serialize» «serializedOperand» «actualArray»)'''
	}
	
	//
	
	protected def dispatch String serializeAction(IfAction _if) {
		val condition = _if.condition
		val then = _if.then
		val _else = _if.^else
		
		return '''
			«localVariableDeclarations»
				if «condition.serialize» then
					«then.serialize»
				else
					«IF _else.nullOrEmptyAction»«localVariableNames»«ELSE»«_else.serialize»«ENDIF» in
		'''
	}
	
	protected def dispatch serializeAction(VariableDeclarationAction action) {
		return #[action].serializeAssignmentActions
	}
	
	protected def dispatch serializeAction(SequentialAction sequence) {
		val actions = sequence.actions
		checkArgument(actions.filter(SequentialAction).empty) // We cannot support blocks within blocks with the return values (r, l)
		
		if (actions.empty) {
			return ""
		}
		if (actions.size <= 1) {
			return actions.head.serialize
		}
		
		val builder = new StringBuilder
		var i = 0
		while (i < actions.size) {
			var j = i
			// Looking for subsequent assignments
			val writtenVariables = newHashSet
			while (j < actions.size - 1 &&
					actions.get(j).id == actions.get(j + 1).id &&
//					!(actions.get(j).queuePeekAction || actions.get(j).queuePopAction) &&
					(actions.get(j) instanceof AssignmentAction || actions.get(j) instanceof VariableDeclarationAction) &&
					(actions.get(j + 1) instanceof AssignmentAction || actions.get(j + 1) instanceof VariableDeclarationAction) &&
						writtenVariables.containsNone(actions.get(j + 1).referredAndLocalVariables) &&
						actions.get(j).writtenAndLocalVariables.containsNone(actions.get(j + 1).referredAndLocalVariables)) {
				writtenVariables += actions.get(j).writtenAndLocalVariables
				j++ 
			}
			// No susbequent assignments
			if (i == j) {
				builder.append(
					actions.get(i).serialize)
			}
			else { // Found subsequent assignments
				val sameRecordAssignments = actions.subList(i, j + 1)
				builder.append(
					sameRecordAssignments.serializeAssignmentActions)
				builder.append(
					actions.get(j).localVariableNamesIfLast)
			}
			//
			i = j + 1
		}
		
		return builder.toString
	}
	
	//
	
	protected def initVariablesIfNotEmpty(Iterable<? extends VariableDeclaration> variables, String id) '''
		«IF variables.empty»let «id» = true in (* Placeholder *)«ELSE»«variables.initVariables(id)»«ENDIF»'''
	
	protected def initVariables(Iterable<? extends VariableDeclaration> variables, String id) '''
		let «id» = {
			«FOR variable : variables
					.reject[it.queueVariable]
					.reject[it.queueSizeVariable && it.hasQueueOfQueueSizeVariable] SEPARATOR System.lineSeparator»«
				variable.serializeName» = «variable.defaultExpression.serialize»;«ENDFOR»
			«FOR variable : variables
					.filter[it.queueVariable] SEPARATOR System.lineSeparator»«
				variable.serializeName» = [];«ENDFOR» } in'''
	
	//
	
	protected def getId(Action action) {
		if (action instanceof AssignmentAction) {
			val declaration = action.lhs.declaration
			return declaration.id
		}
		return Namings.LOCAL_RECORD_IDENTIFIER
	}
	
	protected def String getLocalVariableDeclarations() '''let «localVariableNames» = '''
	
	protected def String getLocalVariableNames() '''«globalVariableName», «Namings.LOCAL_RECORD_IDENTIFIER»'''
	
	protected def String getGlobalVariableDeclaration() '''let «globalVariableName» = '''
	
	protected def String getGlobalVariableName() '''«Namings.GLOBAL_RECORD_IDENTIFIER»'''
	
	protected def getLocalVariableNamesIfLast(Action action) {
		if (action.eContainer === null) {
			return ""
		}
		if (!(action instanceof SequentialAction) && action.last) {
			return localVariableNames
		}
		return ""
	}
	
	protected def changeReturnValue(String action) {
		return action.replaceFirst(localVariableNames + "$", globalVariableName)
	}
	
}
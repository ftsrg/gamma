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

import hu.bme.mit.gamma.codegeneration.java.util.TypeSerializer
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.model.XSTS
import java.util.Map
import java.util.Set

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class InlinedChoiceActionSerializer extends ActionSerializer {
	
	extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
	
	protected int decisionMethodCount = 0
	protected Map<Integer, CharSequence> decisionMethodMap = newHashMap
	protected final String DECISION_METHOD_NAME = "d"
	
	protected int conditionMethodCount = 0
	protected Map<Integer, CharSequence> conditionMethodMap = newHashMap
	protected final String CONDITION_METHOD_NAME = "c"
	
	protected int actionMethodCount = 0
	protected Map<Integer, CharSequence> actionMethodMap = newHashMap
	protected final String ACTION_METHOD_NAME = "a"
	
	//
	override serializeInitializingAction(XSTS xSts) {
		return '''
			«xSts.variableInitializingTransition.action.serialize»
			«xSts.variableInitializingTransition.action.originalWrittenVariables.serializeFinalizationAssignments»
			«xSts.configurationInitializingTransition.action.serialize»
			«xSts.configurationInitializingTransition.action.originalWrittenVariables.serializeFinalizationAssignments»
			«xSts.entryEventTransition.action.serialize»
			«xSts.entryEventTransition.action.originalWrittenVariables.serializeFinalizationAssignments»
		'''
	}
	
	override serializeVariableReset(XSTS xSts) '''
		«xSts.variableInitializingTransition.action.serialize»
		«xSts.variableInitializingTransition.action.originalWrittenVariables.serializeFinalizationAssignments»
	'''
	
	override serializeStateConfigurationReset(XSTS xSts) '''
		«xSts.configurationInitializingTransition.action.serialize»
		«xSts.configurationInitializingTransition.action.originalWrittenVariables.serializeFinalizationAssignments»
	'''
	
	override serializeEntryEventRaise(XSTS xSts) '''
		«xSts.entryEventTransition.action.serialize»
		«xSts.entryEventTransition.action.originalWrittenVariables.serializeFinalizationAssignments»
	'''
	
	// Note that only the first transition is serialized
	override CharSequence serializeChangeState(XSTS xSts) {
		val variableDeclarations = xSts.variableDeclarations.map[it.originalVariable].filter(VariableDeclaration).toSet
		return '''
			// Declaring temporary variables to avoid code duplication
			«FOR variableDeclaration : variableDeclarations»
				private «variableDeclaration.type.serialize» «variableDeclaration.temporaryName» = «variableDeclaration.initialValue.serialize»;
			«ENDFOR»
			
			private void changeState() {
				// Initializing the temporary variables - needed, as timings and clearing of in/out events come from the environment
				«variableDeclarations.serializeInitializationAssignments»
				«xSts.mergedAction.serialize»
				// Finalizing the actions
				«variableDeclarations.serializeFinalizationAssignments»
			}
			
			«serializeChangeStateAuxiliaryMethods»
			
			«serializeConditionAuxiliaryMethods»
			
			«serializeActionAuxiliaryMethods»
		'''
	}
	
	def dispatch CharSequence serialize(Action action) {
		throw new IllegalArgumentException("Not supported action: " + action)
	}
	
	def dispatch CharSequence serialize(AssignmentAction action) '''
		«action.serializeTemporaryAssignment» ««« Setting temporary variables, at the end there is serializeFinalizationAssignments
	'''
	
	def dispatch CharSequence serialize(VariableDeclarationAction action) {
		val variable = action.variableDeclaration
		val intialValue = variable.expression
		return '''
			«variable.type.serialize» «variable.name»«IF intialValue !== null» = «intialValue.serialize»«ENDIF»;
		'''
	}
	
	def dispatch CharSequence serialize(NonDeterministicAction action) '''
		«action.serializeNonDeterministicAction»
	'''
	
	def dispatch CharSequence serialize(SequentialAction action) {
		val xStsSubactions = action.actions
		// Either all contained actions are NOT assume actions...
		if (!xStsSubactions.exists[it instanceof AssumeAction]) {
			return '''
				«FOR xStsSubaction : xStsSubactions»
					«xStsSubaction.serialize»
				«ENDFOR»
			'''
		}
		// Or a single assume action and assignment actions
		val xStsSubactionsSublist = xStsSubactions.subList(1, xStsSubactions.size)
		checkArgument(xStsSubactionsSublist.forall[it instanceof AssignmentAction], "An action is not "
			+ "an assignment action, this code generator does not handle this case: " + xStsSubactionsSublist)
		val xStsAssignmentActions = xStsSubactionsSublist.filter(AssignmentAction)
		'''
«««		 	First assume action is not serialized
			«FOR xStsSubaction : xStsAssignmentActions»
				«xStsSubaction.serializeTemporaryAssignment»
			«ENDFOR»
		'''
	}
	
	private def CharSequence serializeChangeStateAuxiliaryMethods() '''
		«FOR i : 0 ..< decisionMethodCount SEPARATOR System.lineSeparator»
			private void «DECISION_METHOD_NAME»«i»() {
				«decisionMethodMap.get(i)»
			}
		«ENDFOR»
	'''
	
	private def CharSequence serializeConditionAuxiliaryMethods() '''
		«FOR i : 0 ..< conditionMethodCount SEPARATOR System.lineSeparator»
			private boolean «CONDITION_METHOD_NAME»«i»() {
				return «conditionMethodMap.get(i)»;
			}
		«ENDFOR»
	'''
	
	private def CharSequence serializeActionAuxiliaryMethods() '''
		«FOR i : 0 ..< actionMethodCount SEPARATOR System.lineSeparator»
			private void «ACTION_METHOD_NAME»«i»() {
				«actionMethodMap.get(i)»
			}
		«ENDFOR»
	'''
	
	/** Needed because of too long methods */
	private def CharSequence serializeNonDeterministicAction(NonDeterministicAction action) {
		val INITIAL_CHANGE_STATE_METHOD_VALUE = decisionMethodCount
		val MAX_ACTION = 2048
		val ACTION_SIZE = action.actions.size
		val stringBuilder = new StringBuilder(10 * MAX_ACTION)
		for (var i = 0; i < ACTION_SIZE; i++) {
			if (i % MAX_ACTION == 0) {
				if (i != 0) {
					stringBuilder.append(System.lineSeparator + '''else «DECISION_METHOD_NAME»«decisionMethodCount + 1»();''')
					decisionMethodMap.put(decisionMethodCount++, stringBuilder.toString)
				}
				stringBuilder.length = 0
				stringBuilder.append('if ')
			}
			else {
				stringBuilder.append(System.lineSeparator + 'else if ')
			}
			val xStsSubaction = action.actions.get(i)
			stringBuilder.append('''(«xStsSubaction.getCondition.serializeExpression») «xStsSubaction.serializeAction»''')
		}
		decisionMethodMap.put(decisionMethodCount++, stringBuilder.toString)
		'''«DECISION_METHOD_NAME»«INITIAL_CHANGE_STATE_METHOD_VALUE»();'''
	}
	
	/** Needed because of too long methods */
	private def serializeExpression(Expression xStsExpression) {
		conditionMethodMap.put(conditionMethodCount, xStsExpression.serialize)
		return CONDITION_METHOD_NAME + conditionMethodCount++ + "()"
	}
	
	/** Needed because of too long methods */
	private def serializeAction(Action xStsSubaction) {
		actionMethodMap.put(actionMethodCount, xStsSubaction.serialize)
		return ACTION_METHOD_NAME + actionMethodCount++ + "();"
	}
	
	private def CharSequence serializeTemporaryAssignment(AssignmentAction action) {
		val declaration = (action.lhs as DirectReferenceExpression).declaration
		checkArgument(declaration instanceof VariableDeclaration)
		val variable = (declaration as VariableDeclaration).originalVariable
		return '''
			«variable.temporaryName» = «action.rhs.serialize»;
		'''
	}
	
	// Temporary variable handling
	
	private def CharSequence serializeInitializationAssignments(Set<? extends Declaration> variableDeclarations) '''
		«FOR variableDeclaration : variableDeclarations»
			«variableDeclaration.temporaryName» = «variableDeclaration.name»;
		«ENDFOR»
	'''
	
	private def CharSequence serializeFinalizationAssignments(Set<? extends Declaration> variableDeclarations) '''
		«FOR variableDeclaration : variableDeclarations»
			«variableDeclaration.name» = «variableDeclaration.temporaryName»;
		«ENDFOR»
	'''
	
		
	private def getTemporaryName(Declaration declaration) {
		return "__" + declaration.name + "__"
	}
	
	// Get conditions
	
	private def dispatch getCondition(Action action) {
		throw new IllegalArgumentException("Condition retrieval is supported only for
			NonDeterminsiticActions: " + action)
	}
	
	private def dispatch getCondition(SequentialAction action) {
		val firstXStsSubaction = action.actions.head
		checkArgument(firstXStsSubaction instanceof AssumeAction)
		val firstXStAssumeAction = firstXStsSubaction as AssumeAction
		return firstXStAssumeAction.assumption
	}
	
	private def getOriginalWrittenVariables(Action action) {
		return action.writtenVariables.map[it.originalVariable].toSet
	}
	
}
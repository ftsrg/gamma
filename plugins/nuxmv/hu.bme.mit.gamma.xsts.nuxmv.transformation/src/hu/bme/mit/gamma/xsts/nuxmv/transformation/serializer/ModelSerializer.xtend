/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.nuxmv.transformation.serializer

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.lowlevel.xsts.transformation.VariableGroupRetriever
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.AbstractAssignmentAction
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.PrimedVariable
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collection
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EObject

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class ModelSerializer {
	// Singleton
	public static ModelSerializer INSTANCE = new ModelSerializer
	protected new() {}
	//
	
	protected final Map<Declaration, String> localVariableNames = newHashMap
	protected final Map<NonDeterministicAction, String> nonDeterministicActionVariables = newHashMap
	
	protected final Set<VariableDeclaration> iVariables = newLinkedHashSet
	
	//
	protected final extension DeclarationSerializer declarationSerializer = DeclarationSerializer.INSTANCE
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	def String serializeNuxmv(XSTS xSts) {
		localVariableNames.clear
		xSts.customizeLocalVariableNames
		nonDeterministicActionVariables.clear
		xSts.createNonDeterministicActionVariables
		
		iVariables.clear
		
		val inputVariable = xSts.systemInEventVariableGroup.variables
		val inputParameterVariable = xSts.systemInEventParameterVariableGroup.variables
		val inputMasterQueues = xSts.systemMasterMessageQueueGroup.variables
		val inputSlaveQueues = xSts.systemSlaveMessageQueueGroup.variables
		
		val transientVariables = xSts.variableDeclarations.filter[it.transient]
		val resettableVariables = xSts.variableDeclarations.filter[it.resettable]
		
		val localVariables = xSts.getAllContentsOfType(VariableDeclarationAction).map[it.variableDeclaration]
		
		val primedVariables = xSts.variableDeclarations.filter(PrimedVariable)
		
		iVariables += (inputVariable + inputParameterVariable + inputMasterQueues + inputSlaveQueues +
				transientVariables /*+ resettableVariables*/ + localVariables + primedVariables).toList
				
		val primedVariablesInInitializingAction = xSts.initializingAction.writtenVariables
		iVariables -= primedVariablesInInitializingAction // INIT expression cannot contain input variables!
				
		val statefulVariables = newArrayList
		statefulVariables += xSts.variableDeclarations
		statefulVariables -= iVariables
		
//		val optimizedInitializingAction = xSts.initializingAction.optimizeAction
		
		val model = '''
			MODULE main
			VAR
				«FOR statefulVariable : statefulVariables»
					«statefulVariable.serializeVariableDeclaration»
				«ENDFOR»
			
			IVAR
				«FOR iVariable : iVariables»
					«iVariable.serializeVariableDeclaration»
				«ENDFOR»
				«FOR nonDeterministicAction : nonDeterministicActionVariables.keySet»
					«nonDeterministicActionVariables.get(nonDeterministicAction)» : 0..«nonDeterministicAction.actions.size - 1»;
				«ENDFOR»
				
			INIT
				«xSts.initializingAction.serialize»
				«/* Putting '&' if needed */ #[xSts.variableInitializingTransition.action,
					xSts.configurationInitializingTransition.action, xSts.entryEventTransition.action].connectSubsequentActionsIfNeeded»
				«xSts.finalizeVariableInitialization /*Next() assignment at the very end of the highest primes*/»
				
«««			// In event transition is not necessary (IVAR semantics)
			«FOR transition : xSts.transitions»
				TRANS
					«xSts.outEventTransition.action.serialize /*Out event transition is needed*/»
					« /* Putting '&' if needed */ xSts.outEventTransition.action.connectSubsequentActionIfNeeded»
					«transition.action.serialize /*Everything in constraint apart from if-else (case-esac)*/»
					« /* Putting '&' if needed */ transition.action.connectSubsequentActionIfNeeded»
					«xSts.finalizeVariablesInTrans /*Next() assignment at the very end of the highest primes*/»
			«ENDFOR»
		'''
		
		xSts.restoreLocalVariableNames
		
		return model
	}
	
	//
	
	protected def dispatch String serialize(Action action) {
		throw new IllegalArgumentException("Not supported action: " + action)
	}
	
	protected def dispatch String serialize(SequentialAction action) '''
		 «FOR subaction : action.actions SEPARATOR ' & '»
		 	«subaction.serialize»
		 «ENDFOR»
	'''
	
	protected def dispatch String serialize(IfAction action) '''
		 case
		 	«action.condition.serialize»: «action.then.serialize»;
		 	TRUE: «IF action.^else !== null»«action.^else.serialize»«ELSE»TRUE«ENDIF»;
		 esac
	'''
	
	protected def dispatch String serialize(NonDeterministicAction action) {
		val subactions = action.actions
		'''
			case
				 «FOR subaction : subactions»
				 	«nonDeterministicActionVariables.get(action)» = «subactions.indexOf(subaction)»: «subaction.serialize»;
				 «ENDFOR»
			esac
		'''
	}
	
	// SMV does not support 'a = {1, 2, 5}' like assignments
	// It does support a 'CONSTARRAY(typeof(a), 0)' function, but this way seems to be easier 
	protected def dispatch String serialize(AssignmentAction action) '''
		«FOR assignment : action.extractArrayLiteralAssignments SEPARATOR ' & ' /* If rhs is not array literal, the original assignment is returned */»
			«assignment.lhs.serialize» = «assignment.rhs.serialize»
		«ENDFOR»
	'''
	
	protected def dispatch String serialize(EmptyAction action) '''
		 TRUE
	'''
	
	protected def dispatch String serialize(AssumeAction action) '''
		 «action.assumption.serialize»
	'''
	
	//
	
	protected def String finalizeVariablesInTrans(XSTS xSts) {
		return xSts.finalizeVariables(xSts.transitions, "next(", ")")
	}
	
	protected def String finalizeVariableInitialization(XSTS xSts) {
		return xSts.finalizeVariables(
			#[xSts.variableInitializingTransition, xSts.configurationInitializingTransition, xSts.entryEventTransition])
	}
	
	protected def String finalizeVariables(XSTS xSts, Collection<? extends EObject> context) {
		xSts.finalizeVariables(context, "", "")
	}
	
	protected def String finalizeVariables(XSTS xSts, Collection<? extends EObject> context,
			String variableIdBefore, String variableIdAfter) {
		val variablesAssignedInContext = context
				.getSelfAndAllContentsOfType(AbstractAssignmentAction)
				.map[it.lhs.declaration].toSet
		
		val finalPrimedVariables = newLinkedHashSet
		finalPrimedVariables += xSts.finalPrimedVariables // Final primed...
		finalPrimedVariables.retainAll(variablesAssignedInContext) // ...that are assigned in the context...
		finalPrimedVariables.removeIf[iVariables.contains(it.originalVariable)] // ...iVars cannot be assigned
		
		var string = '''
			«FOR finalPrimedVariable : finalPrimedVariables SEPARATOR ' & '»
				«variableIdBefore»«finalPrimedVariable.originalVariable.name»«variableIdAfter» = «finalPrimedVariable.name»
			«ENDFOR»
		'''
		
		// Relevant only in the case of trans - we have to retain the values of unassigned variables
		val unassignedVariables = newLinkedHashSet
		unassignedVariables += xSts.variableDeclarations
		unassignedVariables.removeIf[it instanceof PrimedVariable] // Remove init primed variables that are not IVARs
		unassignedVariables -= iVariables
		unassignedVariables -= finalPrimedVariables.map[it.originalVariable].filter(VariableDeclaration).toList
		
		if (!unassignedVariables.empty) {
			string += '''
				&
				«FOR unassignedVariable : unassignedVariables SEPARATOR ' & '»
					«variableIdBefore»«unassignedVariable.name»«variableIdAfter» = «unassignedVariable.name»
				«ENDFOR»
			'''
		}
		//
		
		string += ''';'''
		
		return string
	}
	
	//
	
	protected def connectSubsequentActionIfNeeded(EObject object) {
		return #[object].connectSubsequentActionsIfNeeded
	}
	
	protected def connectSubsequentActionsIfNeeded(Collection<? extends EObject> objects) {
		for (object : objects) {
			if (object !== null) {
				return '&'
			}
		}
		return ''
	}
	
	//
	
	protected def createNonDeterministicActionVariables(XSTS xSts) {
		val nonDeterministicActions = xSts.getAllContentsOfType(NonDeterministicAction)
		for (nonDeterministicAction : nonDeterministicActions) {
			nonDeterministicActionVariables += nonDeterministicAction -> 
					"nonDeterministicAction" + nonDeterministicAction.hashCode.toString.replaceAll("-","_")
		}
	}
	
	// Second hash is needed as nuXmv does not support local variables with the same name in different scopes
	protected def customizeLocalVariableNames(XSTS xSts) {
		localVariableNames.clear
		for (localVariableAction : xSts.getAllContentsOfType(VariableDeclarationAction)) {
			val localVariable = localVariableAction.variableDeclaration
			val name = localVariable.name
			localVariableNames += localVariable -> name
			
			localVariable.name = localVariable.name + localVariable.hashCode.toString.replaceAll("-","_")
		}
	}
	
	protected def restoreLocalVariableNames(XSTS xSts) {
		for (localVariableAction : xSts.getAllContentsOfType(VariableDeclarationAction)) {
			val localVariable = localVariableAction.variableDeclaration
			val name = localVariableNames.get(localVariable)
			
			localVariable.name = name
		}
	}
	
}
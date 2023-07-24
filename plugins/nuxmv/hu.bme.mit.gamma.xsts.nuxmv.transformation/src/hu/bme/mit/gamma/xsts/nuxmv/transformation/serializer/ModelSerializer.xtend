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

import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.lowlevel.xsts.transformation.VariableGroupRetriever
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.AbstractAssignmentAction
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.HavocAction
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
	
	protected boolean insideInEventTransition = false
	
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
		nonDeterministicActionVariables.clear
		xSts.createNonDeterministicActionVariables
		//
		iVariables.clear
		
		val inputVariable = xSts.systemInEventVariableGroup.variables
		val inputParameterVariable = xSts.systemInEventParameterVariableGroup.variables
		val inputMasterQueues = xSts.systemMasterMessageQueueGroup.variables
		val inputSlaveQueues = xSts.systemSlaveMessageQueueGroup.variables
		
		val transientVariables = xSts.variableDeclarations.filter[it.transient]
		val resettableVariables = xSts.variableDeclarations.filter[it.resettable]
		
		val localVariables = xSts.getAllContentsOfType(VariableDeclarationAction).map[it.variableDeclaration]
		
		val primedVariables = xSts.variableDeclarations.filter(PrimedVariable)
		
		if (xSts.messageQueueGroup.variables.empty) { // If XSTS is synchronous
			iVariables += (inputVariable + inputParameterVariable)
		} // Otherwise, these variables would get random variables that could overwrite the messages in the queues
		
		iVariables += (/*inputVariable + inputParameterVariable +*/ /*inputMasterQueues + inputSlaveQueues +*/
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
					«xSts.serializeInEventTrans /*In event transition is needed*/»
					« /* Putting '&' if needed */ xSts.inEventTransition.action.connectSubsequentActionIfNeeded»
					«xSts.outEventTransition.action.serialize /*Out event transition is needed*/»
					« /* Putting '&' if needed */ xSts.outEventTransition.action.connectSubsequentActionIfNeeded»
					«transition.action.serialize /*Everything in constraint apart from if-else (case-esac)*/»
					« /* Putting '&' if needed */ transition.action.connectSubsequentActionIfNeeded»
					«xSts.finalizeVariablesInTrans /*Next() assignment at the very end of the highest primes*/»
			«ENDFOR»
		'''
		
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
		 	«action.condition.serialize»:
		 		«action.then.serialize»;
		 	TRUE:
		 		«IF action.^else !== null»«action.^else.serialize»«ELSE»TRUE«ENDIF»;
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
	
	protected def dispatch String serialize(AssignmentAction action) {
		val lhs = action.lhs
		val rhs = action.rhs
		if (lhs instanceof ArrayAccessExpression) {
			// See the comment for array priming in StaticSingleAssignmentTransformer
			val array = lhs.declaration as PrimedVariable
			val oldArray = array.primedVariable
			val indexes = lhs.indexes
			val lastIndex = indexes.last
			
			val arrayWriteExpression = new StringBuilder
			arrayWriteExpression.append(oldArray.name)
			
			//a[i][j][k] := 69 -> a2 = W(a, i, W(a, j, W(R(R(a, i), j), k, 69)))
			
			// READ part
			for (index : indexes) {
				if (index !== lastIndex) {
					arrayWriteExpression.insert(0, '''READ(''')
					arrayWriteExpression.append(''', «index.serialize»)''')
				}
				// Else end - moving onto the WRITE part
			}
			
			// WRITE part
			for (index : indexes.reverseView) {
				if (index === lastIndex) { // Writing the new value
					arrayWriteExpression.insert(0, '''WRITE(''')
					arrayWriteExpression.append(''', «index.serialize», «rhs.serialize»)''')
				}
				else { // Keeping all the others
					arrayWriteExpression.insert(0, '''WRITE(«oldArray.name», «index.serialize», ''')
					arrayWriteExpression.append(''')''')
				}
			}
			
			return '''«array.name» = «arrayWriteExpression»''' // SMV supports 'CONSTARRAY(typeof(a), 0)'
		}
		else {
			return '''«lhs.serialize» = «rhs.serialize»'''
		}
	}
	
	protected def dispatch String serialize(VariableDeclarationAction action) {
		val variable = action.variableDeclaration
		val expression = variable.expression
		return (expression === null) ? 'TRUE' : '''«variable.name» = «expression.serialize»'''
	}
	
	protected def dispatch String serialize(EmptyAction action) '''TRUE'''
	
	protected def dispatch String serialize(HavocAction action) {
		if (insideInEventTransition) {
			val declaration = action.lhs.declaration as PrimedVariable
			val previousVariable = declaration.primedVariable
			val originalVariable = declaration.originalVariable
			if (previousVariable === originalVariable) {
				// In XSTS in-event trans, the havoced variable represents the nondeterministic input
				return '''«declaration.name» = «originalVariable.name»'''
			}
		}
		return '''TRUE'''
	}
	
	protected def dispatch String serialize(AssumeAction action) '''«action.assumption.serialize»'''
	
	//
	
	protected def String serializeInEventTrans(XSTS xSts) {
		insideInEventTransition = true
		val serializedInAction = xSts.inEventTransition.action.serialize
		insideInEventTransition = false
		
		return serializedInAction
	}
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
	
}
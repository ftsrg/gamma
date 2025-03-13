/********************************************************************************
 * Copyright (c) 2023-2024 Contributors to the Gamma project
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
import hu.bme.mit.gamma.xsts.model.XTransition
import hu.bme.mit.gamma.xsts.transformation.util.VariableGroupRetriever
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collection
import java.util.Map
import java.util.Scanner
import java.util.Set
import org.eclipse.emf.ecore.EObject

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class ModelSerializer {
	// Singleton
	public static ModelSerializer INSTANCE = new ModelSerializer
	protected new() {}
	//
	
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
		
		if (xSts.messageQueueGroup.variables.empty) { // If XSTS is synchronous or AA is simplifiable
			iVariables += inputVariable
			iVariables += inputParameterVariable.filter[it.isEnvironmentResettable] // Only the transient parameters
			// Persistent parameters may not change if the input event does not change - this is handled in finalizeTrans 
		} // Otherwise, these variables would get random variables that could overwrite the messages in the queues
		
		iVariables += (/*inputVariable + inputParameterVariable +*/ /*inputMasterQueues + inputSlaveQueues +*/
				transientVariables /*+ resettableVariables*/ + localVariables + primedVariables).toList
				
		val initializingAction = xSts.initializingAction
		val primedVariablesInInitializingAction = initializingAction.writtenVariables
		iVariables -= primedVariablesInInitializingAction // INIT expression cannot contain input variables!
				
		val statefulVariables = newArrayList
		statefulVariables += xSts.variableDeclarations
		statefulVariables -= iVariables
		
		val isInitActionSerializableAsDefines = initializingAction.serializableAsDefines
		if (isInitActionSerializableAsDefines) {
			statefulVariables -= primedVariablesInInitializingAction // These will be DEFINEs
		} // variableDeclarations == iVariables + statefulVariables (+ primedVariablesInInitializingAction :: potentially as DEFINEs)
		
//		val optimizedInitializingAction = xSts.initializingAction.optimizeAction
		
		val model = '''
			«xSts.addTimeDomainAnnotation»
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
				
			«IF isInitActionSerializableAsDefines»
				«initializingAction.serializeActionAsDefine»
			«ENDIF»
				
			INIT
				«IF !isInitActionSerializableAsDefines»
					«initializingAction.serialize»
					«/* Putting '&' if needed */ #[xSts.variableInitializingTransition.action,
						xSts.configurationInitializingTransition.action, xSts.entryEventTransition.action].connectSubsequentActionsIfNeeded»
				«ENDIF»
				«xSts.finalizeVariableInitialization /*Next() assignment at the very end of the highest primes (can be DEFINEs)*/»
				
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
		
		if (isInitActionSerializableAsDefines && xSts.variableDeclarations.exists[it.array]) { // Needed due to nuXmv bug
			val postProcessedModel = model.inlineArrayWriteDefines
			return postProcessedModel
		}
		
		return model
	}
	
	//
	
	protected def addTimeDomainAnnotation(XSTS xSts) {
		val timeoutGroup = xSts.timeoutGroup
		val timeoutVariables = timeoutGroup.variables
		if (timeoutVariables.exists[it.realClock]) {
			return '@TIME_DOMAIN continuous'
		}
		return '' // Same as '@TIME_DOMAIN none'
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
		if (nonDeterministicActionVariables.containsKey(action)) {
			val iVar = nonDeterministicActionVariables.get(action)
			return '''
				case
					«FOR subaction : subactions»
						«iVar» = «subactions.indexOf(subaction)»: «subaction.serialize»;
					«ENDFOR»
				esac
			'''
		}
		// It must be an init action: note that this is NOT semantic-preserving
		checkState(action.getContainerOfType(XTransition) === null)
		return '''
			case
				«FOR subaction : subactions»
					«IF subaction.isFirstActionAssume»«subaction.getFirstActionAssume.serialize»«ELSE»TRUE«ENDIF»: «subaction.serialize»;
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
			val lastIndex = indexes.lastOrNull
			
			val arrayWriteExpression = new StringBuilder
			arrayWriteExpression.append(oldArray.name)
			
			// a[i][j][k] := 69 -> a2 = W(a, i, W(a, j, W(R(R(a, i), j), k, 69)))
			// Not 'W(a, i, W(R(a,i), j, W(R(R(a, i), j), k, 69)))'?
			
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
	
	protected def dispatch String serialize(HavocAction action) '''TRUE'''
	
	protected def dispatch String serialize(AssumeAction action) '''«action.assumption.serialize»'''
	
	//
	
	protected def isSerializableAsDefines(Action action) {
		val containedActions = action.getSelfAndAllContentsOfType(Action)
		return containedActions.forall[
				it instanceof SequentialAction || it instanceof AssignmentAction ||
				it instanceof EmptyAction || it instanceof VariableDeclarationAction]
	}
	
//	protected def String serializeInitActionsAsDefines(Action action) {
//		try {
//			return action.serializeActionAsDefine
//		} catch (IllegalArgumentException e) {
//			// Contains unsupported actions
//			return ""
//		}
//	}
	
	protected def dispatch String serializeActionAsDefine(Action action) {
		throw new IllegalArgumentException("Not supported action: " + action)
	}
	
	protected def dispatch String serializeActionAsDefine(SequentialAction action) '''
		«FOR subaction : action.actions»
			«subaction.serializeActionAsDefine»
		«ENDFOR»
	'''
	
	protected def dispatch String serializeActionAsDefine(AssignmentAction action) '''
		DEFINE «action.serialize.replace("=", ":=")»;
	'''
	
	protected def dispatch String serializeActionAsDefine(VariableDeclarationAction action) '''
		DEFINE «action.variableDeclaration.name» := «action.variableDeclaration.expression.serialize»;
	'''
	
	protected def dispatch String serializeActionAsDefine(EmptyAction action) ''''''
	
	//
	
//	protected def String serializeInEventConstraint(XSTS xSts) {
//		if (xSts.simplifiedAsynchronousAdapter) { // Needed only in SMV, as in other languages, in-events keep their false values between steps
//			val inEventVariables = xSts.inEventVariableGroup.variables
//			val oneInNConstraint = inEventVariables.createOneInNExpression
//			return System.lineSeparator + " & " + oneInNConstraint.serialize
//		}
//		
//		return ""
//	}
	
	protected def String serializeInEventTrans(XSTS xSts) {
		val inEventAction = xSts.inEventTransition.action
		
		var serializedInAction = inEventAction.serialize
		
		/// The sync in event variables have to be connected to the last inout prime variable to be shown in the trace
		
		val writtenInVariables = inEventAction.writtenVariables
		
		val linkableInVariables = newArrayList
		linkableInVariables += xSts.systemInEventVariableGroup.variables
		linkableInVariables += xSts.systemInEventParameterVariableGroup.variables
		
		linkableInVariables.retainAll(iVariables) // Not persistent parameters
		linkableInVariables -= writtenInVariables // Not if the variable was written
		
		val finalPrimedVariables = writtenInVariables.filter(PrimedVariable).toList
				.greatestPrimedVariables // Greatest primes among the ones written in InEventTrans
		for (finalPrimedVariable : finalPrimedVariables) {
			val originalVariable = finalPrimedVariable.originalVariable
			if (linkableInVariables.contains(originalVariable)) { // We have to link it to the original for it to appear in the trace
				serializedInAction += '''& «originalVariable.name» = «finalPrimedVariable.name» '''
			}
		}
		
//		// Simplified AA constraint (1 in-event in N) // Taken care of by the XSTS mapping
//		serializedInAction += xSts.serializeInEventConstraint
//		///
		
		return serializedInAction
	}
	
	//
	
	protected def String finalizeVariablesInTrans(XSTS xSts) {
		return xSts.finalizeVariables(
			(#[xSts.inEventTransition /* Persistent parameters */, xSts.outEventTransition] + xSts.transitions).toList, "next(", ")")
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
		unassignedVariables -= iVariables // Remove IVARs
		unassignedVariables -= finalPrimedVariables.map[it.originalVariable].filter(VariableDeclaration).toList // Remove already assigned vars
		
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
		// SMV cannot handle IVAR in the INIT trans
		val variableInitAction = xSts.variableInitializingTransition.action
		val configurationInitAction = xSts.configurationInitializingTransition.action
		val entryEventAction = xSts.entryEventTransition.action
		xSts.variableInitializingTransition.action = null
		xSts.configurationInitializingTransition.action = null
		xSts.entryEventTransition.action = null
		//
		
		val nonDeterministicActions = xSts.getAllContentsOfType(NonDeterministicAction)
		for (nonDeterministicAction : nonDeterministicActions) {
			nonDeterministicActionVariables += nonDeterministicAction -> 
					"nonDeterministicAction" + nonDeterministicAction.hashCode.toString.replaceAll("-","_")
		}
		
		// Restoring the init transitions
		xSts.variableInitializingTransition.action = variableInitAction
		xSts.configurationInitializingTransition.action = configurationInitAction
		xSts.entryEventTransition.action = entryEventAction
	}
	
	//
	
	private def inlineArrayWriteDefines(String model) {
		val scanner = new Scanner(model)
		val processedModel = new StringBuilder(model.length)
		
		val defines = <String, String>newHashMap
		
		var finished = false
		while (scanner.hasNextLine) {
			val line = scanner.nextLine
			
			if (line.startsWith("TRANS")) { // We need to handle only the INIT
				finished = true
			}
			
			if (finished) {
				processedModel.append(line + System.lineSeparator)
			}
			else {
				var needsAppend = true
				val trimmedLine = line.trim // DEFINE array := WRITE(CONSTARRAY(array 0..4 of integer, 0), 0, 1);
				if (trimmedLine.startsWith("DEFINE")) {
					val split = trimmedLine.split(" := ")
					val id = split.head.substring("DEFINE ".length)
					val valueAndSemicolon = split.lastOrNull
					val value = valueAndSemicolon.substring(0, valueAndSemicolon.length - 1)
					if (value.contains("WRITE")) {
						// Save
						defines += id -> value 
						needsAppend = false
					}
				}
				if (needsAppend) { // Does not handle if a DEFINE is referenced in a DEFINE
					// Replace if needed
					var replacedLine = line
					for (id : defines.keySet) {
						val value = defines.get(id)
						replacedLine = replacedLine.replaceAll(id, value)
					}
					
					processedModel.append(replacedLine + System.lineSeparator)
				}
			}
		}
		
		return processedModel.toString
	}
	
}
/********************************************************************************
 * Copyright (c) 2022-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.promela.transformation.serializer

import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssertAction
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
import hu.bme.mit.gamma.xsts.model.XTransition
import hu.bme.mit.gamma.xsts.promela.transformation.util.ArrayHandler
import hu.bme.mit.gamma.xsts.promela.transformation.util.Configuration
import hu.bme.mit.gamma.xsts.promela.transformation.util.HavocHandler
import hu.bme.mit.gamma.xsts.promela.transformation.util.MessageQueueHandler
import hu.bme.mit.gamma.xsts.promela.transformation.util.ParallelActionHandler
import hu.bme.mit.gamma.xsts.transformation.util.MessageQueueUtil
import hu.bme.mit.gamma.xsts.transformation.util.VariableGroupRetriever
import java.util.List
import java.util.Map

import static hu.bme.mit.gamma.xsts.promela.transformation.util.Namings.*

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class ModelSerializer {
	// Singleton
	public static ModelSerializer INSTANCE = new ModelSerializer
	protected new() {}
	//
	
	protected final Map<Declaration, String> names = newHashMap
	
	//
	protected final extension DeclarationSerializer declarationSerializer = DeclarationSerializer.INSTANCE
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
	protected final extension MessageQueueUtil messageQueueUtil = MessageQueueUtil.INSTANCE
	protected final extension MessageQueueHandler queueHandler = MessageQueueHandler.INSTANCE
	protected final extension VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE
	
	protected final extension ParallelActionHandler parallelHandler = new ParallelActionHandler
	protected final extension HavocHandler havocHandler = HavocHandler.INSTANCE
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	protected final extension ArrayHandler arrayHandler = ArrayHandler.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	//
	
	def String serializePromela(XSTS xSts) {
		xSts.customizeLocalVariableNames
		
		val initializingActions = xSts.initializingAction
		val environmentalActions = xSts.environmentalAction
		
		val actions = <Action>newArrayList
		actions += initializingActions
		actions += environmentalActions
		
		val transitions = xSts.transitions
		for (transition : transitions) {
			actions += transition.action
		}
		
		actions.createParallelMapping
		
		val model = '''
			«xSts.serializeDeclaration»
			
			«serializeParallelChannels»
			byte flag = 0;
			bit «isStableVariableName» = 0;

			«serializeParallelProcesses»
			
			proctype EnvTrans() {
				«xSts.serializeXrXs»
				(flag > 0);
				«isStableVariableName» = 1;
			ENV:
				atomic {
					«isStableVariableName» = 0;
					«environmentalActions.serialize»
					flag = 2;
				};
«««				goto TRANS; ««« The verification is faster if the ENV and TRANS are in different atomic blocks
«««			TRANS:
				atomic {
					«transitions.serializeTransitions»
					«isStableVariableName» = 1;
					flag = 1;
				};
				goto ENV;
			}
			
			init {
				«initializingActions.serialize»
				atomic {
					run EnvTrans();
					flag = 1;
				}
			}
		'''
		
		xSts.restoreLocalVariableNames
		
		return model
	}
	
	//
	// Second hash is needed as Promela does not support local variables with the same name in different scopes
	protected def customizeLocalVariableNames(XSTS xSts) {
		names.clear
		for (localVariableAction : xSts.getAllContentsOfType(VariableDeclarationAction)) {
			val localVariable = localVariableAction.variableDeclaration
			val name = localVariable.name
			names += localVariable -> name
			
			localVariable.name = localVariable.name + localVariable.hashCode.toString.replaceAll("-","_")
		}
	}
	
	protected def restoreLocalVariableNames(XSTS xSts) {
		for (localVariableAction : xSts.getAllContentsOfType(VariableDeclarationAction)) {
			val localVariable = localVariableAction.variableDeclaration
			val name = names.get(localVariable)
			
			localVariable.name = name
		}
	}
	
	//
	
	protected def serializeTransitions(List<? extends XTransition> transitions) {
		if (transitions.size > 1) {
			return '''
				if
					«FOR transition : transitions»
					:: «transition.action.serialize»
					«ENDFOR»
				fi;
			'''
		}
		else {
			return '''«transitions.head.action.serialize»'''
		}
	}
	
	//
	
	protected def dispatch String serialize(AssumeAction action) '''
		if :: («action.assumption.serialize»); fi;
	'''
	
	protected def dispatch String serialize(AssignmentAction action) {
		// Native message queue handling
		if (Configuration.HANDLE_NATIVE_MESSAGE_QUEUES) {
			if (action.queueAction) {
				return action.serializeQueueAction
			}
		}
		//
		// Promela does not support multidimensional arrays, so they need to be handled differently
		// It also does not support the use of array init blocks in processes
		val lhs = action.lhs
		val declaration = lhs.declaration
		if (declaration.typeDefinition instanceof ArrayTypeDefinition) {
			return lhs.serializeArrayAssignment(action.rhs)
		}
		return '''«lhs.serialize» = «action.rhs.serialize»;'''
	}
	
	protected def dispatch String serialize(VariableDeclarationAction action) {
		val variableDeclaration = action.variableDeclaration
		// Native message queue handling
		if (Configuration.HANDLE_NATIVE_MESSAGE_QUEUES) {
			if (action.queueAction) {
				val clonedVariableDeclaration = variableDeclaration.clone
				clonedVariableDeclaration.expression = null
				return '''
					«clonedVariableDeclaration.serializeLocalVariableDeclaration»
					«action.serializeQueueAction»
				'''
			}
		}
		//
		return variableDeclaration.serializeLocalVariableDeclaration
	}
	
	protected def dispatch String serialize(EmptyAction action) ''''''
	
	protected def dispatch String serialize(IfAction action) '''
		if
			:: «action.condition.serialize» ->
				«action.then.serialize»
			«IF action.^else !== null && !(action.^else instanceof EmptyAction)»
				:: else ->
					«action.^else.serialize»
			«ELSE»
				:: else
			«ENDIF»
		fi;
	'''
	
	protected def dispatch String serialize(HavocAction action) {
		val xStsDeclaration = action.lhs.declaration
		val xStsVariable = xStsDeclaration as VariableDeclaration
		
		return '''
			if
				«FOR element : xStsVariable.createSet»
					:: «xStsVariable.name» = «element.serialize»;
				«ENDFOR»
			fi;'''
	}
	
	protected def dispatch String serialize(LoopAction action) {
		val name = action.iterationParameterDeclaration.name
		val left = action.range.getLeft(true)
		val right = action.range.getRight(true)
		return '''
			local int «name»;
			for («name» : «left.serialize»..«right.serialize») {
				«action.action.serialize»
			}
			«name» = 0;
		'''
	}
	
	// DEPRACATED: If-else constructs may mess each other up: "error: proctype 'EnvTrans' state 197, inherits 3 'else' stmnts"
	protected def dispatch String serialize(NonDeterministicAction action) '''
		if
			«FOR subaction : action.actions»
				«IF subaction instanceof SequentialAction»
					«IF subaction.isFirstActionAssume»
						:: («subaction.getFirstActionAssume.assumption.serialize») -> atomic {
							«FOR sequentialSubaction : subaction.actionsSkipFirst»
								«sequentialSubaction.serialize»
							«ENDFOR»
						}
					«ELSE»
						«subaction.serializeAsTrivialBranch»
					«ENDIF»
				«ELSE»
					«subaction.serializeAsTrivialBranch»
				«ENDIF»
			«ENDFOR»
		fi;
	'''
	
	protected def String serializeAsTrivialBranch(Action action) '''
		«IF action instanceof AssumeAction»
			:: «action.serialize» -> atomic {
				skip
			}
		«ELSE»
			:: true -> atomic {
				«action.serialize»
			}
		«ENDIF»
	'''
	//
	
	protected def dispatch String serialize(SequentialAction action) '''
		«FOR subaction : action.actions»
			«subaction.serializeD_stepBeginBrackets»
				«subaction.serialize /* Original action*/»
				«IF subaction.last»
					«action.resetLocalVariableDeclarations»
				«ENDIF»
			«subaction.serializeD_stepCloseBrackets»
		«ENDFOR»
	'''
	
	protected def dispatch String serialize(ParallelAction action) {
		val actions = action.actions
		val actionSize = actions.size
		
		if (actionSize > 1) {
			val syncBitName = '''msg_parallel_«action.containmentLevel»_«action.indexOrZero»'''
			return '''
				«FOR index : 0 ..< actionSize»
					run Parallel_«parallelMapping.get(actions)»_«index»(«actions.get(index).serializeParallelProcessCallArguments»);
				«ENDFOR»
				
				local bit «syncBitName» = 0;
				«FOR index : 0 ..< actionSize»
					chan_parallel_«actions.getChanNumber(index)» ? «syncBitName»;
					«syncBitName» == 1;
					«syncBitName» = 0;
				«ENDFOR»
			'''
		}
		else {
			return '''
				«actions.get(0).serialize»
			'''
		}
	}
	
	// xr, xs
	
	protected def serializeXrXs(XSTS xSts) {
		// len(q) counts as a write/send, so xr and xs both can be asserted only if there are no pars
		// Probably causes NO better performance as this info is utilized for ROP
		if (Configuration.HANDLE_NATIVE_MESSAGE_QUEUES && !xSts.containsType(ParallelAction)) {
			return '''
				«FOR queue : xSts.messageQueueGroup.variables.filter[it.array]»
					xr «queue.name»;
					xs «queue.name»;
				«ENDFOR»
			'''
		}
		return ""
	}
	
	// d_step
	
	val d_stepIncludedActions = #[AssertAction, AssignmentAction]
	
	protected def serializeD_stepBeginBrackets(Action action) {
		if (!action.isContainedBy(ParallelAction) && d_stepIncludedActions.exists[it.isInstance(action)]) { // Correct type
			if (action.first ||
					!action.first && !d_stepIncludedActions.exists[it.isInstance(action.previous)]) {
				// Could add another check - next one is also a good type to avoid single element d_steps
				return "d_step {"
			}
		}
		return "" // We serialize nothing
	}
	
	protected def serializeD_stepCloseBrackets(Action action) {
		if (!action.isContainedBy(ParallelAction) && d_stepIncludedActions.exists[it.isInstance(action)]) { // Correct type
			// Potentially, action is already in the middle of the d_step block
			if (action.last ||
					!action.last && !d_stepIncludedActions.exists[it.isInstance(action.next)]) {
				return "}"
			}
		}
		return "" // We serialize nothing
	}
	
	protected def resetLocalVariableDeclarations(SequentialAction action) {
		val localVariableDeclarations = action.actions.filter(VariableDeclarationAction)
		return '''
			«FOR localVariableDeclaration : localVariableDeclarations»
				«localVariableDeclaration.variableDeclaration.name» = «localVariableDeclaration.variableDeclaration.defaultExpression.serialize»;
			«ENDFOR»
		'''
	}
	
	// Parallel
	
	protected def serializeParallelProcesses() '''
		«FOR actions : parallelMapping.keySet SEPARATOR System.lineSeparator»
			«actions.serializeParallelProcess(
					parallelMapping.get(actions))»
		«ENDFOR»
	'''
	
	protected def serializeParallelProcess(List<Action> actions, int index) '''
		«FOR i : 0 ..< actions.size SEPARATOR System.lineSeparator»
			proctype Parallel_«index»_«i»(«actions.get(i).serializeParallelProcessesArguments») {
				«actions.get(i).serialize»
				
				chan_parallel_«actions.getChanNumber(i)» ! 1;
			}
		«ENDFOR»
	'''
	
	protected def serializeParallelChannels() '''
		«FOR index : 0 ..< maxParallelNumber»
			chan chan_parallel_«index» = [0] of { bit };
		«ENDFOR»
	'''
	
	protected def serializeParallelProcessesArguments(Action action) '''«IF parallelVariableMapping.get(action) !== null»«FOR varDecAction : parallelVariableMapping.get(action) SEPARATOR "; "»«varDecAction.type.serializeType» «varDecAction.name»«ENDFOR»«ENDIF»'''
	protected def serializeParallelProcessCallArguments(Action action) '''«IF parallelVariableMapping.get(action) !== null»«FOR varDecAction : parallelVariableMapping.get(action) SEPARATOR ", "»«varDecAction.name»«ENDFOR»«ENDIF»'''
	
}
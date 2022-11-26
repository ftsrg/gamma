/********************************************************************************
 * Copyright (c) 2022 Contributors to the Gamma project
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
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
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
import hu.bme.mit.gamma.xsts.model.XTransition
import hu.bme.mit.gamma.xsts.promela.transformation.util.ArrayHandler
import hu.bme.mit.gamma.xsts.promela.transformation.util.HavocHandler
import hu.bme.mit.gamma.xsts.promela.transformation.util.ParallelActionHandler
import java.util.List

import static hu.bme.mit.gamma.xsts.promela.transformation.util.Namings.*

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class ModelSerializer {
	// Singleton
	public static ModelSerializer INSTANCE = new ModelSerializer
	protected new() {}
	//
	protected final extension DeclarationSerializer declarationSerializer = DeclarationSerializer.INSTANCE
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	
	protected final extension ParallelActionHandler parallelHandler = new ParallelActionHandler
	protected final extension HavocHandler havocHandler = HavocHandler.INSTANCE
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	protected final extension ArrayHandler arrayHandler = ArrayHandler.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	def String serializePromela(XSTS xSts) {
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
		
		return '''
			«xSts.serializeDeclaration»
			
			«serializeParallelChannels»
			byte flag = 0;
			bit «isStableVariableName» = 0;

			«serializeParallelProcesses»
			
			proctype EnvTrans() {
				(flag > 0);
				«isStableVariableName» = 1;
			ENV:
				atomic {
					«isStableVariableName» = 0;
					«environmentalActions.serialize»
					flag = 2;
				};
				goto TRANS;
			TRANS:
				atomic {
					«transitions.serializeTransitions»
					«isStableVariableName» = 1;
				};
				flag = 1; ««« Out of the atomic block to prevent the creating of an entirely empty step
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
	}
	
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
		if
		:: («action.assumption.serialize»);
		fi;
	'''
	
	protected def dispatch String serialize(AssignmentAction action) {
		// Promela does not support multidimensional arrays, so they need to be handled differently
		// It also does not support the use of array init blocks in processes
		val lhs = action.lhs
		if (lhs.declaration.typeDefinition instanceof ArrayTypeDefinition) {
			return lhs.serializeArrayAssignment(action.rhs)
		}
		return '''«lhs.serialize» = «action.rhs.serialize»;'''
	}
	
	protected def dispatch String serialize(VariableDeclarationAction action) '''
		«action.variableDeclaration.serializeLocalVariableDeclaration»
	'''
	
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
			int «name»;
			for («name» : «left.serialize»..«right.serialize») {
				«action.action.serialize»
			}
		'''
	}
	
	protected def dispatch String serialize(NonDeterministicAction action) '''
		if
		«FOR subaction : action.actions»
		:: «subaction.serialize»
		«ENDFOR»
		fi;
	'''
	
	protected def dispatch String serialize(SequentialAction action) '''
		«FOR subaction : action.actions»
			«subaction.serialize»
		«ENDFOR»
	'''
	
	protected def dispatch String serialize(ParallelAction action) {
		val actions = action.actions
		val actionSize = actions.size
		
		if (actionSize > 1) {
			return '''
				«FOR index : 0 ..< actionSize»
					run Parallel_«parallelMapping.get(actions)»_«index»(«actions.get(index).serializeParallelProcessCallArguments»);
				«ENDFOR»
				
				«FOR index : 0 ..< actionSize»
					chan_parallel_«index»?msg_parallel_«index»;
					msg_parallel_«index» == 1;
					msg_parallel_«index» = 0;
				«ENDFOR»
			'''
		}
		else {
			return '''
				«actions.get(0).serialize»
			'''
		}
	}
	
	//
	
	protected def serializeParallelProcesses() '''
		«FOR actions : parallelMapping.keySet SEPARATOR System.lineSeparator»
			«actions.serializeParallelProcess(
					parallelMapping.get(actions))»
		«ENDFOR»
	'''
	
	protected def serializeParallelProcess(List<? extends Action> actions, int index) '''
		«FOR i : 0 ..< actions.size SEPARATOR System.lineSeparator»
			proctype Parallel_«index»_«i»(«actions.get(i).serializeParallelProcessesArguments») {
				«actions.get(i).serialize»
				
				chan_parallel_«i»!1;
			}
		«ENDFOR»
	'''
	
	protected def serializeParallelChannels() '''
		«FOR index : 0 ..< maxParallelNumber»
			chan chan_parallel_«index» = [0] of { bit };
			bit msg_parallel_«index» = 0;
		«ENDFOR»
	'''
	
	protected def serializeParallelProcessesArguments(Action action) '''«IF parallelVariableMapping.get(action) !== null»«FOR varDecAction : parallelVariableMapping.get(action) SEPARATOR "; "»«varDecAction.type.serializeType» «varDecAction.name»«ENDFOR»«ENDIF»'''
	protected def serializeParallelProcessCallArguments(Action action) '''«IF parallelVariableMapping.get(action) !== null»«FOR varDecAction : parallelVariableMapping.get(action) SEPARATOR ", "»«varDecAction.name»«ENDFOR»«ENDIF»'''
}
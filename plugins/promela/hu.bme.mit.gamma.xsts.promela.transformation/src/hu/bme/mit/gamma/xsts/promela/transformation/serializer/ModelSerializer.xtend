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
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.LoopAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.promela.transformation.util.ArrayHandler
import hu.bme.mit.gamma.xsts.promela.transformation.util.HavocHandler

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class ModelSerializer {
	// Singleton
	public static final ModelSerializer INSTANCE = new ModelSerializer
	protected new() {}
	
	protected extension DeclarationSerializer declarationSerializer = DeclarationSerializer.INSTANCE
	protected extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	
	protected final extension HavocHandler havocHandler = HavocHandler.INSTANCE
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	protected final extension ArrayHandler arrayHandler = ArrayHandler.INSTANCE
	
	def String serializePromela(XSTS xSts) '''
		«xSts.serializeDeclaration»
		
		byte flag = 0;
		
		
		proctype EnvTrans() {
			(flag > 0);
		ENV:
			atomic {
				«xSts.environmentalAction.serialize»
				flag = 2;
			};
			goto TRANS;
		TRANS:
			atomic {
				«FOR transition : xSts.transitions»
					«transition.action.serialize»
				«ENDFOR»
				flag = 1;
			};
			goto ENV;
		}
		
		init {
			atomic {
				«xSts.initializingAction.serialize»
				run EnvTrans();
				flag = 1;
			}
		}
	'''
	
	
	def dispatch String serialize(AssumeAction action) '''
		if
		:: («action.assumption.serialize»);
		fi;
	'''
	
	def dispatch String serialize(AssignmentAction action) {
		//Proomela does not support multidimensional arrays, so they need to be handled differently.
		//It also does not support the use of array init blocks in processes.
		if (action.lhs.declaration.typeDefinition instanceof ArrayTypeDefinition) {
			return action.lhs.serializeArrayAssignment(action.rhs)
		}
		return '''«action.lhs.serialize» = «action.rhs.serialize»;'''
	}
	
	def dispatch String serialize(VariableDeclarationAction action) '''
		«action.variableDeclaration.serializeLocalVariableDeclaration»
	'''
	
	def dispatch String serialize(EmptyAction action) ''''''
	
	def dispatch String serialize(IfAction action) '''
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
	
	def dispatch String serialize(HavocAction action) {
		val xStsDeclaration = action.lhs.declaration
		val xStsVariable = xStsDeclaration as VariableDeclaration
		
		return '''
			if
			«FOR i : xStsVariable.createSet»
			:: «xStsVariable.name» = «i»;
			«ENDFOR»
			fi;'''
	}
	
	def dispatch String serialize(LoopAction action) {
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
	
	def dispatch String serialize(NonDeterministicAction action) '''
		if
		«FOR subaction : action.actions»
		:: «subaction.serialize»
		«ENDFOR»
		fi;
	'''
	
	def dispatch String serialize(SequentialAction action) '''
		«FOR subaction : action.actions»
			«subaction.serialize»
		«ENDFOR»
	'''
}
/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation.serializer

import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.LoopAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.OrthogonalAction
import hu.bme.mit.gamma.xsts.model.ParallelAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.model.XSTS

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class ActionSerializer {
	// Singleton
	public static final ActionSerializer INSTANCE = new ActionSerializer
	protected new() {}
	// Auxiliary objects
	protected final extension DeclarationSerializer declarationSerializer = DeclarationSerializer.INSTANCE
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	
	def String serializeXsts(XSTS xSts) {
		return xSts.serializeXsts(false)
	}
	
	def String serializeXsts(XSTS xSts, boolean serializePrimedVariables) '''
		«xSts.serializeDeclarations(serializePrimedVariables)»
		
		trans «FOR transition : xSts.transitions SEPARATOR " or "»{
			«IF xSts.timed»__delay;«ENDIF»
			«transition.action.serialize»
		}«ENDFOR»
		init {
			«xSts.initializingAction.serialize»
		}
		env {
			«xSts.environmentalAction.serialize»
		}
	'''
	
	def dispatch String serialize(AssumeAction action) '''
		assume «action.assumption.serialize»;
	'''
	
	def dispatch String serialize(AssignmentAction action) '''
		«action.lhs.serialize» := «action.rhs.serialize»;
	'''
	
	def dispatch String serialize(HavocAction action) '''
		havoc «action.lhs.serialize»;
	'''
	
	def dispatch String serialize(VariableDeclarationAction action) '''
		«action.variableDeclaration.serializeLocalVariableDeclaration»;
	'''
	
	// nop cannot be parsed by Theta
	def dispatch String serialize(EmptyAction action) ''''''
	
	def dispatch String serialize(LoopAction action) {
		val name = action.iterationParameterDeclaration.name
		val left = action.range.getLeft(true)
		val right = action.range.getRight(false)
		return '''
			for «name» from «left.serialize» to «right.serialize» do {
				«action.action.serialize»
			}
		'''
	}
	
	def dispatch String serialize(IfAction action) '''
		if («action.condition.serialize») {
			«action.then.serialize»
		}
		«IF action.^else !== null && !(action.^else instanceof EmptyAction)»else {
			«action.^else.serialize»
		}«ENDIF»
	'''
	
	def dispatch String serialize(NonDeterministicAction action) '''
		choice «FOR subaction : action.actions SEPARATOR " or "»{
			«subaction.serialize»
		}«ENDFOR»
	'''
	
	def dispatch String serialize(ParallelAction action) '''
		par «FOR subaction : action.actions SEPARATOR " and "»{
			«subaction.serialize»
		}«ENDFOR»
	'''
	
	def dispatch String serialize(OrthogonalAction action) '''
		ort «FOR subaction : action.actions SEPARATOR " "»{
			«subaction.serialize»
		}«ENDFOR»
	'''
	
	def dispatch String serialize(SequentialAction action) '''
«««		seq {
			«FOR subaction : action.actions»
				«subaction.serialize»
			«ENDFOR»
«««		}
	'''
	
}
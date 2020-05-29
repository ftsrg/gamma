/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.lowlevel.xsts.transformation.serializer

import hu.bme.mit.gamma.xsts.model.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.model.OrthogonalAction
import hu.bme.mit.gamma.xsts.model.model.ParallelAction
import hu.bme.mit.gamma.xsts.model.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.model.XSTS
import hu.bme.mit.gamma.xsts.model.model.XTransition

import static extension hu.bme.mit.gamma.xsts.model.derivedfeatures.XSTSDerivedFeatures.*

class ActionSerializer {
	// Auxiliary objects
	protected final extension DeclarationSerializer declarationSerializer = new DeclarationSerializer
	protected final extension ExpressionSerializer expressionSerializer = new ExpressionSerializer
		
	def serializeXSTS(XSTS xSts) '''
		«xSts.serializeDeclarations(false)»
		
		trans {
			«xSts.mergedTransition.serializeTransition»
		}
		init {
			«xSts.initializingAction.serialize»
		}
		env {
			«xSts.environmentalAction.serialize»
		}
	'''
	
	def serializeXSTSTransitions(XSTS xSts) '''
		«FOR xStsTransition : xSts.transitions»
			«xStsTransition.serializeTransition»
		«ENDFOR»
	'''
	
	def serializeTransition(XTransition xStsTransition) '''
		«xStsTransition.action.serialize»
	'''
	
	def dispatch String serialize(AssumeAction action) '''
		assume «action.assumption.serialize»;
	'''
	
	def dispatch String serialize(AssignmentAction action) '''
		«action.lhs.serialize» := «action.rhs.serialize»;
	'''
	
	def dispatch String serialize(EmptyAction action) '''
		nop;
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
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
package hu.bme.mit.gamma.xsts.promela.transformation.util

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.CompositeAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.LoopAction
import hu.bme.mit.gamma.xsts.model.MultiaryAction
import hu.bme.mit.gamma.xsts.model.ParallelAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.promela.transformation.serializer.DeclarationSerializer
import java.util.List
import java.util.Map

class ParallelActionHandler {
	protected final extension DeclarationSerializer declarationSerializer = DeclarationSerializer.INSTANCE
	
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	protected Map<List<Action>, Integer> parallelMapping
	protected Map<Action, List<Declaration>> parallelVariableMapping
	protected Map<Action, Integer> parallelChanMapping
	protected int maxParallelNumber
	
	def createParallelMapping(List<? extends Action> actions) {
		maxParallelNumber = 0
		parallelMapping = newHashMap
		parallelVariableMapping = newHashMap
		parallelChanMapping = newHashMap
		
		// Promela supports the ParallelActions, but we need to create processes
		for (subaction : actions) {
			subaction.parallelActions
		}
	}
	
	protected def void getParallelActions(Action action) {
		if (action instanceof ParallelAction) {
			val actions = action.actions
			val actionSize = actions.size
			// ParallelAction has multiple Actions
			if (actionSize > 1) {
				parallelMapping.put(actions, parallelMapping.size)
				action.createParallelChanMapping
			}
			// ParallelAction uses local variables
			for (subaction : actions) {
				if (actionSize > 1) {
					val List<Declaration> localVariables = newArrayList
					for (parameter : subaction.referredParameters) {
						localVariables += parameter
					}
					for (variable : subaction.referredVariables) {
						val varDecAction = variable.getContainerOfType(VariableDeclarationAction) 
						if (varDecAction !== null) {
							if (!subaction.getAllContentsOfType(VariableDeclarationAction).contains(varDecAction)) {
								localVariables += variable
							}
						}
					}
					if (!localVariables.empty) {
						parallelVariableMapping.put(subaction, localVariables)
					}
				}
				subaction.parallelActions
			}
		}
		else {
			if (action instanceof MultiaryAction) {
				for (subaction : action.actions) {
					subaction.parallelActions
				}
			}
			else if (action instanceof CompositeAction) {
				if (action instanceof IfAction) {
					action.then.parallelActions
					action.^else?.parallelActions
				}
				else if (action instanceof LoopAction) {
					action.action.parallelActions
				}
				else {
					throw new IllegalArgumentException("Not known CompositeAction: " + action)
				}
			}
		}
	}
	
	protected def void createParallelChanMapping(ParallelAction action) {
		val containers = action.getAllContainersOfType(ParallelAction)
		var chanNumber = 0
		if (containers.size > 0) {
			for (container : containers) {
				if (container.actions.size > 1) {
					chanNumber += container.actions.size
				}
			}
		}
		for (subaction : action.actions) {
			parallelChanMapping.put(subaction, chanNumber)
			chanNumber++
			maxParallelNumber = chanNumber > maxParallelNumber ? chanNumber : maxParallelNumber
		}
	}
	
	// Getters
	
	def getParallelMapping() {
		return parallelMapping
	}
	
	def getParallelVariableMapping() {
		return parallelVariableMapping
	}
	
	def getMaxParallelNumber() {
		return maxParallelNumber
	}
	
	def getChanMapping() {
		return parallelChanMapping
	}
	
	def getChanNumber(List<Action> actions, Integer index) {
		return parallelChanMapping.get(actions.get(index))
	}
}
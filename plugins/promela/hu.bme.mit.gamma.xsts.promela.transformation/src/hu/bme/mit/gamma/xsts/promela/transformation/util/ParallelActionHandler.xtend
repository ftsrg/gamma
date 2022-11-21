package hu.bme.mit.gamma.xsts.promela.transformation.util

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.LoopAction
import hu.bme.mit.gamma.xsts.model.MultiaryAction
import hu.bme.mit.gamma.xsts.model.ParallelAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.promela.transformation.serializer.DeclarationSerializer
import java.util.List
import java.util.Map

class ParallelActionHandler {
	// Singleton
	public static final ParallelActionHandler INSTANCE = new ParallelActionHandler
	protected new() {}
	
	protected extension DeclarationSerializer declarationSerializer = DeclarationSerializer.INSTANCE
	
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	public Map<List<Action>, Integer> parallelMapping
	public Map<Action, List<Declaration>> parallelVariableMapping
	public int maxParallelNumber
	
	def createParallelMapping(List<Action> actions) {
		maxParallelNumber = 0
		parallelMapping = newHashMap
		parallelVariableMapping = newHashMap
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
				maxParallelNumber = actionSize > maxParallelNumber ? actionSize : maxParallelNumber
			}
			// ParallelAction uses local variables
			for (subaction : actions) {
				if (actionSize > 1) {
					val List<Declaration> localVariables = newArrayList
					for (parameter : subaction.referredParameters) {
						localVariables += parameter
					}
					for (variable : subaction.referredVariables) {
						if (variable.getContainerOfType(VariableDeclarationAction) !== null) {
							localVariables += variable
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
			else if (action instanceof IfAction) {
				action.then.parallelActions
				action.^else?.parallelActions
			}
			else if (action instanceof LoopAction) {
				action.action.parallelActions
			}
		}
	}
}
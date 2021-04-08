package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.expression.model.SelectExpression
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List

class ExpressionPreconditionTransformer {
	// 
	protected final Trace trace
	protected final extension ActionTransformer actionTransformer
	// Auxiliary objects
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	// Transformation parameters
	protected final boolean functionInlining
	protected final int MAX_RECURSION_DEPTH
	
	protected int currentRecursionDepth
	
	new(Trace trace, ActionTransformer actionTransformer) {
		this(trace, actionTransformer, true, 10)
	}
	
	new(Trace trace, ActionTransformer actionTransformer,
			boolean functionInlining, int maxRecursionDepth) {
		this.trace = trace
		this.actionTransformer = actionTransformer
		this.functionInlining = functionInlining
		this.MAX_RECURSION_DEPTH = maxRecursionDepth
		this.currentRecursionDepth = MAX_RECURSION_DEPTH
	}
	
	def dispatch List<Action> transformPrecondition(Expression expression) {
		return #[]
	}
	
	def dispatch List<Action> transformPrecondition(SelectExpression expression) {
		throw new IllegalArgumentException("Select expressions are not supported: " + expression)
	}
	
	def dispatch List<Action> transformPrecondition(FunctionAccessExpression expression) {
		val actions = newArrayList
		if (currentRecursionDepth <= 0) {
			// Reached max recursion
			// return assert false
			currentRecursionDepth = MAX_RECURSION_DEPTH
		}
		else if (functionInlining) {
			currentRecursionDepth--
			// Bind the parameter values to the arguments copied into local variables (look out for arrays and records)
			// Transform block (look out for multiple transformations in trace)
			// Trace the return expression (filter the return statements and save them in the return variable)
			currentRecursionDepth++
		}
		else {
			throw new UnsupportedOperationException("Only inlining is supported: " + expression)
		}
		return actions
	}
	
}
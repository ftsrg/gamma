package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.Expression
import java.util.List
import hu.bme.mit.gamma.action.model.Action
import java.util.ArrayList
import java.util.LinkedList
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.action.model.ProcedureDeclaration
import java.util.Map
import java.util.HashMap
import hu.bme.mit.gamma.expression.model.FunctionDeclaration
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.expression.model.VoidTypeDefinition
import hu.bme.mit.gamma.expression.model.LambdaDeclaration
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement

import static extension com.google.common.collect.Iterables.getOnlyElement
import hu.bme.mit.gamma.expression.model.VariableDeclaration

class ExpressionPreconditionTransformer {
	// Auxiliary object
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	// Factory objects
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActionModelFactory actionFactory = ActionModelFactory.eINSTANCE
	// Trace 
	protected final Trace trace
	// The containing ActionTransformer
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension ActionTransformer actionTransformer
	// Transformation parameters
	protected final String assertionVariableName
	protected final boolean functionInlining
	protected final int maxRecursionDepth
	protected Map<FunctionDeclaration, Integer> currentRecursionDepth = new HashMap
	
	new(Trace trace, ExpressionTransformer expressionTransformer, ActionTransformer actionTransformer, String assertionVariableName, boolean functionInlining, int maxRecursionDepth) {
		this.trace = trace
		this.expressionTransformer = expressionTransformer
		this.actionTransformer = actionTransformer
		this.assertionVariableName = assertionVariableName
		this.functionInlining = functionInlining
		this.maxRecursionDepth = maxRecursionDepth
	}
	
	protected def dispatch List<Action> transformPrecondition(Expression expression) {
		return new LinkedList<Action>
	}
	
	// TODO return variable assignment may be faulty
	// TODO complex parameters and return types
	protected def dispatch List<Action> transformPrecondition(FunctionAccessExpression expression) {
		val result = new LinkedList<Action>
		if (functionInlining) {
			// increase recursion depth
			val FunctionDeclaration function = (expression.operand as DirectReferenceExpression).declaration as FunctionDeclaration
			if (currentRecursionDepth.containsKey(function)) {
				currentRecursionDepth.replace(function, currentRecursionDepth.get(function) + 1)
			} else {
				currentRecursionDepth.put(function, 1);
			}
			// check recursion depth
			if (currentRecursionDepth.get(function) > maxRecursionDepth) {
				//TODO handle better
				throw new IllegalArgumentException("Max recursion depth reached!")
			}
			// create parameter variables
			if (function.parameterDeclarations.size > 0) {
				val precondition = new LinkedList<Action>
				val List<VariableDeclarationStatement> parameterVariables = new LinkedList<VariableDeclarationStatement>
				for (i : 0 .. function.parameterDeclarations.size - 1) {
					val parameterVariable = createVariableDeclarationStatement => [
							it.variableDeclaration = createVariableDeclaration => [
							it.name = function.name + function.hashCode + function.parameterDeclarations.get(i).name
							it.type = function.parameterDeclarations.get(i).type.transformType
							precondition.addAll(expression.arguments.get(i).transformPrecondition)
							it.expression = expression.arguments.get(i).transformExpression.getOnlyElement	//TODO for complex parameters
						]
					]
					trace.put(function.parameterDeclarations.get(i), parameterVariable.variableDeclaration)
					parameterVariables.add(parameterVariable)
				}
				result.addAll(precondition)
				result.addAll(parameterVariables)
			}
			// create return variable if needed
			var VariableDeclarationStatement returnVariable = null
			if (!(function.type instanceof VoidTypeDefinition)) {
				returnVariable = createVariableDeclarationStatement => [
					it.variableDeclaration = createVariableDeclaration => [
						it.name = function.name + function.hashCode
						it.type = function.type
					]
				]
				var tempList = new ArrayList<VariableDeclaration>
				tempList.add(returnVariable.variableDeclaration)
				trace.put(expression, tempList)
				result += returnVariable
				actionTransformer.returnStack.push(returnVariable.variableDeclaration)
			}
			// transform the actions according to the type of the function
			if (function instanceof LambdaDeclaration) {
				//transform the expression (TODO needed? per def cannot have side effects)
				result.addAll(function.expression.transformPrecondition)
				if (returnVariable !== null) {
					val assignment = createAssignmentStatement => [
						it.rhs = function.expression.transformExpression.getOnlyElement
					]
					assignment.lhs = createDirectReferenceExpression;
					(assignment.lhs as DirectReferenceExpression).declaration = returnVariable.variableDeclaration
					result += assignment
				}
			} else if (function instanceof ProcedureDeclaration) {
				result.addAll(function.body.transformAction(new LinkedList<Action>))
				actionTransformer.returnStack.pop()
				
			} else {
				throw new IllegalArgumentException("Unknown function type: " + function.class)
			}
			// decrease recursion depth
			currentRecursionDepth.replace(function, currentRecursionDepth.get(function) - 1)
			//actionTransformer.currentReturnVariable = null
		}
		return result
	}

	

}
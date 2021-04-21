package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.action.model.Block
import hu.bme.mit.gamma.action.model.ConstantDeclarationStatement
import hu.bme.mit.gamma.action.model.ProcedureDeclaration
import hu.bme.mit.gamma.action.model.ReturnStatement
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement
import hu.bme.mit.gamma.expression.model.AccessExpression
import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.expression.model.LambdaDeclaration
import hu.bme.mit.gamma.expression.model.MultiaryExpression
import hu.bme.mit.gamma.expression.model.SelectExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.model.VoidTypeDefinition
import hu.bme.mit.gamma.expression.util.FieldHierarchy
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension java.lang.Math.abs
import hu.bme.mit.gamma.action.util.ActionModelValidator

class ExpressionPreconditionTransformer {
	// 
	protected final Trace trace
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension ActionTransformer actionTransformer
	protected final extension ValueDeclarationTransformer valueDeclarationTransformer
	// Auxiliary objects
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	// Factory objects
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActionModelFactory actionFactory = ActionModelFactory.eINSTANCE
	// Transformation parameters
	protected final boolean FUNCTION_INLINING
	protected final int MAX_RECURSION_DEPTH
	
	protected int currentRecursionDepth // For procedures
	
	new(Trace trace, ActionTransformer actionTransformer) {
		this(trace, actionTransformer, true, 10)
	}
	
	new(Trace trace, ActionTransformer actionTransformer,
			boolean functionInlining, int maxRecursionDepth) {
		this.trace = trace
		this.actionTransformer = actionTransformer
		this.expressionTransformer = new ExpressionTransformer(this.trace)
		this.valueDeclarationTransformer = new ValueDeclarationTransformer(this.trace)
		this.FUNCTION_INLINING = functionInlining
		this.MAX_RECURSION_DEPTH = maxRecursionDepth
		this.currentRecursionDepth = MAX_RECURSION_DEPTH
	}
	
	def dispatch List<Action> transformPrecondition(Expression expression) {
		return #[]
	}
	
	def dispatch List<Action> transformPrecondition(AccessExpression expression) {
		return expression.operand.transformPrecondition
	}
	
	def dispatch List<Action> transformPrecondition(BinaryExpression expression) {
		val actions = newArrayList
		actions += expression.leftOperand.transformPrecondition
		actions += expression.rightOperand.transformPrecondition
		return actions
	}
	
	def dispatch List<Action> transformPrecondition(MultiaryExpression expression) {
		val actions = newArrayList
		for (operand : expression.operands) {
			actions += operand.transformPrecondition
		}
		return actions
	}
	
	def dispatch List<Action> transformPrecondition(SelectExpression expression) {
		throw new IllegalArgumentException("Select expressions are not supported: " + expression)
	}
	
	def dispatch List<Action> transformPrecondition(FunctionAccessExpression expression) {
		val actions = newArrayList
		val function = expression.accessedDeclaration
		if (FUNCTION_INLINING) {
			if (currentRecursionDepth <= 0) {
				// Reached max recursion
				val functionType = function.type.clone
				val localStatement = functionType.createDeclarationStatement(
					'''_defaultValueOf_«function.name»_«expression.hashCode.abs»_''')
				val localDefaultDeclaration = localStatement.variableDeclaration
				
				val lowlevelStatement = localStatement.transformAction
				val lowlevelReturnDeclarations = trace.getAll(localDefaultDeclaration -> new FieldHierarchy)
				trace.put(expression, lowlevelReturnDeclarations)
				
				actions += lowlevelStatement
				// TODO Add assert false statement
			}
			else {
				currentRecursionDepth--
				
				// Bind the parameter values to the arguments copied into local variables (look out for arrays and records)
				// Transform block (look out for multiple transformations in trace)
				// Trace the return expression (filter the return statements and save them in the return variable)
				actions += function.transformFunction(expression)
				
				currentRecursionDepth++
			}
		}
		else {
			throw new UnsupportedOperationException("Only inlining is supported: " + expression)
		}
		return actions
	}
	
	protected def dispatch List<Action> transformFunction(Declaration procedure,
			FunctionAccessExpression arguments) {
		throw new IllegalArgumentException("Not supported declaration: " + procedure)
	}
	
	protected def dispatch List<Action> transformFunction(ProcedureDeclaration procedure,
			FunctionAccessExpression expression) {
		procedure.checkProcedure
		val arguments = expression.arguments
		val parameterDeclarations = procedure.parameterDeclarations
		val size = arguments.size
		checkState(size == parameterDeclarations.size)
		
		val inlinedActions = <Action>newArrayList
		val clonedBlock = procedure.body.clone
		
		// Rename local declarations
		val declarations = clonedBlock.getAllContentsOfType(VariableDeclarationStatement)
				.map[it.variableDeclaration] + 
			clonedBlock.getAllContentsOfType(ConstantDeclarationStatement).map[it.constantDeclaration]
		for (declaration : declarations) {
			val name = declaration.name
			declaration.name = '''«name»_«declaration.hashCode.abs»_'''
		}
		
		// Create local parameter declarations
		for (var i = 0; i < size; i++) {
			val argument = arguments.get(i)
			val parameterDeclaration = parameterDeclarations.get(i)
			
			val parameterType = parameterDeclaration.type.clone
			val localStatement = parameterType.createDeclarationStatement(
				'''_«parameterDeclaration.name»_«expression.hashCode.abs»_''', argument.clone)
			val localParameterDeclaration = localStatement.variableDeclaration
			
			inlinedActions += localStatement
			localParameterDeclaration.change(parameterDeclaration, clonedBlock)
		}
		
		// Create local return declarations
		val type = procedure.typeDefinition
		var VariableDeclaration localReturnDeclaration
		val isVoid = type instanceof VoidTypeDefinition
		if (!isVoid) {
			val procedureType = type.clone
			val localStatement = procedureType.createDeclarationStatement(
				'''_returnValueOf_«procedure.name»_«expression.hashCode.abs»_''')
			localReturnDeclaration = localStatement.variableDeclaration
			inlinedActions += localStatement
			
			for (returnStatement : clonedBlock.getSelfAndAllContentsOfType(ReturnStatement)) {
				val returnExpression = returnStatement.expression
				if (returnExpression !== null) {
					val clonedReturnExpression = returnExpression.clone
					val reference = localReturnDeclaration.createReferenceExpression
					val returnAssignment = reference.createAssignment(clonedReturnExpression)
					returnAssignment.replace(returnStatement)
				}
				else {
					returnStatement.remove
				}
			}
		}
		inlinedActions += clonedBlock
		
		// Transforming local paramaters, local return declarations and the block
		val lowlevelAction = inlinedActions.transformActions
		if (localReturnDeclaration !== null) {
			// Tracing the function access expression to the return declarations 
			val lowlevelReturnDeclarations = trace.getAll(localReturnDeclaration -> new FieldHierarchy)
			trace.put(expression, lowlevelReturnDeclarations)
		}
		
		if (lowlevelAction instanceof Block) {
			return lowlevelAction.actions
		}
		return #[lowlevelAction]
	}
	
	protected def checkProcedure(ProcedureDeclaration procedure) {
		val extension validator = ActionModelValidator.INSTANCE
		val messages = procedure.checkReturnStatementPositions
		checkState(messages.empty, messages.map[it.resultText].join(" "))
	}
	
	protected def dispatch List<Action> transformFunction(LambdaDeclaration procedure,
			FunctionAccessExpression arguments) {
		// Lambdas must be side effect-free, so no pre-transformation is necessary 
		return #[]
	}
	
}
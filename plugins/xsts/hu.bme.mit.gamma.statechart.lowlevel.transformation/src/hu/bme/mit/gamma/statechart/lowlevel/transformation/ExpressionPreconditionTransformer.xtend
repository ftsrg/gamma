package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.action.model.Block
import hu.bme.mit.gamma.action.model.ConstantDeclarationStatement
import hu.bme.mit.gamma.action.model.ForStatement
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
import java.util.Set
import org.eclipse.emf.ecore.EObject

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension java.lang.Math.abs

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
				// Adding assert false statement
				actions += createAssertionStatement => [
					it.assertion = createFalseExpression
				]
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
			// A default expression is needed, otherwise some uninitialized parts of record can be havoced
			if (declaration.expression === null) {
				declaration.expression = declaration.type.defaultExpression
			}
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
		
		// Handling return statements
		var VariableDeclaration localReturnDeclaration = null
		val returnStatements = clonedBlock.getSelfAndAllContentsOfType(ReturnStatement)
		if (!returnStatements.empty) {
			val procedureType = procedure.type.clone // typeDefinition is not correct due to record literals
			val localDeclarationPostfix = '''_«procedure.name»_«expression.hashCode.abs»_'''
			// This declaration will store the return value
			val isVoid = procedureType.typeDefinition instanceof VoidTypeDefinition 
			if (!isVoid) {
				val localStatement = procedureType.createDeclarationStatement(
					'''_returnValueOf«localDeclarationPostfix»''')
				localReturnDeclaration = localStatement.variableDeclaration
				inlinedActions += localStatement
			}
			// This declaration will store during execution, whether we have to return
			// Later optimizations will remove these declarations if they are unnecessary
			val localIsReturnedStatement = createBooleanTypeDefinition.createDeclarationStatement(
				'''_isReturned«localDeclarationPostfix»''')
			val localIsReturnedDeclaration = localIsReturnedStatement.variableDeclaration
			inlinedActions += localIsReturnedStatement
			
			val extension returnGuardHandler = new ProcedureReturnGuardHandler(localIsReturnedDeclaration)
			
			for (returnStatement : returnStatements) {
				// Setting the boolean flag: a return is executed
				val isReturnedReference = localIsReturnedDeclaration.createReferenceExpression
				val setIsReturned = isReturnedReference.createAssignment(createTrueExpression)
				returnStatement.append(setIsReturned)
				
				setIsReturned.addReturnGuard
				
				// Storing the return value
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
		
		// Transforming local parameters, local return declarations and the block
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
	
	protected def dispatch List<Action> transformFunction(LambdaDeclaration procedure,
			FunctionAccessExpression arguments) {
		// Lambdas must be side effect-free, so no pre-transformation is necessary 
		return #[]
	}
	
	// Auxiliary class for procedure return handling
	
	private static class ProcedureReturnGuardHandler {
		
		final VariableDeclaration isReturnedDeclaration
		final Set<Action> guardedActions = newHashSet // A block or for statement is guarded only once
		// Auxiliary objects
		protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
		protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
		protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
		protected final extension ActionModelFactory actionFactory = ActionModelFactory.eINSTANCE
		
		new(VariableDeclaration isReturnedDeclaration) {
			this.isReturnedDeclaration = isReturnedDeclaration
		}
		
		// EObject is expected to handle branches too
		def void addReturnGuard(EObject action) {
			val container = action.eContainer
			
			if (container === null) {
				return
			}
			if (container instanceof Block) {
				if (!guardedActions.contains(container)) {
					val actions = container.actions
					val size = actions.size
					val firstGuardableActionIndex = action.index + 1
					
					if (firstGuardableActionIndex < size) {
						val guard = createNotExpression => [
							it.operand = isReturnedDeclaration.createReferenceExpression
						]
						val guardedBlock = createBlock => [
							it.actions += actions.subList(firstGuardableActionIndex, size)
						]
						val branch = guard.createBranch(guardedBlock)
						val ifStatement = createIfStatement => [
							it.conditionals += branch
						]
						// Putting the guarded block to the end (guardable actions are inside)
						actions += ifStatement
					}
					
					guardedActions += container
				}
			}
			if (container instanceof ForStatement) {
				if (!guardedActions.contains(container)) {
					val guard = createNotExpression => [
						it.operand = isReturnedDeclaration.createReferenceExpression
					]
					val branch = guard.createBranch(container.body)
					val ifStatement = createIfStatement => [
						it.conditionals += branch
					]
					container.body = ifStatement
					
					guardedActions += container
				}
			}
			
			// Recursion to the top
			container.addReturnGuard
		} 
		
	}
	
}
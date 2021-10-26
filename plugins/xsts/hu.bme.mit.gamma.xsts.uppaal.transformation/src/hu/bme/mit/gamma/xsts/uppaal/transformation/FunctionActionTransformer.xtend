package hu.bme.mit.gamma.xsts.uppaal.transformation

import hu.bme.mit.gamma.uppaal.util.AssignmentExpressionCreator
import hu.bme.mit.gamma.uppaal.util.NtaBuilder
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collection
import uppaal.declarations.Function
import uppaal.declarations.VariableContainer
import uppaal.declarations.VariableDeclaration
import uppaal.statements.Statement

import static extension java.lang.Math.abs

class FunctionActionTransformer {
	
	protected final extension NtaBuilder ntaBuilder
	
	protected final Collection<VariableDeclaration> localVariables = newHashSet
	
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension VariableTransformer variableTransformer
	protected final extension AssignmentExpressionCreator assignmentExpressionCreator
	
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	new(NtaBuilder ntaBuilder, Traceability traceability) {
		this.ntaBuilder = ntaBuilder
		this.variableTransformer = new VariableTransformer(ntaBuilder, traceability)
		this.expressionTransformer = new ExpressionTransformer(traceability)
		this.assignmentExpressionCreator = new AssignmentExpressionCreator(ntaBuilder)
	}
	
	// Wrap into a function
	
	def Function transformIntoFunction(Action action) {
		localVariables.clear
		
		val uppaalAction = action.transformAction // localVariables are filled now
		val uppaalBlock = uppaalAction.createBlock
		
		uppaalBlock.declarations = localVariables.createLocalDeclarations
		val name = '''action_«action.hashCode.abs»'''
		
		return name.createVoidFunction(uppaalBlock)
	} 
	
	// Transform action dispatch
	
	protected def dispatch Statement transformAction(EmptyAction action) {
		throw new IllegalArgumentException("Empty actions are not supported: " + action)
	}
	
	protected def dispatch Statement transformAction(AssignmentAction action) {
		// UPPAAL does not support 'a = {1, 2, 5}' like assignments
		val assignmentActions = action.extractArrayLiteralAssignments
		val uppaalStatements = newArrayList
		for (assignmentAction : assignmentActions) {
			val uppaalLhs = assignmentAction.lhs.transform
			val uppaalRhs = assignmentAction.rhs.transform
			uppaalStatements += uppaalLhs.createAssignmentExpression(uppaalRhs)
		}
		return uppaalStatements.createStatement.createBlock
	}
	
	protected def dispatch Statement transformAction(VariableDeclarationAction action) {
		val xStsVariable = action.variableDeclaration
		
		val uppaalVariable = xStsVariable.transformAndTraceVariable
		uppaalVariable.extendNameWithHash // Needed for local declarations
		uppaalVariable.remove // We will use it as a local variable
		localVariables += uppaalVariable
		
		val xStsInitialValue = xStsVariable.initialValue
		val uppaalRhs = xStsInitialValue.transform
		
		return uppaalVariable.createAssignmentExpression(uppaalRhs).createStatement
	}
	
	protected def void extendNameWithHash(VariableContainer uppaalContainer) {
		for (uppaalVariable : uppaalContainer.variable) {
			uppaalVariable.name = '''«uppaalVariable.name»_«uppaalVariable.hashCode.abs»'''
		}
	}
	
	protected def dispatch Statement transformAction(SequentialAction action) {
		val xStsActions = action.actions
		val uppaalStatements = newArrayList
		for (xStsAction : xStsActions) {
			uppaalStatements += xStsAction.transformAction
		}
		return uppaalStatements.createBlock
	}
	
	protected def dispatch Statement transformAction(NonDeterministicAction action) {
		throw new IllegalArgumentException("Nondeterministic actions are not supported: " + action)
	}
	
	protected def dispatch Statement transformAction(IfAction action) {
		val xStsCondition = action.condition
		val xStsThen = action.then
		val xStsElse = action.^else
		
		val uppaalCondition = xStsCondition.transform
		val uppaalThen = xStsThen.transformAction
		val uppaalElse = xStsElse.transformAction
		
		return uppaalCondition.createIfStatement(uppaalThen, uppaalElse)
	}
	
}
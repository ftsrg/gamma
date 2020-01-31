package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.VariableContainer
import uppaal.expressions.AssignmentExpression
import uppaal.expressions.AssignmentOperator
import uppaal.expressions.ExpressionsPackage
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.LiteralExpression

class AssignmentExpressionCreator {
	// Model manipulator
	protected final extension IModelManipulations manipulation
	// UPPAAL packages
	protected final extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
	// Auxiliary objects
	protected final extension ExpressionTransformer expressionTransformer
	
	new(IModelManipulations manipulation, ExpressionTransformer expressionTransformer) {
		this.manipulation = manipulation
		this.expressionTransformer = expressionTransformer
	}
	
	/**
	 * Puts an assignment expression onto the given container. The left side is the given variable, the right is side either true or false". E.g.: myVariable = true.
	 */
	def void createAssignmentExpression(EObject container, EReference reference, DataVariableDeclaration variable, boolean isTrue) {
		container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = variable.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
				it.text = isTrue.toString
			]
		]
	}
	
	/**
	 * Puts an assignment expression onto the given container. The left side is the first given variable, the right side is the second given variable". E.g.: myFirstVariable = mySecondVariable.
	 */
	def void createAssignmentExpression(EObject container, EReference reference, DataVariableDeclaration lhs, DataVariableDeclaration rhs) {
   		container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = lhs.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = rhs.variable.head // Only one variable is expected
			]
		]
	}
	
	/**
	 * Responsible for creating an assignment expression with the given variable reference and the given expression.
	 */
	def AssignmentExpression createAssignmentExpression(EObject container, EReference reference, VariableContainer variable, Expression rhs, ComponentInstance owner) {
		val assignmentExpression = container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = variable.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.transform(binaryExpression_SecondExpr, rhs, owner)
		]
		return assignmentExpression
	}
	
	def AssignmentExpression createAssignmentExpression(EObject container, EReference reference, VariableContainer variable, uppaal.expressions.Expression rhs) {
		val assignmentExpression = container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = variable.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.secondExpr = rhs
		]
		return assignmentExpression
	}
	
}
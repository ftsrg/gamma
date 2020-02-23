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
import uppaal.expressions.ExpressionsFactory
import uppaal.expressions.ExpressionsPackage
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.LiteralExpression
import uppaal.expressions.LogicalExpression
import uppaal.expressions.LogicalOperator
import uppaal.expressions.NegationExpression
import uppaal.templates.Location
import uppaal.templates.TemplatesPackage

class AssignmentExpressionCreator {
	// NTA builder
	protected final extension NtaBuilder ntaBuilder
	// Model manipulator
	protected final extension IModelManipulations manipulation
	// UPPAAL packages
	protected final extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
	protected final extension TemplatesPackage temPackage = TemplatesPackage.eINSTANCE
	// UPPAAL factories
	protected final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
	// Auxiliary objects
	protected final extension ExpressionTransformer expressionTransformer
	
	new(NtaBuilder ntaBuilder, IModelManipulations manipulation, ExpressionTransformer expressionTransformer) {
		this.ntaBuilder = ntaBuilder
		this.manipulation = manipulation
		this.expressionTransformer = expressionTransformer
	}
	
	/**
	 * Puts an assignment expression onto the given container. The left side is the given variable, the right side is either true or false". E.g.: myVariable = true.
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
	 * Puts an assignment expression onto the given container. The left side is the given variable, the right side is an integer value". E.g.: myVariable = 0.
	 */
	def void createAssignmentExpression(EObject container, EReference reference, DataVariableDeclaration variable, Integer value) {
		container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = variable.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
				it.text = value.toString
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
	
	/**
	 * Puts an assignment expression onto the given container. The left side is the first given variable, the right side is the second given variable in disjunction with the third variable. E.g.: myFirstVariable = mySecondVariable || myThirdVariable.
	 */
	def void createAssignmentLogicalExpression(EObject container, EReference reference, DataVariableDeclaration lhs, DataVariableDeclaration rhsl, DataVariableDeclaration rhsr) {
   		container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = lhs.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, logicalExpression) as LogicalExpression => [
				it.operator = LogicalOperator.OR
				it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
					it.identifier = rhsl.variable.head // Only one variable is expected
				]
				it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
					it.identifier = rhsr.variable.head // Only one variable is expected
				]
			]
		]
	}
	
	/**
	 * Creates a loop edge onto the given location that sets the toRaise flag of the give signal to isTrue.
	 */
	def createLoopEdgeWithBoolAssignment(Location location, DataVariableDeclaration variable, boolean isTrue) {
		val loopEdge = location.createEdge(location)
		// variable = isTrue
		loopEdge.createAssignmentExpression(edge_Update, variable, isTrue)
		return loopEdge
	}
	
	/**
	 * Creates a loop edge onto the given location that sets the toRaise flag of the give signal to true and puts a guard on it too,
	 * so the edge is only fireable if the variable-to-be-set is false.
	 */
	def createLoopEdgeWithGuardedBoolAssignment(Location location, DataVariableDeclaration variable) {
		val loopEdge = location.createLoopEdgeWithBoolAssignment(variable, true)
		val negationExpression = createNegationExpression as NegationExpression => [
			it.createChild(negationExpression_NegatedExpression, identifierExpression) as IdentifierExpression => [
				it.identifier = variable.variable.head
			]
		]
		// Only fireable if the bool variable is not already set
		loopEdge.addGuard(negationExpression, LogicalOperator.AND)
		return loopEdge
	}
	
}
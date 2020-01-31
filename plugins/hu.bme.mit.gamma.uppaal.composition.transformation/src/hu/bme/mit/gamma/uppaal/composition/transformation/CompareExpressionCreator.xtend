package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.TimeoutEventReference
import hu.bme.mit.gamma.uppaal.transformation.traceability.TraceabilityPackage
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import uppaal.declarations.ClockVariableDeclaration
import uppaal.expressions.CompareExpression
import uppaal.expressions.CompareOperator
import uppaal.expressions.Expression
import uppaal.expressions.ExpressionsFactory
import uppaal.expressions.ExpressionsPackage
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.LogicalExpression
import uppaal.expressions.LogicalOperator
import uppaal.templates.Edge
import uppaal.templates.Location
import uppaal.templates.TemplatesPackage

class CompareExpressionCreator {
	// Transformation rule-related extensions
	protected final extension IModelManipulations manipulation
	// Trace
	protected final extension Trace modelTrace
	// UPPAAL packages
	protected final extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
	protected final extension TemplatesPackage temPackage = TemplatesPackage.eINSTANCE
	// UPPAAL factories
	protected final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
	// Gamma package
	protected final extension TraceabilityPackage trPackage = TraceabilityPackage.eINSTANCE
	// Auxiliary objects
	protected final extension NtaBuilder ntaBuilder
	protected final extension ExpressionTransformer expressionTransformer
	
	new(NtaBuilder ntaBuilder, IModelManipulations manipulation,
			ExpressionTransformer expressionTransformer, Trace modelTrace) {
		this.ntaBuilder = ntaBuilder
		this.manipulation = manipulation
		this.expressionTransformer = expressionTransformer
		this.modelTrace = modelTrace
	}
	
	def createMinTimeGuard(Edge clockEdge, ClockVariableDeclaration clockVar, Integer minTime) {
		clockEdge.addGuard(createCompareExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = clockVar.variable.head // Always one variable in the container
			]
			it.operator = CompareOperator.GREATER_OR_EQUAL
			it.secondExpr = createLiteralExpression => [
				it.text = minTime.toString
			] 
		], LogicalOperator.AND)
	}
	
	def createMaxTimeInvariant(Location clockLocation, ClockVariableDeclaration clockVar, Integer maxTime) {
		val locInvariant = clockLocation.invariant
		val maxTimeExpression = createLiteralExpression => [
			it.text = maxTime.toString
		]
		if (locInvariant !== null) {
			clockLocation.insertLogicalExpression(location_Invariant, CompareOperator.LESS_OR_EQUAL, clockVar, maxTimeExpression, locInvariant, LogicalOperator.AND)
		} 
		else {
			clockLocation.insertCompareExpression(location_Invariant, CompareOperator.LESS_OR_EQUAL, clockVar, maxTimeExpression)
		}
	}
	
	/**
	 * Responsible for creating an AND logical expression containing an already existing expression and a clock expression.
	 */
	def insertLogicalExpression(EObject container, EReference reference, CompareOperator compOp, ClockVariableDeclaration clockVar,
			hu.bme.mit.gamma.expression.model.Expression timeExpression, Expression originalExpression, TimeoutEventReference timeoutEventReference, LogicalOperator logOp) {
		val andExpression = container.createChild(reference, logicalExpression) as LogicalExpression => [
			it.operator = logOp
			it.secondExpr = originalExpression
		]
		andExpression.insertCompareExpression(binaryExpression_FirstExpr, compOp, clockVar, timeExpression, timeoutEventReference)
	}
	
	/**
	 * Responsible for creating a compare expression that compares the given clock variable to the given expression.
	 */
	def void insertCompareExpression(EObject container, EReference reference, CompareOperator compOp,
			ClockVariableDeclaration clockVar, hu.bme.mit.gamma.expression.model.Expression timeExpression, TimeoutEventReference timeoutEventReference) {		
		val owner = clockVar.owner
		val compExp = container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = compOp
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = clockVar.variable.head // Always one variable in the container
			]
			it.transform(binaryExpression_SecondExpr, timeExpression, owner)
		]
		addToTrace(timeoutEventReference, #{compExp}, trace)
		addToTrace(owner, #{clockVar}, instanceTrace)
	}
	
	/**
	 * Responsible for creating an AND logical expression containing an already existing expression and a clock expression.
	 */
	def insertLogicalExpression(EObject container, EReference reference, CompareOperator compOp, ClockVariableDeclaration clockVar,
		hu.bme.mit.gamma.expression.model.Expression timeExpression, Expression originalExpression, LogicalOperator logOp) {
		val andExpression = container.createChild(reference, logicalExpression) as LogicalExpression => [
			it.operator = logOp
			it.secondExpr = originalExpression
		]
		andExpression.insertCompareExpression(binaryExpression_FirstExpr, compOp, clockVar, timeExpression)
	}
	
	/**
	 * Responsible for creating a compare expression that compares the given clock variable to the given expression.
	 */
	def insertCompareExpression(EObject container, EReference reference, CompareOperator compOp,
			ClockVariableDeclaration clockVar, hu.bme.mit.gamma.expression.model.Expression timeExpression) {
		container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = compOp	
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = clockVar.variable.head // Always one variable in the container
			]
			it.transform(binaryExpression_SecondExpr, timeExpression, null)		
		]
	}
	
	def insertLogicalExpression(EObject container, EReference reference, CompareOperator compOp, ClockVariableDeclaration clockVar,
			Expression timeExpression, Expression originalExpression, LogicalOperator logOp) {
		val andExpression = container.createChild(reference, logicalExpression) as LogicalExpression => [
				it.operator = logOp
				it.secondExpr = originalExpression
		]
		andExpression.insertCompareExpression(binaryExpression_FirstExpr, compOp, clockVar, timeExpression)
	}
	
	def insertCompareExpression(EObject container, EReference reference, CompareOperator compOp,
			ClockVariableDeclaration clockVar, Expression timeExpression) {
		container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = compOp
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = clockVar.variable.head // Always one variable in the container
			]
			it.secondExpr = timeExpression
		]
	}
	
}
package hu.bme.mit.gamma.xsts.uppaal.transformation

import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.ClockVariableDeclarationAnnotation
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.LiteralExpression
import hu.bme.mit.gamma.expression.model.NotExpression
import hu.bme.mit.gamma.expression.model.OrExpression
import hu.bme.mit.gamma.expression.model.PredicateExpression
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.expression.util.ExpressionNegator
import hu.bme.mit.gamma.expression.util.ExpressionSerializer
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List
import java.util.logging.Logger

/**
 * A utility class that brings guard expressions to DNF form in regard to clock variables.
 * 
 * UPPAAL requires, that 'A guard must be a conjunction of simple conditions on clocks, 
 * differences between clocks, and boolean expressions not involving clocks.'
 * This class can bring an expression to DNF form so it may be split across edges. 
 */
class ClockGuardTransformer {
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ExpressionNegator expressionNegator = ExpressionNegator.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE

	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final Logger logger = Logger.getLogger("GammaLogger")

	/**
	 *  Singleton class instance
	 */
	public static final ClockGuardTransformer INSTANCE = new ClockGuardTransformer

	/**
	 * Split expression into expressions, which used as parallel edges are equivalent to the original.
	 * Clock comparisons may only be in the top level of the expression by itself or in a top level `and` expression.
	 * 
	 * @param guard expression can only contain: AndExpression, LiteralExpression, NotExpression, OrExpression, 
	 * 	PredicateExpression, ReferenceExpression
	 * 
	 * @return List of expressions. May be empty if all created expressions are definitely false.
	 */
	def List<Expression> splitByDisjunction(Expression guard) {
		val clone = guard.clone
		val transformed = clone.toDnfChecked
		if (transformed instanceof OrExpression) {
			return transformed.operands.reject[it.isDefinitelyFalseExpression].clone
		}
		return #[transformed]
	}

	/**
	 * Function to transform expression into DNF form only if it contains references to clock variables.
	 * 
	 * @param exp Limitations listed at splitByDisjunction
	 */
	private def Expression toDnfChecked(Expression exp) {
		if (exp.containsClockReference) {
			return toDnf(exp)
		}
		return exp.clone
	}

	/**
	 * Dispatch recursive function (through toDnfChecked) to bring an expression into DNF form. 
	 * @param exp Limitations listed at splitByDisjunction
	 */
	private dispatch def Expression toDnf(Expression exp) {
		throw new IllegalArgumentException("Unhandled parameter types: " + exp);
	}

	private dispatch def Expression toDnf(ReferenceExpression exp) {
		return exp.clone
	}

	private dispatch def Expression toDnf(LiteralExpression exp) {
		return exp.clone
	}

	private dispatch def Expression toDnf(PredicateExpression exp) {
		return exp.clone
	}

	private dispatch def Expression toDnf(NotExpression expr) {
		val innerExpr = expr.operand

		// not A => not A
		// necessary to avoid infinite recursion
		if (innerExpr instanceof ReferenceExpression) {
			return expr.clone
		}
		// handles DeMorgan transformations
		return innerExpr.negate.toDnfChecked
	}

	private dispatch def Expression toDnf(AndExpression expr) {
		val operands = expr.operands.map[toDnfChecked]

		return distributeAnd(operands)
	}

	private dispatch def Expression toDnf(OrExpression expr) {
		val operands = expr.operands.map[toDnfChecked]

		// Bring up inner `or`s
		// A or (B or C) => A or B or C
		val flattenedOperands = operands.flatMap [
			if (it instanceof OrExpression) {
				return it.operands
			}
			return #[it]
		]

		return createOrExpression => [
			it.operands += flattenedOperands.clone
		]
	}

	/**
	 * This method may be used to distribute ANDs over ORs.
	 * 
	 * @param operands list of operands of the original AND expression. Doesn't have to contain any ORs.
	 * 
	 * @returns if distribution was necessary an `OrExpression`, otherwise an `AndExpression` 
	 */
	private def Expression distributeAnd(List<Expression> operands) {
		if (!operands.exists[it instanceof OrExpression]) {
			return createAndExpression => [
				it.operands += operands
			]
		}
		val listOfOperands = operands.map [
			if (it instanceof OrExpression) {
				return it.operands
			}
			return #[it]
		]
		val product = listProduct(listOfOperands).map [ ops |
			createAndExpression => [
				it.operands += ops
			]
		]

		return createOrExpression => [
			it.operands += product
		]
	}

	/**
	 * Creates a product of the inner lists
	 * 
	 * @param list list of lists where each inner list must have at least 1 element
	 * 
	 * @return every possible combination of the inner lists
	 */
	private def List<List<Expression>> listProduct(List<List<Expression>> list) {
		if (list.empty) {
			return #[]
		}
		if (list.length == 1) {
			return list.head.map[#[it]]
		}
		val tails = listProduct(list.tail.clone)
		// combine each current expression with each possible tail
		return list.head.flatMap [ expr |
			tails.map [ tail |
				val product = newArrayList(expr.clone)
				product += tail.clone
				product
			]
		].clone
	}

	/**
	 * Check if the expression contains a reference to a clock variable
	 */
	private def containsClockReference(Expression expression) {
		return expression !== null && expression.getSelfAndAllContentsOfType(DirectReferenceExpression).exists [
			it.clock
		]
	}

	/**
	 * Check if the referenced variable is a clock
	 */
	private def boolean isClock(DirectReferenceExpression expr) {
		val declaration = expr.declaration
		if (declaration instanceof VariableDeclaration) {
			return declaration.annotations.exists[it instanceof ClockVariableDeclarationAnnotation]
		}
		return false
	}
}

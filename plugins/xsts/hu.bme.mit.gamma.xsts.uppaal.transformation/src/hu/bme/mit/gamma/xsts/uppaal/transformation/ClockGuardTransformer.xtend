package hu.bme.mit.gamma.xsts.uppaal.transformation

import hu.bme.mit.gamma.expression.model.Expression
import java.util.List
import hu.bme.mit.gamma.expression.model.NotExpression
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.OrExpression
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.LiteralExpression
import hu.bme.mit.gamma.expression.model.PredicateExpression
import hu.bme.mit.gamma.expression.util.ExpressionNegator

class ClockGuardTransformer {
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ExpressionNegator expressionNegator = ExpressionNegator.INSTANCE

	public static final ClockGuardTransformer INSTANCE = new ClockGuardTransformer

	def /*List<Expression>*/ splitByDisjunction(Expression guard) {
		try {
			guard.toDnf
		} catch (Exception e) {
		}
	}

	private dispatch def Expression toDnf(Expression exp) {
		throw new IllegalArgumentException("Unhandled parameter types: " + exp);
	}

	private dispatch def Expression toDnf(NotExpression expr) {
		val innerExpr = expr.operand
		if (innerExpr instanceof ReferenceExpression || innerExpr instanceof LiteralExpression ||
			innerExpr instanceof PredicateExpression) {
			return expr
		}

		// not not A => A
		if (innerExpr instanceof NotExpression) {
			return toDnf(innerExpr.operand)
		}
		// not (A and B) => (not A or not B)
		if (innerExpr instanceof AndExpression) {
			createOrExpression => [
				it.operands += innerExpr.operands.map [
					return toDnf(it.negate)
				]
			]
		}

		// not (A or B) => (not A and not B)
		if (innerExpr instanceof OrExpression) {
			createAndExpression => [
				it.operands += innerExpr.operands.map [
					return toDnf(it.negate)
				]
			]
		}

		throw new IllegalArgumentException("Unhandled parameter types: " + expr);
	}
}

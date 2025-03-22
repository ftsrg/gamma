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
import hu.bme.mit.gamma.expression.util.ExpressionSerializer
import java.util.logging.Logger
import java.util.logging.Level

class ClockGuardTransformer {
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ExpressionNegator expressionNegator = ExpressionNegator.INSTANCE
	
	protected final extension ExpressionSerializer expressionSerializer=ExpressionSerializer.INSTANCE
		protected final Logger logger = Logger.getLogger("GammaLogger")
	

	public static final ClockGuardTransformer INSTANCE = new ClockGuardTransformer

	def /*List<Expression>*/ splitByDisjunction(Expression guard) {
		try {
			val clone=guard.clone
			val preservedClone=guard.clone
			val res = clone.toDnf
			logger.log(Level.INFO, '''Before: «preservedClone.serialize»; After: «res.serialize»''')
		} catch (Exception e) {
		}
	}

	private dispatch def Expression toDnf(Expression exp) {
		throw new IllegalArgumentException("Unhandled parameter types: " + exp);
	}

	private dispatch def Expression toDnf(ReferenceExpression exp) {
		return exp
	}

	private dispatch def Expression toDnf(LiteralExpression exp) {
		return exp
	}

	private dispatch def Expression toDnf(PredicateExpression exp) {
		return exp
	}

	private dispatch def Expression toDnf(NotExpression expr) {
		val innerExpr = expr.operand

		// A => A
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
			return createOrExpression => [
				it.operands += innerExpr.operands.map [
					toDnf(it.negate)
				]
			]
		}

		// not (A or B) => (not A and not B)
		if (innerExpr instanceof OrExpression) {
			return createAndExpression => [
				it.operands += innerExpr.operands.map [
					toDnf(it.negate)
				]
			]
		}

		throw new IllegalArgumentException("Unhandled parameter types: " + expr);
	}

	private dispatch def Expression toDnf(AndExpression expr) {
		val operands = expr.operands.map[toDnf]

		return distributeAnd(operands)
	}
	
	private dispatch def Expression toDnf(OrExpression expr){
		val operands=expr.operands.map[toDnf]
		
		val flattenedOperands=operands.flatMap[
			if(it instanceof OrExpression){
				return it.operands
			}
			return #[it]
		]
		
		return createOrExpression=>[
			it.operands+=flattenedOperands
		]
	}

	/**
	 * This method may be used to distribute ANDs over ORs.
	 * 
	 * @param operands list of operands
	 * 
	 * @returns if distribution was necessary an `OrExpression`, otherwise an #[list.head]`AndExpression` 
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
}

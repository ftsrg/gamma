package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.statechart.model.TimeSpecification
import hu.bme.mit.gamma.statechart.model.TimeUnit
import java.math.BigInteger

class InPlaceExpressionTransformer {
	// Gamma factory for the millisecond multiplication
	protected final ExpressionModelFactory constrFactory = ExpressionModelFactory.eINSTANCE
		
	def convertToMs(TimeSpecification time) {
		switch (time.unit) {
			case SECOND: {
				val newValue = time.value.multiplyExpression(1000)
				// Maybe strange changing the S to MS in the View model 
				// New expression needs to be contained in a resource because of the expression trace mechanism) 
				// Somehow the tracing works, in a way that the original (1 s) expression is not changed
				time.value = newValue
				time.unit = TimeUnit.MILLISECOND
				newValue
			}
			case MILLISECOND:
				time.value
			default: 
				throw new IllegalArgumentException("Not known unit: " + time.unit)
		}
	}
	
	/**
	 * Transforms Gamma expression "100" into "100 * value" or "timeValue" into "timeValue * value"
	 */
	def multiplyExpression(Expression base, long value) {
		val multiplyExp = constrFactory.createMultiplyExpression => [
			it.operands += base
			it.operands += constrFactory.createIntegerLiteralExpression => [
				it.value = BigInteger.valueOf(value)
			]
		]
		return multiplyExp
	}
	
}
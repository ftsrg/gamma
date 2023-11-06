package hu.bme.mit.gamma.trace.testgeneration.c

import hu.bme.mit.gamma.expression.model.BooleanLiteralExpression
import hu.bme.mit.gamma.expression.model.DecimalLiteralExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.RationalLiteralExpression

class TypeSerializer {
	
	def String serialize(Expression expression) {
		throw new IllegalArgumentException("Not supported expression: " + expression);
	}
	
	def dispatch String serialize(IntegerLiteralExpression expression, String name) {
		return '''uint32_t'''
	}
	
		def dispatch String serialize(BooleanLiteralExpression type, String name) {
		return '''bool''';
	}

	def dispatch String serialize(DecimalLiteralExpression type, String name) {
		return '''float''';
	}

	def dispatch String serialize(RationalLiteralExpression type, String name) {
		return '''float''';
	}
	
	
}
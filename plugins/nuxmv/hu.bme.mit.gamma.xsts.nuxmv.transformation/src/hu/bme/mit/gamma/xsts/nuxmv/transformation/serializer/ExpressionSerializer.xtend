package hu.bme.mit.gamma.xsts.nuxmv.transformation.serializer

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression

class ExpressionSerializer extends hu.bme.mit.gamma.expression.util.ExpressionSerializer {
	// Singleton
	public static final ExpressionSerializer INSTANCE = new ExpressionSerializer
	protected new() {}
	//
	
	override String _serialize(EnumerationLiteralExpression expression) '''«expression.reference.name»'''
	
	override String serialize(Expression expression) {
		return super.serialize(expression)
	}
}
package hu.bme.mit.gamma.xsts.nuxmv.transformation.serializer

import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.OrExpression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.expression.model.XorExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression

class ExpressionSerializer extends hu.bme.mit.gamma.expression.util.ExpressionSerializer {
	// Singleton
	public static final ExpressionSerializer INSTANCE = new ExpressionSerializer
	protected new() {}
	//
	
	override String _serialize(EnumerationLiteralExpression expression) '''«expression.reference.name»'''
	
	override String serialize(Expression expression) {
		return super.serialize(expression)
	}
	
	override String _serialize(TrueExpression expression) {
		return "TRUE";
	}

	override String _serialize(FalseExpression expression) {
		return "FALSE";
	}
	
	override String _serialize(OrExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' | '»«operand.serialize»«ENDFOR»)'''

	override String _serialize(XorExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' xor '»«operand.serialize»«ENDFOR»)'''

	override String _serialize(AndExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' & '»«operand.serialize»«ENDFOR»)'''

	override String _serialize(EqualityExpression expression) '''(«expression.leftOperand.serialize» = «expression.rightOperand.serialize»)'''

}
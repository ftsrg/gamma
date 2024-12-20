package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.ImplyExpression
import hu.bme.mit.gamma.expression.model.OrExpression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.expression.model.XorExpression
import hu.bme.mit.gamma.statechart.statechart.PortEventReference

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.ocra.transformation.NamingSerializer.*


class OcraPropertyExpressionSerializer extends ThetaPropertyExpressionSerializer {
	
	new(AbstractReferenceSerializer referenceSerializer) {
		super(referenceSerializer)
	}
	
	override String serialize(Expression expression) {
		if (expression instanceof PortEventReference) {
			return expression.serializePortEventReferenceExpression
		}
		return super.serialize(expression)
	}
	
	def String serializePortEventReferenceExpression(PortEventReference expression) {
		val instance = expression.port.containingComponent
		val port = expression.port
		val event = expression.event
		return '''«event.customizePortName(port, instance)»'''
	}
	
	override String _serialize(TrueExpression expression) '''TRUE'''

	override String _serialize(FalseExpression expression) '''FALSE'''
	
	override String _serialize(OrExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' | '»«operand.serialize»«ENDFOR»)'''

	override String _serialize(XorExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' xor '»«operand.serialize»«ENDFOR»)'''

	override String _serialize(AndExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' & '»«operand.serialize»«ENDFOR»)'''

	override String _serialize(ImplyExpression expression) '''(«expression.leftOperand.serialize» -> «expression.rightOperand.serialize»)'''

	override String _serialize(EqualityExpression expression) '''(«expression.leftOperand.serialize» = «expression.rightOperand.serialize»)'''

	override String _serialize(IfThenElseExpression expression) '''((«expression.condition.serialize») ? («expression.then.serialize») : («expression.^else.serialize»))'''
	
	override String _serialize(ArrayAccessExpression arrayAccessExpression) '''READ(«arrayAccessExpression.operand.serialize», «arrayAccessExpression.index.serialize»)'''
	
	//override String _serialize(PortEventReference expression) '''«expression.event.customizePortName(expression.port, expression.containingComponent)»'''
	
	
}
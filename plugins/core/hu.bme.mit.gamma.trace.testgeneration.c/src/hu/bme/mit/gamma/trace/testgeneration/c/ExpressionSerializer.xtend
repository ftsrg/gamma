package hu.bme.mit.gamma.trace.testgeneration.c

import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.NotExpression
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.trace.model.RaiseEventAct

import static extension hu.bme.mit.gamma.trace.testgeneration.c.util.TestGeneratorUtil.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ExpressionSerializer {
	
	val ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	
	def dispatch String serialize(Expression expression, String name) {
		return expressionEvaluator.evaluate(expression).toString
	}
	
	def dispatch String serialize(RaiseEventAct expression, String name) {
		return '''«expression.port.name»_«expression.event.name»_Out(&statechart)'''
	}
	
	def dispatch String serialize(NotExpression expression, String name) {
		return '''!(«expression.operand.serialize(name)»)'''
	}
	
	def dispatch String serialize(EqualityExpression expression, String name) {
		return '''(«expression.leftOperand.serialize(name)» == «expression.rightOperand.serialize(name)»)'''
	}
	
	def dispatch String serialize(ComponentInstanceStateReferenceExpression expression, String name) {
		val state_name = expression.region.name.toLowerCase + "_"+ expression.instance.componentInstance.name.toLowerCase
		val state_type = expression.region.name.toLowerCase + "_"+ expression.instance.componentInstance.derivedType.name.toLowerCase
		return '''(statechart.«name.toLowerCase»statechart.«state_name» == «expression.state.name»_«state_type»)'''
	}
	
	def dispatch String serialize(ComponentInstanceVariableReferenceExpression expression, String name) {
		return '''statechart.«name.toLowerCase»statechart.«expression.variableDeclaration.name»_«expression.instance.componentInstance.name»'''
	}
	
	def dispatch String serialize(ArrayLiteralExpression expression, String name) {
		return '''(«expression.arrayType»«expression.arraySize»){«expression.operands.map[it.serialize(name)].join(', ')»}'''
	}
	
}
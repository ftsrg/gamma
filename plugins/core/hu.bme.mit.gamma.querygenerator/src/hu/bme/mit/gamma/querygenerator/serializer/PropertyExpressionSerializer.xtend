package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.property.model.ComponentInstanceEventParameterReference
import hu.bme.mit.gamma.property.model.ComponentInstanceEventReference
import hu.bme.mit.gamma.property.model.ComponentInstanceStateConfigurationReference
import hu.bme.mit.gamma.property.model.ComponentInstanceStateExpression
import hu.bme.mit.gamma.property.model.ComponentInstanceVariableReference
import hu.bme.mit.gamma.statechart.util.ExpressionSerializer
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance

class PropertyExpressionSerializer extends ExpressionSerializer {
	
	protected extension AbstractReferenceSerializer referenceSerializer
	
	new (AbstractReferenceSerializer referenceSerializer) {
		this.referenceSerializer = referenceSerializer
	}
	
	override String serialize(Expression expression) {
		if (expression instanceof ComponentInstanceStateExpression) {
			return expression.serializeStateExpression
		}
		return super.serialize(expression)
	}
	
	protected def dispatch serializeStateExpression(ComponentInstanceStateConfigurationReference expression) {
		val instance = expression.simpleInstance
		val region = expression.region
		val state = expression.state
		return '''«state.getId(region, instance)»'''
	}
	
	protected def dispatch serializeStateExpression(ComponentInstanceVariableReference expression) {
		val instance = expression.simpleInstance
		val variable = expression.variable
		return '''«variable.getId(instance)»'''
	}
	
	protected def dispatch serializeStateExpression(ComponentInstanceEventReference expression) {
		val instance = expression.simpleInstance
		val port = expression.port
		val event = expression.event
		// Could be extended with in-events too
		return '''«event.getId(port, instance)»'''
	}
	
	protected def dispatch serializeStateExpression(ComponentInstanceEventParameterReference expression) {
		val instance = expression.simpleInstance
		val port = expression.port
		val event = expression.event
		val parameter = expression.parameter
		// Could be extended with in-events too
		return '''«event.getId(port, parameter, instance)»'''
	}
	
	protected def getSimpleInstance(ComponentInstanceStateExpression expression) {
		return expression.instance.componentInstanceHierarchy.last as SynchronousComponentInstance
	}
	
}
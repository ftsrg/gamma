package hu.bme.mit.gamma.trace.testgeneration.java

import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.trace.model.Assert
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.Schedule
import java.util.List

import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

abstract class AbstractAssertionHandler {
	
	protected final int min
	protected final int max
	protected String schedule
	
	protected final ActAndAssertSerializer serializer
	protected final ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE
	
	new(ExecutionTrace trace, ActAndAssertSerializer serializer) {
		if (trace.hasAllowedWaitingAnnotation) {
			val waitingAnnotation = trace.allowedWaitingAnnotation
			this.min = evaluator.evaluateInteger(waitingAnnotation.lowerLimit)
			this.max = evaluator.evaluateInteger(waitingAnnotation.upperLimit)
		}
		else {
			this.min = -1
			this.max = -1
		}
		this.serializer = serializer
		val firstInstance = trace.steps.flatMap[it.actions].findFirst[it instanceof Schedule]
		if (firstInstance !== null) {
			this.schedule = serializer.serialize(firstInstance).toString
		} 
	}

	def abstract String generateAssertBlock(List<Assert> asserts)

}

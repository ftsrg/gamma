package hu.bme.mit.gamma.trace.testgeneration.java

import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.trace.model.Assert
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.ExecutionTraceAllowedWaitingAnnotation
import hu.bme.mit.gamma.trace.model.Schedule
import java.util.List

abstract class AbstractAllowedWaitingHandler {

	protected var int min

	protected var int max

	protected var String schedule

	protected val ActAndAssertSerializer serializer

	new(ExecutionTrace trace, ActAndAssertSerializer serializer) {
		val waitingAnnotation = trace.annotations.
			findFirst[it instanceof ExecutionTraceAllowedWaitingAnnotation] as ExecutionTraceAllowedWaitingAnnotation
		if (waitingAnnotation === null) {
			this.min = -1
			this.max = -1
		}
		else
		{
			val evaluator = ExpressionEvaluator.INSTANCE
			this.min = evaluator.evaluateInteger(waitingAnnotation.lowerLimit)
			this.max = evaluator.evaluateInteger(waitingAnnotation.upperLimit)
		}
		
		
		this.serializer = serializer
		val firstInstance = trace.steps.flatMap[it.actions].findFirst[it instanceof Schedule]
		if (firstInstance !== null) {
			this.schedule = serializer.serialize(firstInstance).toString
		} 
	}

	def abstract String generateAssertBlock(List<Assert> asserts)

}

package hu.bme.mit.gamma.trace.testgeneration.java

import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.ExecutionTraceAllowedWaitingAnnotation
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator

abstract class AbstractAllowedWaitingHandler {
	
	protected var int min
	
	protected var int max
	
	protected var String schedule
	
	protected var String asserts
	
	new(ExecutionTrace trace, String schedule, String asserts){
		val waitingAnnotation = trace.annotations.findFirst[it instanceof ExecutionTraceAllowedWaitingAnnotation] as ExecutionTraceAllowedWaitingAnnotation
		if(waitingAnnotation === null){
			throw(new IllegalArgumentException('''ExecutionTrace «trace.name» is not equiped with an AllowedWaiting annotation.'''))
		}
		val evaluator = ExpressionEvaluator.INSTANCE
		this.min = evaluator.evaluateInteger(waitingAnnotation.lowerLimit)
		this.schedule = schedule
		this.max = evaluator.evaluateInteger(waitingAnnotation.upperLimit)
		this.asserts = asserts
	}
	
		
	def abstract String generateAssertBlock()
	
	
}
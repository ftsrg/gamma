package hu.bme.mit.gamma.transformation.util.reducer

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.property.model.ComponentInstanceEventParameterReference
import hu.bme.mit.gamma.property.model.ComponentInstanceEventReference
import hu.bme.mit.gamma.property.model.ComponentInstanceStateConfigurationReference
import hu.bme.mit.gamma.property.model.ComponentInstanceStateExpression
import hu.bme.mit.gamma.property.model.ComponentInstanceVariableReference
import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.property.util.PropertyUtil
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration
import hu.bme.mit.gamma.trace.model.InstanceVariableState
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.transformation.util.SimpleInstanceHandler
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Collection

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class CoveredPropertyReducer {
	
	protected final Collection<StateFormula> formulas
	protected final ExecutionTrace trace
	
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	
	protected final extension PropertyUtil propertyUtil = PropertyUtil.INSTANCE
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension SimpleInstanceHandler instanceHandler = SimpleInstanceHandler.INSTANCE
	
	new(Collection<StateFormula> formulas, ExecutionTrace trace) {
		this.formulas = formulas
		this.trace = trace
	}
	
	def execute() {
		val unnecessaryFormulas = newArrayList
		for (formula : formulas) {
			val egLessFormula = formula.egLessFormula
			if (egLessFormula !== null) {
				val clonedFormula = egLessFormula.clone
				for (step : trace.steps) {
					for (instanceStateExpression : clonedFormula
							.getAllContentsOfType(ComponentInstanceStateExpression)) {
						val evaluation = instanceStateExpression.evaluate(step)
						evaluation.replace(instanceStateExpression)
						if (evaluation.isDefinitelyTrueExpression) {
							unnecessaryFormulas += formula
						}
					}
				}
			}
		}
		return unnecessaryFormulas
	}
	
	
	protected def dispatch evaluate(ComponentInstanceEventParameterReference expression, Step step) {
		val topComponentPort = expression.port.connectedTopComponentPort
		val event = expression.event
		val parameter = expression.parameter
		val parameterIndex = parameter.index
		
		for (raiseEventAct : step.outEvents) {
			val raisedPort = raiseEventAct.port
			val rasiedEvent = raiseEventAct.event
			val arguments = raiseEventAct.arguments
			if (topComponentPort.helperEquals(raisedPort) && event.helperEquals(rasiedEvent)) {
				return arguments.get(parameterIndex).clone
			}
		}
		return createFalseExpression
	}
	
	protected def dispatch evaluate(ComponentInstanceEventReference expression, Step step) {
		val topComponentPort = expression.port.connectedTopComponentPort
		val event = expression.event
		
		for (raiseEventAct : step.outEvents) {
			val raisedPort = raiseEventAct.port
			val rasiedEvent = raiseEventAct.event
			if (topComponentPort.helperEquals(raisedPort) && event.helperEquals(rasiedEvent)) {
				return createTrueExpression
			}
		}
		return createFalseExpression
	}
	
	protected def dispatch evaluate(ComponentInstanceStateConfigurationReference expression, Step step) {
		val instance = expression.instance
		val state = expression.state
		
		for (stateConfiguration : step.instanceStates.filter(InstanceStateConfiguration)) {
			val stateInstance = stateConfiguration.instance
			val stateVariable = stateConfiguration.state
			if (instance.contains(stateInstance) && state.helperEquals(stateVariable)) {
				return createTrueExpression
			}
		}
		return createFalseExpression
	}
	
	protected def dispatch evaluate(ComponentInstanceVariableReference expression, Step step) {
		val instance = expression.instance
		val variable = expression.variable
		
		for (variableState : step.instanceStates.filter(InstanceVariableState)) {
			val stateInstance = variableState.instance
			val stateVariable = variableState.declaration
			if (instance.contains(stateInstance) && variable.helperEquals(stateVariable)) {
				val value = variableState.value
				return value.clone
			}
		}
		throw new IllegalStateException('''Not found variable: «variable.name»''')
	}
		
}
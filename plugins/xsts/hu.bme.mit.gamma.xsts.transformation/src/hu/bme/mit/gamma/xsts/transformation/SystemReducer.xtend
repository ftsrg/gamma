package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.util.XSTSActionUtil

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class SystemReducer {
	// Singleton
	public static final SystemReducer INSTANCE =  new SystemReducer
	protected new() {}
	// Auxiliary objects
	protected extension GammaEcoreUtil expressionUtil = GammaEcoreUtil.INSTANCE
	protected extension XSTSActionUtil xStsActionUtil = XSTSActionUtil.INSTANCE
	
	def void deleteUnusedPorts(XSTS xSts, CompositeComponent component) {
		val xStsAssignmentActions = xSts.getAllContentsOfType(AssignmentAction) // Caching
		val xStsDeletableAssignmentActions = newHashSet
		val xStsDeletableVariables = newHashSet
		for (instance : component.derivedComponents) {
			for (instancePort : instance.unusedPorts) {
				// In events on required port
				for (inputEvent : instancePort.inputEvents) {
					val inEventName = inputEvent.customizeInputName(instancePort, instance)
					val xStsInEventVariable = xSts.getVariable(inEventName)
					if (xStsInEventVariable !== null) {
						xStsDeletableVariables += xStsInEventVariable
						xStsDeletableAssignmentActions += xStsInEventVariable.getAssignments(xStsAssignmentActions)
						// In-parameters - they can ba placed on transitions without trigger, so we do not delete them
//						for (parameter : inputEvent.parameterDeclarations) {
//							val inParamaterName = parameter.customizeInName(instancePort, instance)
//							val xStsInParameterVariable = xSts.getVariable(inParamaterName)
//							if (xStsInParameterVariable !== null) {
//								xStsDeletableVariables += xStsInParameterVariable
//								xStsDeletableAssignmentActions += xStsInParameterVariable.getAssignments(xStsAssignmentActions)
//							}
//						}
					}
				}
				for (outputEvent : instancePort.outputEvents) {
					val outEventName = outputEvent.customizeOutputName(instancePort, instance)
					val xStsOutEventVariable = xSts.getVariable(outEventName)
					if (xStsOutEventVariable !== null) {
						xStsDeletableVariables += xStsOutEventVariable
						xStsDeletableAssignmentActions += xStsOutEventVariable.getAssignments(xStsAssignmentActions)
						// Out-parameters
						for (parameter : outputEvent.parameterDeclarations) {
							val inParamaterName = parameter.customizeOutName(instancePort, instance)
							val xStsOutParameterVariable = xSts.getVariable(inParamaterName)
							if (xStsOutParameterVariable !== null) {
								xStsDeletableVariables += xStsOutParameterVariable
								xStsDeletableAssignmentActions += xStsOutParameterVariable.getAssignments(xStsAssignmentActions)
							}
						}
					}
				}
			}
		}
		for (xStsDeletableAssignmentAction : xStsDeletableAssignmentActions) {
			xStsDeletableAssignmentAction.remove // To speed up the process
		}
		for (xStsDeletableVariable : xStsDeletableVariables) {
			xStsDeletableVariable.delete // Delete needed due to e.g., transientVariables list
		}
	}
	
}
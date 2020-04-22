package hu.bme.mit.gamma.statechart.phase.transformation

import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.phase.MissionPhaseStateAnnotation
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import org.eclipse.emf.ecore.util.EcoreUtil.UsageCrossReferencer

import static com.google.common.base.Preconditions.checkState

import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import hu.bme.mit.gamma.statechart.model.StatechartModelFactory

class PhaseStatechartToStatechartTransformer {
	
	extension StatechartUtil statechartUtil = new StatechartUtil
	extension StatechartModelFactory statechartModelFactory = StatechartModelFactory.eINSTANCE
	
	def execute(StatechartDefinition phaseStatechart) {
		val statechart = phaseStatechart.clone(true, true)
		// These should be repeated from "bottom-up"
		val phaseStates = statechart.getAllContents(true).filter(State)
				.filter[it.annotation instanceof MissionPhaseStateAnnotation].toList
		for (phaseState : phaseStates) {
			val annotation = phaseState.annotation as MissionPhaseStateAnnotation
			annotation.remove
			val stateDefinitions = annotation.stateDefinitions
			for (stateDefinition : stateDefinitions) {
				val component = stateDefinition.component
				val inlineableStatechart = component.type.clone(true, true) as StatechartDefinition
				val boundVariables = newHashSet
				// Resetting bound variable references
				for (variableBinding : stateDefinition.variableBindings) {
					val statechartVariable = variableBinding.statechartVariable
					val originalVariable = variableBinding.instanceVariableReference.variable
					val variableCopies = inlineableStatechart.variableDeclarations
							.filter[it.helperEquals(originalVariable)]
					checkState(variableCopies.size == 1, variableCopies)
					val variableCopy = variableCopies.head
					val variableReferences = UsageCrossReferencer.find(variableCopy, inlineableStatechart)
					for (variableReference : variableReferences) {
						variableReference.set(statechartVariable)
					}
				}
				// Adding not bound variables to the parent statechart
				for (unboundVariable : inlineableStatechart.variableDeclarations.filter[!boundVariables.contains(it)]) {
					unboundVariable.name = unboundVariable.name + "Of" + component.name
					statechart.variableDeclarations += unboundVariable
				}
				// Resetting bound port references				
				for (portBinding : stateDefinition.portBindings) {
					val statechartPort = portBinding.compositeSystemPort
					val originalPort = portBinding.instancePortReference.port
					val portCopies = inlineableStatechart.ports.filter[it.helperEquals(originalPort)]
					checkState(portCopies.size == 1, portCopies)
					val portCopy = portCopies.head
					val portReferences = UsageCrossReferencer.find(portCopy, inlineableStatechart)
					for (portReference : portReferences) {
						portReference.set(statechartPort)
					}
				}
				// Inlining regions
				val history = stateDefinition.history
				for (statechartRegion : inlineableStatechart.regions) {
					phaseState.regions += statechartRegion
					// Replacing entry node
					
				}
				
			}
		}
	}
	
}
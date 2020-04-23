package hu.bme.mit.gamma.statechart.phase.transformation

import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.StatechartModelFactory
import hu.bme.mit.gamma.statechart.model.composite.PortBinding
import hu.bme.mit.gamma.statechart.model.phase.History
import hu.bme.mit.gamma.statechart.model.phase.MissionPhaseStateAnnotation
import hu.bme.mit.gamma.statechart.model.phase.VariableBinding
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.phase.transformation.Namings.*
import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.expression.model.ReferenceExpression

class PhaseStatechartToStatechartTransformer {
	
	extension StatechartUtil statechartUtil = new StatechartUtil
	extension StatechartModelFactory statechartModelFactory = StatechartModelFactory.eINSTANCE
	
	def execute(StatechartDefinition phaseStatechart) {
		val statechart = phaseStatechart.clone(true, true)
		val checkedAnnotations = newHashSet
		var annotations = statechart.getAllMissionPhaseStateAnnotations
		while (!checkedAnnotations.containsAll(annotations)) {
			for (annotation : annotations.reject[checkedAnnotations.contains(it)]) {
				val stateDefinitions = annotation.stateDefinitions
				for (stateDefinition : stateDefinitions) {
					val component = stateDefinition.component
					val inlineableStatechart = component.type.clone(true, true) as StatechartDefinition
					for (portBinding : stateDefinition.portBindings) {
						portBinding.inlinePorts(inlineableStatechart)
					}
					for (variableBinding : stateDefinition.variableBindings) {
						variableBinding.inlineVariables(inlineableStatechart)
					}
					component.inlineParameters(inlineableStatechart)
					statechart.inlineRemainingStatechart(inlineableStatechart, stateDefinition.history)
				}
				checkedAnnotations += annotation
			}
			annotations = statechart.allMissionPhaseStateAnnotations
		}
		//
		for (annotation : annotations) {
			val stateDefinitions = annotation.stateDefinitions
			for (stateDefinition : stateDefinitions) {
				for (portBinding : stateDefinition.portBindings) {
					val port = portBinding.compositeSystemPort
					val removeablePort = portBinding.instancePortReference.port
					port.change(removeablePort, statechart)
				}
				for (variableBinding : stateDefinition.variableBindings) {
					val variable = variableBinding.statechartVariable
					val removeableVariable = variableBinding.instanceVariableReference.variable
					variable.change(removeableVariable, statechart)
				}
			}
			annotation.remove
		}
		return statechart
	}
	
	private def List<MissionPhaseStateAnnotation> getAllMissionPhaseStateAnnotations(StatechartDefinition statechart) {
		return statechart.getAllContents(true).filter(State).map[it.annotation]
				.filter(MissionPhaseStateAnnotation).toList
	}
	
	private def void inlinePorts(PortBinding portBinding, StatechartDefinition inlineableStatechart) {
		val statechart = portBinding.containingStatechart
		val originalPort = portBinding.instancePortReference.port
		val portCopies = inlineableStatechart.ports.filter[it.helperEquals(originalPort)]
		checkState(portCopies.size == 1, portCopies)
		val portCopy = portCopies.head
		portBinding.instancePortReference.port = portCopy
		statechart.ports += inlineableStatechart.ports
	}
	
	private def void inlineVariables(VariableBinding variableBinding, StatechartDefinition inlineableStatechart) {
		val statechart = variableBinding.containingStatechart
		val originalVariable = variableBinding.instanceVariableReference.variable
		val instance = variableBinding.instanceVariableReference.instance
		val variableCopies = inlineableStatechart.variableDeclarations.filter[it.helperEquals(originalVariable)]
		checkState(variableCopies.size == 1, variableCopies)
		val variableCopy = variableCopies.head
		variableCopy.name = variableCopy.getName(instance)
		variableBinding.instanceVariableReference.variable = variableCopy
		statechart.variableDeclarations += inlineableStatechart.variableDeclarations
	}
	
	private def void inlineParameters(SynchronousComponentInstance instance, StatechartDefinition inlineableStatechart) {
		val parameters = inlineableStatechart.parameterDeclarations
		for (var i = 0; i < parameters.size; i++) {
			val parameter = parameters.get(i)
			for (reference : inlineableStatechart.getAllContents(true).filter(ReferenceExpression)
					.filter[it.declaration === parameter].toList) {
				val argument = instance.arguments.get(i)
				reference.replace(argument)
			}
		}
		
	}
	
	private def void inlineRemainingStatechart(StatechartDefinition statechart, StatechartDefinition inlineableStatechart, History history) {
		val inlineableRegions = inlineableStatechart.regions
		for (inlineableRegion : inlineableRegions) {
			val newEntryState = switch (history) {
				case NO_HISTORY: {
					createInitialState
				}
				case SHALLOW_HISTORY : {
					createShallowHistoryState
				}
				case DEEP_HISTORY : {
					createDeepHistoryState
				}
			}
			inlineableRegion.stateNodes += newEntryState
			val oldEntryState = inlineableRegion.entryState
			newEntryState.change(oldEntryState, inlineableStatechart)
		}
		statechart.transitions += inlineableStatechart.transitions
		statechart.timeoutDeclarations += inlineableStatechart.timeoutDeclarations
	}
	
}
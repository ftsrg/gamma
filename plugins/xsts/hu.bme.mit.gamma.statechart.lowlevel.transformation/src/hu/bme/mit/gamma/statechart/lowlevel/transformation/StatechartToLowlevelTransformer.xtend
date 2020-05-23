package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.action.model.util.ActionUtil
import hu.bme.mit.gamma.expression.model.ElseExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.Component
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.StateNode
import hu.bme.mit.gamma.statechart.lowlevel.model.StatechartModelFactory
import hu.bme.mit.gamma.statechart.model.Package
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.PseudoState
import hu.bme.mit.gamma.statechart.model.RealizationMode
import hu.bme.mit.gamma.statechart.model.Region
import hu.bme.mit.gamma.statechart.model.SchedulingOrder
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.TimeoutDeclaration
import hu.bme.mit.gamma.statechart.model.Transition
import hu.bme.mit.gamma.statechart.model.TransitionPriority
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class StatechartToLowlevelTransformer {
	// Auxiliary objects
	protected final extension ActionUtil actionUtil = new ActionUtil
	protected final extension EventAttributeTransformer eventAttributeTransformer = new EventAttributeTransformer
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension ActionTransformer actionTransformer
	protected final extension TriggerTransformer triggerTransformer
	protected final extension PseudoStateTransformer pseudoStateTransformer
	// Low-level statechart model factory
	protected final extension StatechartModelFactory factory = StatechartModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActionModelFactory actionFactory = ActionModelFactory.eINSTANCE
	// Trace object for storing the mappings
	protected final Trace trace

	new() {
		this.trace = new Trace
		this.expressionTransformer = new ExpressionTransformer(this.trace)
		this.actionTransformer = new ActionTransformer(this.trace)
		this.triggerTransformer = new TriggerTransformer(this.trace)
		this.pseudoStateTransformer = new PseudoStateTransformer(this.trace)
	}

	def hu.bme.mit.gamma.statechart.lowlevel.model.Package execute(Package _package) {
		return _package.transform
	}
	
	def hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition execute(StatechartDefinition statechart) {
		return statechart.transformComponent as hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition
	}

	protected def hu.bme.mit.gamma.statechart.lowlevel.model.Package transform(Package _package) {
		if (trace.isMapped(_package)) {
			// It is already transformed
			return trace.get(_package)
		}
		val lowlevelPackage = createPackage => [
			it.name = _package.name
		]
		trace.put(_package, lowlevelPackage) // Saving in trace
		for (typeDeclaration : _package.typeDeclarations
				.reject[it.type.isPrimitive] /* Not serializing "typedefs" */) {
			lowlevelPackage.typeDeclarations += typeDeclaration.transform
		}
		for (_import : _package.imports) {
			lowlevelPackage.imports += _import.transform
		}
		return lowlevelPackage
	}
	
	protected def transform(TypeDeclaration typeDeclaration) {
		val newTypeDeclaration = constraintFactory.create(typeDeclaration.eClass) as TypeDeclaration => [
			it.name = typeDeclaration.name
			it.type = typeDeclaration.type.transformType
		]
		trace.put(typeDeclaration, newTypeDeclaration)
		return newTypeDeclaration
	}
	
	protected def VariableDeclaration transform(ParameterDeclaration gammaParameter) {
		// Cloning the variable
		val lowlevelVariable = createVariableDeclaration => [
			it.name = gammaParameter.name
			it.type = gammaParameter.type.transformType
		]
		trace.put(gammaParameter, lowlevelVariable)
		return lowlevelVariable
	}

	protected def VariableDeclaration transform(VariableDeclaration variable) {
		// Cloning the variable
		val lowlevelVariable = variable.transformVariable
		trace.put(variable, lowlevelVariable)
		return lowlevelVariable
	}

	/**
	 * Returns a list, as an INOUT declaration is mapped to an IN and an OUT declaration.
	 */
	protected def List<EventDeclaration> transform(hu.bme.mit.gamma.statechart.model.interface_.EventDeclaration declaration, Port gammaPort) {
		val gammaDirection = declaration.direction
		val realizationMode = gammaPort.interfaceRealization.realizationMode
		if (gammaDirection == EventDirection.IN &&
				realizationMode == RealizationMode.PROVIDED ||
				gammaDirection == EventDirection.OUT &&
				realizationMode == RealizationMode.REQUIRED) {
			// Event coming in
			val lowlevelEventIn = declaration.event.transform(gammaPort, EventDirection.IN)
			trace.put(gammaPort, declaration, lowlevelEventIn) // Tracing the EventDeclaration
			trace.put(gammaPort, declaration.event, lowlevelEventIn) // Tracing the Event
			return #[lowlevelEventIn]
		}
		else if	(gammaDirection == EventDirection.IN &&
				realizationMode == RealizationMode.REQUIRED ||
				gammaDirection == EventDirection.OUT &&
				realizationMode == RealizationMode.PROVIDED) {
			// Events going out
			val lowlevelEventOut = declaration.event.transform(gammaPort, EventDirection.OUT)
			trace.put(gammaPort, declaration, lowlevelEventOut) // Tracing the EventDeclaration
			trace.put(gammaPort, declaration.event, lowlevelEventOut) // Tracing the Event
			return #[lowlevelEventOut]
		}
		else {
			// In-out events
			checkState(gammaDirection == EventDirection.INOUT)
			val lowlevelEventIn = declaration.event.transform(gammaPort, EventDirection.IN)
			trace.put(gammaPort, declaration, lowlevelEventIn) // Tracing the EventDeclaration
			val lowlevelEventOut = declaration.event.transform(gammaPort, EventDirection.OUT)
			trace.put(gammaPort, declaration, lowlevelEventOut) // Tracing the EventDeclaration
			return #[lowlevelEventIn, lowlevelEventOut]
		}
	}

	protected def EventDeclaration transform(Event gammaEvent, Port gammaPort, EventDirection direction) {
		checkState(direction == EventDirection.IN || direction == EventDirection.OUT)
		val lowlevelEvent = createEventDeclaration => [
			it.name = if (direction == EventDirection.IN) gammaEvent.getInputName(gammaPort) else gammaEvent.getOutputName(gammaPort)
			it.persistency = gammaEvent.persistency.transform
			it.direction = direction.transform
			it.isRaised = createVariableDeclaration => [
				it.name = "isRaised"
				it.type = createBooleanTypeDefinition
			]
		]
		trace.put(gammaPort, gammaEvent, lowlevelEvent)
		// Transforming the parameters
		for (gammaParam : gammaEvent.parameterDeclarations) {
			val lowlevelParam = createVariableDeclaration => [
				it.name = if (direction == EventDirection.IN) gammaParam.getInName(gammaPort) else gammaParam.getOutName(gammaPort)
				it.type = gammaParam.type.transformType
			]
			lowlevelEvent.parameters += lowlevelParam
			trace.put(gammaPort, gammaEvent, gammaParam, lowlevelEvent.direction, lowlevelParam)
		}
		return lowlevelEvent
	}

	protected def VariableDeclaration transform(TimeoutDeclaration timeout) {
		val lowlevelTimeout = createVariableDeclaration => [
			it.name = timeout.name
			it.type = createIntegerTypeDefinition // Could be rational
		]
		trace.put(timeout, lowlevelTimeout)
		return lowlevelTimeout
	}

	protected def getEvents(Port port) {
		return port.interfaceRealization.interface.events
	}

	protected def dispatch Component transformComponent(hu.bme.mit.gamma.statechart.model.composite.Component component) {
		throw new IllegalArgumentException("Not known component: " + component)
	}

	protected def dispatch Component transformComponent(StatechartDefinition statechart) {
		if (trace.isMapped(statechart)) {
			// It is already transformed
			return trace.get(statechart)
		}
		val lowlevelStatechart = createStatechartDefinition => [
			it.name = statechart.name
			it.schedulingOrder = statechart.schedulingOrder.transform
		]
		trace.put(statechart, lowlevelStatechart) // Saving in trace
		// No parameter declarations mapping
		for (parameterDeclaration : statechart.parameterDeclarations) {
			val lowlevelParameterDeclaration = parameterDeclaration.transform
			lowlevelStatechart.variableDeclarations += lowlevelParameterDeclaration
			lowlevelStatechart.parameterDeclarations += lowlevelParameterDeclaration
		}
		for (variableDeclaration : statechart.variableDeclarations) {
			lowlevelStatechart.variableDeclarations += variableDeclaration.transform
		}
		for (timeoutDeclaration : statechart.timeoutDeclarations) {
			// Timeout declarations are transformed to integer variable declarations
			val lowlevelTimeoutDeclaration = timeoutDeclaration.transform
			lowlevelStatechart.variableDeclarations += lowlevelTimeoutDeclaration
			lowlevelStatechart.timeoutDeclarations += lowlevelTimeoutDeclaration
		}
		for (port : statechart.ports) {
			// Both in and out events are transformed to a boolean VarDecl with additional parameters
			for (eventDecl : port.events) {
				lowlevelStatechart.eventDeclarations += eventDecl.transform(port)
			}
		}
		for (region : statechart.regions) {
			lowlevelStatechart.regions += region.transform
		}
		for (transition : statechart.transitions) {
			val lowlevelTransition = transition.transform
			lowlevelStatechart.transitions += lowlevelTransition
		}
		// Prioritizing transitions
		if (statechart.transitionPriority != TransitionPriority.OFF) {
			statechart.prioritizeTransitions
		}
		return lowlevelStatechart
	}

	protected def hu.bme.mit.gamma.statechart.lowlevel.model.SchedulingOrder transform(SchedulingOrder order) {
		switch (order) {
			case SchedulingOrder.BOTTOM_UP: {
				return hu.bme.mit.gamma.statechart.lowlevel.model.SchedulingOrder.BOTTOM_UP
			}
			case SchedulingOrder.TOP_DOWN: {
				return hu.bme.mit.gamma.statechart.lowlevel.model.SchedulingOrder.TOP_DOWN
			}
			default: {
				throw new IllegalArgumentException("Not known scheduling order: " + order)
			}
		}
	}

	protected def hu.bme.mit.gamma.statechart.lowlevel.model.Region transform(Region region) {
		val lowlevelRegion = createRegion => [
			it.name = region.regionName
		]
		trace.put(region, lowlevelRegion)
		// Transforming normal nodes
		for (stateNode : region.stateNodes.filter(State)) {
			lowlevelRegion.stateNodes += stateNode.transformNode
		}
		// Transforming abstract transition nodes
		for (pseudoState : region.stateNodes.filter(PseudoState)) {
			lowlevelRegion.stateNodes += pseudoState.transformPseudoState
		}
		return lowlevelRegion
	}
	
	protected def StateNode transformNode(State state) {
		val lowlevelState = createState => [
			it.name = state.stateName
		]
		trace.put(state, lowlevelState)
		// Transforming regions
		for (region : state.regions) {
			lowlevelState.regions += region.transform
		}
		// Entry and exit actions
		lowlevelState.entryAction = state.entryActions.transformActions
		lowlevelState.exitAction = state.exitActions.transformActions
		return lowlevelState
	}

	protected def hu.bme.mit.gamma.statechart.lowlevel.model.Transition transform(Transition gammaTransition) {
		// Trivial simple transitions
		val gammaSource = gammaTransition.sourceState
		val gammaTarget = gammaTransition.targetState
		val lowlevelSource = if (gammaSource instanceof State) {
			trace.get(gammaSource)
		} else if (gammaSource instanceof PseudoState) {
			trace.get(gammaSource)
		}
		val lowlevelTarget = if (gammaTarget instanceof State) {
			trace.get(gammaTarget)
		} else if (gammaTarget instanceof PseudoState) {
			trace.get(gammaTarget)
		}
		val lowlevelTransition = createTransition => [
			it.source = lowlevelSource
			it.target = lowlevelTarget
		]
		trace.put(gammaTransition, lowlevelTransition) // Saving in trace
		// Important to trace the Gamma transition as the trigger transformer depends on it
		val lowlevelGuard = gammaTransition.transformTriggerAndGuard
		val lowlevelAction = gammaTransition.effects.transformActions
		lowlevelTransition => [
			it.guard = lowlevelGuard
			it.action = lowlevelAction
		]
		return lowlevelTransition
	}
	
	/**
	 * Can return null.
	 */
	protected def Expression transformTriggerAndGuard(Transition transition) {
		val lowlevelGuardList = newLinkedList
		if (transition.trigger !== null) {
			lowlevelGuardList += transition.trigger.transformTrigger // Trigger guard
		}
		var guard = transition.guard
		if (guard !== null) {
			// Transforming else expressions
			if (guard instanceof ElseExpression) {
				val source = transition.sourceState
				val andExpression = createAndExpression => [
					for (otherGuard : source.outgoingTransitions
											.reject[it === transition]
											.map[it.guard]) {
						it.operands += createNotExpression => [
							it.operand = otherGuard.clone
						]
					}
				]
				guard = andExpression
			}
			lowlevelGuardList += guard.transformExpression // Guard
		}
		if (lowlevelGuardList.empty) {
			return null
		}
		if (lowlevelGuardList.size == 1) {
			// Only one expression is on the transition
			return lowlevelGuardList.head
		}
		// The expressions are in an AND relation
		return createAndExpression => [
			it.operands += lowlevelGuardList
		]
	}
	
	protected def prioritizeTransitions(StatechartDefinition statechart) {
		for (gammaTransition : statechart.transitions) {
			val lowlevelTransition = trace.get(gammaTransition)
			val lowlevelSource = lowlevelTransition.source
			if (lowlevelSource instanceof hu.bme.mit.gamma.statechart.lowlevel.model.State) {
				val newGuardExpression = createAndExpression
				for (prioritizedTransition : gammaTransition.prioritizedTransitions) {
					newGuardExpression.operands += createNotExpression => [
						it.operand = prioritizedTransition.transformTriggerAndGuard // New expression
					]
				}
				// New guard
				if (!newGuardExpression.operands.empty) {
					lowlevelTransition.guard = newGuardExpression => [
						it.operands += lowlevelTransition.guard // No clone here
					]
				}
			}
		}
	}
	
	protected def getPrioritizedTransitions(Transition gammaTransition) {
		val gammaStatechart = gammaTransition.containingStatechart
		val transitionPriority = gammaStatechart.transitionPriority
		val gammaOutgoingTransitions = gammaTransition.sourceState.outgoingTransitions
		val prioritizedTransitions = newLinkedList
		switch (transitionPriority) {
			case OFF: {
				// No operation
			}
			case ORDER_BASED : {
				for (gammaOutgoingTransition : gammaOutgoingTransitions) {
					if (gammaOutgoingTransitions.indexOf(gammaOutgoingTransition) < 
							gammaOutgoingTransitions.indexOf(gammaTransition)) {
						prioritizedTransitions += gammaOutgoingTransition
					}
				}
			}
			case VALUE_BASED : {
				for (gammaOutgoingTransition : gammaOutgoingTransitions) {
					if (gammaOutgoingTransition.priority > gammaTransition.priority) {
						prioritizedTransitions += gammaOutgoingTransition
					}
				}
			}
			default: {
				throw new IllegalArgumentException("Not known priority enum literal: " + transitionPriority)
			}
		}
		return prioritizedTransitions
	}

}
	
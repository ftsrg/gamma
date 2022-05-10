package hu.bme.mit.gamma.scenario.statechart.generator

import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.scenario.model.Delay
import hu.bme.mit.gamma.scenario.model.InteractionDefinition
import hu.bme.mit.gamma.scenario.model.InteractionDirection
import hu.bme.mit.gamma.scenario.model.ModalInteractionSet
import hu.bme.mit.gamma.scenario.model.NegatedModalInteraction
import hu.bme.mit.gamma.scenario.model.ScenarioCheckExpression
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration
import hu.bme.mit.gamma.scenario.model.ScenarioModelFactory
import hu.bme.mit.gamma.scenario.model.Signal
import hu.bme.mit.gamma.scenario.statechart.util.ScenarioStatechartUtil
import hu.bme.mit.gamma.statechart.contract.ContractModelFactory
import hu.bme.mit.gamma.statechart.contract.NotDefinedEventMode
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification
import hu.bme.mit.gamma.statechart.interface_.TimeUnit
import hu.bme.mit.gamma.statechart.interface_.Trigger
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger
import hu.bme.mit.gamma.statechart.statechart.BinaryType
import hu.bme.mit.gamma.statechart.statechart.ChoiceState
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger
import hu.bme.mit.gamma.statechart.statechart.UnaryType
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import java.util.List
import java.util.Map

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import hu.bme.mit.gamma.scenario.model.ScenarioAssignmentStatement

abstract class AbstractContractStatechartGeneration {

	protected val extension StatechartModelFactory statechartfactory = StatechartModelFactory.eINSTANCE
	protected val extension ScenarioModelFactory scenariofactory = ScenarioModelFactory.eINSTANCE
	protected val extension ExpressionModelFactory expressionfactory = ExpressionModelFactory.eINSTANCE
	protected val extension InterfaceModelFactory interfacefactory = InterfaceModelFactory.eINSTANCE
	protected val extension ActionModelFactory actionfactory = ActionModelFactory.eINSTANCE
	protected val extension ContractModelFactory contractfactory = ContractModelFactory.eINSTANCE
	protected val extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected val extension ExpressionEvaluator exprEval = ExpressionEvaluator.INSTANCE
	protected val extension ExpressionUtil exprUtil = ExpressionUtil.INSTANCE
	protected val extension ScenarioStatechartUtil scenarioStatechartUtil = ScenarioStatechartUtil.INSTANCE
	protected val StatechartUtil statechartUtil = StatechartUtil.INSTANCE

	protected val JavaUtil javaUtil = JavaUtil.INSTANCE

	protected var Component component = null
	protected var ScenarioDeclaration scenario = null
	protected var StatechartDefinition statechart = null
	protected val Map<String, VariableDeclaration> variableMap = <String, VariableDeclaration>newHashMap
	protected var exsistingChoices = 0
	protected var exsistingMerges = 0
	protected var stateCount = 0
	protected var timeoutCount = 0
	protected var Region firstRegion = null
	protected var StateNode previousState = null
	protected var State hotViolation = null
	protected var State coldViolation = null
	protected val Map<StateNode, StateNode> replacedStateWithValue = <StateNode, StateNode>newHashMap

	def abstract StatechartDefinition execute()

	new(ScenarioDeclaration scenario, Component component) {
		this.component = component
		this.scenario = scenario
	}

	def VariableDeclaration getOrCreate(Map<String, VariableDeclaration> map, String string) {
		val result = map.get(string)
		if (result !== null) {
			return result
		} else {
			val newVariable = createIntegerVariable(string)
			variableMap.put(string, newVariable)
			statechart.variableDeclarations += newVariable
			return newVariable
		}
	}

	def protected addPorts(Component component) {
		for (port : component.ports) {
			val pcopy = createPort
			val iReali = createInterfaceRealization
			iReali.realizationMode = port.interfaceRealization.realizationMode
			iReali.interface = port.interfaceRealization.interface
			pcopy.interfaceRealization = iReali
			pcopy.name = port.name
			statechart.ports += pcopy
			val preverse = createPort
			preverse.name = scenarioStatechartUtil.getTurnedOutPortName(port)
			val iRealiR = createInterfaceRealization
			iRealiR.interface = port.interfaceRealization.interface
			iRealiR.realizationMode = port.interfaceRealization.realizationMode.opposite
			preverse.interfaceRealization = iRealiR
			statechart.ports += preverse
		}
	}

	protected def addScenarioContractAnnotation(NotDefinedEventMode mode) {
		val annotation = createScenarioContractAnnotation
		annotation.monitoredComponent = component
		annotation.scenarioType = mode
		statechart.annotations += annotation
	}

///////// Create Set and Check Variables
	protected def AssignmentStatement incrementVar(VariableDeclaration variable) {
		var assign = createAssignmentStatement
		var addition = createAddExpression
		addition.operands += exprUtil.createReferenceExpression(variable)
		addition.operands += exprUtil.toIntegerLiteral(1)
		assign.rhs = addition
		assign.lhs = exprUtil.createReferenceExpression(variable)
		return assign
	}

	def protected VariableDeclaration createIntegerVariable(String name) {
		return exprUtil.createVariableDeclaration(createIntegerTypeDefinition, name, exprUtil.toIntegerLiteral(0))
	}

	protected def setIntVariable(VariableDeclaration variable, int value) {
		var variableAssignment = createAssignmentStatement
		variableAssignment.lhs = exprUtil.createReferenceExpression(variable)
		variableAssignment.rhs = exprUtil.toIntegerLiteral(value)
		return variableAssignment
	}

	def protected Expression getVariableLessEqualParamExpression(VariableDeclaration variable, int maxValue) {
		var maxCheck = createLessEqualExpression
		maxCheck.leftOperand = exprUtil.createReferenceExpression(variable)
		maxCheck.rightOperand = exprUtil.toIntegerLiteral(maxValue)
		return maxCheck
	}

	def protected Expression getVariableGreaterEqualParamExpression(VariableDeclaration variable, int minValue) {
		var minCheck = createGreaterEqualExpression
		minCheck.leftOperand = exprUtil.createReferenceExpression(variable)
		minCheck.rightOperand = exprUtil.toIntegerLiteral(minValue)
		return minCheck
	}

	def protected Expression getVariableInIntervalExpression(VariableDeclaration variable, int minV, int maxV) {
		var and = createAndExpression
		and.operands += getVariableGreaterEqualParamExpression(variable, minV)
		and.operands += getVariableLessEqualParamExpression(variable, maxV)
		return and
	}

//////// Create Binary and negate triggers
	def protected void negateBinaryTree(BinaryTrigger binaryTrigger) {
		val right = binaryTrigger.rightOperand
		val left = binaryTrigger.leftOperand
		if (right instanceof EventTrigger) {
			binaryTrigger.rightOperand = negateEventTrigger(right)
		}
		if (left instanceof EventTrigger) {
			binaryTrigger.leftOperand = negateEventTrigger(left)
		}
		if (left instanceof BinaryTrigger) {
			negateBinaryTree(left)
		}
		if (right instanceof BinaryTrigger) {
			negateBinaryTree(right)
		}
	}

	def protected Trigger negateEventTrigger(Trigger trigger) {
		if (trigger instanceof UnaryTrigger) {
			if (trigger.type == UnaryType.NOT) {
				return trigger.operand
			}
		}
		var negated = createUnaryTrigger
		negated.type = UnaryType.NOT
		negated.operand = trigger
		return negated
	}

	def protected BinaryTrigger getBinaryTriggerFromTriggers(List<Trigger> triggers, BinaryType type) {
		val binaryTrigger = createBinaryTrigger
		binaryTrigger.type = type
		var runningbin = binaryTrigger
		var signalCount = 0
		for (trigger : triggers) {
			signalCount++
			if (runningbin.leftOperand === null) {
				runningbin.leftOperand = trigger
			} else if (signalCount == triggers.size) {
				runningbin.rightOperand = trigger
			} else {
				var newbin = createBinaryTrigger
				runningbin.rightOperand = newbin
				newbin.type = type
				runningbin = newbin
				runningbin.leftOperand = trigger
			}
		}
		return binaryTrigger
	}

	def protected BinaryTrigger getAllEvents(BinaryType type) {
		var bin = createBinaryTrigger
		bin.type = type
		var ports = statechart.ports.filter[!it.inputEvents.empty]
		var size = ports.size
		var runningbin = bin
		var signalCount = 0
		for (i : 0 ..< size) {
			signalCount++
			var ref = createAnyPortEventReference
			ref.port = ports.get(i)
			var trigger = createEventTrigger
			trigger.eventReference = ref
			if (runningbin.leftOperand === null)
				runningbin.leftOperand = trigger
			else if (signalCount == size) {
				runningbin.rightOperand = trigger
			} else {
				var newbin = createBinaryTrigger
				runningbin.rightOperand = newbin
				newbin.type = type
				runningbin = newbin
				runningbin.leftOperand = trigger
			}
		}
		return bin
	}

	protected def List<Trigger> createOtherNegatedTriggers(ModalInteractionSet set) {
		val triggers = <Trigger>newArrayList
		val ports = newArrayList
		val events = newArrayList
		val allPorts = statechart.ports.filter[!it.inputEvents.empty]
		for (modalInteraction : set.modalInteractions) {
			var Signal signal = null
			if (modalInteraction instanceof Signal) {
				signal = modalInteraction
			} else if (modalInteraction instanceof NegatedModalInteraction) {
				val innerModalInteraction = modalInteraction.modalinteraction
				if (innerModalInteraction instanceof Signal) {
					signal = innerModalInteraction
				}
			}
			if (signal !== null) {
				val portName = signal.direction == InteractionDirection.SEND
						? scenarioStatechartUtil.getTurnedOutPortName(signal.port)
						: signal.port.name
				ports += getPort(portName)
				events += getEvent(signal.event.name, getPort(portName))
			}
		}
		for (port : allPorts) {
			if (!ports.contains(port)) {
				val anyPortEvent = createAnyPortEventReference
				anyPortEvent.port = port
				val trigger = createEventTrigger
				trigger.eventReference = anyPortEvent
				val unary = createUnaryTrigger
				unary.operand = trigger
				unary.type = UnaryType.NOT
				triggers += unary
			} else {
				val concrateEvents = port.inputEvents.filter[!(events.contains(it))]
				for (concrateEvent : concrateEvents) {
					val trigger = createEventTrigger
					val portEventReference = createPortEventReference
					portEventReference.event = concrateEvent
					portEventReference.port = port
					trigger.eventReference = portEventReference
					val unaryTrigger = createUnaryTrigger
					unaryTrigger.operand = trigger
					unaryTrigger.type = UnaryType.NOT
					triggers += unaryTrigger
				}
			}
		}
		return triggers
	}

	def protected BinaryTrigger getBinaryTrigger(List<InteractionDefinition> interactions, BinaryType type,
		boolean reversed) {
		val triggers = newArrayList
		for (interaction : interactions) {
			triggers += getEventTrigger(interaction, reversed)
		}
		return getBinaryTriggerFromTriggers(triggers, type)
	}

	// /////////////// Event triggers based on Interactions	
	def protected dispatch Trigger getEventTrigger(Signal signal, boolean reversed) {
		val trigger = createEventTrigger
		val eventref = createPortEventReference
		val port = reversed
				? getPort(scenarioStatechartUtil.getTurnedOutPortName(signal.port))
				: getPort(signal.port.name)
		eventref.event = getEvent(signal.event.name, port)
		eventref.port = port
		trigger.eventReference = eventref
		return trigger
	}

	def protected dispatch Trigger getEventTrigger(Delay s, boolean reversed) {
		val trigger = createEventTrigger
		val timeoutEventReference = createTimeoutEventReference
		val timeoutDeclaration = statechart.timeoutDeclarations.last
		timeoutEventReference.timeout = timeoutDeclaration
		trigger.eventReference = timeoutEventReference
		return trigger
	}

	def protected dispatch Trigger getEventTrigger(NegatedModalInteraction negatedInteraction, boolean reversed) {
		val trigger = createEventTrigger
		if (negatedInteraction.modalinteraction instanceof Signal) {
			var signal = negatedInteraction.modalinteraction as Signal
			var Port port = signal.direction.equals(InteractionDirection.SEND)
					? getPort(scenarioStatechartUtil.getTurnedOutPortName(signal.port))
					: getPort(signal.port.name)
			val Event event = getEvent(signal.event.name, port)
			val eventRef = createPortEventReference
			eventRef.event = event
			eventRef.port = port
			trigger.eventReference = eventRef
			val unary = createUnaryTrigger
			unary.operand = trigger
			unary.type = UnaryType.NOT
			return unary
		}
		return trigger
	}

////////// RaiseEventActions based on Interactions
	def protected dispatch Action getRaiseEventAction(Signal signal, boolean reversed) {
		var action = createRaiseEventAction
		var port = getPort(getNameOfNewPort(signal.port, reversed))
		val event = getEvent(signal.event.name, port)
		action.event = event
		action.port = port
		for (argument : event.parameterDeclarations) {
			val reference = createEventParameterReferenceExpression
			reference.port = getPort(port.turnedOutPortName)
			reference.event = getEvent(signal.event.name, reference.port)
			reference.parameter = argument
			action.arguments += reference
		}
		return action
	}

	def protected dispatch Action getRaiseEventAction(Delay delay, boolean reversed) {
		return null
	}

	def protected dispatch Action getRaiseEventAction(NegatedModalInteraction negatedInteraction, boolean reversed) {
		return null
	}

	def protected Port getPort(String name) {
		for (port : statechart.ports) {
			if (port.name == name) {
				return port
			}
		}
		return null
	}

	def protected Event getEvent(String name, Port port) {
		for (event : port.allEventDeclarations) {
			if (event.event.name == name) {
				return event.event
			}
		}
		return null
	}

	def protected createNewState(String name) {
		var state = createState
		state.name = name
		return state
	}

	def protected createNewState() {
		return createNewState(scenarioStatechartUtil.stateName + String.valueOf(stateCount++))
	}

	def protected ChoiceState createNewChoiceState() {
		exsistingChoices++
		var choice = createChoiceState
		var name = String.valueOf(scenarioStatechartUtil.choiceName + exsistingChoices++)
		choice.name = name
		return choice
	}

	def protected handleArguments(List<InteractionDefinition> set, Transition transition) {
		var signals = set.filter(Signal).filter[!it.arguments.empty]
		if (signals.empty) {
			val firstInteraction = set.get(0)
			if (set.size == 1 && firstInteraction instanceof NegatedModalInteraction) {
				val interaction = firstInteraction as NegatedModalInteraction
				val innerInteraction = interaction.modalinteraction
				if (innerInteraction instanceof Signal) {
					if (!innerInteraction.arguments.empty) {
						signals = newArrayList(innerInteraction)
					}
				}
			}
		}
		if (signals.empty) {
			return
		}
		val guard1 = createAndExpression
		for (signal : signals) {
			val tmp = signal
			var i = 0
			var String portName = tmp.port.name
			if (tmp.direction.equals(InteractionDirection.SEND)) {
				if (!scenarioStatechartUtil.isTurnedOut(tmp.port)) {
					portName = scenarioStatechartUtil.getTurnedOutPortName(tmp.port)
				}
			}
			val port = getPort(portName)
			val event = getEvent(tmp.event.name, port)
			for (paramDec : event.parameterDeclarations) {
				val paramRef = createEventParameterReferenceExpression
				paramRef.parameter = paramDec
				paramRef.port = port
				paramRef.event = event
				guard1.operands += createEqualityExpression(paramRef, tmp.arguments.get(i).clone)
				i++
			}
		}
		var Expression expr = null
		if (guard1.operands.size == 1) {
			expr = guard1.operands.get(0)
		} else {
			expr = guard1
		}
		val guard = transition.guard
		if (guard === null) {
			transition.guard = expr
		} else {
			val and = createAndExpression
			and.operands += expr
			and.operands += guard
			transition.guard = and
		}
	}

	def protected setupForwardTransition(ModalInteractionSet set, boolean reversed, boolean isNegated,
		Transition forwardTransition) {
		val eventParamRefs = ecoreUtil.getAllContentsOfType(set, EventParameterReferenceExpression)
		for (eventParamRef : eventParamRefs) {
			eventParamRef.port = getPort(getNameOfNewPort(eventParamRef.port, reversed))
			eventParamRef.event = getEvent(eventParamRef.event.name, eventParamRef.port)
		}
		var Trigger trigger = null
		val checks = set.modalInteractions.filter(ScenarioCheckExpression)
		val assignments = set.modalInteractions.filter(ScenarioAssignmentStatement)
		val nonCheckOrAssignmentInteractitons = set.modalInteractions.filter [
			!(it instanceof ScenarioCheckExpression) && ! (it instanceof ScenarioAssignmentStatement)
		].toList
		if (nonCheckOrAssignmentInteractitons.size > 1) {
			trigger = getBinaryTrigger(nonCheckOrAssignmentInteractitons, BinaryType.AND, reversed)
		} else if (nonCheckOrAssignmentInteractitons.size == 1) {
			trigger = getEventTrigger(nonCheckOrAssignmentInteractitons.head, reversed)
		} else {
			trigger = createOnCycleTrigger
		}
		if (isNegated) {
			forwardTransition.trigger = negateEventTrigger(trigger)
		} else {
			forwardTransition.trigger = trigger
			for (modalInteraction : nonCheckOrAssignmentInteractitons) {
				val effect = getRaiseEventAction(modalInteraction, !reversed)
				if (effect !== null) {
					forwardTransition.effects += effect
				}
			}
		}
		if (checks.size > 1) {
			val andExpression = createAndExpression
			andExpression.operands += checks.map[it.expression.clone]
			forwardTransition.guard = andExpression
		} else if (checks.size == 1) {
			forwardTransition.guard = checks.head.expression.clone
		}
		for (assignment : assignments) {
			val newAssignment = createAssignmentStatement
			newAssignment.lhs = assignment.lhs.clone
			newAssignment.rhs = assignment.rhs.clone
			forwardTransition.effects += newAssignment
		}
	}

	def protected handleDelays(ModalInteractionSet set) {
		val delays = set.modalInteractions.filter(Delay)
		if (!delays.empty) {
			val delay = delays.head
			val timeoutDeclaration = createTimeoutDeclaration
			val timeSpecification = createTimeSpecification(delay.minimum)
			setTimeoutDeclarationForState(previousState, timeoutDeclaration, timeSpecification)
		}
	}

	def protected createTimeoutDeclaration() {
		val timeoutDeclaration = statechartfactory.createTimeoutDeclaration
		timeoutDeclaration.name = getDelayName(timeoutCount++)
		statechart.timeoutDeclarations += timeoutDeclaration
		return timeoutDeclaration
	}

	def protected createTimeSpecification(Expression expr) {
		val timeSpecification = createTimeSpecification
		timeSpecification.unit = TimeUnit.MILLISECOND
		timeSpecification.value = expr.clone
		return timeSpecification
	}

	def protected void setTimeoutDeclarationForState(StateNode state, TimeoutDeclaration timeoutDeclaration,
		TimeSpecification timeSpecification) {
		val action = createSetTimeoutAction
		action.timeoutDeclaration = timeoutDeclaration
		action.time = timeSpecification
		if (state instanceof State) {
			state.entryActions += action
		}
	}
}

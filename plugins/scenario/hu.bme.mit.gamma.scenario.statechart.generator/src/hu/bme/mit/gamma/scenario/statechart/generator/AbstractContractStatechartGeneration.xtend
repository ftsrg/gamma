package hu.bme.mit.gamma.scenario.statechart.generator

import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.scenario.model.InteractionDirection
import hu.bme.mit.gamma.scenario.model.ModalInteractionSet
import hu.bme.mit.gamma.scenario.model.NegatedModalInteraction
import hu.bme.mit.gamma.scenario.model.ScenarioDefinition
import hu.bme.mit.gamma.scenario.model.Signal
import hu.bme.mit.gamma.scenario.model.derivedfeatures.ScenarioModelDerivedFeatures
import hu.bme.mit.gamma.scenario.statechart.util.ScenarioStatechartUtil
import hu.bme.mit.gamma.statechart.contract.ContractModelFactory
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.Trigger
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger
import hu.bme.mit.gamma.statechart.statechart.BinaryType
import hu.bme.mit.gamma.statechart.statechart.ChoiceState
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger
import hu.bme.mit.gamma.statechart.statechart.UnaryType
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import java.util.List
import java.util.Map

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

abstract class AbstractContractStatechartGeneration {

	protected val extension StatechartModelFactory statechartfactory = StatechartModelFactory.eINSTANCE
	protected val extension ExpressionModelFactory expressionfactory = ExpressionModelFactory.eINSTANCE
	protected val extension InterfaceModelFactory interfacefactory = InterfaceModelFactory.eINSTANCE
	protected val extension ActionModelFactory actionfactory = ActionModelFactory.eINSTANCE
	protected val extension ContractModelFactory contractfactory = ContractModelFactory.eINSTANCE
	protected val extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected val extension ExpressionEvaluator exprEval = ExpressionEvaluator.INSTANCE
	protected val extension ExpressionUtil exprUtil = ExpressionUtil.INSTANCE
	protected val extension ScenarioStatechartUtil scenarioStatechartUtil = ScenarioStatechartUtil.INSTANCE
	protected val extension ScenarioModelDerivedFeatures scenarioModelDerivedFeatures = ScenarioModelDerivedFeatures.INSTANCE
	protected val StatechartUtil statechartUtil = StatechartUtil.INSTANCE

	protected val JavaUtil javaUtil = JavaUtil.INSTANCE

	protected var Component component = null
	protected var ScenarioDefinition scenario = null
	protected var StatechartDefinition statechart = null
	protected val variableMap = <String, VariableDeclaration>newHashMap
	protected var exsistingChoices = 0
	protected var exsistingMerges = 0
	protected var stateCount = 0
	protected var timeoutCount = 0

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
		var variable = createVariableDeclaration
		// exprUtil.createVariableDeclaration()
		variable.name = name
		variable.expression = exprUtil.toIntegerLiteral(0)
		var type = createIntegerTypeDefinition
		variable.type = type
		return variable
	}

	protected def setIntVariable(VariableDeclaration variable, int value) {
		var variableAssignment = createAssignmentStatement
		variableAssignment.lhs = exprUtil.createReferenceExpression(variable)
		variableAssignment.rhs = exprUtil.toIntegerLiteral(value)
		return variableAssignment
	}

	def protected Expression getVariableLessEqualParamExpression(VariableDeclaration variable, int maxValue) { // megnézni utilban összeset
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
			binaryTrigger.leftOperand = negateEventTrigger(left as EventTrigger)
		}
		if (left instanceof BinaryTrigger) {
			negateBinaryTree(left as BinaryTrigger)
		}
		if (right instanceof BinaryTrigger) {
			negateBinaryTree(right as BinaryTrigger)
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
				var anyPortEvent = createAnyPortEventReference
				anyPortEvent.port = port
				var trigger = createEventTrigger
				trigger.eventReference = anyPortEvent
				var unary = createUnaryTrigger
				unary.operand = trigger
				unary.type = UnaryType.NOT
				triggers += unary
			} else {
				var concrateEvents = port.inputEvents.filter[!(events.contains(it))]
				for (concrateEvent : concrateEvents) {
					var trigger = createEventTrigger
					var portEventReference = createPortEventReference
					portEventReference.event = concrateEvent
					portEventReference.port = port
					trigger.eventReference = portEventReference
					var u = createUnaryTrigger
					u.operand = trigger
					u.type = UnaryType.NOT
					triggers += u
				}
			}
		}
		return triggers
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
		for (event :   port.allEventDeclarations) {
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

}

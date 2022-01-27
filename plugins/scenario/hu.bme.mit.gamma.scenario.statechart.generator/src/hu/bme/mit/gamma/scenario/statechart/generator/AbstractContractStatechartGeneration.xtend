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
import hu.bme.mit.gamma.scenario.model.ScenarioDefinition
import hu.bme.mit.gamma.scenario.model.Signal
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
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger
import hu.bme.mit.gamma.statechart.statechart.UnaryType
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.math.BigInteger
import java.util.List
import java.util.Map
import org.eclipse.emf.common.util.EList

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import hu.bme.mit.gamma.util.JavaUtil

abstract class AbstractContractStatechartGeneration {
	
	protected val extension StatechartModelFactory statechartfactory = StatechartModelFactory.eINSTANCE
	protected val extension ExpressionModelFactory expressionfactory = ExpressionModelFactory.eINSTANCE
	protected val extension InterfaceModelFactory interfacefactory = InterfaceModelFactory.eINSTANCE
	protected val extension ActionModelFactory actionfactory = ActionModelFactory.eINSTANCE
	protected val extension ContractModelFactory contractfactory = ContractModelFactory.eINSTANCE
	protected val extension GammaEcoreUtil ecureUtil = GammaEcoreUtil.INSTANCE
	protected val extension ExpressionEvaluator exprEval = ExpressionEvaluator.INSTANCE
	protected val extension ExpressionUtil exprUtil = ExpressionUtil.INSTANCE
	protected val ScenarioStatechartUtil scenarioStatechartUtil = ScenarioStatechartUtil.INSTANCE
	protected static final JavaUtil javaUtil = JavaUtil.INSTANCE;
	
	protected var Component component = null
	protected var ScenarioDefinition scenario = null
	protected var StatechartDefinition statechart = null
	protected val variableMap = <String,VariableDeclaration>newHashMap
	protected int exsistingChoices = 0;
	protected int exsistingMerges = 0;
	protected var stateCount = 0
	protected var timeoutCount = 0
	
	def VariableDeclaration getOrCreate(Map<String, VariableDeclaration> map, String string) {
		val result = map.get(string)
		if (result !== null){
			return result
		} 
		else {
			val newVariable = createIntegerVariable(string)
			variableMap.put(string,newVariable)
			statechart.variableDeclarations+=newVariable
			return newVariable
		}
	}
	
	protected def setupTransition(Transition transition, StateNode source, StateNode target, Trigger trigger, Expression guard, List<Action> effects){
		if (source !== null){
			transition.sourceState = source
		}
		if (target !== null){
			transition.targetState = target
		}
		if (trigger !== null){
			transition.trigger = trigger
		}
		if (guard !== null){
			transition.guard = guard
		}
		if (effects !== null){
			transition.effects.clear
			transition.effects += effects
		}
	}
	
///////// Create Set and Check Variables
	
	protected def AssignmentStatement incrementVar(VariableDeclaration variable) {
		var assign = createAssignmentStatement
		var addition = createAddExpression
		addition.operands.add(exprUtil.createReferenceExpression(variable))
		addition.operands.add(exprUtil.toIntegerLiteral(1))
		assign.rhs = addition
		assign.lhs = exprUtil.createReferenceExpression(variable)
		return assign
	}
	
	def protected VariableDeclaration createIntegerVariable(String name) {
		var variable = createVariableDeclaration
		variable.name = name
		variable.expression = exprUtil.toIntegerLiteral(0)
		var type = createIntegerTypeDefinition
		variable.type = type
		return variable
	}
	
	protected def setIntVariable(VariableDeclaration variable, int Value) {
		var variableAssignment = createAssignmentStatement
		variableAssignment.lhs = exprUtil.createReferenceExpression(variable)
		variableAssignment.rhs = exprUtil.toIntegerLiteral(Value)
		return variableAssignment
	}
	
	def protected Expression getVariableLessEqualParamExpression(VariableDeclaration variable, int maxV) {
		var maxCheck = createLessEqualExpression
		maxCheck.leftOperand = exprUtil.createReferenceExpression(variable)
		maxCheck.rightOperand = exprUtil.toIntegerLiteral(maxV)
		return maxCheck
	}

	def protected Expression getVariableGreaterEqualParamExpression(VariableDeclaration variable, int minV) {
		var minCheck = createGreaterEqualExpression
		minCheck.leftOperand = exprUtil.createReferenceExpression(variable)
		minCheck.rightOperand = exprUtil.toIntegerLiteral(minV)
		return minCheck
	}

	def protected Expression getVariableInIntervalExpression(VariableDeclaration variable, int minV, int maxV) {
		var and = createAndExpression
		and.operands.add(getVariableGreaterEqualParamExpression(variable, minV))
		and.operands.add(getVariableLessEqualParamExpression(variable, maxV))
		return and
	}
	

//////// Create Binary and negate triggers
	
	def protected void negateBinaryTree(BinaryTrigger b) {
		if (b.rightOperand instanceof EventTrigger) {
			b.rightOperand = negateEventTrigger(b.rightOperand as EventTrigger)
		}
		if (b.leftOperand instanceof EventTrigger) {
			b.leftOperand = negateEventTrigger(b.leftOperand as EventTrigger)
		}
		if (b.leftOperand instanceof BinaryTrigger) {
			negateBinaryTree(b.leftOperand as BinaryTrigger)
		}
		if (b.rightOperand instanceof BinaryTrigger) {
			negateBinaryTree(b.rightOperand as BinaryTrigger)
		}
	}

	def protected Trigger negateEventTrigger(Trigger t) {
		if (t instanceof UnaryTrigger && (t as UnaryTrigger).type == UnaryType.NOT)
			return (t as UnaryTrigger).operand
		var n = createUnaryTrigger
		n.type = UnaryType.NOT
		n.operand = t
		return n
	}
	
	def protected BinaryTrigger getBinaryTrigger(EList<InteractionDefinition> i, BinaryType type, boolean reversed) {
		val triggers = newArrayList
		for (interaction : i) {
			triggers+= getEventTrigger(interaction, reversed)
		}
		return getBinaryTriggerFromTriggers(triggers,type);
	}
	
	def protected BinaryTrigger getBinaryTriggerFromTriggers(List<Trigger> triggers, BinaryType type) {
		var bin = createBinaryTrigger
		bin.type = type
		var runningbin = bin
		var signalCount = 0
		for (trigger : triggers) {
			signalCount++
			if (runningbin.leftOperand === null) {
				runningbin.leftOperand = trigger
			}
			else if (signalCount == triggers.size) {
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
			var t = createEventTrigger
			t.eventReference = ref
			if (runningbin.leftOperand === null)
				runningbin.leftOperand = t
			else if (signalCount == size) {
				runningbin.rightOperand = t
			} else {
				var newbin = createBinaryTrigger
				runningbin.rightOperand = newbin
				newbin.type = type
				runningbin = newbin
				runningbin.leftOperand = t
			}
		}
		return bin
	}
	
	protected def List<Trigger> createOtherNegatedTriggers(ModalInteractionSet set) {
		var triggers = newArrayList
		var ports = newArrayList
		val events = newArrayList
		var allPorts = statechart.ports.filter[!it.inputEvents.empty]
		for (modalInteraction : set.modalInteractions) {
			var Signal signal = null
			if (modalInteraction instanceof Signal) {
				signal = modalInteraction
			} 
			else if (modalInteraction instanceof NegatedModalInteraction) {
				val m = modalInteraction.modalinteraction
				if (m instanceof Signal) {
					signal = m
				}
			}
			if(signal !== null){
				val portName = signal.direction == InteractionDirection.SEND
						? scenarioStatechartUtil.getTurnedOutPortName(signal.port)
						: signal.port.name
				ports.add(getPort(portName))
				events.add(getEvent(signal.event.name, getPort(portName)))
			}
		}
		for (port : allPorts) {
			if (!ports.contains(port)) {
				var any = createAnyPortEventReference
				any.port = port
				var t = createEventTrigger
				t.eventReference = any
				var u = createUnaryTrigger
				u.operand = t
				u.type = UnaryType.NOT
				triggers.add(u)
			} else {
				var concrateEvents = port.inputEvents.filter[!(events.contains(it))]
				for (concrateEvent : concrateEvents) {
					var t = createEventTrigger
					var e = createPortEventReference
					e.event = concrateEvent
					e.port = port
					t.eventReference = e
					var u = createUnaryTrigger
					u.operand = t
					u.type = UnaryType.NOT
					triggers.add(u)
				}
			}
		}
		return triggers
	}
	
///////////////// Event triggers based on Interactions	
	
	def protected dispatch Trigger getEventTrigger(Signal s, boolean reversed) {
		var t = createEventTrigger
		var eventref = createPortEventReference
		var port = reversed ? getPort(scenarioStatechartUtil.getTurnedOutPortName(s.port)) : getPort(s.port.name)
		eventref.event = getEvent(s.event.name, port)
		eventref.port = port
		t.eventReference = eventref
		return t
	}

	def protected dispatch Trigger getEventTrigger(Delay s, boolean reversed) {
		var t = createEventTrigger
		var er = createTimeoutEventReference
		var td = statechart.timeoutDeclarations.last
		er.timeout = td
		t.eventReference = er
		return t
	}

	def protected dispatch Trigger getEventTrigger(NegatedModalInteraction s, boolean reversed) {
		var t = createEventTrigger
		if (s.modalinteraction instanceof Signal) {
			var signal = s.modalinteraction as Signal
			var Port port = signal.direction.equals(InteractionDirection.SEND) ? 
					getPort(scenarioStatechartUtil.getTurnedOutPortName(signal.port)) :
					getPort(signal.port.name)
			var Event event = getEvent(signal.event.name, port)
			var eventRef = createPortEventReference
			eventRef.event = event
			eventRef.port = port
			t.eventReference = eventRef
			var unary = createUnaryTrigger
			unary.operand = t
			unary.type = UnaryType.NOT
			return unary
		}
		return t
	}
	
////////// RaiseEventActions based on Interactions

	def protected dispatch Action getRaiseEventAction(Signal s, boolean reversed) {
		var a = createRaiseEventAction
		var port = reversed ? getPort(scenarioStatechartUtil.getTurnedOutPortName(s.port)) : getPort(s.port.name)
		a.event = getEvent(s.event.name, port)
		a.port = port
		for (argument : (s as Signal).arguments) {
			a.arguments.add(ecureUtil.clone(argument))
		}
		return a
	}

	def protected dispatch Action getRaiseEventAction(Delay s, boolean reversed) {
		return null
	}

	def protected dispatch Action getRaiseEventAction(NegatedModalInteraction s, boolean reversed) {
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
		for (event : port.interfaceRealization.interface.events) {
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
		return createNewState("state" + String.valueOf(stateCount++))
	}
	
	
	def protected ChoiceState addChoiceState() {
		exsistingChoices++;
		var choice = createChoiceState
		var name = String.valueOf("Choice" + exsistingChoices++)
		choice.name = name
		return choice
	}
	
}
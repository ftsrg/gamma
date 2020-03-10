package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.AnyTrigger
import hu.bme.mit.gamma.statechart.model.Clock
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.MessageQueue
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.EventsIntoMessageQueues
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.QueuePriorities
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RunOnceClockControl
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RunOnceEventControl
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.SimpleWrapperInstances
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopSyncSystemInEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopSyncSystemOutEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopWrapperComponents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.UnusedWrapperEvents
import hu.bme.mit.gamma.uppaal.transformation.queries.ValuesOfEventParameters
import hu.bme.mit.gamma.uppaal.transformation.traceability.MessageQueueTrace
import java.util.Collection
import java.util.HashSet
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRule
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory
import uppaal.declarations.ChannelVariableDeclaration
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.FunctionDeclaration
import uppaal.declarations.Variable
import uppaal.expressions.CompareExpression
import uppaal.expressions.CompareOperator
import uppaal.expressions.Expression
import uppaal.expressions.ExpressionsFactory
import uppaal.expressions.ExpressionsPackage
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.LiteralExpression
import uppaal.expressions.LogicalOperator
import uppaal.expressions.NegationExpression
import uppaal.templates.Edge
import uppaal.templates.Location
import uppaal.templates.LocationKind
import uppaal.templates.SynchronizationKind
import uppaal.templates.TemplatesPackage

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class AsynchronousConnectorTemplateCreator {
	// Transformation rule-related extensions
	protected extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
	protected final extension IModelManipulations manipulation
	// Trace
	protected final extension Trace modelTrace
	// UPPAAL packages
	protected final extension TemplatesPackage temPackage = TemplatesPackage.eINSTANCE
	protected final extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
	// UPPAAL factories
	protected final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
	// Id
	var id = 0
	protected final DataVariableDeclaration isStableVar
	// Message struct types
	protected final DataVariableDeclaration messageEvent
	protected final DataVariableDeclaration messageValue
	// Auxiliary objects
	protected final extension Cloner cloner = new Cloner
	protected final extension NtaBuilder ntaBuilder
	protected final extension AsynchronousComponentHelper asynchronousComponentHelper
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension AssignmentExpressionCreator assignmentExpressionCreator
	// Rules
	protected BatchTransformationRule<TopWrapperComponents.Match, TopWrapperComponents.Matcher> topWrapperConnectorRule
	protected BatchTransformationRule<SimpleWrapperInstances.Match, SimpleWrapperInstances.Matcher> instanceWrapperConnectorRule
	
	new(NtaBuilder ntaBuilder, IModelManipulations manipulation, AssignmentExpressionCreator assignmentExpressionCreator,
			AsynchronousComponentHelper asynchronousComponentHelper, ExpressionTransformer expressionTransformer,
			Trace modelTrace, DataVariableDeclaration isStableVar, DataVariableDeclaration messageEvent, DataVariableDeclaration messageValue) {
		this.ntaBuilder = ntaBuilder
		this.manipulation = manipulation
		this.modelTrace = modelTrace
		this.isStableVar = isStableVar
		this.assignmentExpressionCreator = assignmentExpressionCreator
		this.asynchronousComponentHelper = asynchronousComponentHelper
		this.expressionTransformer = expressionTransformer
		this.messageEvent = messageEvent
		this.messageValue = messageValue
	}
	
	/**
	 * Responsible for creating a wrapper-sync connector template for a single synchronous composite component wrapped by a Wrapper.
	 * Note that it only fires if there are top wrappers.
	 * Depends on no rules.
	 */
	def getTopWrapperConnectorRule() {
		if (topWrapperConnectorRule === null) {
			topWrapperConnectorRule = createRule(TopWrapperComponents.instance).action [		
				// Creating the template
				val initLoc = createTemplateWithInitLoc(it.wrapper.name + "Connector" + id++, "DefaultLoc")
				val connectorTemplate = initLoc.parentTemplate
				val asyncChannel = wrapper.asyncSchedulerChannel // The wrapper is scheduled with this channel
				val syncChannel = wrapper.syncSchedulerChannel // The wrapped sync component is scheduled with this channel
				val initializedVar = wrapper.initializedVariable // This variable marks the whether the wrapper has been initialized
				val relayLoc = wrapper.createConnectorEdges(initLoc, asyncChannel, syncChannel, initializedVar, null /*no owner in this case*/)
				relayLoc.locationTimeKind = LocationKind.COMMITED
				// A new entry is needed so the entry events and event transmissions are transmitted to the proper queues 
				val initEdge = relayLoc.createEdgeCommittedTarget("ConnectorEntry" + id++)
				initEdge.source.locationTimeKind = LocationKind.URGENT
				connectorTemplate.init = initEdge.source
			].build
		}
	}
	
	/**
	 * Responsible for creating a scheduler template for all synchronous composite components wrapped by wrapper instances.
	 * Note that it only fires if there are wrapper instances.
	 * Depends on no rules.
	 */
	def getInstanceWrapperConnectorRule() {
		if (instanceWrapperConnectorRule === null) {
			instanceWrapperConnectorRule = createRule(SimpleWrapperInstances.instance).action [		
				// Creating the template
				val initLoc = createTemplateWithInitLoc(it.wrapper.name + "Connector" + id++, "DefaultLoc")
				val connectorTemplate = initLoc.parentTemplate
				val asyncChannel = it.instance.asyncSchedulerChannel // The wrapper is scheduled with this channel
				val syncChannel = it.instance.syncSchedulerChannel // The wrapped sync component is scheduled with this channel
				val initializedVar = it.instance.initializedVariable // This variable marks the whether the wrapper has been initialized
				val relayLoc = it.wrapper.createConnectorEdges(initLoc, asyncChannel, syncChannel, initializedVar, it.instance)
				relayLoc.locationTimeKind = LocationKind.COMMITED
				// A new entry is needed so the entry events and event transmissions are transmitted to the proper queues 
				val initEdge = relayLoc.createEdgeCommittedTarget("ConnectorEntry" + id++)
				initEdge.source.locationTimeKind = LocationKind.URGENT
				connectorTemplate.init = initEdge.source
			].build
		}
	}
	
	private def createConnectorEdges(AsynchronousAdapter wrapper, Location initLoc, ChannelVariableDeclaration asyncChannel,
			ChannelVariableDeclaration syncChannel, DataVariableDeclaration initializedVar, AsynchronousComponentInstance owner) {
		checkState(wrapper.controlSpecifications.map[it.trigger].filter(AnyTrigger).empty, "Any triggers are not supported in formal verification.")
		val synchronousComponent = wrapper.wrappedComponent.type
		val relayLocPair = initLoc.createRelayEdges(synchronousComponent, syncChannel, initializedVar)
		val waitingForRelayLoc = relayLocPair.key
		val relayLoc = relayLocPair.value
		// Sync composite in events
		for (systemPort : synchronousComponent.ports) {
			for (inEvent : systemPort.inputEvents) {
			var Edge loopEdge // Now a single input port can be bound to multiple instance ports
			for (match : TopSyncSystemInEvents.Matcher.on(engine).getAllMatches(synchronousComponent, systemPort, null, null, inEvent)) {
				val toRaiseVar = match.event.getToRaiseVariable(match.port, match.instance) // The event that needs to be raised
				val queue = wrapper.getContainerMessageQueue(match.systemPort, match.event) // In what message queue this event is stored
				val messageQueueTrace = queue.getTrace(owner) // Getting the queue trace in accordance with owner
				// Creating the loop edge with the toRaise = true
				if (loopEdge === null) {
					loopEdge = initLoc.createLoopEdgeWithBoolAssignment(toRaiseVar, true)
				}
				else {
					loopEdge.createAssignmentExpression(edge_Update, toRaiseVar, true)
				}
				// Creating the ...Value = ...Messages().value
				val expressions = ValuesOfEventParameters.Matcher.on(engine).getAllValuesOfexpression(match.port, match.event)
				if (!expressions.empty) {
					val valueOfVars = match.event.parameterDeclarations.head.allValuesOfTo
							.filter(DataVariableDeclaration).filter[it.owner == match.instance]
					if (valueOfVars.size != 1) {
						throw new IllegalArgumentException("Not one valueOfVar: " + valueOfVars)
					}	
					val valueOfVar = valueOfVars.head
					// Creating the ...Messages().value expression
					val scopedIdentifierExp = messageQueueTrace.peekFunction.messageValueScopeExp(messageValue.variable.head)
					// Creating the ...Value = ...Messages().value
					loopEdge.createAssignmentExpression(edge_Update, valueOfVar, scopedIdentifierExp)
				}
				// "Basic" loop edge
				loopEdge.createConnectorEdge(asyncChannel, wrapper, messageQueueTrace, match.systemPort, match.event, owner)
				// If this event is in a control spec, the wrapped sync component needs to be scheduled
				if (RunOnceEventControl.Matcher.on(engine).hasMatch(wrapper, match.systemPort, match.event)) {
					// Scheduling the sync
					val syncEdge = waitingForRelayLoc.createCommittedSyncTarget(syncChannel.variable.head, "schedule" + id++)
					loopEdge.target = syncEdge.source
				}
			}
			}
		}
		// Creating edges for control events of wrapper
		for (match : RunOnceEventControl.Matcher.on(engine).getAllMatches(wrapper, null, null)
				.filter[!TopSyncSystemInEvents.Matcher.on(engine).hasMatch(it.wrapper.wrappedComponent.type, it.port, null, null, it.event)]) {
			// No events of the wrapped component
			val queue = wrapper.getContainerMessageQueue(match.port, match.event) // In what message queue this event is stored
			val messageQueueTrace = queue.getTrace(owner) // Getting the queue trace in accordance with onwer
			// Creating the loop edge
			val edge = initLoc.createEdge(initLoc)
			edge.createConnectorEdge(asyncChannel, wrapper, messageQueueTrace, match.port, match.event, owner)
			val syncEdge = waitingForRelayLoc.createCommittedSyncTarget(syncChannel.variable.head, "schedule" + id++)
			edge.target = syncEdge.source
		}
		// Creating edges for unused events of wrapper
		for (match : UnusedWrapperEvents.Matcher.on(engine).getAllMatches(wrapper, null, null)) {
			val queue = wrapper.getContainerMessageQueue(match.port, match.event) // In what message queue this event is stored
			val messageQueueTrace = queue.getTrace(owner) // Getting the queue trace in accordance with onwer
			// Creating the loop edge
			val edge = initLoc.createEdge(initLoc)
			edge.createConnectorEdge(asyncChannel, wrapper, messageQueueTrace, match.port, match.event, owner)
		}
		// Creating the loop edges for clock triggers
		for (match : RunOnceClockControl.Matcher.on(engine).getAllMatches(wrapper, null, null)) {
			val messageQueueTrace = match.queue.getTrace(owner)
			// Creating the scheduler sync edge
			val syncEdge = waitingForRelayLoc.createCommittedSyncTarget(syncChannel.variable.head, "schedule" + id++)
			// Creating the edge checking for the events in the queue
			val edge = initLoc.createEdge(syncEdge.source)
			edge.setSynchronization(asyncChannel.variable.head, SynchronizationKind.RECEIVE) // Setting the sync
			// Guards checking higher priority queues
			for (higherPirorityQueue : QueuePriorities.Matcher.on(engine).getAllValuesOfhigherPriotityQueue(wrapper, match.queue)) {
				edge.addPriorityGuard(wrapper, higherPirorityQueue, owner)
			}
			// ...Messages().event == clocksignal
			val valueCompareExpression = createPeekClockCompare(messageQueueTrace, match.clock)
			edge.addGuard(valueCompareExpression, LogicalOperator.AND)
			// Shifting the message queue
			edge.addFunctionCall(edge_Update, messageQueueTrace.shiftFunction.function)
			// Adding isStable  guard
			edge.addGuard(isStableVar, LogicalOperator.AND)
		}
		return relayLoc
	}
	
	private def void createConnectorEdge(Edge edge, ChannelVariableDeclaration asyncChannel, AsynchronousAdapter wrapper,
			MessageQueueTrace messageQueueTrace, Port port, Event event, ComponentInstance owner) {
		// Putting the ? async channel to the loop edge
		edge.setSynchronization(asyncChannel.variable.head, SynchronizationKind.RECEIVE)
		// The event must be on the guard
		// ...Messages().event == Port_event
		val valueCompareExpression = createPeekValueCompare(messageQueueTrace, port, event)
		edge.addGuard(valueCompareExpression, LogicalOperator.AND)
		// The priority needs to be on the guard
		for (higherPirorityQueue : QueuePriorities.Matcher.on(engine).getAllValuesOfhigherPriotityQueue(wrapper, messageQueueTrace.queue)) {
			edge.addPriorityGuard(wrapper, higherPirorityQueue, owner)
		}
		// Adding isStable  guard
		edge.addGuard(isStableVar, LogicalOperator.AND)
		// Shifting the message queue
		edge.addFunctionCall(edge_Update, messageQueueTrace.shiftFunction.function)
	}
	
	private def createRelayEdges(Location initLoc, SynchronousComponent syncComposite,
			ChannelVariableDeclaration syncChan, DataVariableDeclaration initializedVar) {
		val parentTemplate = initLoc.parentTemplate
		val relayLoc = parentTemplate.createChild(template_Location, location) as Location => [
			it.name = "RelayLoc"
		]
		val finishRelayEdge = relayLoc.createEdge(initLoc)
		val waitingForRelayLoc = parentTemplate.createChild(template_Location, location) as Location => [
			it.name = "WaitingRelayLoc"
		]
		val waitingRelaySyncEdge = waitingForRelayLoc.createEdge(relayLoc)
		waitingRelaySyncEdge.setSynchronization(syncChan.variable.head, SynchronizationKind.RECEIVE)
		// Creating relay edges
		val originalGuards = new HashSet<Expression>
		for (outEventMatch : TopSyncSystemOutEvents.Matcher.on(engine).getAllMatches(syncComposite, null, null, null, null)) {
			val relayEdge = relayLoc.createEdge(relayLoc)
			val outVariable = outEventMatch.event.getOutVariable(outEventMatch.port, outEventMatch.instance)
			// Adding out-event guard
			val guard = relayEdge.addGuard(outVariable, LogicalOperator.AND)
			originalGuards += guard
			// Resetting the out-event variable
			relayEdge.createAssignmentExpression(edge_Update, outVariable, false)
			for (queueMatch : EventsIntoMessageQueues.Matcher.on(engine).getAllMatches(null, outEventMatch.systemPort, outEventMatch.event, null, null, null)) {
				var DataVariableDeclaration valueOfVar = null
				if (!outEventMatch.event.parameterDeclarations.empty) {
					valueOfVar = outEventMatch.event.getValueOfVariable(outEventMatch.port/* Not sure if correct port*/, outEventMatch.instance)
				}
				relayEdge.createQueueInsertion(queueMatch.inPort, queueMatch.raisedEvent, queueMatch.inInstance, valueOfVar)
			}
		}
		// Putting "default" guard on the finish relay edge
		finishRelayEdge.createDefaultExpression(originalGuards)
		// Setting the isStable = true, needed after the initialization 
		finishRelayEdge.createAssignmentExpression(edge_Update, initializedVar, true)
		return new Pair<Location, Location>(waitingForRelayLoc, relayLoc)
	}
	
	private def CompareExpression createPeekValueCompare(MessageQueueTrace messageQueueTrace, Port port, Event event) {
		createCompareExpression => [
			it.firstExpr = messageQueueTrace.peekFunction.messageValueScopeExp(messageEvent.variable.head)
			it.operator = CompareOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = event.getConstRepresentation(port).variable.head
			]	
		]
	}
	
	private def CompareExpression createPeekClockCompare(MessageQueueTrace messageQueueTrace, Clock clock) {
		return createCompareExpression => [
			it.firstExpr = messageQueueTrace.peekFunction.messageValueScopeExp(messageEvent.variable.head)
			it.operator = CompareOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = clock.getConstRepresentation().variable.head
			]	
		]
	}
	
	private def messageValueScopeExp(FunctionDeclaration peekFunction, Variable variable) {
		return createScopedIdentifierExpression => [
			it.addFunctionCall(scopedIdentifierExpression_Scope, peekFunction.function)
			it.createChild(scopedIdentifierExpression_Identifier, identifierExpression) as IdentifierExpression => [
				it.identifier = variable
			]
		]
	}
	
	private def addPriorityGuard(Edge edge, AsynchronousAdapter wrapper, MessageQueue higherPirorityQueue, ComponentInstance owner) {
		val higherPriorityQueueTrace = higherPirorityQueue.getTrace(owner) // No owner in this case
		// ...MessagesSize == 0
		val sizeCompareExpression = createCompareExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = higherPriorityQueueTrace.capacityVar.variable.head
			]	
			it.operator = CompareOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
				it.text = "0"
			]	
		]
		edge.addGuard(sizeCompareExpression, LogicalOperator.AND)		
	}
	
	private def createDefaultExpression(Edge edge, Collection<? extends Expression> expressions) {
		for (exp : expressions) {
			val negatedExp = createNegationExpression as NegationExpression => [
				it.negatedExpression = exp.clone(true, true)
			]
			edge.addGuard(negatedExp, LogicalOperator.AND)
		}
	}
	
}
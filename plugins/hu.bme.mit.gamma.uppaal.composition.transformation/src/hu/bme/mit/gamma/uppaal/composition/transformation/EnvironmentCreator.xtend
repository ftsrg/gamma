package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.DistinctWrapperInEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopAsyncCompositeComponents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopAsyncSystemInEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopSyncSystemInEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopUnwrappedSyncComponents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopWrapperComponents
import hu.bme.mit.gamma.uppaal.transformation.queries.ValuesOfEventParameters
import hu.bme.mit.gamma.uppaal.transformation.traceability.MessageQueueTrace
import java.math.BigInteger
import java.util.HashSet
import java.util.Set
import java.util.logging.Level
import java.util.logging.Logger
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRule
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory
import uppaal.declarations.DataVariableDeclaration
import uppaal.expressions.ExpressionsFactory
import uppaal.expressions.ExpressionsPackage
import uppaal.expressions.LogicalOperator
import uppaal.templates.Edge
import uppaal.templates.Location
import uppaal.templates.TemplatesPackage

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class EnvironmentCreator {
	// Logger
	protected extension Logger logger = Logger.getLogger("GammaLogger")
	// Transformation rule-related extensions
	protected extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
	protected final extension IModelManipulations manipulation
	// Trace
	protected final extension Trace modelTrace
	// Engine
	protected final extension ViatraQueryEngine engine
	// UPPAAL packages
	protected final extension TemplatesPackage temPackage = TemplatesPackage.eINSTANCE
	protected final extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
	// UPPAAL factories
	protected final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
	// Id
	var id = 0
	protected final DataVariableDeclaration isStableVar
	// Auxiliary objects
	protected final extension Cloner cloner = new Cloner
	protected final extension AsynchronousComponentHelper asynchronousComponentHelper
	protected final extension NtaBuilder ntaBuilder
	protected final extension AssignmentExpressionCreator assignmentExpressionCreator
	// Rules
	protected BatchTransformationRule<TopUnwrappedSyncComponents.Match, TopUnwrappedSyncComponents.Matcher> topSyncEnvironmentRule
	protected BatchTransformationRule<TopWrapperComponents.Match, TopWrapperComponents.Matcher> topWrapperEnvironmentRule
	protected BatchTransformationRule<TopAsyncCompositeComponents.Match, TopAsyncCompositeComponents.Matcher> instanceWrapperEnvironmentRule
	
	new(NtaBuilder ntaBuilder, ViatraQueryEngine engine, IModelManipulations manipulation,
			AssignmentExpressionCreator assignmentExpressionCreator, AsynchronousComponentHelper asynchronousComponentHelper,
			Trace modelTrace, DataVariableDeclaration isStableVar) {
		this.ntaBuilder = ntaBuilder
		this.engine = engine
		this.manipulation = manipulation
		this.assignmentExpressionCreator = assignmentExpressionCreator
		this.asynchronousComponentHelper = asynchronousComponentHelper
		this.modelTrace = modelTrace
		this.isStableVar = isStableVar
	}
	
	/**
	 * Responsible for creating the control template that enables the user to fire events.
	 */
	def getTopSyncEnvironmentRule() {
		if (topSyncEnvironmentRule === null) {
			topSyncEnvironmentRule = createRule(TopUnwrappedSyncComponents.instance).action [
				val initLoc = createTemplateWithInitLoc("Environment", "InitLoc")
				val loopEdges = newHashMap
				// Simple event raisings
				for (systemPort : it.syncComposite.ports) {
					for (inEvent : systemPort.inputEvents) {
						var Edge loopEdge = null // Needed as now a port with only in events can be bound to multiple instance ports
						for (match : TopSyncSystemInEvents.Matcher.on(engine).getAllMatches(it.syncComposite, systemPort, null, null, inEvent)) {
							val toRaiseVar = match.event.getToRaiseVariable(match.port, match.instance)
							log(Level.INFO, "Information: System in event: " + match.instance.name + "." + match.port.name + "_" + match.event.name)
							if (loopEdge === null) {
								loopEdge = initLoc.createLoopEdgeWithGuardedBoolAssignment(toRaiseVar)
								loopEdge.addGuard(isStableVar, LogicalOperator.AND)
								loopEdges.put(new Pair(systemPort, inEvent), loopEdge)
							}
							else {
								loopEdge.extendLoopEdgeWithGuardedBoolAssignment(toRaiseVar)
							}
						}
					}
				}
				// Parameter adding if necessary
				for (systemPort : it.syncComposite.ports) {
					for (inEvent : systemPort.inputEvents) {
						var Edge loopEdge = loopEdges.get(new Pair(systemPort, inEvent))
						for (match : TopSyncSystemInEvents.Matcher.on(engine).getAllMatches(it.syncComposite, systemPort, null, null, inEvent)) {
							// Collecting parameter values for each instant event
							val expressions = ValuesOfEventParameters.Matcher.on(engine).getAllValuesOfexpression(match.port, match.event)
							if (!expressions.empty) {
								// Removing original edge from the model
								val template = loopEdge.parentTemplate
								template.edge -= loopEdge
								var boolean hasTrue = false
								var boolean hasFalse = false
								val hasValue = new HashSet<BigInteger>
								for (expression : expressions) {
									// Putting variables raising for ALL instance parameters
				   					val clonedLoopEdge = loopEdge.clone(true, true)
									if (!hasTrue && (expression instanceof TrueExpression)) {
										hasTrue = true
										for (innerMatch : TopSyncSystemInEvents.Matcher.on(engine).getAllMatches(it.syncComposite, systemPort, null, null, inEvent)) {
											clonedLoopEdge.extendValueOfLoopEdge(innerMatch.port, innerMatch.event, innerMatch.instance, expression)
										}
										template.edge += clonedLoopEdge
									}
									else if (!hasFalse && (expression instanceof FalseExpression)) {
										hasFalse = true
										for (innerMatch : TopSyncSystemInEvents.Matcher.on(engine).getAllMatches(it.syncComposite, systemPort, null, null, inEvent)) {
											clonedLoopEdge.extendValueOfLoopEdge(innerMatch.port, innerMatch.event, innerMatch.instance, expression)
										}
										template.edge += clonedLoopEdge
									}
									else if (!hasValue(hasValue, expression) && !(expression instanceof TrueExpression) && !(expression instanceof FalseExpression)) {
										for (innerMatch : TopSyncSystemInEvents.Matcher.on(engine).getAllMatches(it.syncComposite, systemPort, null, null, inEvent)) {
											clonedLoopEdge.extendValueOfLoopEdge(innerMatch.port, innerMatch.event, innerMatch.instance, expression)
										}
										template.edge += clonedLoopEdge									}
								}
								// Adding a different value if the type is an integer
								if (!hasValue.empty) {
				   					val clonedLoopEdge = loopEdge.clone(true, true)
									val maxValue = hasValue.max
									val biggerThanMax = constrFactory.createIntegerLiteralExpression => [it.value = maxValue.add(BigInteger.ONE)]
									for (innerMatch : TopSyncSystemInEvents.Matcher.on(engine).getAllMatches(it.syncComposite, systemPort, null, null, inEvent)) {
										clonedLoopEdge.extendValueOfLoopEdge(innerMatch.port, innerMatch.event, innerMatch.instance, biggerThanMax)
									}
									template.edge += clonedLoopEdge
									biggerThanMax.removeGammaElementFromTrace
								}
							}
						}
					}
				}
			].build
		}
	}
	
	private def void extendValueOfLoopEdge(Edge loopEdge, Port port, Event event, ComponentInstance owner, Expression expression) {
		val valueOfVars = event.parameterDeclarations.head.allValuesOfTo.filter(DataVariableDeclaration)
							.filter[it.owner == owner && it.port == port]
		if (valueOfVars.size != 1) {
			throw new IllegalArgumentException("Not one valueOfVar: " + valueOfVars)
		}
		val valueOfVar = valueOfVars.head
		loopEdge.createAssignmentExpression(edge_Update, valueOfVar, expression, owner)
	}
	
	/**
	 * Returns whether the given set contains an IntegerLiteralExpression identical to the given Expression.
	 */
	private def hasValue(Set<BigInteger> hasValue, Expression expression) {
		if (!(expression instanceof IntegerLiteralExpression)) {
			return false
		}
		val anInt = expression as IntegerLiteralExpression
		for (exp : hasValue) {
			if (exp.equals(anInt.value)) {				
				return true
			}
		}
		hasValue.add(anInt.value)
		return false
	}
	
	def getTopWrapperEnvironmentRule() {
		if (topWrapperEnvironmentRule === null) {
			topWrapperEnvironmentRule = createRule(TopWrapperComponents.instance).action [
				// Creating the template
				val initLoc = createTemplateWithInitLoc(it.wrapper.name + "Environment" + id++, "InitLoc")
				val component = wrapper.wrappedComponent.type
				for (match : TopSyncSystemInEvents.Matcher.on(engine).getAllMatches(component, null, null, null, null)) {
					val queue = wrapper.getContainerMessageQueue(match.systemPort /*Wrapper port*/, match.event) // In what message queue this event is stored
					val messageQueueTrace = queue.getTrace(null) // Getting the owner
					// Creating the loop edge (or edges in case of parametered events)
					initLoc.createEnvironmentLoopEdges(messageQueueTrace, match.systemPort, match.event, match.instance /*Sync owner*/)		
				}
				for (match : DistinctWrapperInEvents.Matcher.on(engine).getAllMatches(wrapper, null, null)) {
					val queue = wrapper.getContainerMessageQueue(match.port, match.event) // In what message queue this event is stored
					val messageQueueTrace = queue.getTrace(null) // Getting the owner
					// Creating the loop edge (or edges in case of parametered events)
					initLoc.createEnvironmentLoopEdges(messageQueueTrace, match.port, match.event, null)		
				}
			].build
		}
	}
	
	def getInstanceWrapperEnvironmentRule() {
		if (instanceWrapperEnvironmentRule === null) {
			instanceWrapperEnvironmentRule = createRule(TopAsyncCompositeComponents.instance).action [
				// Creating the template
				val initLoc = createTemplateWithInitLoc(it.asyncComposite.name + "Environment" + id++, "InitLoc")
				// Creating in events
				for (match : TopAsyncSystemInEvents.Matcher.on(engine).getAllMatches(it.asyncComposite, null, null, null, null)) {
					val wrapper = match.instance.type as AsynchronousAdapter
					val queue = wrapper.getContainerMessageQueue(match.port /*Wrapper port, this is the instance port*/, match.event) // In what message queue this event is stored
					val messageQueueTrace = queue.getTrace(match.instance) // Getting the owner
					// Creating the loop edge (or edges in case of parametered events)
					initLoc.createEnvironmentLoopEdges(messageQueueTrace, match.port, match.event, null /*no sync owner*/)
				}
			].build
		}
	}
	
	private def void createEnvironmentLoopEdges(Location initLoc, MessageQueueTrace messageQueueTrace, Port port, Event event, SynchronousComponentInstance owner) {
		// Checking the parameters
		val expressions = ValuesOfEventParameters.Matcher.on(engine).getAllValuesOfexpression(port, event)
		for (expression : expressions) {
			// New edge is needed in every iteration!
			val loopEdge = initLoc.createEdge(initLoc)
			loopEdge.createEnvironmentEdge(messageQueueTrace, event.getConstRepresentation(port), expression, owner)
			loopEdge.addGuard(isStableVar, LogicalOperator.AND) // For the cutting of the state space
			loopEdge.addInitializedGuards
		}
		if (expressions.empty) {
			val loopEdge = initLoc.createEdge(initLoc)
			loopEdge.createEnvironmentEdge(messageQueueTrace, event.getConstRepresentation(port), createLiteralExpression => [it.text = "0"])
			loopEdge.addGuard(isStableVar, LogicalOperator.AND) // For the cutting of the state space
			loopEdge.addInitializedGuards
		}
	}
	
	private def void createEnvironmentEdge(Edge edge, MessageQueueTrace messageQueueTrace,
			DataVariableDeclaration representation, Expression expression, SynchronousComponentInstance instance) {
		// !isFull...
		val isNotFull = createNegationExpression => [
			it.addFunctionCall(negationExpression_NegatedExpression, messageQueueTrace.isFullFunction.function)
		 ]
		edge.addGuard(isNotFull, LogicalOperator.AND)
		// push....
		edge.addPushFunctionUpdate(messageQueueTrace, representation, expression, instance)
	}
	
	private def void createEnvironmentEdge(Edge edge, MessageQueueTrace messageQueueTrace,
			DataVariableDeclaration representation, uppaal.expressions.Expression expression) {
		// !isFull...
		val isNotFull = createNegationExpression => [
			it.addFunctionCall(negationExpression_NegatedExpression, messageQueueTrace.isFullFunction.function)
		 ]
		edge.addGuard(isNotFull, LogicalOperator.AND)
		// push....
		edge.addPushFunctionUpdate(messageQueueTrace, representation, expression)
	}
	
}
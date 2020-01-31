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
				for (match : TopSyncSystemInEvents.Matcher.on(engine).getAllMatches(it.syncComposite, null, null, null, null)) {
					val toRaiseVar = match.event.getToRaiseVariable(match.port, match.instance) 
					log(Level.INFO, "Information: System in event: " + match.instance.name + "." + match.port.name + "_" + match.event.name)			
					val expressions = ValuesOfEventParameters.Matcher.on(engine).getAllValuesOfexpression(match.port, match.event)
					var Edge loopEdge
					if (!expressions.empty) {
						var boolean hasTrue = false
						var boolean hasFalse = false
						val hasValue = new HashSet<BigInteger>
						val isRaisedVar = match.event.getIsRaisedVariable(match.port, match.instance)	
						for (expression : expressions) {
							if (!hasTrue && (expression instanceof TrueExpression)) {
								hasTrue = true
				   				loopEdge = initLoc.createValueOfLoopEdge(match.port, match.event, toRaiseVar, isRaisedVar, match.instance, expression)
							}
							else if (!hasFalse && (expression instanceof FalseExpression)) {
								hasFalse = true
				   				loopEdge = initLoc.createValueOfLoopEdge(match.port, match.event, toRaiseVar, isRaisedVar, match.instance, expression)			
							}
							else if (!hasValue(hasValue, expression) && !(expression instanceof TrueExpression) && !(expression instanceof FalseExpression)) {
								loopEdge = initLoc.createValueOfLoopEdge(match.port, match.event, toRaiseVar, isRaisedVar, match.instance, expression)		
							}
							loopEdge.addGuard(isStableVar, LogicalOperator.AND) // isStable is needed on all parameter value loop edge	
						}
						// Adding a different value if the type is an integer
						if (!hasValue.empty) {
							val maxValue = hasValue.max
							val biggerThanMax = constrFactory.createIntegerLiteralExpression => [it.value = maxValue.add(BigInteger.ONE)]
							loopEdge = initLoc.createValueOfLoopEdge(match.port, match.event, toRaiseVar, isRaisedVar, match.instance, biggerThanMax)		
							biggerThanMax.removeGammaElementFromTrace
						}
					}
					else {
						loopEdge = initLoc.createLoopEdgeWithGuardedBoolAssignment(toRaiseVar)
						loopEdge.addGuard(isStableVar, LogicalOperator.AND)
					}
				}	
			].build
		}
	} 
	
	/**
	 * Creates a loop edge onto the given location that sets the toRaise flag of the give signal to true and sets the valueof variable
	 * according to the given Expression. 
	 */
	private def createValueOfLoopEdge(Location location, Port port, Event event, DataVariableDeclaration toRaiseVar,
			DataVariableDeclaration isRaisedVar, ComponentInstance owner, Expression expression) {
		val loopEdge = location.createLoopEdgeWithGuardedBoolAssignment(toRaiseVar)
		val valueOfVars = event.parameterDeclarations.head.allValuesOfTo.filter(DataVariableDeclaration)
							.filter[it.owner == owner && it.port == port]
		if (valueOfVars.size != 1) {
			throw new IllegalArgumentException("Not one valueOfVar: " + valueOfVars)
		}
		val valueOfVar = valueOfVars.head
		loopEdge.createAssignmentExpression(edge_Update, valueOfVar, expression, owner)
		return loopEdge
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
	
	private def createEnvironmentEdge(Edge edge, MessageQueueTrace messageQueueTrace,
			DataVariableDeclaration representation, Expression expression, SynchronousComponentInstance instance) {
		// !isFull...
		val isNotFull = createNegationExpression => [
			it.addFunctionCall(negationExpression_NegatedExpression, messageQueueTrace.isFullFunction.function)
		 ]
		edge.addGuard(isNotFull, LogicalOperator.AND)
		// push....
		edge.addPushFunctionUpdate(messageQueueTrace, representation, expression, instance)
	}
	
	private def createEnvironmentEdge(Edge edge, MessageQueueTrace messageQueueTrace,
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
/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.transformation.util.queries.DistinctWrapperInEvents
import hu.bme.mit.gamma.transformation.util.queries.TopAsyncCompositeComponents
import hu.bme.mit.gamma.transformation.util.queries.TopAsyncSystemInEvents
import hu.bme.mit.gamma.transformation.util.queries.TopSyncSystemInEvents
import hu.bme.mit.gamma.transformation.util.queries.TopUnwrappedSyncComponents
import hu.bme.mit.gamma.transformation.util.queries.TopWrapperComponents
import hu.bme.mit.gamma.transformation.util.queries.WrapperTopSyncSystemInEvents
import hu.bme.mit.gamma.uppaal.transformation.queries.ValuesOfEventParameters
import hu.bme.mit.gamma.uppaal.transformation.traceability.MessageQueueTrace
import hu.bme.mit.gamma.uppaal.util.NtaBuilder
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.math.BigInteger
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

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class EnvironmentCreator {
	// Logger
	protected final extension Logger logger = Logger.getLogger("GammaLogger")
	// Transformation rule-related extensions
	protected final extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
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
	// Gamma factories
	protected final extension ExpressionModelFactory emFact = ExpressionModelFactory.eINSTANCE
	// Id
	var id = 0
	protected final DataVariableDeclaration isStableVar
	// Auxiliary objects
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
    protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension AsynchronousComponentHelper asynchronousComponentHelper
	protected final extension NtaBuilder ntaBuilder
	protected final extension AssignmentExpressionCreator assignmentExpressionCreator
	protected final extension ExpressionEvaluator expressionEvaluator
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
		this.expressionEvaluator = new ExpressionEvaluator(this.engine)
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
				val template = initLoc.parentTemplate
				val loopEdges = newHashMap
				// Simple event raisings
				for (systemPort : it.syncComposite.ports) {
					for (inEvent : systemPort.inputEvents) {
						var Edge loopEdge = null // Needed as now a port with only in events can be bound to multiple instance ports
						for (match : TopSyncSystemInEvents.Matcher.on(engine).getAllMatches(it.syncComposite, systemPort, null, null, inEvent)) {
							log(Level.INFO, "Information: System in event: " + match.instance.name + "." + match.port.name + "_" + match.event.name)
							if (loopEdge === null) {
								loopEdge = initLoc.createLoopEdgeWithGuardedBoolAssignment(match.port, match.event, match.instance)
								loopEdge.addGuard(isStableVar, LogicalOperator.AND)
								loopEdges.put(new Pair(systemPort, inEvent), loopEdge)
							}
							else {
								loopEdge.extendLoopEdgeWithGuardedBoolAssignment(match.port, match.event, match.instance)
							}
						}
					}
				}
				// Parameter adding if necessary
				for (systemPort : it.syncComposite.ports) {
					for (inEvent : systemPort.inputEvents) {
						val pair = new Pair(systemPort, inEvent)
						// If the event is not used, the map does not contain this pair
						if (loopEdges.containsKey(pair)) {
							var Edge loopEdge = loopEdges.get(pair)
							var expressionSet = newHashMap
							for (match : TopSyncSystemInEvents.Matcher.on(engine).getAllMatches(it.syncComposite, systemPort, null, null, inEvent)) {
								// Collecting parameter values for each instant parameter
								for (parameter : match.event.parameterDeclarations) {
									val values = ValuesOfEventParameters.Matcher.on(engine).getAllValuesOfexpression(match.port, match.event, parameter)
									if (values.empty) {
										// So if one of the parameters is not referenced, the edge still gets created
										values += parameter.type.initialValueOfType
									}
									expressionSet.put(parameter, values)
								}
							}
							if (!expressionSet.empty) {
								// Removing original edge from the model - only if there is a valid expression
								template.edge -= loopEdge
								val processableEdges = newArrayList(loopEdge)
								val processedEdges = newArrayList
								for (parameter : expressionSet.keySet) {
									val originalExpressions = expressionSet.get(parameter)
									val expressions = originalExpressions.removeDuplicatedExpressions // Removing the expression duplications (that are evaluated to the same expression)
									for (processableEdge : processableEdges) {
										for (expression : expressions) {
											// Putting variables raising for ALL instance parameters
					   						val clonedLoopEdge = processableEdge.clone
					   						for (innerMatch : TopSyncSystemInEvents.Matcher.on(engine).getAllMatches(it.syncComposite, systemPort, null, null, inEvent)) {
												clonedLoopEdge.extendValueOfLoopEdge(innerMatch.port, innerMatch.event, parameter, innerMatch.instance, expression)
											}
											expression.removeGammaElementFromTrace
											processedEdges += clonedLoopEdge
										}
										// Adding a different value if the type is an integer
										if (originalExpressions.filter(EnumerationLiteralExpression).empty &&
												expressions.exists[it instanceof IntegerLiteralExpression]) {
						   					val clonedLoopEdge = processableEdge.clone
											val maxValue = expressions.filter(IntegerLiteralExpression).map[it.value].max
											val biggerThanMax = constrFactory.createIntegerLiteralExpression => [it.value = maxValue.add(BigInteger.ONE)]
											for (innerMatch : TopSyncSystemInEvents.Matcher.on(engine).getAllMatches(it.syncComposite, systemPort, null, null, inEvent)) {
												clonedLoopEdge.extendValueOfLoopEdge(innerMatch.port, innerMatch.event, parameter, innerMatch.instance, biggerThanMax)
											}
											biggerThanMax.removeGammaElementFromTrace
											processedEdges += clonedLoopEdge
										}
									}
									processableEdges.clear
									processableEdges += processedEdges
									processedEdges.clear
								}
								template.edge += processableEdges
							}
						}
					}
				}
			].build
		}
	}
	
	private def createLoopEdgeWithGuardedBoolAssignment(Location initLoc, Port port, Event event,
			ComponentInstance instance) {
		val toRaiseVar = event.getToRaiseVariable(port, instance)
		return initLoc.createLoopEdgeWithGuardedBoolAssignment(toRaiseVar)
	}
	
	private def void extendLoopEdgeWithGuardedBoolAssignment(Edge loopEdge, Port port, Event event,
			ComponentInstance instance) {
		val toRaiseVar = event.getToRaiseVariable(port, instance)
		loopEdge.extendLoopEdgeWithGuardedBoolAssignment(toRaiseVar)
	}
	
	private def void extendValueOfLoopEdge(Edge loopEdge, Port port, Event event, ParameterDeclaration parameter,
			ComponentInstance owner, Expression expression) {
		val valueOfVar = modelTrace.getToRaiseValueOfVariable(event, port, parameter, owner)
		loopEdge.createAssignmentExpression(edge_Update, valueOfVar, expression)
	}
	
	def getTopWrapperEnvironmentRule() {
		if (topWrapperEnvironmentRule === null) {
			topWrapperEnvironmentRule = createRule(TopWrapperComponents.instance).action [
				// Creating the template
				val initLoc = createTemplateWithInitLoc(it.wrapper.name + "Environment" + id++, "InitLoc")
				val component = wrapper.wrappedComponent.type
				for (match : WrapperTopSyncSystemInEvents.Matcher.on(engine).getAllMatches(component, null, null)) {
					val queue = wrapper.getContainerMessageQueue(match.systemPort /*Wrapper port*/, match.event) // In what message queue this event is stored
					val messageQueueTrace = queue.getTrace(null) // Getting the owner
					// Creating the loop edge (or edges in case of parameterized events)
					initLoc.createEnvironmentLoopEdges(messageQueueTrace,
						match.systemPort /*The wrapper port is traced*/, match.event)
				}
				for (match : DistinctWrapperInEvents.Matcher.on(engine).getAllMatches(wrapper, null, null)) {
					val queue = wrapper.getContainerMessageQueue(match.port, match.event) // In what message queue this event is stored
					val messageQueueTrace = queue.getTrace(null) // Getting the owner
					// Creating the loop edge (or edges in case of parameterized events)
					initLoc.createEnvironmentLoopEdges(messageQueueTrace, match.port, match.event)
				}
			].build
		}
	}
	
	private def void createEnvironmentLoopEdges(Location initLoc,
			MessageQueueTrace messageQueueTrace, Port port, Event event) {
		// Checking the parameters
		val parameters = event.parameterDeclarations
		if (!parameters.empty) {
			checkState(parameters.size == 1)
			for (parameter : parameters) {
				val expressions = newArrayList
				for (statechartPort : port.allBoundSimplePorts) {
					expressions += ValuesOfEventParameters.Matcher.on(engine)
						.getAllValuesOfexpression(statechartPort /*Not port*/, event, parameter)
				}
				for (expression : expressions.removeDuplicatedExpressions) {
					// New edge is needed in every iteration!
					val loopEdge = initLoc.createEdge(initLoc)
					loopEdge.extendEnvironmentEdge(messageQueueTrace,
						event.getConstRepresentation(port) /*Not statechartPort*/, expression)
					loopEdge.addGuard(isStableVar, LogicalOperator.AND) // For the cutting of the state space
					loopEdge.addInitializedGuards
					expression.removeGammaElementFromTrace // As the expression is not contained
				}
			}
		}
		else {
			val loopEdge = initLoc.createEdge(initLoc)
			loopEdge.extendEnvironmentEdge(messageQueueTrace, event.getConstRepresentation(port),
				createLiteralExpression => [it.text = "0"])
			loopEdge.addGuard(isStableVar, LogicalOperator.AND) // For the cutting of the state space
			loopEdge.addInitializedGuards
		}
	}
	
	def getInstanceWrapperEnvironmentRule() {
		if (instanceWrapperEnvironmentRule === null) {
			instanceWrapperEnvironmentRule = createRule(TopAsyncCompositeComponents.instance).action [
				// Creating the template
				val initLoc = createTemplateWithInitLoc(it.asyncComposite.name + "Environment" + id++, "InitLoc")
				// Collecting in event parameters
				val parameterMap = newHashMap
				for (systemPort : it.asyncComposite.ports) {
					for (inEvent : systemPort.inputEvents) {
						for (match : TopAsyncSystemInEvents.Matcher.on(engine).getAllMatches(it.asyncComposite, systemPort, null, null, inEvent)) {
							val parameters = inEvent.parameterDeclarations
							checkState(parameters.size <= 1)
							val parameter = parameters.head
							val expressions = ValuesOfEventParameters.Matcher.on(engine).getAllValuesOfexpression(match.port, match.event, parameter)
							var Set<Expression> expressionList
							if (!parameterMap.containsKey(new Pair(systemPort, inEvent))) {
								expressionList = newHashSet
								parameterMap.put(new Pair(systemPort, inEvent), expressionList)
							}
							else {
								expressionList = parameterMap.get(new Pair(systemPort, inEvent))
							}
							expressionList += expressions
						}
					}
				}
				// Setting updates, one update may affect multiple queues (full in port events can be connected to multiple instance ports)
				for (systemPort : it.asyncComposite.ports) {
					for (inEvent : systemPort.inputEvents) {
						val pair = new Pair(systemPort, inEvent)
						// If the event is not used, the map does not contain this pair
						if (parameterMap.containsKey(pair)) {
							val expressionList = parameterMap.get(pair)
							if (expressionList.empty) {
								val loopEdge = initLoc.createEdge(initLoc)
								loopEdge.addGuard(isStableVar, LogicalOperator.AND) // For the cutting of the state space
								loopEdge.addInitializedGuards
								for (match : TopAsyncSystemInEvents.Matcher.on(engine).getAllMatches(it.asyncComposite, systemPort, null, null, inEvent)) {
									val wrapper = match.instance.type as AsynchronousAdapter
									val queue = wrapper.getContainerMessageQueue(match.port /*Wrapper port, this is the instance port*/, match.event) // In what message queue this event is stored
									val messageQueueTrace = queue.getTrace(match.instance) // Getting the owner
									loopEdge.extendEnvironmentEdge(messageQueueTrace, match.event.getConstRepresentation(match.port), createLiteralExpression => [it.text = "0"])
								}
							}
							else {
								val expressionSet = expressionList.removeDuplicatedExpressions
								for (expression : expressionSet) {
									// New edge is needed in every iteration!
									val loopEdge = initLoc.createEdge(initLoc)
									loopEdge.addGuard(isStableVar, LogicalOperator.AND) // For the cutting of the state space
									loopEdge.addInitializedGuards
									for (match : TopAsyncSystemInEvents.Matcher.on(engine).getAllMatches(it.asyncComposite, systemPort, null, null, inEvent)) {
										val wrapper = match.instance.type as AsynchronousAdapter
										val queue = wrapper.getContainerMessageQueue(match.port /*Wrapper port, this is the instance port*/, match.event) // In what message queue this event is stored
										val messageQueueTrace = queue.getTrace(match.instance) // Getting the owner
										loopEdge.extendEnvironmentEdge(messageQueueTrace, match.event.getConstRepresentation(match.port), expression)
									}
									expression.removeGammaElementFromTrace
								}
							}
						}
					}
				}
			].build
		}
	}
	
	private def void extendEnvironmentEdge(Edge edge, MessageQueueTrace messageQueueTrace,
			DataVariableDeclaration representation, Expression expression) {
		// !isFull...
		val isNotFull = createNegationExpression => [
			it.addFunctionCall(negationExpression_NegatedExpression, messageQueueTrace.isFullFunction.function)
		 ]
		edge.addGuard(isNotFull, LogicalOperator.AND)
		// push....
		edge.addPushFunctionUpdate(messageQueueTrace, representation, expression)
	}
	
	private def void extendEnvironmentEdge(Edge edge, MessageQueueTrace messageQueueTrace,
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
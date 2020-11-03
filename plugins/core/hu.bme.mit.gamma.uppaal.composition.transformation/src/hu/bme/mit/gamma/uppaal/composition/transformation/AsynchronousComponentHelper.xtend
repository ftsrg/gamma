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

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.transformation.util.queries.QueuesOfEvents
import hu.bme.mit.gamma.transformation.util.queries.SimpleWrapperInstances
import hu.bme.mit.gamma.uppaal.transformation.traceability.MessageQueueTrace
import hu.bme.mit.gamma.uppaal.util.NtaBuilder
import java.util.logging.Level
import java.util.logging.Logger
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import uppaal.declarations.DataVariableDeclaration
import uppaal.expressions.Expression
import uppaal.expressions.ExpressionsFactory
import uppaal.expressions.ExpressionsPackage
import uppaal.expressions.FunctionCallExpression
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.LogicalOperator
import uppaal.templates.Edge
import uppaal.templates.TemplatesPackage

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class AsynchronousComponentHelper {
	// Logger
	protected extension Logger logger = Logger.getLogger("GammaLogger")
	// Component
	protected final Component component 
	// Engine
	protected final extension ViatraQueryEngine engine
	// Auxiliary objects
	protected final extension NtaBuilder ntaBuilder
	protected final extension IModelManipulations manipulation
	protected final extension ExpressionTransformer expressionTransformer
	// Gamma factory
	protected final ExpressionModelFactory constrFactory = ExpressionModelFactory.eINSTANCE
	// UPPAAL packages
	protected final extension TemplatesPackage temPackage = TemplatesPackage.eINSTANCE
	protected final extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
	// UPPAAL factories
	protected final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
	// Trace
	final extension Trace trace
	
	new(Component component, ViatraQueryEngine engine, IModelManipulations manipulation,
			ExpressionTransformer expressionTransformer, NtaBuilder ntaBuilder, Trace trace) {
		this.component = component
		this.engine = engine
		this.manipulation = manipulation
		this.expressionTransformer = expressionTransformer
		this.ntaBuilder = ntaBuilder
		this.trace = trace
	}
	
	def getContainerMessageQueue(AsynchronousAdapter wrapper, Port port, Event event) {
		val queues = QueuesOfEvents.Matcher.on(engine).getAllValuesOfqueue(wrapper, port, event)
		if (queues.size > 1) {
			log(Level.WARNING, "Warning: more than one message queue " + wrapper.name + "." + port.name + "_" + event.name + ":" + queues)			
		}
		return queues.head
	}
	
	def addInitializedGuards(Edge edge) {
		if (component instanceof AsynchronousAdapter) {
			val isInitializedVar = component.initializedVariable
			edge.addGuard(isInitializedVar, LogicalOperator.AND)
		}
		if (component instanceof AsynchronousCompositeComponent) {
			for (instance : SimpleWrapperInstances.Matcher.on(engine).allValuesOfinstance) {
				val isInitializedVar = instance.initializedVariable
				edge.addGuard(isInitializedVar, LogicalOperator.AND)
			}
		}
	}
	
	/**
	 * Places a message insert in a queue equivalent update on the given edge.
	 */
	def void createQueueInsertion(Edge edge, Port systemPort, Event toRaiseEvent, ComponentInstance inInstance, DataVariableDeclaration variable) {
		val wrapper = inInstance.derivedType as AsynchronousAdapter
		val queue = wrapper.getContainerMessageQueue(systemPort, toRaiseEvent) // In what message queue this event is stored
		val messageQueueTrace = queue.getTrace(inInstance) // Getting the owner
		try {
			val constRepresentation = toRaiseEvent.getConstRepresentation(systemPort)
			if (variable === null) {  		
				edge.addPushFunctionUpdate(messageQueueTrace, constRepresentation, createLiteralExpression => [it.text = "0"])
			}
			else {
				edge.addPushFunctionUpdate(messageQueueTrace, constRepresentation, createIdentifierExpression => [it.identifier = variable.variable.head])
			}
		} catch (IllegalArgumentException e) {
			// The event is not used, we do not have to do anything
		}
	}
	
	def FunctionCallExpression addPushFunctionUpdate(Edge edge, MessageQueueTrace messageQueueTrace,
			DataVariableDeclaration representation, hu.bme.mit.gamma.expression.model.Expression expression) {
		// No addFunctionCall method as there are arguments
		edge.createChild(edge_Update, functionCallExpression) as FunctionCallExpression => [
			it.function = messageQueueTrace.pushFunction.function
			   	it.createChild(functionCallExpression_Argument, identifierExpression) as IdentifierExpression => [
			   		it.identifier = representation.variable.head
			   	]
			it.transform(functionCallExpression_Argument, expression)
		]
	}
	
		
	def FunctionCallExpression addPushFunctionUpdate(Edge edge, MessageQueueTrace messageQueueTrace,
			DataVariableDeclaration representation, Expression expression) {
		// No addFunctionCall method as there are arguments
		edge.createChild(edge_Update, functionCallExpression) as FunctionCallExpression => [
			it.function = messageQueueTrace.pushFunction.function
			it.createChild(functionCallExpression_Argument, identifierExpression) as IdentifierExpression => [
				it.identifier = representation.variable.head
			]
			it.argument += expression
		]
	}
	
}
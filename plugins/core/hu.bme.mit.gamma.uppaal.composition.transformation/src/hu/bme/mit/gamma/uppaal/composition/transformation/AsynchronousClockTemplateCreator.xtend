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

import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.transformation.util.queries.QueuesOfClocks
import hu.bme.mit.gamma.transformation.util.queries.SimpleWrapperInstances
import hu.bme.mit.gamma.transformation.util.queries.TopAsyncCompositeComponents
import hu.bme.mit.gamma.transformation.util.queries.TopWrapperComponents
import hu.bme.mit.gamma.uppaal.transformation.traceability.TraceabilityPackage
import hu.bme.mit.gamma.uppaal.util.NtaBuilder
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRule
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory
import uppaal.NTA
import uppaal.declarations.ClockVariableDeclaration
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.DeclarationsPackage
import uppaal.expressions.AssignmentExpression
import uppaal.expressions.CompareExpression
import uppaal.expressions.CompareOperator
import uppaal.expressions.ExpressionsFactory
import uppaal.expressions.ExpressionsPackage
import uppaal.expressions.FunctionCallExpression
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.LiteralExpression
import uppaal.expressions.LogicalOperator
import uppaal.templates.Location
import uppaal.templates.TemplatesPackage

import static extension hu.bme.mit.gamma.uppaal.util.Namings.*

class AsynchronousClockTemplateCreator {
	// NTA
	final NTA nta
	// Transformation rule-related extensions
	protected extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
	protected final extension IModelManipulations manipulation
	// Trace
	protected final extension Trace modelTrace
	// Engine
	protected final extension ViatraQueryEngine engine
	// Gamma package
	protected final extension TraceabilityPackage trPackage = TraceabilityPackage.eINSTANCE
	// UPPAAL packages
	protected final extension DeclarationsPackage declPackage = DeclarationsPackage.eINSTANCE
	protected final extension TemplatesPackage temPackage = TemplatesPackage.eINSTANCE
	protected final extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
	// UPPAAL factories
	protected final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
	// Id
	var id = 0
	protected final DataVariableDeclaration isStableVar
	// Auxiliary objects
    protected final extension InPlaceExpressionTransformer inPlaceExpressionTransformer = new InPlaceExpressionTransformer
	protected final extension NtaBuilder ntaBuilder
	protected final extension CompareExpressionCreator compareExpressionCreator
	protected final extension AsynchronousComponentHelper asynchronousComponentHelper
	protected final extension ExpressionTransformer expressionTransformer
	// Rules
	protected BatchTransformationRule<TopWrapperComponents.Match, TopWrapperComponents.Matcher> topWrapperClocksRule
	protected BatchTransformationRule<TopAsyncCompositeComponents.Match, TopAsyncCompositeComponents.Matcher> instanceWrapperClocksRule
	
	new(NtaBuilder ntaBuilder, ViatraQueryEngine engine, IModelManipulations manipulation,
			CompareExpressionCreator compareExpressionCreator, Trace modelTrace, DataVariableDeclaration isStableVar,
			AsynchronousComponentHelper asynchronousComponentHelper, ExpressionTransformer expressionTransformer) {
		this.ntaBuilder = ntaBuilder
		this.nta = ntaBuilder.nta
		this.manipulation = manipulation
		this.engine = engine
		this.modelTrace = modelTrace
		this.isStableVar = isStableVar
		this.compareExpressionCreator = compareExpressionCreator
		this.asynchronousComponentHelper = asynchronousComponentHelper
		this.expressionTransformer = expressionTransformer
	}
	
	def getTopWrapperClocksRule() {
		if (topWrapperClocksRule === null) {
			topWrapperClocksRule = createRule(TopWrapperComponents.instance).action [
				if (!it.wrapper.clocks.empty) {
					// Creating the template
					val initLoc = createTemplateWithInitLoc(it.wrapper.name + "Clock" + id++, "InitLoc")
					// Creating clock events
					wrapper.createClockEvents(initLoc, null /*no owner in this case*/)
				}
			].build
		}
	}
	
	def getInstanceWrapperClocksRule() {
		if (instanceWrapperClocksRule === null) {
			instanceWrapperClocksRule = createRule(TopAsyncCompositeComponents.instance).action [
				// Creating the template
				val initLoc = createTemplateWithInitLoc(it.asyncComposite.name + "Clock" + id++, "InitLoc")
				// Creating clock events
				for (match : SimpleWrapperInstances.Matcher.on(engine).allMatches) {
					match.wrapper.createClockEvents(initLoc, match.instance)
				}
			].build
		}
	}
	
	private def createClockEvents(AsynchronousAdapter wrapper, Location initLoc, AsynchronousComponentInstance owner) {
		val clockTemplate = initLoc.parentTemplate
		for (match : QueuesOfClocks.Matcher.on(engine).getAllMatches(wrapper, null, null)) {
			val messageQueueTrace = match.queue.getTrace(owner) // Getting the queue trace with respect to the owner
			// Creating the loop edge
			val clockEdge = initLoc.createEdge(initLoc)
			// It can be fired even when the queue is full to avoid DEADLOCKS (the function handles this)
			// It can be fired only if the template is stable
			clockEdge.addGuard(isStableVar, LogicalOperator.AND)		
			// Only if the wrapper/instance is initialized
			clockEdge.addInitializedGuards
			// Creating an Uppaal clock var
			val clockVar = clockTemplate.declarations.createChild(declarations_Declaration, clockVariableDeclaration) as ClockVariableDeclaration
			clockVar.createTypeAndVariable(nta.clock, clockNamePrefix + match.clock.name + owner.postfix)
			// Creating the trace
			addToTrace(match.clock, #{clockVar}, trace)
			// push....
			clockEdge.createChild(edge_Update, functionCallExpression) as FunctionCallExpression => [
		   		// No addFunctionCall method as there are arguments
		   		it.function = messageQueueTrace.pushFunction.function
		   		it.createChild(functionCallExpression_Argument, identifierExpression) as IdentifierExpression => [
		   			it.identifier = match.clock.constRepresentation.variable.head
		   		]
		   		it.createChild(functionCallExpression_Argument, literalExpression) as LiteralExpression => [
		   			it.text = "0"
		   		]
		   	]
		   	// clock = 0
		   	clockEdge.createChild(edge_Update, assignmentExpression) as AssignmentExpression => [
		   		it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
		   			it.identifier = clockVar.variable.head
		   		]
		   		it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
		   			it.text = "0"
		   		]
		   	]
			// Transforming S to MS
			val timeSpec = match.clock.timeSpecification
			val timeValue = timeSpec.convertToMs
			val locInvariant = initLoc.invariant
			// Putting the clock expression onto the location as invariant
			if (locInvariant !== null) {
				initLoc.insertLogicalExpression(location_Invariant, CompareOperator.LESS_OR_EQUAL, clockVar, timeValue, locInvariant, LogicalOperator.AND)
			} 
			else {
				initLoc.insertCompareExpression(location_Invariant, CompareOperator.LESS_OR_EQUAL, clockVar, timeValue)
			}
			// Putting the clock expression onto the location as guard
			clockEdge.addGuard(createCompareExpression as CompareExpression => [
				it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
					it.identifier = clockVar.variable.head // Always one variable in the container
				]
				it.operator = CompareOperator.GREATER_OR_EQUAL	
				it.transform(binaryExpression_SecondExpr, timeValue)		
			], LogicalOperator.AND)
		}
	}
	
}
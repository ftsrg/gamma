/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.yakindu.transformation.batch

import hu.bme.mit.gamma.expression.model.ExpressionModelPackage
import hu.bme.mit.gamma.expression.model.NamedElement
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.ParametricElement
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventDeclaration
import hu.bme.mit.gamma.statechart.interface_.EventDirection
import hu.bme.mit.gamma.statechart.interface_.Interface
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelPackage
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.yakindu.transformation.queries.Events
import hu.bme.mit.gamma.yakindu.transformation.queries.Interfaces
import hu.bme.mit.gamma.yakindu.transformation.traceability.TraceabilityFactory
import hu.bme.mit.gamma.yakindu.transformation.traceability.TraceabilityPackage
import hu.bme.mit.gamma.yakindu.transformation.traceability.Y2GTrace
import java.util.AbstractMap.SimpleEntry
import org.eclipse.emf.ecore.EClass
import org.eclipse.viatra.query.runtime.api.IPatternMatch
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.api.ViatraQueryMatcher
import org.eclipse.viatra.query.runtime.emf.EMFScope
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.SimpleModelManipulations
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRule
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory
import org.eclipse.viatra.transformation.runtime.emf.transformation.batch.BatchTransformation
import org.eclipse.viatra.transformation.runtime.emf.transformation.batch.BatchTransformationStatements
import org.yakindu.sct.model.sgraph.Statechart

class InterfaceTransformer {

	// Transformation-related extensions
	extension BatchTransformation transformation
	extension BatchTransformationStatements statements

	// Transformation rule-related extensions
	extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
	extension IModelManipulations manipulation

	// Engine
	protected ViatraQueryEngine engine
	// Yakindu statechart
	protected Statechart yakinduStatechart
	// The container of interfaces
	protected Package statechartInterfaces
	// The trace
	protected Y2GTrace traceRoot

	// Packages of the metamodels
	extension InterfaceModelPackage ifPackage = InterfaceModelPackage.eINSTANCE
	extension ExpressionModelPackage cmPackage = ExpressionModelPackage.eINSTANCE
	extension TraceabilityPackage trPackage = TraceabilityPackage.eINSTANCE
	
	// For add to trace
	extension ExpressionTransformer expressionTransformer

	// Transformation rules
	protected BatchTransformationRule<? extends IPatternMatch, ? extends ViatraQueryMatcher<?>> interfaceRule
	protected BatchTransformationRule<? extends IPatternMatch, ? extends ViatraQueryMatcher<?>> eventsRule

	new(Statechart yakinduStatechart, String packageName) {
		this.yakinduStatechart = yakinduStatechart
		val scope = new EMFScope(yakinduStatechart)
		engine = ViatraQueryEngine.on(scope);
		statechartInterfaces = InterfaceModelFactory.eINSTANCE.createPackage=> [
			it.name = packageName
		]
		traceRoot = TraceabilityFactory.eINSTANCE.createY2GTrace => [
			it.yakinduStatechart = yakinduStatechart
		]
		createTransformation
	}

	def execute() {
		getInterfaceRule.fireAllCurrent
		getEventsRule.fireAllCurrent
		// The created EMF models are returned
		return new SimpleEntry<Package, Y2GTrace>(statechartInterfaces, traceRoot)
	}

	private def createTransformation() {
		// Create VIATRA model manipulations
		this.manipulation = new SimpleModelManipulations(engine)
		// Create VIATRA Batch transformation
		transformation = BatchTransformation.forEngine(engine).build
		// Initialize batch transformation statements
		statements = transformation.transformationStatements
		// No genmodel here in the ExpressionTransformer, as this transformation takes place before it
		expressionTransformer = new ExpressionTransformer(this.manipulation, null /* getGammaEvent will not work*/,
			this.traceRoot,	ViatraQueryEngine.on(new EMFScope(traceRoot)), null)
	}

	protected def getInterfaceRule() {
		if (interfaceRule === null) {
			interfaceRule = createRule(Interfaces.instance).action [
				val yInterface = it.interface
				if (yInterface.name === null) {
					throw new IllegalArgumentException("The interface must have a name! " + yInterface)
				}
				val interfaceName = switch yInterface.name { case null: "Default" default: yInterface.name }
				// Creating the interface
				val interface = statechartInterfaces.createChild(package_Interfaces, ifPackage.interface) as Interface => [
					it.name = interfaceName
				]
				// Creating the trace
				addToTrace(yInterface, #{interface}, trace)
			].build
		}
		return interfaceRule
	}

	protected def getEventsRule() {
		if (eventsRule === null) {
			eventsRule = createRule(Events.instance).action [
				val yEvent = it.event
				val dir = it.direction
				// Placing it into its interface
				if ((yEvent.eContainer).allValuesOfTo.size != 1) {
					throw new IllegalArgumentException("Not one created interface: " + yEvent.eContainer + " : " +
						(yEvent.eContainer).allValuesOfTo.size)
				}
				val interface = (yEvent.eContainer).allValuesOfTo.head
				var EventDirection eventDirection
				switch (dir) {
					case IN:
						eventDirection = EventDirection.IN
					case OUT:
						eventDirection = EventDirection.OUT
					case LOCAL:
						throw new IllegalArgumentException("Local direction: " + yEvent)
				}
				val eventDeclaration = interface.createChild(interface_Events, eventDeclaration) as EventDeclaration
				eventDeclaration.direction = eventDirection
				var event = eventDeclaration.createChild(eventDeclaration_Event, ifPackage.event) as Event => [
					it.name = yEvent.name
				]
				// Adding a parameter if the Yakindu event has a type
				var ParameterDeclaration eventParam = null
				if (yEvent.type !== null) {
					switch yEvent.type.name {
						case "boolean":
							eventParam = event.createEventType(booleanTypeDefinition, event.eventParameterName)
						case "integer":
							eventParam = event.createEventType(integerTypeDefinition, event.eventParameterName)
						case "string":
							eventParam = event.createEventType(integerTypeDefinition, event.eventParameterName)
						case "real":
							eventParam = event.createEventType(decimalTypeDefinition, event.eventParameterName)
						case "void":
							event.createEventType(null, event.eventParameterName)
						default:
							throw new IllegalArgumentException("This type cannot be transformed: " + yEvent.type.name + "!")
					}
					addToTrace(yEvent.type, #{eventParam.type}, trace)
				}
				// Creating the trace
				if (eventParam !== null) {
					addToTrace(yEvent, #{event, eventParam}, trace)
				} else {
					addToTrace(yEvent, #{event}, trace)
				}
			].build
		}
		return eventsRule
	}
	
	/**
     * Creates the parameter for an event with a type.
     */
    private def createEventType(ParametricElement parametricElement, EClass type, String name) {
    	if (type === null) {
    		return null
    	}
    	return parametricElement.createChild(parametricElement_ParameterDeclarations, parameterDeclaration) as ParameterDeclaration => [
    		it.name = name
    		it.createChild(declaration_Type, type)
    	]
    }
    
    /**
     * Returns the name of the value of the given signal.
     */
    private def String getEventParameterName(NamedElement element) {
    	return element.name + "Value"
    }

	def dispose() {
		if (transformation !== null) {
			transformation.ruleEngine.dispose
		}
		transformation = null
		return
	}
}

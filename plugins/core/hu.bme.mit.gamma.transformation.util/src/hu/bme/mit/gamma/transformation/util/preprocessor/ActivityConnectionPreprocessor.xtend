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
package hu.bme.mit.gamma.transformation.util.preprocessor

import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.statechart.ActivityComposition.ActivityCompositionFactory
import hu.bme.mit.gamma.statechart.ActivityComposition.ActivityControllerPort
import hu.bme.mit.gamma.statechart.ActivityComposition.ActivityControllerPortConnection
import hu.bme.mit.gamma.statechart.ActivityComposition.ActivityDefinition
import hu.bme.mit.gamma.statechart.ActivityComposition.RunActivityAction
import hu.bme.mit.gamma.statechart.composite.AbstractAsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory
import hu.bme.mit.gamma.statechart.composite.SimpleChannel
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventDirection
import hu.bme.mit.gamma.statechart.interface_.Interface
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Persistency
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.RealizationMode
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import java.util.Map

import static com.google.common.base.Preconditions.checkNotNull

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ActivityConnectionPreprocessor {
		
	protected static final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	protected static final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected static final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	
	protected static final extension InterfaceModelFactory factory = InterfaceModelFactory.eINSTANCE
	protected static final InterfaceModelFactory interfaceFactory = InterfaceModelFactory.eINSTANCE
	protected static final CompositeModelFactory compositeFactory = CompositeModelFactory.eINSTANCE
	protected static final ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	protected static final ActivityCompositionFactory activityCompositionFactory = ActivityCompositionFactory.eINSTANCE
	protected static final extension StatechartModelFactory statechartFactory = StatechartModelFactory.eINSTANCE
	
	static ParameterDeclaration isActiveParameter // Singleton
	static Event controlEvent // Singleton
	static Interface controllerInterface // Singleton
		
	Trace trace
	
	new () {
		trace = new Trace()
	}
	
	def static getIsActiveParameter() {
		if (isActiveParameter === null) {
			isActiveParameter = expressionFactory.createParameterDeclaration
			isActiveParameter.type = expressionFactory.createBooleanTypeDefinition
			isActiveParameter.name = Namings.controlParameterName
		}
		return isActiveParameter
	}
		
	def static getControlEvent() {
		if (controlEvent === null) {
			controlEvent = interfaceFactory.createEvent
			controlEvent.persistency = Persistency.PERSISTENT
			controlEvent.name = Namings.controlEventName
			controlEvent.parameterDeclarations += getIsActiveParameter
		}
		return controlEvent
	}
	
	def static getControllerInterface() {
		if (controllerInterface === null) {
			controllerInterface = interfaceFactory.createInterface
			controllerInterface.name = Namings.controllerInterfaceName
			
			val eventDeclaration = interfaceFactory.createEventDeclaration
			controllerInterface.events += eventDeclaration
			eventDeclaration.direction = EventDirection.IN
			eventDeclaration.event = getControlEvent
		}
		return controllerInterface
	}
			
	dispatch def void unfoldActivityConnections(Component component) {
		// NO-OP
	}
		
	dispatch def void unfoldActivityConnections(AbstractSynchronousCompositeComponent component) {
		for (connection : component.activityConnections) {
			component.channels += connection.transform
		}
		
		component.activityConnections.clear // removing connections, as they are not processable after this point
		
		for (instance : component.components) {
			instance.derivedType.unfoldActivityConnections
		}
	}
	
	dispatch def void unfoldActivityConnections(AbstractAsynchronousCompositeComponent component) {
		for (connection : component.activityConnections) {
			component.channels += connection.transform
		}
		
		component.activityConnections.clear // removing connections, as they are not processable after this point
		
		for (instance : component.components) {
			instance.derivedType.unfoldActivityConnections
		}
	}
	
	dispatch def void unfoldActivityConnections(StatechartDefinition component) {		
		for (port : component.activities) {
			component.ports += port.transform
		}
		
		component.activities.clear // removing ports, as they are not processable after this point
		
		for (state : component.allStates) {
			val runActions = state.doActions.filter[it instanceof RunActivityAction].map[it as RunActivityAction].toList
			
			for (runAction : runActions) {
				state.entryActions += runAction.createEntryEvent
				state.exitActions += runAction.createExitEvent
				state.doActions -= runAction
			}
		}
	}
	
	dispatch def void unfoldActivityConnections(ActivityDefinition component) {		
		component.ports += component.controlPort
	}
	
	private def SimpleChannel transform(ActivityControllerPortConnection activityConnection) {
		if (trace.isMapped(activityConnection)) {
			return trace.get(activityConnection)
		}
		
		val activity = activityConnection.provided.derivedType as ActivityDefinition
		val channel = compositeFactory.createSimpleChannel
		
		trace.put(activityConnection, channel)
		
		channel.providedPort = compositeFactory.createInstancePortReference => [
			it.instance = activityConnection.provided
			it.port = activity.controlPort
		]
		channel.requiredPort = compositeFactory.createInstancePortReference => [
			it.instance = activityConnection.required.instance
			it.port = activityConnection.required.port.transform
		]
		
		return channel
	}
	
	private def Port transform(ActivityControllerPort activityPort) {
		if (trace.isMapped(activityPort)) {
			return trace.get(activityPort)
		}
		
		val port = interfaceFactory.createPort => [
			// Need different names for the different activities, as EcoreUtils equality  would otherwise confuse the ports
			it.name = Namings.getControllerPortName(activityPort.activity)
			it.interfaceRealization = interfaceFactory.createInterfaceRealization => [
				it.interface = getControllerInterface
				it.realizationMode = RealizationMode.REQUIRED
			]
		]
		
		trace.put(activityPort, port)
		
		return port
	}
	
	private def Port getControlPort(ActivityDefinition activity) {
		if (trace.isMapped(activity)) {
			return trace.get(activity)
		}
		
		val port = interfaceFactory.createPort => [
			it.name = Namings.controllerPortName
			it.interfaceRealization = interfaceFactory.createInterfaceRealization => [
				it.interface = getControllerInterface
				it.realizationMode = RealizationMode.PROVIDED
			]
			it.annotations += activityCompositionFactory.createActivityControllerPortAnnotation
		]
		
		trace.put(activity, port)
		
		return port
	}
	
	private def Action createEntryEvent(RunActivityAction action) {
		return createRaiseEventAction => [
			it.port = action.activity.transform
			it.event = getControlEvent
			it.arguments += expressionFactory.createTrueExpression
		]
	}
	
	private def Action createExitEvent(RunActivityAction action) {
		return createRaiseEventAction => [
			it.port = action.activity.transform
			it.event = getControlEvent
			it.arguments += expressionFactory.createFalseExpression
		]
	}
	
	static class Trace {
		
		Map<ActivityControllerPortConnection, SimpleChannel> connectionMappings = newHashMap
		Map<ActivityControllerPort, Port> portMappings = newHashMap
		Map<ActivityDefinition, Port> activityMappings = newHashMap
		
		def put(ActivityControllerPortConnection connection, SimpleChannel channel) {
			checkNotNull(connection)
			checkNotNull(channel)
			return connectionMappings.put(connection, channel)
		}
	
		def isMapped(ActivityControllerPortConnection connection) {
			checkNotNull(connection)
			return connectionMappings.containsKey(connection)
		}
	
		def get(ActivityControllerPortConnection connection) {
			checkNotNull(connection)
			return connectionMappings.get(connection)
		}
		
		def put(ActivityControllerPort activityPort, Port port) {
			checkNotNull(activityPort)
			checkNotNull(port)
			return portMappings.put(activityPort, port)
		}
	
		def isMapped(ActivityControllerPort activityPort) {
			checkNotNull(activityPort)
			return portMappings.containsKey(activityPort)
		}
	
		def get(ActivityControllerPort activityPort) {
			checkNotNull(activityPort)
			return portMappings.get(activityPort)
		}
		
		def put(ActivityDefinition activity, Port port) {
			checkNotNull(activity)
			checkNotNull(port)
			return activityMappings.put(activity, port)
		}
	
		def isMapped(ActivityDefinition activity) {
			checkNotNull(activity)
			return activityMappings.containsKey(activity)
		}
	
		def get(ActivityDefinition activity) {
			checkNotNull(activity)
			return activityMappings.get(activity)
		}
		
	}
	
	static class Namings {
	
		def static String getControllerPortName() {
			return "controller"
		}
		
		def static String getControllerPortName(Component component) {
			return component.name + "_controller"
		}
		
		def static String getControllerInterfaceName() {
			return "Controller"
		}
				
		def static String getControlEventName() {
			return "control"
		}
		
		def static String getControlParameterName() {
			return "isActive"
		}
		
	}
	
}

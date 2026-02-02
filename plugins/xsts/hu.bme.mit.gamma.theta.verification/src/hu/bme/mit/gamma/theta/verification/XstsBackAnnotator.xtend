/********************************************************************************
 * Copyright (c) 2021-2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.expression.language.parser.ExpressionLanguageParserAndLinker
import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.OpaqueExpression
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.util.ComplexTypeUtil
import hu.bme.mit.gamma.expression.util.FieldHierarchy
import hu.bme.mit.gamma.expression.util.IndexHierarchy
import hu.bme.mit.gamma.querygenerator.ThetaQueryGenerator
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.language.parser.StatechartExpressionLanguageParserAndLinker
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.trace.model.InstanceSchedule
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.verification.util.TraceBuilder
import hu.bme.mit.gamma.xsts.transformation.util.Namings
import java.util.List
import java.util.Map
import java.util.Set
import java.util.function.Function
import java.util.function.Supplier
import org.eclipse.emf.ecore.EObject

import static com.google.common.base.Preconditions.checkState
import static hu.bme.mit.gamma.xsts.transformation.util.QueueNamings.*

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class XstsBackAnnotator {
	
	protected final Component component
	protected final ThetaQueryGenerator xStsQueryGenerator
	protected final extension XstsArrayParser arrayParser
	//
	protected final Map<String, String> expressionPreprocess
	protected final XstsReferenceBackAnnotator referenceBackAnnotator
	//
	protected final String SCHEDULING_VARIABLE_PREFIX
	//
	protected ExpressionLanguageParserAndLinker parser // Lazy load
	protected final Set<Pair<Port, Event>> storedAsynchronousInEvents = newHashSet
	
	// To check if certain elements are actually raised/reached
	protected final Set<Pair<Port, Event>> raisedInEvents = newHashSet
	protected final Set<Pair<Port, Event>> raisedOutEvents = newHashSet
	protected final Set<State> activatedStates = newHashSet
	
	protected final extension TraceBuilder traceBuilder = TraceBuilder.INSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	
	new(ThetaQueryGenerator queryGenerator, XstsArrayParser arrayParser) {
		this(queryGenerator, arrayParser, "")
	}
	
	new(ThetaQueryGenerator queryGenerator, XstsArrayParser arrayParser, String schedulingVariablePrefix) {
		this(queryGenerator, arrayParser, schedulingVariablePrefix, newHashMap)
	}
	
	new(ThetaQueryGenerator queryGenerator, XstsArrayParser arrayParser,
			String schedulingVariablePrefix, Map<String, String> expressionPreprocess) {
		this(queryGenerator, arrayParser, schedulingVariablePrefix, expressionPreprocess,
			new XstsReferenceBackAnnotator(queryGenerator, [it.get(0) + " == " + it.get(1) + "." + it.get(2)]))
	}
	
	new(ThetaQueryGenerator queryGenerator, XstsArrayParser arrayParser,
			String schedulingVariablePrefix, Map<String, String> expressionPreprocess,
			XstsReferenceBackAnnotator referenceBackAnnotator) {
		this.component = queryGenerator.component
		this.xStsQueryGenerator = queryGenerator
		this.arrayParser = arrayParser
		this.SCHEDULING_VARIABLE_PREFIX = schedulingVariablePrefix // E.g., _ in IML
		this.expressionPreprocess = expressionPreprocess
		this.referenceBackAnnotator = referenceBackAnnotator
	}
	
	//
	
	def isSchedulingVariable(String id) {
		return id == Namings.instanceEndcodingVariableName.prefix
	}
	
	def String prefix(String id) '''«SCHEDULING_VARIABLE_PREFIX»«id»'''
	
	def addScheduling(String id, String value, Step step) {
		val scheduledInstanceId = Integer.valueOf(value)
		if (scheduledInstanceId <= 0) {
			return // This is not a valid index
		}
		
		val scheduledInstance = component.getScheduledInstance(scheduledInstanceId)
		
		step.addScheduling(scheduledInstance)
		// Remove old one
		step.actions.removeIf[it instanceof ComponentSchedule]
	}
	
	def void addSchedulingIfNeeded(Step step) {
		if (step.containsType(InstanceSchedule)) {
			// Async schedule already added
			return
		}
		// No schedule yet
		step.addScheduling
	}
	
	//
	
	def void parseState(String potentialStateString, Step step) {
		val instanceState = xStsQueryGenerator.getSourceState(potentialStateString)
		val controlState = instanceState.key
		val instance = instanceState.value
		step.addInstanceState(instance, controlState)
		activatedStates += controlState
	}
	
	def void parseVariable(String id, String value, Step step) {
		val instanceVariable = xStsQueryGenerator.getSourceVariable(id)
		val instance = instanceVariable.value
		val variable = instanceVariable.key
		// Getting fields and indexes regardless of primitive or complex types
		// In the case of primitive types, these hierarchies will be empty
		val fieldIndex = variable.handleFields(id, value,
				[xStsQueryGenerator.getSourceVariableFieldHierarchy(id)])
		val field = fieldIndex.key
		val indexPairs = fieldIndex.value
		for (indexPair : indexPairs) {
			val index = indexPair.key
			val parsedValue = indexPair.value
			try {
				// If the string is a literal value (e.g., false, 0, ENUM_LITERAL)
				step.addInstanceVariableState(instance, variable, field, index, parsedValue)
			} catch (RuntimeException e) {
				// Value is not a literal; parsing expression
				val expression = parsedValue.parseExpression
				step.addInstanceVariableState(instance, variable, field, index, expression)
				// This could be used in general, but the string literal based solution
				// was kept for performance purposes (no actual expression parsing is needed most of the time)
			}
		}
	}
	
	def void parseOutEvent(String id, String value, Step step) {
		val systemOutEvent = xStsQueryGenerator.getSourceOutEvent(id)
		if (value == "true" || value == "TRUE" || value == "1") { // For Theta and UPPAAL
			val event = systemOutEvent.get(0) as Event
			val port = systemOutEvent.get(1) as Port
			val systemPort = port.boundTopComponentPort // Back-tracking to the system port
			step.addOutEvent(systemPort, event)
			// Denoting that this event has been actually raised
			raisedOutEvents += systemPort -> event
		}
	}
	
	def void parseOutEventParameter(String id, String value, Step step) {
		val systemOutEvent = xStsQueryGenerator.getSourceOutEventParameter(id)
		val event = systemOutEvent.get(0) as Event
		val port = systemOutEvent.get(1) as Port
		val systemPort = port.boundTopComponentPort // Back-tracking to the system port
		val parameter = systemOutEvent.get(2) as ParameterDeclaration
		// Getting fields and indexes regardless of primitive or complex types
		val fieldIndex = parameter.handleFields(id, value,
				[xStsQueryGenerator.getSourceOutEventParameterFieldHierarchy(id)])
		val field = fieldIndex.key
		val indexPairs = fieldIndex.value
		//
		for (indexPair : indexPairs) {
			val index = indexPair.key
			val parsedValue = indexPair.value
			try {
				step.addOutEventWithStringParameter(systemPort, event, parameter,
						field, index, parsedValue)
			} catch (RuntimeException e) {
				val expression = parsedValue.parseExpression
				step.addOutEventWithParameter(systemPort, event, parameter,
						field, index, expression)
			}
		}
	}
	
	def void parseSynchronousInEvent(String id, String value, Step step) {
		val systemInEvent = xStsQueryGenerator.getSynchronousSourceInEvent(id)
		if (value == "true" || value == "TRUE" || value == "1") { // For Theta and UPPAAL
			val event = systemInEvent.get(0) as Event
			val port = systemInEvent.get(1) as Port
			val systemPort = port.boundTopComponentPort // Back-tracking to the system port
			step.addInEvent(systemPort, event)
			// Denoting that this event has been actually raised
			raisedInEvents += systemPort -> event
		}
	}
	
	def void parseSynchronousInEventParameter(String id, String value, Step step) {
		val systemInEvent = xStsQueryGenerator.getSynchronousSourceInEventParameter(id)
		val event = systemInEvent.get(0) as Event
		val port = systemInEvent.get(1) as Port
		val systemPort = port.boundTopComponentPort // Back-tracking to the system port
		val parameter = systemInEvent.get(2) as ParameterDeclaration
		// Getting fields and indexes regardless of primitive or complex types
		val fieldIndex = parameter.handleFields(id, value,
				[xStsQueryGenerator.getSynchronousSourceInEventParameterFieldHierarchy(id)])
		val field = fieldIndex.key
		val indexPairs = fieldIndex.value
		//
		for (indexPair : indexPairs) {
			val index = indexPair.key
			val parsedValue = indexPair.value
			try {
				step.addInEventWithParameter(systemPort, event, parameter, field, index, parsedValue)
			} catch (RuntimeException e) {
				val expression = parsedValue.parseExpression
				step.addInEventWithParameter(systemPort, event, parameter,
						field, index, expression)
			}
		}
	}
	
	protected def parseAsynchronousInEvent(String id, String value) {
		val messageQueue = xStsQueryGenerator.getAsynchronousSourceMessageQueue(id)
		
		val values = id.parseArray(value)
		var stringEventId = values.findFirst[it.key == new IndexHierarchy(0)]?.value
		// Note that 'id' might be a single value instead of an array due to optimization
		if (stringEventId === null) {
			stringEventId = values.findFirst[it.key == new IndexHierarchy]?.value
		}
		
		// If null - it is a default 0 value, nothing is raised
		if (stringEventId !== null) {
			// Event ID parsing
			val eventId = try {
				Integer.parseInt(stringEventId) // Enum literal indexes: UPPAAL
			} catch (NumberFormatException e) { // Enum literal names: Theta, Spin, nuXmv
				val integerEventId = stringEventId.substring(
						stringEventId.lastIndexOf("_") + 1) // _1 -> 1, _2 -> 2, ...
				try {
					Integer.parseInt(integerEventId)
				} catch (NumberFormatException e2) {
					checkState(stringEventId.endsWith("EMPTY"), stringEventId) // Empty enum literal
					0
				}
			}
			//
			if (eventId != 0) { // 0 is the "empty" cell
				try {
					val portEvent = messageQueue.getEvent(eventId) // Works if it is a port-event id
					val port = portEvent.key
					val event = portEvent.value
					val systemPort = port.boundTopComponentPort // Back-tracking to the top port
					// Sometimes message queue can contain internal events
					if (component.contains(systemPort)) {
						return systemPort -> event
					}
				} catch (IndexOutOfBoundsException e) { // Not a port-event id
					return null
				}
			}
		}
	}
	
	def void parseAsynchronousInEvent(String id, String value, Step step) {
		val systemPortEvent = id.parseAsynchronousInEvent(value)
		if (systemPortEvent !== null) {
			val systemPort = systemPortEvent.key
			val event = systemPortEvent.value
			// Checking if this event has been raised in the previous cycle
			if (!storedAsynchronousInEvents.contains(systemPort -> event)) {
				step.addInEvent(systemPort, event)
				// Denoting that this event has been actually raised
				raisedInEvents += systemPort -> event
			}
		}
	}
	
	def void parseAsynchronousInEventParameter(String id, String value, Step step) {
		val systemInEvent = xStsQueryGenerator.getAsynchronousSourceInEventParameter(id)
		val event = systemInEvent.get(0) as Event
		val port = systemInEvent.get(1) as Port
		val systemPort = port.boundTopComponentPort // Back-tracking to the system port
		// Sometimes message queues can contain internal events too
		if (component.contains(systemPort)) {
			val parameter = systemInEvent.get(2) as ParameterDeclaration
			// Getting fields and indexes regardless of primitive or complex types
			val fieldIndex = parameter.handleFields(id, value,
					[xStsQueryGenerator.getAsynchronousSourceInEventParameterFieldHierarchy(id)])
			val field = fieldIndex.key
			val indexPairs = fieldIndex.value
			
			var firstElement = indexPairs.findFirst[it.key == new IndexHierarchy(0)]
			// Note that 'id' might be a single value instead of an array due to optimization
			if (firstElement === null) {
				firstElement = indexPairs.findFirst[it.key == new IndexHierarchy]
			}
			
			if (firstElement !== null) { // Null: default value, not necessary to add explicitly
				// The slave queue should be a single-size array - sometimes there are more elements?
				val index = firstElement.key
				index.removeFirstIfNotEmpty // If the slave queue is an array, we remove the first index
				// Or we do not do anything if it is a plain value due to array optimization
				val parsedValue = firstElement.value
				try {
					step.addInEventWithParameter(systemPort, event,
							parameter, field, index, parsedValue)
				} catch (RuntimeException e) {
					val expression = parsedValue.parseExpression
					step.addInEventWithParameter(systemPort, event, parameter,
							field, index, expression)
				}
			}
		}
	}
	
	///
	
	def void handleStoredAsynchronousInEvents(String id, String value) {
		val systemPortEvent = id.parseAsynchronousInEvent(value)
		if (systemPortEvent !== null) {
			val systemPort = systemPortEvent.key
			val event = systemPortEvent.value
			// Denoting that this event is already in the queue, not a new one
			storedAsynchronousInEvents += systemPort -> event
		}
	}
	
	protected def void handleOneCapacityArrayValues(Declaration targetValueHolder,
			FieldHierarchy fieldHierarchy, List<Pair<IndexHierarchy, String>> indexPairs) {
		val dimension = targetValueHolder.getDimension(fieldHierarchy)
		for (indexPair : indexPairs) {
			val indexes = indexPair.key
			val size = indexes.size
			
			var targetType = targetValueHolder.typeDefinition
			
			for (var i = size; i < dimension; i++) {
				checkState(targetType.oneCapacityArray)
				val value = 0
				indexes.prepend(value)
				
				targetType = targetType.arrayElementType.typeDefinition
			}
		}
	}
	
	protected def handleFields(Declaration declaration, String id, String value,
			Supplier<FieldHierarchy> fieldComputer) {
		val field = fieldComputer.get
		val indexPairs = id.parseArray(value)
		declaration.handleOneCapacityArrayValues(field, indexPairs)
		
		return field -> indexPairs
	}
	
	///
	
	protected def getParser() {
		if (parser === null) {
			parser = new StatechartExpressionLanguageParserAndLinker
		}
		return parser
	}
	
	def parseAndPostprocessExpression(String value) {
		val expression = value.parseExpression
		val postprocessedExpression = expression.postprocess
		return postprocessedExpression
	}
	
	def parseExpression(String value) {
		val parser = getParser
		val expression = parser.preprocessAndParse(value,
			new Function<String, EObject> {
				override apply(String id) {
					return referenceBackAnnotator.parseReference(id)
				}
			},
			expressionPreprocess)
		
		return expression
	}
	
	def Expression postprocess(Expression expression) {
		if (expression instanceof ComponentInstanceEventReferenceExpression) {
			val port = expression.port
			val systemPort = port.boundTopComponentPort
			
			val raiseAct = systemPort.createRaiseEventAct(expression.event)
			raiseAct.arguments.clear
			return raiseAct
		}
		else if (expression instanceof ComponentInstanceEventParameterReferenceExpression) {
			val port = expression.port
			val systemPort = port.boundTopComponentPort
			
			return systemPort.createEventParameterReference(expression.parameterDeclaration)
		}
		else if (expression instanceof EqualityExpression) {
			val left = expression.leftOperand
			val right = expression.rightOperand
			if (left instanceof OpaqueExpression) {
				val lString = left.expression
				if (right instanceof ComponentInstanceStateReferenceExpression) { // Control location
					return right // No else
				}
				if (right instanceof OpaqueExpression) {
					// "_subtraffic_light_Example_ControllerStatechart" = "_subtraffic_light_Example_ControllerStatechart";
					val rString = right.expression
					if (lString == rString) {
						if (xStsQueryGenerator.isSourceRegion(lString)) {
							val regionInstance = xStsQueryGenerator.getSourceRegion(lString)
							val region = regionInstance.key
							val instance = regionInstance.value
							return '''Region «region.name» of «instance.name» remains the same'''.createOpaqueExpression
						}
					}
					/// Queue handling: note that these are heuristics
					if (lString.startsWith(MASTER_PREFIX.prefix)) {
						val lhs = lString.substring(MASTER_PREFIX.prefix.length)
								.replace(OF, ''' «OF» ''' )
						val rhs = (rString.endsWith("EMPTY")) ? "is empty" : "contains " + rString.substring(
								[!it.idChar]).substring([it.idChar])
								
						return '''«lhs» «rhs»'''.createOpaqueExpression
					}
					///
				}
			}
		}
		if (expression instanceof BinaryExpression) {
			val left = expression.leftOperand
			val right = expression.rightOperand
			if (left instanceof OpaqueExpression) {
				val lString = left.expression
				/// Queue handling: note that these are heuristics
				var string =
					if (lString.startsWith(SIZE_MASTER_PREFIX.prefix)) {
						"Size of " + lString.substring(SIZE_MASTER_PREFIX.prefix.length)
					}
					else if (lString.startsWith(SLAVE_PREFIX.prefix)) {
						lString.substring(SLAVE_PREFIX.prefix.length)
					}
					else if (lString.startsWith(SIZE_SLAVE_PREFIX.prefix)) {
						"Size of " + lString.substring(SIZE_SLAVE_PREFIX.prefix.length)
					}
					else { "" }
				string = string.replace(OF, ''' «OF» ''' )
				if (!string.nullOrEmpty) {
					if (left.helperEquals(right)) {
						return '''«string» retains its value'''.createOpaqueExpression
					}
					left.expression = string
					// No return
				}
				///
			}
		}
		
		val subexpressions = expression.getAllContentsOfType(Expression)
		for (subexpression : subexpressions) {
			val newSubexpression = subexpression.postprocess
			newSubexpression.replace(subexpression)
		}
		
		return expression
	}
	
	static class XstsReferenceBackAnnotator {
		//
		protected final List<String> unparsableIds = newArrayList
		
		protected final ThetaQueryGenerator xStsQueryGenerator
		protected final Function<List<?>, String> targetStateAdapter
		
		protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
		protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
		protected final extension ComplexTypeUtil complexTypeUtil = ComplexTypeUtil.INSTANCE
		//
		
		new(ThetaQueryGenerator xStsQueryGenerator) {
			this(xStsQueryGenerator, null)
		}
		
		new(ThetaQueryGenerator xStsQueryGenerator, Function<List<?>, String> targetStateAdapter) {
			this.xStsQueryGenerator = xStsQueryGenerator
			this.targetStateAdapter = targetStateAdapter
		}
		
		//
		protected def parseReference(String id) {
			// TODO arrays
			return if (xStsQueryGenerator.isSourceVariable(id)) {
				val instanceVariable = xStsQueryGenerator.getSourceVariable(id)
				val instance = instanceVariable.value
				val variable = instanceVariable.key
				
				val reference = instance.createInstanceReference.createVariableReference(variable)
				
				reference.handleFields([xStsQueryGenerator.getSourceVariableFieldHierarchy(id)])
			}
			else if (xStsQueryGenerator.isSourceOutEvent(id) ||
						xStsQueryGenerator.isSynchronousStatechartSourceInEvent(id) /* Only sync, no support for queues */) {
				val isOut = xStsQueryGenerator.isSourceOutEvent(id)
				val instanceEvent = isOut ?
					xStsQueryGenerator.getSourceOutEvent(id):
					xStsQueryGenerator.getSynchronousSourceInEvent(id)
				val event = instanceEvent.head as Event
				val port = instanceEvent.get(1) as Port
				val instance = instanceEvent.lastOrNull as ComponentInstance
				
				instance.createInstanceReference.createEventReference(port, event)
			}
			else if (xStsQueryGenerator.isSourceOutEventParameter(id) ||
						xStsQueryGenerator.isSynchronousStatechartSourceInEventParameter(id) /* Only sync, no support for queues */) {
				val isOut = xStsQueryGenerator.isSourceOutEventParameter(id)
				val instanceEvent = isOut ?
					xStsQueryGenerator.getSourceOutEventParameter(id) :
					xStsQueryGenerator.getSynchronousSourceInEventParameter(id)
				val event = instanceEvent.head as Event
				val port = instanceEvent.get(1) as Port
				val parameter = instanceEvent.get(2) as ParameterDeclaration
				val instance = instanceEvent.lastOrNull as ComponentInstance
				
				val reference = instance.createInstanceReference.createParameterReference(port, event, parameter)
				
				reference.handleFields(isOut ? [xStsQueryGenerator.getSourceOutEventParameterFieldHierarchy(id)] :
						[xStsQueryGenerator.getSynchronousSourceInEventParameterFieldHierarchy(id)])
			}
			else if (xStsQueryGenerator.isSourceTypeDeclaration(id)) {
				val typeDeclaration = xStsQueryGenerator.getSourceTypeDeclaration(id)
				typeDeclaration.createTypeReference
			}
			else if (id.isSourceState) { // Before enums as an enum literal can have the same id as a state
				val instanceState = id.getSourceState
				unparsableIds.clear
				
				val instance = instanceState.value
				val state = instanceState.key
				
				instance.createInstanceReference.createStateReference(state)
			}
			else if (xStsQueryGenerator.isSourceEnumLiteral(id)) {
				val literal = xStsQueryGenerator.getSourceEnumLiteral(id)
				literal.createEnumerationLiteralExpression
			}
			else {
				unparsableIds += id
				null // As expected by the parser
			}
		}
		
		protected def isSourceState(String id) {
			try {
				id.getSourceState
				return true
			} catch (IllegalArgumentException e) {
				return false
			}
		}
		
		protected def getSourceState(String id) {
			if (unparsableIds.size < 2) {
				throw new IllegalArgumentException
			}
			
			val beforeLast = unparsableIds.beforeLastElement
			val last = unparsableIds.lastElement
			
			val potentialStateString = targetStateAdapter.apply(#[beforeLast, last, id])
			
			return xStsQueryGenerator.getSourceState(potentialStateString)
		}
		
		protected def handleFields(Expression reference, Supplier<FieldHierarchy> fieldComputer) {
			val fields = fieldComputer.get
			return (fields.empty) ? reference :
					reference.createAccess(fields)
		}
		
	}
	
	///
	
	def isArray(String id, String value) {
		return arrayParser.isArray(id, value)
	}
	
	///
	
	def void checkStates(Step step) {
		val raiseEventActs = step.outEvents
		for (raiseEventAct : raiseEventActs) {
			if (!raisedOutEvents.contains(raiseEventAct.port -> raiseEventAct.event)) {
				raiseEventAct.delete
			}
		}
		val asserts = step.asserts
		val instanceStates = step.instanceStateConfigurations
		for (instanceState : instanceStates) {
			// A state is active if all of its ancestor states are active
			val ancestorStates = instanceState.state.ancestors
			for (ancestorState : ancestorStates) {
				if (!activatedStates.contains(ancestorState)) { // Can happen due to slicing
					val ancestorStateReference = instanceState.clone
					ancestorStateReference.region = ancestorState.parentRegion
					ancestorStateReference.state = ancestorState
					
					if (!asserts.exists[it.helperEquals(ancestorStateReference)]) { // To avoid duplication
						asserts += ancestorStateReference
					}
				}
//				instanceState.delete // Was necessary when history literals were not yet introduced
			}
		}
		raisedOutEvents.clear // Crucial
		activatedStates.clear // Crucial
	}
	
	def void checkInEvents(Step step) {
		val raiseEventActs = step.actions.filter(RaiseEventAct).toList
		for (raiseEventAct : raiseEventActs) {
			if (!raisedInEvents.contains(raiseEventAct.port -> raiseEventAct.event)) {
				raiseEventAct.delete
			}
		}
		raisedInEvents.clear // Crucial
		storedAsynchronousInEvents.clear // Crucial
	}
	
}
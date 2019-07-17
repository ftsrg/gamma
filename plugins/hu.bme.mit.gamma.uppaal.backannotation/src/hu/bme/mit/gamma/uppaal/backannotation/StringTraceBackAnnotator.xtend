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
package hu.bme.mit.gamma.uppaal.backannotation

import hu.bme.mit.gamma.constraint.model.BooleanTypeDefinition
import hu.bme.mit.gamma.constraint.model.ConstraintModelFactory
import hu.bme.mit.gamma.constraint.model.Expression
import hu.bme.mit.gamma.constraint.model.IntegerTypeDefinition
import hu.bme.mit.gamma.constraint.model.ParameterDeclaration
import hu.bme.mit.gamma.statechart.model.Package
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponent
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.trace.model.TraceFactory
import hu.bme.mit.gamma.uppaal.backannotation.patterns.EventRepresentations
import hu.bme.mit.gamma.uppaal.backannotation.patterns.ExpressionTraces
import hu.bme.mit.gamma.uppaal.backannotation.patterns.Functions
import hu.bme.mit.gamma.uppaal.backannotation.patterns.InstanceTraces
import hu.bme.mit.gamma.uppaal.backannotation.patterns.IsActiveVariables
import hu.bme.mit.gamma.uppaal.backannotation.patterns.LocationToState
import hu.bme.mit.gamma.uppaal.backannotation.patterns.Locations
import hu.bme.mit.gamma.uppaal.backannotation.patterns.PortTraces
import hu.bme.mit.gamma.uppaal.backannotation.patterns.TopAsyncSystemInEvents
import hu.bme.mit.gamma.uppaal.backannotation.patterns.TopAsyncSystemOutEvents
import hu.bme.mit.gamma.uppaal.backannotation.patterns.TopSyncSystemInEvents
import hu.bme.mit.gamma.uppaal.backannotation.patterns.TopSyncSystemOutEvents
import hu.bme.mit.gamma.uppaal.backannotation.patterns.Traces
import hu.bme.mit.gamma.uppaal.backannotation.patterns.VariableDelcarations
import hu.bme.mit.gamma.uppaal.backannotation.patterns.VariableToEvent
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace
import java.io.BufferedReader
import java.io.StringReader
import java.math.BigInteger
import java.util.AbstractMap.SimpleEntry
import java.util.ArrayList
import java.util.Collection
import java.util.HashSet
import java.util.LinkedList
import java.util.Map
import java.util.Map.Entry
import java.util.regex.Pattern
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.emf.ecore.util.EcoreUtil.Copier
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.ExpressionInitializer
import uppaal.declarations.Variable
import uppaal.declarations.VariableDeclaration
import uppaal.templates.Location
import uppaal.templates.Template

import static com.google.common.base.Preconditions.checkState

class StringTraceBackAnnotator {
	
	protected final String STATE_CONST_PREFIX = "State"
	protected final String STATE_CONST = "State:"
	protected final String TRANSITIONS_CONST = "Transitions:"
	protected final String DELAY_CONST = "Delay:" 
	
	protected final String stringUppaalTrace
	
	protected final ResourceSet resourceSet
	protected final ViatraQueryEngine engine
	
	protected Package gammaPackage
	protected Component component
	
	protected final extension ConstraintModelFactory cntFact = ConstraintModelFactory.eINSTANCE
	protected final extension TraceFactory trFact = TraceFactory.eINSTANCE

	new(ResourceSet resourceSet, String stringUppaalTrace) {
//		val fileWriter = new FileWriter("F:\\eclipse_ws\\gamma_dev\\runtime-EclipseXtext\\hu.bme.mit.gamma.tutorial\\model\\trace.txt")
//		fileWriter.write(stringUppaalTrace)
//		fileWriter.flush
//		fileWriter.close		
//		println(stringUppaalTrace)
		this.stringUppaalTrace = stringUppaalTrace
		this.resourceSet = resourceSet
		this.resourceSet.loadModels
		this.engine = ViatraQueryEngine.on(new EMFScope(this.resourceSet))	
	}

	/**
	 * Creates the Trace model.
	 */
	def ExecutionTrace execute() {
		// Creating the trace component
		val trace = createExecutionTrace => [
			it.component = this.component
			it.import = this.component.eContainer as Package
			it.name = this.component.name + "Trace"
		]
		// Setting the arguments
		for (parameter : this.component.parameterDeclarations) {
			val uppaalVariableDeclaration = parameter.allValuesOfTo.head as DataVariableDeclaration
			val uppaalVariable = uppaalVariableDeclaration.variable.head
			val initExpression = uppaalVariable.initializer as ExpressionInitializer
			val gammaExpression = initExpression.expression.allExpressionValuesOfFrom.head as Expression
			val newGammaExpression = gammaExpression.clone(true, true)
			trace.arguments += newGammaExpression
		}
		// Back-annotating the steps
		var isFirstStep = true
		// Collections to store the locations and variable values in
		var Collection<Location> lastActiveLocations
		var Collection<Entry<Variable, Integer>> variableCollection
		// Actual step into we collect the actions
		var step = createStep
		
		val reader = new BufferedReader(new StringReader(stringUppaalTrace))
		var String line = null
		var state = BackAnnotatorState.INITIAL
		while ((line = reader.readLine) !== null) {
			// Variable line contains a single line from the trace
			switch (line) {
				case STATE_CONST_PREFIX: // There is a bug where State is written instead of State:
					state = BackAnnotatorState.STATE_LOCATIONS
				case STATE_CONST:
					state = BackAnnotatorState.STATE_LOCATIONS
				case TRANSITIONS_CONST:
					state = BackAnnotatorState.TRANSITIONS
				case line.startsWith(DELAY_CONST): {
					// Parsing delays
					val delay = parseDelay(line)
					step.addTimeElapse(delay)
				}
				case line.empty:
					state = state // no operation
				default:
					// This is the place for the parsing
					switch (state) {
						case BackAnnotatorState.STATE_LOCATIONS: {
							lastActiveLocations = parseLocations(line)
							state = BackAnnotatorState.STATE_VARIABLES					
						}
						case BackAnnotatorState.STATE_VARIABLES: {
							variableCollection = parseVariables(line)					
						}
						case BackAnnotatorState.TRANSITIONS: {
							// Parsing in events
							step.parseTransition(line)
							// Parsing schedulings
							step.parseAsyncInstances(line) // Executes only for Async Composites
							if (isStepStarted(line) && isFirstStep) {
								// New step is created in the first step
								val firstStep = createStep
								firstStep.parseOutActions(lastActiveLocations, variableCollection)
								trace.steps += firstStep
								isFirstStep = false
								// No incoming events or delay are cleared, as these occurrences will appear in the next step
							}
							else if (isStepEnded(line) && !isFirstStep) {
								step.parseOutActions(lastActiveLocations, variableCollection)
								// If it is a sync component, this is where it has to be scheduled
								step.scheduleIfSynchronousComponent
								trace.steps += step
								// Creating a new step for the next turn
								step = createStep
							}						
						}
						case BackAnnotatorState.DELAY: {
							// Parsed in the previous switch
						}
						default:
							throw new IllegalArgumentException("Not known line: " + line)
					}
			}
		}
		if (isFirstStep) {
			// In this case not a single step has been executed
			val firstStep = createStep
			firstStep.parseOutActions(lastActiveLocations, variableCollection)
			trace.steps += firstStep
		}
		return trace
	}
	
	/**
	 * Loads the individual resources from the resource set. 
	 */
	protected def loadModels(ResourceSet resourceSet) {
		// Getting the G2UTrace from the resource set
		val g2uTraceResourceList = resourceSet.resources.filter[it.contents.head instanceof G2UTrace].toList
		if (g2uTraceResourceList.size != 1) {
			throw new IllegalArgumentException("The resource set contains more than one g2uTrace: " + resourceSet)
		}
		val traceRoot = g2uTraceResourceList.head.contents.head as G2UTrace
		val nta = traceRoot.nta
		gammaPackage = traceRoot.gammaPackage
		component = gammaPackage.components.head
		if (traceRoot === null || nta === null) {
			throw new IllegalArgumentException("One required resource could not be resolved.")
		}
	}
	
	protected def scheduleIfSynchronousComponent(Step step) {
		if (component instanceof SynchronousComponent) {
			step.addComponentScheduling
		}
	}
	
	protected def addInEvent(Step step, Port port, Event event, Integer parameter) {
		val eventRaise = createRaiseEventAct(port, event, parameter)
		step.actions += eventRaise
	}
	
	protected def createRaiseEventAct(Port port, Event event, Integer parameter) {
		val RaiseEventAct eventRaise = createRaiseEventAct => [
			it.port = port
			it.event = event
		]
		if (parameter !== null) {
			eventRaise.arguments += event.createParameter(parameter)
		}		
		return eventRaise
	}
	
	protected def createParameter(Event event, Integer parameter) {
		if (event.parameterDeclarations.empty) {
			return null
		}
		val paramType = event.parameterDeclarations.head.type
		val literal = switch (paramType) {
			IntegerTypeDefinition: createIntegerLiteralExpression => [it.value = BigInteger.valueOf(parameter)]
			BooleanTypeDefinition: {
				if (parameter == 0) {
					createFalseExpression
				}
				else {
					createTrueExpression
				}
			}
		}
		return literal
	}
	
	protected def addTimeElapse(Step step, int elapsedTime) {
		val timeElapseActions = step.actions.filter(TimeElapse)
		if (!timeElapseActions.empty) {
			// A single time elapse action in all steps
			val action = timeElapseActions.head
			val newTime = action.elapsedTime + BigInteger.valueOf(elapsedTime)
			action.elapsedTime = newTime
		}
		else {
			// No time elapses in this step so far
			step.actions += createTimeElapse => [
				it.elapsedTime = BigInteger.valueOf(elapsedTime)
			]
		}
	}
	
	protected def addScheduling(Step step, AsynchronousComponentInstance instance) {
		step.actions += createInstanceSchedule => [
			it.scheduledInstance = instance
		]
	}
	
	protected def addComponentScheduling(Step step) {
		step.actions += createComponentSchedule
	}
	
	protected def addOutEvent(Step step, Port port, Event event, Integer parameter) {
		val eventRaise = createRaiseEventAct(port, event, parameter)
		step.outEvents += eventRaise
	}
	
	protected def addInstanceState(Step step, SynchronousComponentInstance instance, State state) {
		step.instanceStates += createInstanceStateConfiguration => [
			it.instance = instance
			it.state = state
		]
	}
	
	/** ( P_ControlTemplate.InitLoc P_main_regionOfStatechartOftest.S P_innerOfSOftest.EntryLocation0 P_SchedulerTemplate.InitLoc ) */
	protected def Collection<Location> parseLocations(String line) {
		val locations = new HashSet<Location>
		val locationNames = new LinkedList<String>(line.split(" "))
		// Dropping the first " (" and last " )" elements
		locationNames.removeIf[it == "(" || it == ")"]
		for (locationName : locationNames) {
			val fullName = locationName.split("\\.")
			val templateName = fullName.head.substring(2) // Removing P_ from the template name: ControlTemplate
			val shortLocationName = fullName.last // Getting InitLoc
			val location = Locations.Matcher.on(engine).getAllValuesOflocation(null, templateName, shortLocationName)
			if (location.size != 1) {
				throw new IllegalArgumentException("No location retrieved: " + locationName)
			}
			locations.add(location.head)
		}
		return locations
	}
	
	protected def parseVariables(String line) {
		val Collection<Entry<Variable, Integer>> variableList = new ArrayList<Entry<Variable, Integer>>
		// isStable=1 countOftest=3 toRaise_TestRequired_cOftest=0 isRaised_TestRequired_cOftest=0
		val allVariableValues = line.split(" ")
		for (variableValue : allVariableValues.filter[!it.empty]) {
			val splittedName = variableValue.split("=") // [P_inner2OfSOftest.timer9, 0]
			val fullName = splittedName.head
			val name = if (fullName.contains(".")) {
				fullName.substring(splittedName.head.lastIndexOf(".") + 1)
			}
			else {
				fullName
			}
			// Not parsing timers, as they are not needed and their parsing is complicated
			// P_inner2OfSOftest.timer7<=0, P_inner2OfSOftest.timer7-P_inner2OfSOftest.timer9<=0,
			if (!name.startsWith("timer") && !name.startsWith("#depth")) { // #depth is given in cases of A<>, maybe cycle?
				var Collection<VariableDeclaration> variableDeclarations
				// Parsing isActive variables uniquely as their names do not differ
				if (name == "isActive") {
					val templateName = fullName.substring(2, splittedName.head.lastIndexOf("."))
					variableDeclarations = IsActiveVariables.Matcher.on(engine).getAllValuesOfisActiveVariableDeclaration(templateName)
				}
				else {				
					variableDeclarations = VariableDelcarations.Matcher.on(engine).getAllValuesOfvariableDeclaration(name)
				}
				if (variableDeclarations.size != 1) {
					throw new IllegalArgumentException("More than one variable retrieved for " + variableValue + ": " + variableDeclarations.map[it.variable.head])
				}
				val value = splittedName.last
				val variable = variableDeclarations.head.variable.head
				variableList.add(new SimpleEntry<Variable, Integer>(variable, Integer.parseInt(value)))			
			}		
		}
		return variableList
	}
	
	protected def backAnnotateLocations(Step step, Collection<Location> locations, Collection<Entry<Variable, Integer>> variableList) {
		for (location: locations) {
			val template = location.parentTemplate
			if (template.isActive(variableList)) {
				val state = location.toState
				if (state !== null) {
					val instance = template.owner
					step.addInstanceState(instance, state)
				}
			}
		}
	}
	
	protected def parseSystemOutEvents(Step step, Collection<Entry<Variable, Integer>> variableList) {
		for (variableMap : variableList) {
			// Back-annotation according to parameter type			
			val event = (variableMap.key.container as VariableDeclaration).event
			val uppaalVariable = variableMap.key.container as VariableDeclaration
			if (event === null) {
				// Not an event, it might be a valueof
				val params = uppaalVariable.allValuesOfFrom.filter(ParameterDeclaration) // These variables are traced to ParameterDeclarations only (and not events)
					// Checking whether the variable is a parameter variable: valueOf variable					
					if (params.size == 1) {
						val paramedEvent = params.head.eContainer as Event // Getting the container Event of the ParameterDeclaration
						// Getting the composite system Port bound to the instance port (Uppaal variables contain the port name on which the event is raised)
						val matches = TopSyncSystemOutEvents.Matcher.on(engine).getAllMatches(null, null, uppaalVariable.owner, uppaalVariable.port, paramedEvent)
						if (matches.size > 0) {
							checkState(matches.size == 1, matches)
							val match = matches.head
							// Getting the valueof Uppaal variable
							val uppaalVars = paramedEvent.allValuesOfTo.filter(DataVariableDeclaration).filter[it.owner == uppaalVariable.owner]
												.filter[it.variable.head.name == paramedEvent.getOutEventName(uppaalVariable.port, uppaalVariable.owner)] // Connected to isRaised variable
							if (uppaalVars.size != 1) {
								throw new IllegalArgumentException("Not one uppaal variable from parameter: " + paramedEvent.name + " " + uppaalVars)
							}
							val uppaalVar = uppaalVars.head.variable.head
							// Checking whether the bool event flag is raised (out events have one bool flag)
							if (variableList.filter[it.key == uppaalVar].head.value >= 1) {
								val rightValue = variableMap.value
								val syncPort = match.systemPort
								val raisedEvent = match.event
								// Checking if it led out to an async composite system port
								val asyncMatches = TopAsyncSystemOutEvents.Matcher.on(engine).getAllMatches(null, null, null, syncPort, raisedEvent)
								if (asyncMatches.size > 1) {
									throw new IllegalArgumentException("More than one async system event: " + asyncMatches)
								}
								if (asyncMatches.size == 1) {
									// Event is led out to an async system port
									val asyncPort = asyncMatches.head.systemPort
									step.addOutEvent(asyncPort, raisedEvent, rightValue)
								}
								else if (component instanceof AsynchronousAdapter || component instanceof SynchronousComponent)  {
									// Event is not led out to an async system port (sync or wrapper component)
									step.addOutEvent(syncPort, match.event, rightValue)
								}
							}
						}
					}
					// Else it is a regular variable
			}
			// Next, checking wheter it is an event without parameter (No valueOf) (Valueofs are taken care of in the if branch)
			else if (event.parameterDeclarations.empty) {
				val matches = TopSyncSystemOutEvents.Matcher.on(engine).getAllMatches(null, null, uppaalVariable.owner, uppaalVariable.port, event)
				if (matches.size > 0) {
					val match = matches.head
					// Checking whether it is raised
					if (variableMap.value >= 1) {
						val syncPort = match.systemPort
						val raisedEvent = match.event
						// Checking if it led out to an async composite system port
						val asyncMatches = TopAsyncSystemOutEvents.Matcher.on(engine).getAllMatches(null, null, null, syncPort, raisedEvent)
						if (asyncMatches.size > 1) {
							throw new IllegalArgumentException("More than one async system event: " + asyncMatches)
						}
						if (asyncMatches.size == 1) {
							// Event is led out to an async system port
							val asyncPort = asyncMatches.head.systemPort
							step.addOutEvent(asyncPort, raisedEvent, null)
						}
						else if (component instanceof AsynchronousAdapter || component instanceof SynchronousComponent) {
							// Event is not led out to an async system port (sync or wrapper component)
							step.addOutEvent(syncPort, raisedEvent, null)
						}						
					}
				}
			}		
		}
	}
	
	protected def parseDelay(String line) {
		if (line.empty) {
			return 0
		}
		return Integer.parseInt(line.substring(DELAY_CONST.length + 1))
	}
	
	protected def parseAsyncInstances(Step step, String line) {
		if (!(component instanceof AsynchronousComponent) || /*Only for async composites*/
			!line.matches("(.*)Scheduler(.*)\\.(.*)->(.*)Scheduler(.*)\\.(.*)") /*Parsing scheduler template*/){
			// The line is not of scheduler template
			return
		}
		if (component instanceof AsynchronousAdapter) {
			step.addComponentScheduling
		}
		else {
			// Parsing scheduling synchronizations of asynchronous composite components
			val actionStrings = line.substring(line.indexOf("{") + 2, line.indexOf("}") - 1).split(", ")  // { 1, crossroads1!, 1 } -> 1, crossroads1!, 1
			val sync = actionStrings.findFirst[it.endsWith("!")]
			val syncVariableName = sync.substring(0, sync.length - 1)
			val syncVariable = syncVariableName.variableDeclaration
			val asyncInstance = syncVariable.allValuesOfFrom.filter(AsynchronousComponentInstance).head
			step.addScheduling(asyncInstance)
		}
	}
	
	protected def containsEnvironmentEvents(String line) {
		line.matches("(.*)Environment(.*)\\.InitLoc->(.*)Environment(.*)\\.InitLoc(.*)") || // Sync component
		line.matches("(.*)Connector(.*)\\.InitLoc->(.*)") // Wrapper component
	}
	
	protected def isWrapperEnvironment(String line) {
		return component instanceof AsynchronousComponent && 
			line.matches("(.*)Environment(.*)\\.InitLoc->(.*)Environment(.*)\\.InitLoc(.*)")
	}
	
	protected def isWrapperConnector(String line) {
		return component instanceof AsynchronousComponent && 
			line.matches("(.*)Connector(.*)\\.InitLoc->(.*)") // Wrapper component
	}
	
	protected def parseTransition(Step step, String line) {
		if (!line.containsEnvironmentEvents) {
			return
		}
		// Parsing in events
		val actionString = line.substring(line.indexOf("{") + 2, line.indexOf("}") - 1) // { 1, tau, isStable := 1 } -> 1, tau, isStable := 1
		val actions = actionString.splitLine // [pushcrossroadsMessages(PoliceInterrupt_police, 0)] -> [pushcrossroadsMessages(PoliceInterrupt_police, 0)]
		// Checking in events and parameters
		val eventRaiseActions = actions.filter[it.startsWith("toRaise_") /* Synchronous components */ 
			|| it.startsWith("isRaised_") /* Cascade components (only a single event queue) */
			|| it.split(" := ").head.endsWith("Value") /* Value of */
			|| (line.isWrapperEnvironment && it.matches(".*push(.)*\\((?<event>\\w+), (?<value>\\d+)\\).*")) /* Async in events*/
		].toList
		// Getting the variable declaration objects
		for (eventRaiseAction : eventRaiseActions) {
			// isActive := 0
			val splittedAction = eventRaiseAction.parseEventRaise // [toRaise..., 0]
			val variableName = splittedAction.get("name")
			val variableValue = splittedAction.get("value")
			val variableDeclaration = variableName.variableDeclaration
			if (component instanceof SynchronousComponent) {
				val event = variableDeclaration.event
				if (event !== null) {
					// Getting the composite system Port bound to the instance port (Uppaal variables contain the port name on which the event is raised)
					val matches = TopSyncSystemInEvents.Matcher.on(engine).getAllMatches(null, null, variableDeclaration.owner, variableDeclaration.port, event)
					if (matches.size > 0) {
						val match = matches.head							
						if (event.parameterDeclarations.empty) {
							// Putting in the trace only if it is not a typed event (with valueof variable)
							// If it is a typed event, the else branch will take care of it in the next turn
							// [toRaise_Test_testInOfcontroller := 1, Test_testInOfcontrollerValue := 5]
							step.addInEvent(match.systemPort,  match.event, null)						
						}
					}				
				}
				else {
					val params = variableDeclaration.allValuesOfFrom.filter(ParameterDeclaration) // These variables are traced to ParameterDeclarations only (and not events)
					// Checking whether the variable is a parameter variable: valueOf variable					
					if (params.size == 1) {
						val paramedEvent = params.head.eContainer as Event // Getting the container Event of the ParameterDeclaration
						// Getting the composite system Port bound to the instance port (Uppaal variables contain the port name on which the event is raised)
						val matches = TopSyncSystemInEvents.Matcher.on(engine).getAllMatches(null, null, variableDeclaration.owner, variableDeclaration.port, paramedEvent)
						if (matches.size > 0) {
							val match = matches.head
							step.addInEvent(match.systemPort, match.event, Integer.parseInt(variableValue))
						}
					}
					// Else it is a regular variable assignment, we do not care about it
				}			
			}
			else if (component instanceof AsynchronousAdapter) {
				val match = (variableDeclaration as DataVariableDeclaration).getWrapperEvent(null)
				if (match !== null) {
					if (match.event.parameterDeclarations.empty) {
						step.addInEvent(match.port, match.event, null)
					} 
					else {
						step.addInEvent(match.port, match.event, Integer.parseInt(variableValue))
					}
				}
			}
			else if (component instanceof AsynchronousCompositeComponent) {
				val functionName = splittedAction.get("function") // Push function
				val owner = functionName.peekFunction.asyncOwner
				val match = (variableDeclaration as DataVariableDeclaration).getWrapperEvent(owner.type as AsynchronousAdapter)
				if (match !== null) {
					// Instance ports must be traced back to system level ports
					val systemMatches = TopAsyncSystemInEvents.Matcher.on(engine).getAllMatches(null, null, owner, match.port, match.event)
					if (systemMatches.size > 0) {
						// It is not an error if there is no match, as not all events are connected to a system level port
						if (systemMatches.size != 1) {
							throw new IllegalArgumentException("Not one system match: " + systemMatches)
						}
						val systemMatch = systemMatches.head
						if (systemMatch.event.parameterDeclarations.empty) {
							step.addInEvent(systemMatch.systemPort, systemMatch.event, null)
						} 
						else {
							step.addInEvent(systemMatch.systemPort, systemMatch.event, Integer.parseInt(variableValue))
						}
					}
				}
			}
		}
	}
	
    protected def parseOutActions(Step step, Collection<Location> lastActiveLocations, Collection<Entry<Variable, Integer>> variableCollection) {
		step.backAnnotateLocations(lastActiveLocations, variableCollection)
		// Checking the out events of the first stable state
		step.parseSystemOutEvents(variableCollection)
    }
	 
	/**
	 * Used to merge splitted function calls.
	 */
	protected def String[] splitLine(String line) {
		val actions = line.split(", ")
		val newActions = new ArrayList<String>
		for (var i = 0; i < actions.size; i++) {
			var actual = actions.get(i)
			if (actual.contains("(") && !actual.contains(")")) {
				// Rebuilding the function call
				while (!actions.get(i).contains(")")) {
					actual += ", " + actions.get(i + 1)
					i++;
				}
			}
			newActions.add(actual)
		}
		return newActions
	}
	
	protected def Map<String, String> parseEventRaise(String eventRaise) {
		if (eventRaise.contains(" := ")) {
			// Synchronous components
			val eventRaiseSplit = eventRaise.split(" := ")
			return #{"name" -> eventRaiseSplit.head , "value" -> eventRaiseSplit.last}
		}
		// Wrapper components: pushcrossroadsMessages(testPort_testIn, 5)
		val matcher = Pattern.compile("(?<push>push.*)\\((?<event>\\w+), (?<value>\\d+)\\).*").matcher(eventRaise)
		if (matcher.find) {
			val eventName = matcher.group("event")
			val value = matcher.group("value")
			val pushFunctionName = matcher.group("push")
			return #{"name" -> eventName , "value" -> value, "function" -> pushFunctionName}
		}
		// Wrapper components: peekexecutionMessages().event == execution_execute
		val peekMatcher = Pattern.compile("(.)*(?<peek>peek.*)\\(\\)\\.event == (?<event>\\w+).*").matcher(eventRaise)
		if (peekMatcher.find) {
			val eventName = peekMatcher.group("event")
			val peekFunctionName = peekMatcher.group("peek")
			val value = "1"
			return #{"name" -> eventName , "value" -> value, "function" -> peekFunctionName}
		}
	}
	
	protected def isActive(Template template, Collection<Entry<Variable, Integer>> variableMap) {
		val isActiveVar = template.isActiveVariable
		if (isActiveVar === null) {
			return true
		}
		val entry = variableMap.filter[it.key == isActiveVar].head		
		if (entry.value == 0) {
			return false
		}
		return true
	}
	
	protected def getIsActiveVariable(Template template) {
		try {
			return template.declarations.declaration.filter(DataVariableDeclaration)
					.filter[it.variable.head.name.equals("isActive")].head.variable.head
		} catch (NullPointerException e) {
			return null
		}
	}
	
	/**
	 * Returns the Gamma State the UPPAAL Location is transformed from.
	 */
	protected def toState(Location location) {
		return LocationToState.Matcher.on(engine).getAllValuesOfstate(location).head
	}
	
	protected def getVariableDeclaration(String variableName) {
		val variableDeclarations = VariableDelcarations.Matcher.on(engine).getAllValuesOfvariableDeclaration(variableName)
		if (variableDeclarations.size != 1) {
			throw new IllegalArgumentException("Not one variable retrieved for variable: " + variableName + " - " + variableDeclarations)
		}
		variableDeclarations.head
	}
	
	protected def getPeekFunction(String name) {
		val peekFunctions = Functions.Matcher.on(engine).getAllValuesOffunction(name)
		if (peekFunctions.size != 1) {
			throw new IllegalArgumentException("Not one variable retrieved for peek function: " + name + " - " + peekFunctions)
		}
		peekFunctions.head
	}
	
	protected def getEvent(VariableDeclaration variable) {
		val events = VariableToEvent.Matcher.on(engine).getAllValuesOfevent(variable)
		return events.head
	}
	
	protected def getWrapperEvent(DataVariableDeclaration variable, AsynchronousAdapter wrapper) {
		val events = EventRepresentations.Matcher.on(engine).getAllMatches(wrapper, null, null, variable)
		return events.head
	}
	
	/** 
     * Returns the sync ComponentInstance the given object is element of.
     */
    protected def SynchronousComponentInstance getOwner(EObject object) {
		val traces = InstanceTraces.Matcher.on(engine).getAllValuesOfinstance(null, object).filter(SynchronousComponentInstance)
		if (traces.size != 1) {
			throw new IllegalArgumentException("This number of owners of this object is not one! Object: " + object + " Size: " + traces.size + " Owners: " + traces.map[it.owner])
		}
		return traces.head as SynchronousComponentInstance
    }
    
    /** 
     * Returns the async ComponentInstance the given object is element of.
     */
    private def AsynchronousComponentInstance getAsyncOwner(EObject object) {
		val traces = InstanceTraces.Matcher.on(engine).getAllValuesOfinstance(null, object).filter(AsynchronousComponentInstance)
		if (traces.size != 1) {
			throw new IllegalArgumentException("The number of owners of this object is not one! Object: " + object + " Size: " + traces.size + " Owners: " + traces.map[it.owner])
		}
		return traces.head as AsynchronousComponentInstance
    }
    
    /** 
     * Returns the Port that contains the Event the given VariableDeclaration is mapped of.
     */
    protected def getPort(VariableDeclaration variableDeclaration) {
    	val traces = PortTraces.Matcher.on(engine).getAllValuesOfport(null, variableDeclaration)
		if (traces.size != 1) {
			throw new IllegalArgumentException("The number of owners of this object is not one! Object: " + variableDeclaration + " Size: " + traces.size + " Owners: " + traces.map[it.owner])
		}
		return traces.head
    }
    
	protected def isStepStarted(String line) {
		return line.matches("(.*)Orchestrator(.*)\\.InitLoc->(.*)Orchestrator(.*)")
	}
	
	protected def isStepEnded(String line) {
		return line.matches("(.*)Orchestrator(.*)\\.final->(.*)Orchestrator(.*)\\.InitLoc(.*)")
	}
	
	/**
     * Returns a Set of EObjects that are created of the given "from" object.
     */
    protected def getAllValuesOfTo(EObject from) {
    	return Traces.Matcher.on(engine).getAllValuesOfto(null, from)    	
    }
    
    /**
     * Returns a Set of EObjects that the given "to" object is created of.
     */
    protected def getAllValuesOfFrom(EObject to) {
    	return Traces.Matcher.on(engine).getAllValuesOffrom(null, to)
    }
    
    /**
     * Returns a Set of Expression EObjects that the given "to" object is created of.
     */
    protected def getAllExpressionValuesOfFrom(EObject to) {
    	return ExpressionTraces.Matcher.on(engine).getAllValuesOffrom(null, to)
    }
    
    /**
	 * Returns the name of the isRaised boolean flag of the given event of the given port.
	 */
	protected def isRaisedName(Event event, Port port, SynchronousComponentInstance instance) {
		return "isRaised_" + port.name + "_" + event.name + "Of" + instance.name
	}
	
	protected def getOutEventName(Event event, Port port, SynchronousComponentInstance owner) {
		return port.name + "_" + event.name + "Of" + owner.name
	}
	
	private def <T extends EObject> T clone(T model, boolean a, boolean b) {
		// A new copier should be used every time, otherwise anomalies happen (references are changed without asking)
		val copier = new Copier(a, b)
		val clone = copier.copy(model);
		copier.copyReferences();
		return clone as T;
	}
	
}

enum BackAnnotatorState {INITIAL, STATE_LOCATIONS, STATE_VARIABLES, TRANSITIONS, DELAY}
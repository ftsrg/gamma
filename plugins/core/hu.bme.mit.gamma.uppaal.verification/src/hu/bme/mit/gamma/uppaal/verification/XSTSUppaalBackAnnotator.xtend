package hu.bme.mit.gamma.uppaal.verification

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.querygenerator.XSTSUppaalQueryGenerator
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.uppaal.util.XSTSNamings
import java.util.Scanner
import java.util.Set
import org.eclipse.emf.ecore.util.EcoreUtil

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class XSTSUppaalBackAnnotator extends AbstractUppaalBackAnnotator {
	
	protected final XSTSUppaalQueryGenerator xStsUppaalQueryGenerator
	
	new(Package gammaPackage, Scanner traceScanner) {
		this(gammaPackage, traceScanner, true)
	}
	
	new(Package gammaPackage, Scanner traceScanner, boolean sortTrace) {
		super(traceScanner, sortTrace)
		this.gammaPackage = gammaPackage
		this.component = gammaPackage.components.head
		this.xStsUppaalQueryGenerator = new XSTSUppaalQueryGenerator(gammaPackage)
	}
	
	override execute() throws EmptyTraceException {
		val trace = super.createTrace
		
		var Step step = null
		
		val activatedStates = newHashSet
		
		var String line = null
		var state = BackAnnotatorState.INITIAL
		var localState = StableEnvironmentState.INITIAL
		while (traceScanner.hasNext) {
			line = traceScanner.nextLine
			// Variable line contains a single line from the trace
			switch (line) {
				case line.empty: {
					// No operation
				}
				case line.contains(ERROR_CONST):
					// If the condition is not well formed, an exception is thrown
					throw new IllegalArgumentException("Error in the trace: " + line)
				case line.contains(WARNING_CONST): {
					// No operation
				}
				case TRANSITIONS_CONST: {
					state = BackAnnotatorState.TRANSITIONS
				}
				case STATE_CONST_PREFIX: // There is a bug where State is written instead of State:
					state = BackAnnotatorState.STATE_LOCATIONS
				case STATE_CONST:
					state = BackAnnotatorState.STATE_LOCATIONS
				case line.startsWith(DELAY_CONST): {
					// Parsing delays
					val delay = Integer.parseInt(line.substring(DELAY_CONST.length + 1))
					step.addTimeElapse(delay)
				}
				default: {
					switch (state) {
						case BackAnnotatorState.INITIAL: {
							// Creating a new step
							step = createStep
							step.addReset
						}
						case BackAnnotatorState.STATE_LOCATIONS: {
							val processLocationNames = newArrayList
							processLocationNames += line.split(" ").toList
							// Dropping the first " (" and last " )" elements
							processLocationNames.removeIf[it == "(" || it == ")"]
							checkState(processLocationNames.size == 1)
							val processLocationName = processLocationNames.head
							val split = processLocationName.split("\\.")
							val locationName = split.last
							if (locationName.equals(XSTSNamings.stableLocationName)) {
								state = BackAnnotatorState.STATE_VARIABLES
								localState = StableEnvironmentState.STABLE
							}
							else if (locationName.equals(XSTSNamings.environmentFinishLocationName)) {
								state = BackAnnotatorState.STATE_VARIABLES
								localState = StableEnvironmentState.ENVIRONMENT
							}
							else if (locationName.equals(XSTSNamings.initialLocationName)) {
								state = BackAnnotatorState.INITIAL
								localState = StableEnvironmentState.INITIAL
							}
							else {
								state = BackAnnotatorState.STATE_VARIABLES
								localState = StableEnvironmentState.OTHER
							}
							// Other locations are committed and not checked
						}
						case BackAnnotatorState.STATE_VARIABLES: {
							if (localState != StableEnvironmentState.OTHER) {
								val variableValues = line.split(" ")
								for (variableValue : variableValues) {
									val split = variableValue.split("=")
									val variable = split.head
									val value = split.last
									
									switch (localState) {
										case STABLE: {
											try {
												
												val index = Integer.parseInt(value) /* Subtract __Inactive__ */
												val instanceState = xStsUppaalQueryGenerator.getSourceState(
													'''«variable» == «index»''') // Method made just for this
												println('''«variable» == «index»''')
												val controlState = instanceState.key
												val instance = instanceState.value
												println(controlState + " " + instance)
												if (index > 0) {
													step.addInstanceState(instance, controlState)
													activatedStates += controlState
												}
											} catch (IllegalArgumentException e) {
												try {
													val instanceVariable = xStsUppaalQueryGenerator.getSourceVariable(variable)
													step.addInstanceVariableState(instanceVariable.value, instanceVariable.key, value)
												} catch (IllegalArgumentException e1) {
													try {
														val systemOutEvent = xStsUppaalQueryGenerator.getSourceOutEvent(variable)
														if (value.equals("1")) {
															val event = systemOutEvent.get(0) as Event
															val port = systemOutEvent.get(1) as Port
															val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
															step.addOutEvent(systemPort, event)
															// TODO Denoting that this event has been actually raised!
														}
													} catch (IllegalArgumentException e2) {
														try {
															val systemOutEvent = xStsUppaalQueryGenerator.getSourceOutEventParamater(variable)
															val event = systemOutEvent.get(0) as Event
															val port = systemOutEvent.get(1) as Port
															val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
															val parameter = systemOutEvent.get(2) as ParameterDeclaration
															step.addOutEventWithStringParameter(systemPort, event, parameter, value)
															// TODO Denoting that this event has been actually raised!
														} catch (IllegalArgumentException e3) {}
													}
												}
											}
										}
										case ENVIRONMENT: {
											try {
												val systemInEvent = xStsUppaalQueryGenerator.getSourceInEvent(variable)
												if (value.equals("1")) {
													val event = systemInEvent.get(0) as Event
													val port = systemInEvent.get(1) as Port
													val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
													step.addInEvent(systemPort, event)
													// TODO Denoting that this event has been actually raised!
												}
											} catch (IllegalArgumentException e) {
												try {
													val systemInEvent = xStsUppaalQueryGenerator.getSourceInEventParamater(variable)
													val event = systemInEvent.get(0) as Event
													val port = systemInEvent.get(1) as Port
													val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
													val parameter = systemInEvent.get(2) as ParameterDeclaration
													step.addInEventWithParameter(systemPort, event, parameter, value)
													// TODO Denoting that this event has been actually raised!
												} catch (IllegalArgumentException e1) {}
											}
										}
										default: {
											throw new IllegalStateException("Not known state")
										}
									}
								}
							}
							if (localState == StableEnvironmentState.STABLE) {
								// Deleting states that are not inactive due to history
								step.checkStates(activatedStates)
								// Creating a new step
								trace.steps += step
								step = createStep
							}
							if (localState == StableEnvironmentState.ENVIRONMENT) {
								// Add schedule
								step.addComponentScheduling
							}
						}
						case BackAnnotatorState.TRANSITIONS: {
							// No operation
						}
						default: {
							throw new IllegalStateException("Not known state")
						}
					}
				}
			}
		}
		if (sortTrace) {
			trace.sortInstanceStates
		}
		return trace
	}
	
	protected def void checkStates(Step step, Set<State> activatedStates) {
		val instanceStates = step.instanceStates.filter(InstanceStateConfiguration).toList
		for (instanceState : instanceStates) {
			// A state is active if all of its ancestor states are active
			val ancestorStates = instanceState.state.ancestors
			if (!activatedStates.containsAll(ancestorStates)) {
				EcoreUtil.delete(instanceState)
			}
		}
		activatedStates.clear
	}
	
}

enum StableEnvironmentState {INITIAL, STABLE, ENVIRONMENT, OTHER}

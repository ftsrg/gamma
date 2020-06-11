package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.querygenerator.ThetaQueryGenerator
import hu.bme.mit.gamma.statechart.model.Package
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.TraceFactory
import hu.bme.mit.gamma.trace.model.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.verification.util.TraceBuilder
import java.util.Scanner
import java.util.logging.Level
import java.util.logging.Logger
import org.eclipse.emf.ecore.util.EcoreUtil

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration
import java.util.NoSuchElementException

class TraceBackAnnotator {
	
	protected final String XSTS_TRACE = "(XstsStateSequence"
	protected final String XSTS_STATE = "(XstsState"
	protected final String EXPL_STATE = "(ExplState"
	
	protected final Scanner traceScanner
	protected final extension ThetaQueryGenerator thetaQueryGenerator
	
	protected final Package gammaPackage
	protected final Component component
	
	protected final boolean sortTrace
	// Auxiliary objects	
	protected final extension TraceFactory trFact = TraceFactory.eINSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.instance
	protected final extension TraceBuilder traceBuilder = TraceBuilder.instance
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.instance
	protected Logger logger = Logger.getLogger("GammaLogger")
	
	new(Package gammaPackage, Scanner traceScanner) {
		this(gammaPackage, traceScanner, true)
	}
	
	new(Package gammaPackage, Scanner traceScanner, boolean sortTrace) {
		this.gammaPackage = gammaPackage
		this.component = gammaPackage.components.head
		this.thetaQueryGenerator = new ThetaQueryGenerator(gammaPackage)
		this.traceScanner = traceScanner
		this.sortTrace = sortTrace
	}
	
	def ExecutionTrace execute() {
		// Creating the trace component
		val trace = createExecutionTrace => [
			it.component = this.component
			it.import = this.gammaPackage
			it.name = this.component.name + "Trace"
		]
		// Setting the arguments: AnalysisModelPreprocessor saved them in the Package
		// Note that the top component does not contain parameter declarations anymore due to the preprocessing
		checkState(gammaPackage.topComponentArguments.size == component.parameterDeclarations.size, 
			"The numbers of top component arguments and top component parameters are not equal: " +
			gammaPackage.topComponentArguments.size + " - " + component.parameterDeclarations.size)
		logger.log(Level.INFO, "The number of arguments of the top component is " +
			gammaPackage.topComponentArguments.size)
		trace.arguments += gammaPackage.topComponentArguments.map[it.clone(true, true)]
		var step = createStep
		trace.steps += step
		// Sets for raised in and out events and activated states
		val raisedOutEvents = newHashSet
		val raisedInEvents = newHashSet
		val activatedStates = newHashSet
		// Parsing
		var state = BackAnnotatorState.INIT
		try {
			while (traceScanner.hasNext) {
				var line = traceScanner.nextLine.trim // Trimming leading white spaces
				switch (line) {
					case line.startsWith(XSTS_TRACE): {
						// Skipping the first state
						var countedExplicitState = 0
						while (countedExplicitState < 2) {
							line = traceScanner.nextLine.trim
							if (line.startsWith(EXPL_STATE)) {
								countedExplicitState++
							}
						}
						// Adding reset
						step.actions += createReset
						line = traceScanner.nextLine.trim
						state = BackAnnotatorState.STATE_CHECK
					}
					case line.startsWith(XSTS_STATE): {
						// Deleting unnecessary in and out events
						switch (state) {
							case STATE_CHECK: {
								val raiseEventActs = step.outEvents.filter(RaiseEventAct).toList
								for (raiseEventAct : raiseEventActs) {
									if (!raisedOutEvents.contains(new Pair(raiseEventAct.port, raiseEventAct.event))) {
										EcoreUtil.delete(raiseEventAct)
									}
								}
								val instanceStates = step.instanceStates.filter(InstanceStateConfiguration).toList
								for (instanceState : instanceStates) {
									// A state is active if all of its ancestor states are active
									val ancestorStates = instanceState.state.ancestors
									if (!activatedStates.containsAll(ancestorStates)) {
										EcoreUtil.delete(instanceState)
									}
								}
								raisedOutEvents.clear
								activatedStates.clear
								// Creating a new step
								step = createStep
								trace.steps += step
								// Setting the state
								state = BackAnnotatorState.ENVIRONMENT_CHECK
							}
							case ENVIRONMENT_CHECK: {
								val raiseEventActs = step.actions.filter(RaiseEventAct).toList
								for (raiseEventAct : raiseEventActs) {
									if (!raisedInEvents.contains(new Pair(raiseEventAct.port, raiseEventAct.event))) {
										EcoreUtil.delete(raiseEventAct)
									}
								}
								raisedInEvents.clear
								// Add schedule
								step.addComponentScheduling
								// Setting the state
								state = BackAnnotatorState.STATE_CHECK
							}
							default:
								throw new IllegalArgumentException("Not know state: " + state)
						}
						// Skipping two lines
						line = traceScanner.nextLine
						line = traceScanner.nextLine.trim
					}
				}
				// We parse in every turn
				line = line.unwrap
				val split = line.split(" ")
				val id = split.get(0)
				val value = split.get(1)
				switch (state) {
					case STATE_CHECK: {
						try {
							val instanceState = thetaQueryGenerator.getSourceState('''«id» == «value»''')
							val controlState = instanceState.key
							val instance = instanceState.value
							step.addInstanceState(instance, controlState)
							activatedStates += controlState
						} catch (IllegalArgumentException e) {
							try {
								val instanceVariable = thetaQueryGenerator.getSourceVariable(id)
								step.addInstanceVariableState(instanceVariable.value, instanceVariable.key, value)
							} catch (IllegalArgumentException e1) {
								try {
									val systemOutEvent = thetaQueryGenerator.getSourceOutEvent(id)
									if (value.equals("true")) {
										val event = systemOutEvent.get(0) as Event
										val port = systemOutEvent.get(1) as Port
										val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
										step.addOutEvent(systemPort, event)
										// Denoting that this event has been actually
										raisedOutEvents += new Pair(systemPort, event)
									}
								} catch (IllegalArgumentException e2) {
									try {
										val systemOutEvent = thetaQueryGenerator.getSourceOutEventParamater(id)
										val event = systemOutEvent.get(0) as Event
										val port = systemOutEvent.get(1) as Port
										val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
										val parameter = systemOutEvent.get(2) as ParameterDeclaration
										step.addOutEventWithStringParameter(systemPort, event, parameter, value)
									} catch (IllegalArgumentException e3) {}
								}
							}
						}
					}
					case ENVIRONMENT_CHECK: {
						// TODO delays
						try {
							val systemInEvent = thetaQueryGenerator.getSourceInEvent(id)
							if (value.equals("true")) {
								val event = systemInEvent.get(0) as Event
								val port = systemInEvent.get(1) as Port
								val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
								step.addInEvent(systemPort, event)
								// Denoting that this event has been actually
								raisedInEvents += new Pair(systemPort, event)
							}
						} catch (IllegalArgumentException e) {
							try {
								val systemInEvent = thetaQueryGenerator.getSourceInEventParamater(id)
								val event = systemInEvent.get(0) as Event
								val port = systemInEvent.get(1) as Port
								val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
								val parameter = systemInEvent.get(2) as ParameterDeclaration
								step.addInEventWithParameter(systemPort, event, parameter, value)
							} catch (IllegalArgumentException e1) {}
						}
					}
					default:
						throw new IllegalArgumentException("Not known state: " + state)
				}
			}
			// Sorting if needed
			if (sortTrace) {
				trace.sortInstanceStates
			}
		} catch (NoSuchElementException e) {
			// If there are not enough lines, that means there are no environment actions
			step.actions += createReset
		}
		return trace
	}
	
	enum BackAnnotatorState {INIT, STATE_CHECK, ENVIRONMENT_CHECK}
	
}
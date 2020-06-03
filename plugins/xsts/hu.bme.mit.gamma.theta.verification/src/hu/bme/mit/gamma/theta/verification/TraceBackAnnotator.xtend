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

class TraceBackAnnotator {
	
	protected final String XSTS_TRACE = "(Trace"
	protected final String XSTS_STATE = "(XstsState "
	protected final String EXPL_STATE = "(ExplState "
	protected final String XSTS_ACTION = "(XstsAction"
	
	protected final Scanner traceScanner
	protected final extension ThetaQueryGenerator thetaQueryGenerator
	
	protected final Package gammaPackage
	protected final Component component
	
	protected final boolean sortTrace
	// Auxiliary objects	
	protected final extension TraceFactory trFact = TraceFactory.eINSTANCE
	protected final extension TraceUtil traceUtil = new TraceUtil
	protected final extension TraceBuilder traceBuilder = new TraceBuilder
	protected final extension GammaEcoreUtil gammaEcoreUtil = new GammaEcoreUtil
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
		logger.log(Level.INFO, "The number of arguments of the top component is " +
			gammaPackage.topComponentArguments.size)
		trace.arguments += gammaPackage.topComponentArguments.map[it.clone(true, true)]
		var step = createStep
		trace.steps += step
		// Sets for raised in and out events
		val raisedOutEvents = newHashSet
		val raisedInEvents = newHashSet
		// Parsing
		var state = BackAnnotatorState.INIT
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
					state = BackAnnotatorState.STATE_CHECK
				}
				case line.startsWith(XSTS_ACTION): {
					// Deleting unnecessary in and out events
					switch (state) {
						case STATE_CHECK: {
							val raiseEventActs = step.outEvents.filter(RaiseEventAct)
							for (raiseEventAct : raiseEventActs) {
								if (!raisedOutEvents.contains(new Pair(raiseEventAct.port, raiseEventAct.event))) {
									EcoreUtil.delete(raiseEventAct)
								}
							}
							raisedOutEvents.clear
							// Creating a new step
							step = createStep
							trace.steps += step
							// Setting the state
							state = BackAnnotatorState.ENVIRONMENT_CHECK
						}
						case ENVIRONMENT_CHECK: {
							val raiseEventActs = step.actions.filter(RaiseEventAct)
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
				case line.startsWith(XSTS_STATE): {
					// Skipping actions
					line = traceScanner.nextLine
					line = traceScanner.nextLine.trim
				}
				default: {
					// This is the place for the parsing
					// First line contains a (ExplState ...
					if (line.startsWith(EXPL_STATE)) {
						line = line.substring(EXPL_STATE.length + 1)
					}
					line = line.unwrap
					val split = line.split(" ")
					val id = split.get(0)
					val value = split.get(1)
					switch (state) {
						case STATE_CHECK: {
							// It is either a state or a variable id
							try {
								val instanceState = thetaQueryGenerator.getSourceState('''«id» == «value»''')
								step.addInstanceState(instanceState.value, instanceState.key)
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
											step.addOutEvent(port, event)
											// Denoting that this event has been actually
											raisedOutEvents += new Pair(port, event)
										}
									} catch (IllegalArgumentException e2) {
										try {
											val systemOutEvent = thetaQueryGenerator.getSourceOutEventParamater(id)
											val event = systemOutEvent.get(0) as Event
											val port = systemOutEvent.get(1) as Port
											val parameter = systemOutEvent.get(2) as ParameterDeclaration
											step.addOutEventWithStringParameter(port, event, parameter, value)
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
									step.addInEvent(port, event)
									// Denoting that this event has been actually
									raisedInEvents += new Pair(port, event)
								}
							} catch (IllegalArgumentException e) {
								try {
									val systemInEvent = thetaQueryGenerator.getSourceInEventParamater(id)
									val event = systemInEvent.get(0) as Event
									val port = systemInEvent.get(1) as Port
									val parameter = systemInEvent.get(2) as ParameterDeclaration
									step.addInEventWithParameter(port, event, parameter, value)
								} catch (IllegalArgumentException e1) {}
							}
						}
						default: 
							throw new IllegalArgumentException("Not known state: " + state)
					}
				}
				
			}
		}
		// Sorting if needed
		if (sortTrace) {
			trace.sortInstanceStates
		}
		return trace
	}
	
	enum BackAnnotatorState {INIT, STATE_CHECK, ENVIRONMENT_CHECK}
	
}
package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.querygenerator.ThetaQueryGenerator
import hu.bme.mit.gamma.statechart.model.Package
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.TraceFactory
import hu.bme.mit.gamma.trace.model.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.verification.util.TraceBuilder
import java.util.Scanner

import static com.google.common.base.Preconditions.checkState

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
		checkState(component.parameterDeclarations.size == gammaPackage.topComponentArguments.size)
		trace.arguments += gammaPackage.topComponentArguments.map[it.clone(true, true)]
		var step = createStep
		trace.steps += step
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
				case line.startsWith(XSTS_STATE): {
					
				}
				case line.startsWith(EXPL_STATE): {
					
				}
				case line.startsWith(XSTS_TRACE): {
					
				}
				default: {
					// This is the place for the parsing
					switch (state) {
						case STATE_CHECK: {
							// First line contains a (ExplState ...
							if (line.startsWith(EXPL_STATE)) {
								line = line.substring(EXPL_STATE.length + 1)
							}
							line = line.unwrap
							val split = line.split(" ")
							val id = split.get(0)
							val value = split.get(1)
							// It is either a state or a variable id
							try {
								val instanceState = thetaQueryGenerator.getSourceState('''«id» == «value»''')
								step.addInstanceState(instanceState.value, instanceState.key)
							} catch (IllegalArgumentException e) {
								try {
									val instanceState = thetaQueryGenerator.getSourceVariable(id)
									step.addInstanceVariableState(instanceState.value, instanceState.key, value)
								} catch (IllegalArgumentException ex) {}
							}
						}
						case ENVIRONMENT_CHECK: {
							step = createStep
							trace.steps += step
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
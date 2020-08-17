package hu.bme.mit.gamma.uppaal.verification

import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.verification.util.TraceBuilder
import java.util.Scanner
import java.util.logging.Level
import java.util.logging.Logger

import static com.google.common.base.Preconditions.checkState
import hu.bme.mit.gamma.util.GammaEcoreUtil

abstract class AbstractUppaalBackAnnotator {
	
	protected final String ERROR_CONST = "[error]"
	protected final String WARNING_CONST = "[warning]"
	
	protected final String STATE_CONST_PREFIX = "State"
	protected final String STATE_CONST = "State:"
	protected final String TRANSITIONS_CONST = "Transitions:"
	protected final String DELAY_CONST = "Delay:"
	
	protected final Scanner traceScanner
	
	protected Package gammaPackage
	protected Component component
	
	protected final boolean sortTrace
	
	protected final extension TraceModelFactory traceModelFactory = TraceModelFactory.eINSTANCE

	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	protected final extension TraceBuilder traceBuilder = TraceBuilder.INSTANCE
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	
	protected Logger logger = Logger.getLogger("GammaLogger")
	
	new(Scanner traceScanner, boolean sortTrace) {
		this.traceScanner = traceScanner
		this.sortTrace = sortTrace
	}
	
	protected def createTrace() {
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
		return trace
	}
	
	def ExecutionTrace execute() throws EmptyTraceException
	
}

enum BackAnnotatorState {INITIAL, STATE_LOCATIONS, STATE_VARIABLES, TRANSITIONS, DELAY}

class EmptyTraceException extends Exception {}
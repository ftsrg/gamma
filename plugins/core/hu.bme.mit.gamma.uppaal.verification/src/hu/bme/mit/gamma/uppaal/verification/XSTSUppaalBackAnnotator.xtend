package hu.bme.mit.gamma.uppaal.verification

import hu.bme.mit.gamma.querygenerator.ThetaQueryGenerator
import hu.bme.mit.gamma.statechart.interface_.Package
import java.util.Scanner

class XSTSUppaalBackAnnotator extends AbstractUppaalBackAnnotator {
	
	protected final extension ThetaQueryGenerator thetaQueryGenerator
	
	new(Package gammaPackage, Scanner traceScanner) {
		this(gammaPackage, traceScanner, true)
	}
	
	new(Package gammaPackage, Scanner traceScanner, boolean sortTrace) {
		super(traceScanner, sortTrace)
		this.gammaPackage = gammaPackage
		this.component = gammaPackage.components.head
		this.thetaQueryGenerator = new ThetaQueryGenerator(gammaPackage)
	}
	
	override execute() throws EmptyTraceException {
		val trace = super.createTrace
		
		
		if (sortTrace) {
			trace.sortInstanceStates
		}
		return trace
	}
	
}
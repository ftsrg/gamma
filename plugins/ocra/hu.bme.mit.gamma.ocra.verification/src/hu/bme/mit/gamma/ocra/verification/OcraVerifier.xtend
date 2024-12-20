package hu.bme.mit.gamma.ocra.verification

import java.util.Scanner
import hu.bme.mit.gamma.util.ScannerLogger
import java.io.File
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.verification.util.AbstractVerifier

class OcraVerifier extends AbstractVerifier {
	protected final static extension FileUtil fileUtil = FileUtil.INSTANCE
	
	public static final String SET_OCRA_TIMED = "set ocra_timed 1"
	
	
	
	override verifyQuery(Object traceability, String parameters, File modelFile, File queryFile) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override protected getHelpCommand() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override protected getUnavailableBackendMessage() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
		
}	
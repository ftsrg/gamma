package hu.bme.mit.gamma.verification.util

import java.io.File
import java.util.logging.Logger

import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil

abstract class AbstractVerification {

	protected final FileUtil fileUtil = FileUtil.INSTANCE
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE

	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	abstract def ExecutionTrace execute(File modelFile, File queryFile)
	
}
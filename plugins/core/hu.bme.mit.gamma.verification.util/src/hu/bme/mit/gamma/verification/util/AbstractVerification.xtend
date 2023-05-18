/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.verification.util

import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.io.File
import java.util.logging.Logger
import java.util.regex.Pattern

abstract class AbstractVerification {

	protected final FileUtil fileUtil = FileUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE

	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	def Result execute(File modelFile, File queryFile) {
		return this.execute(modelFile, queryFile, defaultArguments)
	}
	abstract def Result execute(File modelFile, File queryFile, String[] arguments) throws InterruptedException
	abstract def String[] getDefaultArguments()
	
	protected def sanitizeArgument(String argument) {
		val match = Pattern.matches(getArgumentPattern, argument.trim)
		if (!match) {
			throw new IllegalArgumentException(argument + " is not a valid argument")
		}
	}
	
	protected abstract def String getArgumentPattern()
	
}
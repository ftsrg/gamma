/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.verification.util

import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.querygenerator.serializer.PropertySerializer
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.InterruptableCallable
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.util.ThreadRacer
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.io.File
import java.util.concurrent.TimeUnit
import java.util.logging.Logger
import java.util.regex.Pattern

abstract class AbstractVerification {
	//
	protected final FileUtil fileUtil = FileUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE

	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	//
	
	def Result execute(File modelFile, File queryFile) {
		return this.execute(modelFile, queryFile, -1, null)
	}
	
	def Result execute(File modelFile, File queryFile, long timeout, TimeUnit unit) {
		return this.execute(modelFile, queryFile, defaultArguments, timeout, unit)
	}
	
	def Result execute(File modelFile, File queryFile, String[] arguments) {
		return this.execute(modelFile, queryFile, arguments, -1, null)
	}
	
	def Result execute(File modelFile, PropertyPackage propertyPackage, String[] arguments,
			long timeout, TimeUnit unit) throws InterruptedException {
		val propertySerializer = createPropertySerializer
		val serializedProperties = propertySerializer.serializeCommentableStateFormulas(
				propertyPackage.formulas)
		
		val propertyFolder = modelFile.parent
		val propertyFileName = "." + fileUtil.getExtensionlessName(modelFile) + ".p"
		val propertyFileUri = propertyFolder + File.separator + propertyFileName
		val propertyFile = new File(propertyFileUri)
		fileUtil.saveString(propertyFile, serializedProperties)
		propertyFile.deleteOnExit
		
		return this.execute(modelFile, propertyFile, arguments, timeout, unit)
	}
	
	def Result execute(File modelFile, File queryFile, String[] arguments,
			long timeout, TimeUnit unit) throws InterruptedException {
		// Racer callable(s)
		val callables = modelFile.loadModelAndCreateVerificationCallables(queryFile, arguments)
		// Racer, but for only one thread
		val racer = new ThreadRacer<Result>(callables, timeout, unit)
		//
		var result = racer.execute
		// Handle in case of timeout
		return result.handleNull
	}
	
	def handleNull(Result result) {
		if (result === null) {
			return new Result(ThreeStateBoolean.UNDEF, null)
		}
		return result
	}
	
	abstract protected def String getTraceabilityFileName(String fileName)
	
	def loadModelAndCreateVerificationCallables(File modelFile,
			File queryFile, String[] arguments) {
		val fileName = modelFile.name
		val traceabilityFileName = fileName.traceabilityFileName
		val traceabilityObject = ecoreUtil.normalLoad(modelFile.parent, traceabilityFileName)
		
		arguments.sanitizeArguments
		// Creating the racer callable(s)
		val callables = traceabilityObject.createVerificationCallables(arguments, modelFile, queryFile)
		
		return callables
	}
	
	protected def createVerificationCallables(Object traceabilityObject, Iterable<String> arguments,
			File modelFile, File queryFile) {
		val callables = <InterruptableCallable<Result>>newArrayList
		
		for (argument : arguments) {
			val verifier = createVerifier
			val className = verifier.class.name
			
			callables += new InterruptableCallable<Result> {
				override Result call() {
					logger.info('''Starting «className» instance with "«argument»"''')
					val result = verifier.verifyQuery(traceabilityObject, argument, modelFile, queryFile)
					return result
				}
				override void cancel() {
					verifier.cancel
					logger.info('''«className» instance with "«argument»" has been cancelled''')
				}
			}
		}
		
		return callables
	}
	
	abstract protected def AbstractVerifier createVerifier()
	
	abstract protected def PropertySerializer createPropertySerializer()
	
	//
	abstract def String[] getDefaultArguments()
	
	def String[] getDefaultArguments(File modelFile) {
		return defaultArguments
	}
	
	def String[] getDefaultArgumentsForInvarianceChecking(File modelFile) {
		return defaultArgumentsForInvarianceChecking
	}
	
	def String[] getDefaultArgumentsForInvarianceChecking() {
		return defaultArguments
	}
	//
	
	protected def sanitizeArgument(String argument) {
		val match = Pattern.matches(getArgumentPattern, argument.trim)
		if (!match) {
			throw new IllegalArgumentException(argument + " is not a valid argument")
		}
	}
	
	protected def sanitizeArguments(Iterable<String> arguments) {
		for (argument : arguments) {
			argument.sanitizeArgument
		}
	}
	
	protected abstract def String getArgumentPattern()
	
}
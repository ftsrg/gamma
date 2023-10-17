/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.nuxmv.verification

import hu.bme.mit.gamma.util.InterruptableCallable
import hu.bme.mit.gamma.util.ThreadRacer
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerification
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.io.File
import java.util.concurrent.TimeUnit

class NuxmvVerification extends AbstractVerification {
	// Singleton
	public static final NuxmvVerification INSTANCE = new NuxmvVerification
	protected new() {}
	//
	
	override Result execute(File modelFile, File queryFile, String[] arguments,
			long timeout, TimeUnit unit) {
		val fileName = modelFile.name
		val packageFileName = fileName.unfoldedPackageFileName
		val gammaPackage = ecoreUtil.normalLoad(modelFile.parent, packageFileName)
		
		val argument = arguments.head
		
		argument.sanitizeArgument
		
		// Racer, but for only one thread
		val racer = new ThreadRacer<Result>
		val callables = <InterruptableCallable<Result>>newArrayList
		
		val verifier = new NuxmvVerifier
		callables += new InterruptableCallable<Result> {
			
			override Result call() {
				logger.info('''Starting nuXmv with "«argument»"''')
				val result = verifier.verifyQuery(gammaPackage, argument, modelFile, queryFile)
				return result
			}
			
			override void cancel() {
				verifier.cancel
				logger.info('''nuXmv verification instance with "«argument»" has been cancelled''')
			}
			
		}
		
		var result = racer.execute(callables, timeout, unit)
		
		// In case of timeout
		if (result === null) {
			result = new Result(ThreeStateBoolean.UNDEF, null)
		}
		
		return result
	}
	
	protected override createVerifier() {
		return new NuxmvVerifier
	}
	
	override getDefaultArguments(File modelFile) {
		if (NuxmvVerifier.isTimedModel(modelFile)) {
			return #[
				NuxmvVerifier.CHECK_TIMED_LTL // LTL
				// 'timed_check_invar -a 1 -p' // Invariant properties
			]
		}
		return getDefaultArguments
	}
	
	override getDefaultArguments() {
		return #[
			NuxmvVerifier.CHECK_UNTIMED_LTL // LTL
			// 'check_property_as_invar_ic3 -L' // Invariant properties
		]
	}
	
	override protected getArgumentPattern() {
		return ".*" // TODO
	}
	
}
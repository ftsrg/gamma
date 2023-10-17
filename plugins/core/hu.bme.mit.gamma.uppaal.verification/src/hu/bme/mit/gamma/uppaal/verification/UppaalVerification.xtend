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
package hu.bme.mit.gamma.uppaal.verification

import hu.bme.mit.gamma.util.InterruptableCallable
import hu.bme.mit.gamma.util.ThreadRacer
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.io.File
import java.util.concurrent.TimeUnit

class UppaalVerification extends AbstractUppaalVerification {
	// Singleton
	public static final UppaalVerification INSTANCE = new UppaalVerification
	protected new() {}
	//
	
	override Result execute(File modelFile, File queryFile, String[] arguments,
			long timeout, TimeUnit unit) {
		val fileName = modelFile.name
		val packageFileName = fileName.gammaUppaalTraceabilityFileName
		val gammaTrace = ecoreUtil.normalLoad(modelFile.parent, packageFileName)
		val argument = arguments.head // Only first value is used
		
		argument.sanitizeArgument
		
		// Racer, but for only one thread
		val racer = new ThreadRacer<Result>
		val callables = <InterruptableCallable<Result>>newArrayList
		
		val verifier = new UppaalVerifier
		callables += new InterruptableCallable<Result> {
			
			override Result call() {
				logger.info('''Starting UPPAAL with "«argument»"''')
				val result = verifier.verifyQuery(gammaTrace, argument, modelFile, queryFile)
				return result
			}
			
			override void cancel() {
				verifier.cancel
				logger.info('''UPPAAL verification instance with "«argument»" has been cancelled''')
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
		return new UppaalVerifier
	}
	
	override getDefaultArguments() {
		return #[ "-C -T -t0" ]
	}

}

/********************************************************************************
 * Copyright (c) 2022-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.promela.verification

import hu.bme.mit.gamma.util.InterruptableCallable
import hu.bme.mit.gamma.util.ThreadRacer
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerification
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.io.File
import java.util.concurrent.TimeUnit

class PromelaVerification extends AbstractVerification {
	// Singleton
	public static final PromelaVerification INSTANCE = new PromelaVerification
	protected new() {}
	
	override Result execute(File modelFile, File queryFile, String[] arguments,
			long timeout, TimeUnit unit) {
		val fileName = modelFile.name
		val packageFileName = fileName.unfoldedPackageFileName
		val gammaPackage = ecoreUtil.normalLoad(modelFile.parent, packageFileName)
		
		arguments.sanitizeArguments
		
		// Racer, but for only one thread
		val racer = new ThreadRacer<Result>
		val callables = <InterruptableCallable<Result>>newArrayList
		
		callables += gammaPackage.createVerificationCallables(arguments, modelFile, queryFile)
		
		var result = racer.execute(callables, timeout, unit)
		
		// In case of timeout
		if (result === null) {
			result = new Result(ThreeStateBoolean.UNDEF, null)
		}
		
		return result
	}
	
	def createVerificationCallables(Object gammaPackage, Iterable<String> arguments,
			File modelFile, File queryFile) {
		val callables = <InterruptableCallable<Result>>newArrayList
		
		for (argument : arguments) {
			val verifier = new PromelaVerifier
			
			callables += new InterruptableCallable<Result> {
				override Result call() {
					logger.info('''Starting Promela with "«argument»"''')
					val result = verifier.verifyQuery(gammaPackage, argument, modelFile, queryFile)
					return result
				}
				override void cancel() {
					verifier.cancel
					logger.info('''Promela verification instance with "«argument»" has been cancelled''')
				}
			}
		}
		
		return callables
	}
	
	override getDefaultArguments() {
		val MAX_DEPTH = 350000
		return #[
//			"-search -a -b" // default: -a search for acceptance cycles, -b bounded search mode, makes it an error to exceed the search depth, triggering and error trail
			'''-search -I -m«MAX_DEPTH» -w32 -DVECTORSZ=6144'''
//			'''-search -i -m«MAX_DEPTH» -w32 -DVECTORSZ=4096'''
//			 '''-search -bfs -DVECTORSZ=4096'''
		]
		// -A apply slicing algorithm
		// -m Changes the semantics of send events. Ordinarily, a send action will be (blocked) if the target message buffer is full. With this option a message sent to a full buffer is lost.
		// -b bounded search mode, makes it an error to exceed the search depth, triggering and error trail
		// -I like -i, but approximate and faster
		// -i search for shortest path to error (causes an increase of complexity)
		// -n no listing of unreached states at the end of the run
		// -PN for models with embedded C code, reproduce trail, but print only steps from the process with pid N
	}
	
	protected override String getArgumentPattern() {
		return "(-([A-Za-z])*([0-9])*(=)?([0-9])*( )*)*"
	}
}
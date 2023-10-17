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
package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.util.InterruptableCallable
import hu.bme.mit.gamma.util.ThreadRacer
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerification
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.io.File
import java.util.concurrent.TimeUnit

class ThetaVerification extends AbstractVerification {
	// Singleton
	public static final ThetaVerification INSTANCE = new ThetaVerification
	protected new() {}
	//
	
	override Result execute(File modelFile, File queryFile, String[] arguments,
			long timeout, TimeUnit unit) {
		val fileName = modelFile.name
		val packageFileName = fileName.unfoldedPackageFileName
		val gammaPackage = ecoreUtil.normalLoad(modelFile.parent, packageFileName)
		val queries = fileUtil.loadString(queryFile)
		
		var Result result = null
		
		for (query /* TODO not referenced */ : queries.splitLines) {
			// Racing for every query separately
			val racer = new ThreadRacer<Result>
			val callables = <InterruptableCallable<Result>>newArrayList
			
			for (argument : arguments) {
				argument.sanitizeArgument
				
				val verifier = new ThetaVerifier
				callables += new InterruptableCallable<Result> {
					
					override Result call() {
						val currentThread = Thread.currentThread
						logger.info('''Starting Theta on thread «currentThread.name» with "«argument»"''')
						val result = verifier.verifyQuery(gammaPackage, argument, modelFile, queries)
						logger.info('''Thread «currentThread.name» with "«argument»" has won''')
						return result
					}
					
					override void cancel() {
						verifier.cancel
						logger.info('''Theta verification instance with "«argument»" has been cancelled''')
					}
					
				}
			}
			
			val newResult = racer.execute(callables, timeout, unit)
			
			if (result === null) {
				result = newResult
			}
			else {
				result = result.extend(newResult)
			}
		}
		
		// In case of timeout
		if (result === null) {
			result = new Result(ThreeStateBoolean.UNDEF, null)
		}
		
		return result
	}
	
	protected override createVerifier() {
		return new ThetaVerifier
	}
	
	override getDefaultArguments() {
		return #[
				"",
				"--domain EXPL --refinement SEQ_ITP --maxenum 250 --initprec CTRL",
				"--domain EXPL_PRED_COMBINED --autoexpl NEWOPERANDS --initprec CTRL"
			]
		// --domain PRED_CART --refinement SEQ_ITP // default - cannot be used with loops
		// --domain EXPL --refinement SEQ_ITP --maxenum 250 // --initprec CTRL should be used to support loops
		// --domain EXPL_PRED_COMBINED --autoexpl NEWOPERANDS --initprec CTRL
	}
	
	protected override String getArgumentPattern() {
		return "(--[a-z]+( )[_0-9A-Z]+( )*)*"
	}
	
}
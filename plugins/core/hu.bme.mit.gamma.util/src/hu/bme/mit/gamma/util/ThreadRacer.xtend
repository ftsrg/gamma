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
package hu.bme.mit.gamma.util

import java.util.Collection
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import java.util.logging.Logger

class ThreadRacer<T> {
	
	final CountDownLatch latch = new CountDownLatch(1)
	volatile T object

	int numberOfCallablesShouldBeRunning = 0
	final AtomicInteger numberOfAbortedCallables = new AtomicInteger
	
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	def T execute(Collection<? extends InterruptableCallable<T>> callables) {
		return this.execute(callables, -1, null)
	}

	def T execute(Collection<? extends InterruptableCallable<T>> callables, long timeout, TimeUnit unit) {
		val size = callables.size
		numberOfCallablesShouldBeRunning = size
		
		val wrappedCallables = newArrayList
		val futures = newArrayList
		
		val executor = Executors.newFixedThreadPool(size)
		try {
			for (callable :  callables) {
				val wrappedCallable = callable.wrap
				wrappedCallables += wrappedCallable
				futures += executor.submit(wrappedCallable)
			}
			
			// Racing
			logger.info('''Waiting for the threads to return a result with «IF timeout <= 0»no timeout«ELSE»a timeout of «timeout»«ENDIF»''')
			if (timeout <= 0) {
				latch.await
				logger.info('''A result has been returned''')
				// One of the threads won
			}
			else {
				latch.await(timeout, unit)
				logger.info('''«timeout» «unit» timeout has been reached''')
			}
			//
			
			return object
		} finally {
			// In case of interruption - finally block
			for (future : futures) {
				future.cancel(true)
			}
			for (callable : wrappedCallables) {
				callable.cancel
			}
			
			executor.shutdownNow
		}
	}
	
	protected def synchronized fillObject(T object) {
		if (this.object === null) {
			this.object = object
			latch.countDown
		}
	}
	
	protected def synchronized incrementNumberOfAbortedCallables(){
		val numberOfAborted = numberOfAbortedCallables.incrementAndGet
		if (numberOfAborted == numberOfCallablesShouldBeRunning) {
			// Every callable has aborted, letting the main thread go
			latch.countDown
		}
	}
	
	protected def wrap(InterruptableCallable<T> callable) {
		return new InterruptableCallable<T> {
			
			override cancel() {
				callable.cancel
			}
			
			override call() throws Exception {
				try {
					val result = callable.call
					if (Thread.currentThread.isInterrupted) {
						// The thread has been interrupted, the result is not valid
						return null
					}
					
					result.fillObject
					
					return result
				} catch (Exception e) {
					// Exception, increment counter
					incrementNumberOfAbortedCallables
					if (Thread.currentThread.isInterrupted) {
						// The thread has been interrupted, the result is not valid
						return null
					}
					e.printStackTrace
					throw e // Valid exception
				}
			}
			
		}
	}
	
}
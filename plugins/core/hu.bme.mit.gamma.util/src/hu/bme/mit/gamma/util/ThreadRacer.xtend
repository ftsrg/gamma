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
import java.util.List
import java.util.concurrent.CountDownLatch
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import java.util.logging.Logger

class ThreadRacer<T> {
	//
	final Collection<InterruptableCallable<T>> callables = newArrayList
	final Collection<InterruptableCallable<T>> wrappedCallables = newArrayList
	final Collection<Future<T>> futures = newArrayList
	final ExecutorService executor
	
	final long timeout
	final TimeUnit unit
	
	volatile T object

	final int numberOfCallablesShouldBeRunning
	final AtomicInteger numberOfAbortedCallables = new AtomicInteger
	final CountDownLatch latch = new CountDownLatch(1)
	//
	protected final Logger logger = Logger.getLogger("GammaLogger")
	//
	
	new(InterruptableCallable<T> callable) {
		this(List.of(callable), -1, null)
	}
	
	new(Collection<? extends InterruptableCallable<T>> callables) {
		this(callables, -1, null)
	}

	new(Collection<? extends InterruptableCallable<T>> callables, long timeout, TimeUnit unit) {
		val size = callables.size
		this.numberOfCallablesShouldBeRunning = size
		
		this.callables += callables
		this.executor = Executors.newFixedThreadPool(size)
		
		this.timeout = timeout
		this.unit = unit
	}
	
	def T execute() {
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
				logger.info('''A result has been returned''') // One of the threads won
			}
			else {
				latch.await(timeout, unit)
				logger.info('''«timeout» «unit» timeout has been reached''')
			}
			//
			
			return object
		} finally {
			// In case of interruption - finally block
			shutdown
		}
	}
	
	def shutdown() {
		// Canceling working threads
		for (future : futures) {
			future.cancel(true)
		}
		for (callable : wrappedCallables) {
			callable.cancel
		}
		executor.shutdownNow
		// Letting the waiting thread go - not working as cannot force working threads to stop
		// latch.countDown
	}
	
	def isTerminated() {
		return executor.terminated
	}
	
	//
	
	protected def synchronized fillObject(T object) {
		if (this.object === null) {
			this.object = object
			latch.countDown
			logger.info('''Result returned by «Thread.currentThread.name»''')
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
				val currentThread = Thread.currentThread
				try {
					val result = callable.call
					if (currentThread.isInterrupted) {
						// The thread has been interrupted, the result is not valid
						return null
					}
					
					result.fillObject
					
					return result
				} catch (Throwable e) {
					val cause = e.cause
					// Exception, increment counter
					incrementNumberOfAbortedCallables
					if (currentThread.isInterrupted || // The thread has been interrupted, the result is not valid
							cause?.class.name.endsWith("NotSolvableException")) { // Theta cannot solve this task
						// TODO model checking OOM exception should be swallowed here
						return null
					}
					
					e.printStackTrace
					throw e // Valid exception
				}
			}
			
		}
	}
	
}
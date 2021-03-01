package hu.bme.mit.gamma.util

import java.util.Collection
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors

class ThreadRacer<T> {
	
	final CountDownLatch latch = new CountDownLatch(1)
	volatile T object

	def T execute(Collection<InterruptableCallable<T>> callables) {
		val size = callables.size
		val executor = Executors.newFixedThreadPool(size)
		val futures = newArrayList
		val wrappedCallables = newArrayList
		for (callable :  callables) {
			val wrappedCallable = callable.wrap
			wrappedCallables += wrappedCallable
			futures += executor.submit(wrappedCallable)
		}
		// Racing
		latch.await
		// One of the threads won
		for (future : futures) {
			future.cancel(true)
		}
		for (callable : wrappedCallables) {
			callable.cancel
		}
		executor.shutdownNow
		return object
	}
	
	protected def synchronized fillObject(T object) {
		if (this.object === null) {
			this.object = object
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
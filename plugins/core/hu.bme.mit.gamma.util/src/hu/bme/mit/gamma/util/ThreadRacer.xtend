package hu.bme.mit.gamma.util

import java.util.Collection
import java.util.concurrent.CountDownLatch

class ThreadRacer<T> {
	
	final CountDownLatch latch = new CountDownLatch(1)
	volatile T object

	def T execute(Collection<InterruptableRunnable> runnables) {
		val threads = newArrayList
		for (runnable : runnables) {
			val thread = new Thread(runnable)
			thread.start
			threads += thread
		}
		// Racing
		latch.await
		// One of the threads won
		for (runnable : runnables) {
			runnable.interrupt
		}
		for (thread : threads) {
			thread.interrupt
		}
			
		return object
	}
	
	def synchronized setObject(T object) {
		if (this.object === null) {
			this.object = object
			latch.countDown
		}
	}
	
}
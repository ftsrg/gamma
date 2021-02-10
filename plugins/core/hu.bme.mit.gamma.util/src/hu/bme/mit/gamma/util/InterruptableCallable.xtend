package hu.bme.mit.gamma.util

import java.util.concurrent.Callable

interface InterruptableCallable<T> extends Callable<T> {
	
	def void cancel()
	
}
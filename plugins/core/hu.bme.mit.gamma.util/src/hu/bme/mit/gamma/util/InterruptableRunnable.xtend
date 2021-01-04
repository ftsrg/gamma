package hu.bme.mit.gamma.util

interface InterruptableRunnable extends Runnable {
	
	def void interrupt()
	
}
package hu.bme.mit.gamma.util

interface ElementMatcher<R, M, S> {

	def boolean hasMatch(M matchableElement, S source)
	def R match(M matchableElement, S source)
	
}
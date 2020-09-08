package hu.bme.mit.gamma.uppaal.verification.settings

import static hu.bme.mit.gamma.uppaal.verification.settings.UppaalSettings.SEARCH_ORDER_BF
import static hu.bme.mit.gamma.uppaal.verification.settings.UppaalSettings.SEARCH_ORDER_DF
import static hu.bme.mit.gamma.uppaal.verification.settings.UppaalSettings.SEARCH_ORDER_OF
import static hu.bme.mit.gamma.uppaal.verification.settings.UppaalSettings.SEARCH_ORDER_RDF
import static hu.bme.mit.gamma.uppaal.verification.settings.UppaalSettings.SEARCH_ORDER_RODF
import static hu.bme.mit.gamma.uppaal.verification.settings.UppaalSettings.STATE_SPACE_REDUCTION_AGGRESSIVE
import static hu.bme.mit.gamma.uppaal.verification.settings.UppaalSettings.STATE_SPACE_REDUCTION_CONSERVATIVE
import static hu.bme.mit.gamma.uppaal.verification.settings.UppaalSettings.STATE_SPACE_REDUCTION_NONE
import static hu.bme.mit.gamma.uppaal.verification.settings.UppaalSettings.STATE_SPACE_REPRESENTATION_DBM
import static hu.bme.mit.gamma.uppaal.verification.settings.UppaalSettings.STATE_SPACE_REPRESENTATION_OA
import static hu.bme.mit.gamma.uppaal.verification.settings.UppaalSettings.STATE_SPACE_REPRESENTATION_UA
import static hu.bme.mit.gamma.uppaal.verification.settings.UppaalSettings.TRACE_FASTEST
import static hu.bme.mit.gamma.uppaal.verification.settings.UppaalSettings.TRACE_SHORTEST
import static hu.bme.mit.gamma.uppaal.verification.settings.UppaalSettings.TRACE_SOME

class UppaalSettingsSerializer {
	def String serialize(UppaalSettings settings) {
		'''«convertStateSpaceRepresentation(settings.stateSpaceRepresentation)» «convertSearchOrder(settings.searchOrder, settings.trace)» «convertDiagnosticTrace(settings.trace)» «convertReuseStateSpace(settings.reuseStateSpace)» «convertHashtableSize(settings.hashtableSize)» «convertStateSpaceReduction(settings.stateSpaceReduction)»'''
	}

	def private String convertSearchOrder(String searchOrder, String trace) {
		val traceIsShortestOrFastest = TRACE_SHORTEST.equals(trace) || TRACE_FASTEST.equals(trace)
		val parameterName = "-o "
		switch (searchOrder) {
			case SEARCH_ORDER_BF: {
				'''«parameterName»0'''
			}
			case SEARCH_ORDER_DF: {
				'''«parameterName»1'''
			}
			case SEARCH_ORDER_RDF: {
				'''«parameterName»2'''
			}
			case SEARCH_ORDER_OF: {
				if (traceIsShortestOrFastest) {
					'''«parameterName»3'''
				} // BFS
				else {
					'''«parameterName»0'''
				}
			}
			case SEARCH_ORDER_RODF: {
				if (traceIsShortestOrFastest) {
					'''«parameterName»4'''
				} else { // BFS
					'''«parameterName»0'''
				}
			}
			default: {
				throw new IllegalArgumentException('''Not known option: «searchOrder»''');
			}
		}
	}

	def private String convertStateSpaceRepresentation(String stateSpaceRepresentation) {
		switch (stateSpaceRepresentation) {
			case STATE_SPACE_REPRESENTATION_DBM: {
				"-C"
			}
			case STATE_SPACE_REPRESENTATION_OA: {
				"-A"
			}
			case STATE_SPACE_REPRESENTATION_UA: {
				"-Z"
			}
			default: {
				throw new IllegalArgumentException('''Not known option: «stateSpaceRepresentation»''');
			}
		}
	}

	def private String convertHashtableSize(int hashtableSize) {
		/*
		 * -H n Set hash table size for bit state hashing to 2**n (default = 27)
		 */
		val int exponent = 20 + (Math.floor(Math.log10(hashtableSize) / Math.log10(2)) as int)
		// log2(value)
		'''-H «exponent»'''
	}

	def private String convertStateSpaceReduction(String stateSpaceReduction) {
		val parameterName = "-S "
		switch (stateSpaceReduction) {
			case STATE_SPACE_REDUCTION_NONE: {
				// BFS
				'''«parameterName»0'''
			}
			case STATE_SPACE_REDUCTION_CONSERVATIVE: {
				// DFS
				'''«parameterName»1'''
			}
			case STATE_SPACE_REDUCTION_AGGRESSIVE: {
				// Random DFS
				'''«parameterName»2'''
			}
			default: {
				throw new IllegalArgumentException('''Not known option: «stateSpaceReduction»''');
			}
		}
	}

	def private String convertReuseStateSpace(boolean isReuseStateSpace) {
		if(isReuseStateSpace) "-T" else ""
	}

	def private String convertDiagnosticTrace(String trace) {
		val parameterName = "-t"
		switch (trace) {
			case TRACE_SOME: {
				// Some trace
				'''«parameterName»0'''
			}
			case TRACE_SHORTEST: {
				// Shortest trace
				'''«parameterName»1'''
			}
			case TRACE_FASTEST: {
				// Fastest trace
				'''«parameterName»2'''
			}
			default: {
				throw new IllegalArgumentException('''Not known option: «trace»''');
			}
		}
	}
}

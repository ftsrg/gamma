/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
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
		return '''«convertStateSpaceRepresentation(settings.stateSpaceRepresentation)» «convertSearchOrder(settings.searchOrder, settings.trace)» «convertDiagnosticTrace(settings.trace)» «convertReuseStateSpace(settings.reuseStateSpace)» «convertHashtableSize(settings.hashtableSize)» «convertStateSpaceReduction(settings.stateSpaceReduction)»'''
	}

	def private String convertSearchOrder(String searchOrder, String trace) {
		val traceIsShortestOrFastest = TRACE_SHORTEST.equals(trace) || TRACE_FASTEST.equals(trace)
		val parameterName = "-o "
		switch (searchOrder) {
			case SEARCH_ORDER_BF: {
				return '''«parameterName»0'''
			}
			case SEARCH_ORDER_DF: {
				return '''«parameterName»1'''
			}
			case SEARCH_ORDER_RDF: {
				return '''«parameterName»2'''
			}
			case SEARCH_ORDER_OF: {
				if (traceIsShortestOrFastest) {
					return '''«parameterName»3'''
				} // BFS
				else {
					return '''«parameterName»0'''
				}
			}
			case SEARCH_ORDER_RODF: {
				if (traceIsShortestOrFastest) {
					return '''«parameterName»4'''
				} else { // BFS
					return '''«parameterName»0'''
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
				return "-C"
			}
			case STATE_SPACE_REPRESENTATION_OA: {
				return "-A"
			}
			case STATE_SPACE_REPRESENTATION_UA: {
				return "-Z"
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
		return '''-H «exponent»'''
	}

	def private String convertStateSpaceReduction(String stateSpaceReduction) {
		val parameterName = "-S "
		switch (stateSpaceReduction) {
			case STATE_SPACE_REDUCTION_NONE: {
				// BFS
				return '''«parameterName»0'''
			}
			case STATE_SPACE_REDUCTION_CONSERVATIVE: {
				// DFS
				return '''«parameterName»1'''
			}
			case STATE_SPACE_REDUCTION_AGGRESSIVE: {
				// Random DFS
				return '''«parameterName»2'''
			}
			default: {
				throw new IllegalArgumentException('''Not known option: «stateSpaceReduction»''');
			}
		}
	}

	def private String convertReuseStateSpace(boolean isReuseStateSpace) {
		return if(isReuseStateSpace) "-T" else ""
	}

	def private String convertDiagnosticTrace(String trace) {
		val parameterName = "-t"
		switch (trace) {
			case TRACE_SOME: {
				// Some trace
				return '''«parameterName»0'''
			}
			case TRACE_SHORTEST: {
				// Shortest trace
				return '''«parameterName»1'''
			}
			case TRACE_FASTEST: {
				// Fastest trace
				return '''«parameterName»2'''
			}
			default: {
				throw new IllegalArgumentException('''Not known option: «trace»''');
			}
		}
	}
}

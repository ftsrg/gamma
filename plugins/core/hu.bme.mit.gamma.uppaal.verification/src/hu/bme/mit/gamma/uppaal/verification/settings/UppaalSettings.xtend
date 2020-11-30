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

import org.eclipse.xtend.lib.annotations.Accessors

class UppaalSettings {

	public static final UppaalSettings DEFAULT_SETTINGS = createDefault

	public static final String SEARCH_ORDER_BF = "Breadth First"
	public static final String SEARCH_ORDER_DF = "Depth First"
	public static final String SEARCH_ORDER_RDF = "Random Depth First"
	public static final String SEARCH_ORDER_OF = "Optimal First"
	public static final String SEARCH_ORDER_RODF = "Random Optimal Depth First"
	public static final String SEARCH_ORDER_DEFAULT = SEARCH_ORDER_BF

	public static final String STATE_SPACE_REPRESENTATION_OA = "Over Approximation"
	public static final String STATE_SPACE_REPRESENTATION_UA = "Under Approximation"
	public static final String STATE_SPACE_REPRESENTATION_DBM = "DBM"
	public static final String STATE_SPACE_REPRESENTATION_DEFAULT = STATE_SPACE_REPRESENTATION_DBM

	public static final String TRACE_SOME = "Some"
	public static final String TRACE_SHORTEST = "Shortest"
	public static final String TRACE_FASTEST = "Fastest"
	public static final String TRACE_DEFAULT = TRACE_SHORTEST

	public static final int HASHTABLE_SIZE_64 = 64
	public static final int HASHTABLE_SIZE_256 = 256
	public static final int HASHTABLE_SIZE_512 = 512
	public static final int HASHTABLE_SIZE_1024 = 1024
	public static final int HASHTABLE_SIZE_DEFAULT = HASHTABLE_SIZE_512

	public static final String STATE_SPACE_REDUCTION_NONE = "None"
	public static final String STATE_SPACE_REDUCTION_AGGRESSIVE = "Aggressive"
	public static final String STATE_SPACE_REDUCTION_CONSERVATIVE = "Conservative"
	public static final String STATE_SPACE_REDUCTION_DEFAULT = STATE_SPACE_REDUCTION_CONSERVATIVE

	@Accessors(PUBLIC_GETTER) String searchOrder
	@Accessors(PUBLIC_GETTER) String stateSpaceRepresentation
	@Accessors(PUBLIC_GETTER) String trace
	@Accessors(PUBLIC_GETTER) int hashtableSize
	@Accessors(PUBLIC_GETTER) String stateSpaceReduction
	@Accessors(PUBLIC_GETTER) boolean reuseStateSpace

	static class Builder {
		UppaalSettings instance

		new() {
			this.instance = new UppaalSettings
		}

		def Builder searchOrder(String value) {
			instance.searchOrder = value
			return this
		}

		def Builder stateSpaceRepresentation(String value) {
			instance.stateSpaceRepresentation = value
			return this
		}

		def Builder trace(String value) {
			instance.trace = value
			return this
		}

		def Builder hashtableSize(int value) {
			instance.hashtableSize = value
			return this
		}

		def Builder stateSpaceReduction(String value) {
			instance.stateSpaceReduction = value
			return this
		}

		def Builder reuseStateSpace(boolean value) {
			instance.reuseStateSpace = value
			return this
		}

		def UppaalSettings build() {
			return instance
		}
	}

	def private static UppaalSettings createDefault() {
		return (new Builder).searchOrder(SEARCH_ORDER_DEFAULT).stateSpaceRepresentation(
			STATE_SPACE_REPRESENTATION_DEFAULT).trace(TRACE_DEFAULT).hashtableSize(HASHTABLE_SIZE_DEFAULT).
			stateSpaceReduction(STATE_SPACE_REDUCTION_DEFAULT).build
	}
}

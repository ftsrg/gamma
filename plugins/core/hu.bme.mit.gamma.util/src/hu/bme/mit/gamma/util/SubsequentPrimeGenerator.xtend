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
package hu.bme.mit.gamma.util

class SubsequentPrimeGenerator {
	
	protected final boolean IS_ONE_PRIME
	protected long lastValue
	
	new(long lowerBound) {
		this(lowerBound, false)
	}
	
	new(boolean isOnePrime) {
		this(0, isOnePrime)
	}
	
	new(long lowerBound, boolean isOnePrime) {
		if (lowerBound < 0) {
			throw new IllegalArgumentException("Only non-negative values are accepted: " + lowerBound)
		}
		this.IS_ONE_PRIME = isOnePrime
		this.lastValue = lowerBound
	}
	
	def getNextPrime() {
		if (lastValue <= 0) {
			if (IS_ONE_PRIME) {
				lastValue = 1
			}
			else {
				lastValue = 2
			}
		}
		else if (lastValue == 1) {
			lastValue = 2
		}
		else if (lastValue == 2) {
			lastValue = 3
		}
		else {
			var i = lastValue + 2
			while (!i.isPrime) {
				i += 2
			}
			lastValue = i
		}
		return lastValue
	}
	
	protected def isPrime(long value) {
		if (value != 2 && value % 2 == 0) {
			return false;
		}
		for (var i = 3; i * i <= value; i += 2) {
			if (value % i == 0) {
				return false;
			}
		}
		return true;
	}
	
}
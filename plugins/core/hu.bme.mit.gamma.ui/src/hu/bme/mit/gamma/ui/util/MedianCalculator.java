/********************************************************************************
 * Copyright (c) 2020-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.ui.util;

import java.util.Collections;
import java.util.List;

public class MedianCalculator implements Calculator<Double> {
	// Singleton
	public static final MedianCalculator INSTANCE = new MedianCalculator();
	protected MedianCalculator() {}
	//
	
	public double calculate(List<Double> values) {
		Collections.sort(values);
		
		int size = values.size();
		int halfSize = size / 2;
		if (size % 2 == 0) {
			double median = (values.get(halfSize - 1) + values.get(halfSize)) / 2.0;
			return median;
		}
		else {
			return values.get(halfSize);
		}
	}
	
}

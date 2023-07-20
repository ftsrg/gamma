/********************************************************************************
 * Copyright (c) 2021-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.expression.util.IndexHierarchy
import java.util.List

interface XstsArrayParser {
	
	def List<Pair<IndexHierarchy, String>> parseArray(String id, String value)
	
	def boolean isArray(String id, String value)
	
}
/********************************************************************************
 * Copyright (c) 2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.verification.util

import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.util.Collection

abstract class VerificationPostprocessor {
	//
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	//
	
	def Object execute(Collection<? extends Result> results)
	
}
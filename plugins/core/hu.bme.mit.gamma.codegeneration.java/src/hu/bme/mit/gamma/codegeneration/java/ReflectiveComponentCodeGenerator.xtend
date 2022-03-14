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
package hu.bme.mit.gamma.codegeneration.java

import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.statechart.interface_.Component

class ReflectiveComponentCodeGenerator extends hu.bme.mit.gamma.codegeneration.java.util.ReflectiveComponentCodeGenerator {
	
	protected final extension TypeTransformer typeTransformer

	new(String BASE_PACKAGE_NAME, Trace trace) {
		super(BASE_PACKAGE_NAME, null)
		this.typeTransformer = new TypeTransformer(trace)
	}
	
	def generateReflectiveClass(Component component) {
		super.component = component
		return super.createReflectiveClass
	}
	
	protected override transformType(Type type) '''«typeTransformer.transformType(type)»'''
	
}
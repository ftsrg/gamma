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
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.property.model.UnaryPathOperator

import static hu.bme.mit.gamma.uppaal.util.Namings.*
import static hu.bme.mit.gamma.uppaal.util.XstsNamings.*

class XstsUppaalPropertySerializer extends UppaalPropertySerializer {
	// Singleton
	public static final XstsUppaalPropertySerializer INSTANCE = new XstsUppaalPropertySerializer
	protected new() {
		super.serializer = new UppaalPropertyExpressionSerializer(XstsUppaalReferenceSerializer.INSTANCE)
	}
	//
	
	protected override String addIsStable(UnaryPathOperator operator) {
		switch (operator) {
			case FUTURE: {
				return '''&& «getProcessName(templateName)».«stableLocationName»'''
			}
			case GLOBAL: {
				return '''|| !«getProcessName(templateName)».«stableLocationName»'''
			}
			default: 
				throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
}
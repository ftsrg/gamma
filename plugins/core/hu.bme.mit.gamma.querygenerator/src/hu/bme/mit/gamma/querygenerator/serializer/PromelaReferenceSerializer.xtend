/********************************************************************************
 * Copyright (c) 2022-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State

import static extension hu.bme.mit.gamma.xsts.promela.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class PromelaReferenceSerializer extends ThetaReferenceSerializer {
	// Singleton
	public static final PromelaReferenceSerializer INSTANCE = new PromelaReferenceSerializer
	protected new() {}
	
	override protected getSingleTargetStateName(State state, Region parentRegion, ComponentInstanceReferenceExpression instance) {
		return '''«parentRegion.customizeName(instance)» == «state.customizeEnumLiteralName(parentRegion)»'''
	}
	
}
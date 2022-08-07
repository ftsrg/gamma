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

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import java.util.List

abstract interface AbstractReferenceSerializer {
	
	def String getId(State state, Region parentRegion, ComponentInstanceReferenceExpression instance)
	def String getId(Event event, Port port, ComponentInstanceReferenceExpression instance)
	def List<String> getId(VariableDeclaration variable, ComponentInstanceReferenceExpression instance)
	def List<String> getId(Event event, Port port, ParameterDeclaration parameter,
			ComponentInstanceReferenceExpression instance)
	
}

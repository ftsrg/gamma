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
package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification
import java.util.List
import org.eclipse.xtend.lib.annotations.Data

abstract class Constraint {}

@Data
class OrchestratingConstraint extends Constraint {
	TimeSpecification minimumPeriod
	TimeSpecification maximumPeriod
}

@Data
class SchedulingConstraint extends Constraint {
	List<AsynchronousInstanceConstraint > instanceConstraints = newArrayList
}

@Data
class AsynchronousInstanceConstraint {
	// This is not transformed to a concrete instance, has to be done manually in the scheduler
	ComponentInstanceReferenceExpression instance 
	OrchestratingConstraint orchestratingConstraint
}

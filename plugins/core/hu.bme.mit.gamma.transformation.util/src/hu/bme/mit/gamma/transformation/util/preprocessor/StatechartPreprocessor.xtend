/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util.preprocessor

import hu.bme.mit.gamma.eventpriority.transformation.EventPriorityTransformer
import hu.bme.mit.gamma.statechart.phase.transformation.PhaseStatechartTransformer
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition

class StatechartPreprocessor {
	
	protected final StatechartDefinition statechart
	
	protected final EventPriorityTransformer eventPriorityTransformer
	protected final PhaseStatechartTransformer phaseStatechartTransformer
	
	new(StatechartDefinition statechart) {
		this.statechart = statechart
		this.eventPriorityTransformer = new EventPriorityTransformer(statechart)
		this.phaseStatechartTransformer = new PhaseStatechartTransformer(statechart)
	}
	
	def execute() {
		eventPriorityTransformer.execute
		phaseStatechartTransformer.execute
	}
	
}
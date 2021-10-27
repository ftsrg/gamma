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
package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

abstract class LowlevelTransitionToXTransitionTransformer {
	// Auxiliary object
	protected final extension LowlevelTransitionToActionTransformer lowlevelTransitionToActionTransformer
	protected final extension StateAssumptionCreator stateAssumptionCreator
	protected final extension TransitionPreconditionCreator transitionPreconditionCreator
	protected final extension RegionActivator regionActivator
	protected final extension RegionDeactivator regionDeactivator
	protected final extension EntryActionRetriever entryActionRetriever
	protected final extension ExitActionRetriever exitActionRetriever
	protected final extension ActionTransformer actionTransformer
	protected final extension ExpressionTransformer expressionTransformer
	// Model factories
	protected final extension XSTSModelFactory factory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory constraintModelfactory = ExpressionModelFactory.eINSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	// Engine
	protected final ViatraQueryEngine engine
	// Trace
	protected final Trace trace
	
	new(ViatraQueryEngine engine, Trace trace) {
		this(engine, trace, null)
	}
	
	new(ViatraQueryEngine engine, Trace trace, RegionActivator regionActivator) {
		this.engine = engine
		this.trace = trace
		this.lowlevelTransitionToActionTransformer = new LowlevelTransitionToActionTransformer(
			engine, trace, regionActivator)
		// Delegating the contained objects to the subclasses too
		this.stateAssumptionCreator = this.lowlevelTransitionToActionTransformer.stateAssumptionCreator
		this.transitionPreconditionCreator = this.lowlevelTransitionToActionTransformer.transitionPreconditionCreator
		this.regionActivator = this.lowlevelTransitionToActionTransformer.regionActivator
		this.regionDeactivator = this.lowlevelTransitionToActionTransformer.regionDeactivator
		this.entryActionRetriever = this.lowlevelTransitionToActionTransformer.entryActionRetriever
		this.exitActionRetriever = this.lowlevelTransitionToActionTransformer.exitActionRetriever
		this.actionTransformer = this.lowlevelTransitionToActionTransformer.actionTransformer
		this.expressionTransformer = this.lowlevelTransitionToActionTransformer.expressionTransformer
	}
	
	/**
	 * Creates an xSTS transition based on the low-level transition and the xSTS action to be contained.
	 */
	protected def createXStsTransition(Action xStsTransitionAction) {
		val xStsTransition = createXTransition => [
			it.action = xStsTransitionAction
			// Noting uses it right now, so commenting out to speed up the transformation
//			it.reads += xStsTransitionAction.readVariables
//			it.writes += xStsTransitionAction.writtenVariables
		]
		// Cannot be traced here, as each transition needs different tracing
		return xStsTransition
	}
	
}
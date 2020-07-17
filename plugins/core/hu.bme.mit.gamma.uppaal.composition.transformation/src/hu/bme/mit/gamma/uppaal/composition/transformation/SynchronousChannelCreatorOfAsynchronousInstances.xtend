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

import hu.bme.mit.gamma.transformation.util.queries.SimpleWrapperInstances
import hu.bme.mit.gamma.transformation.util.queries.TopWrapperComponents
import hu.bme.mit.gamma.uppaal.transformation.traceability.TraceabilityPackage
import hu.bme.mit.gamma.uppaal.util.NtaBuilder
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRule
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory
import uppaal.NTA
import uppaal.declarations.DataVariablePrefix
import uppaal.declarations.DeclarationsPackage
import uppaal.types.TypesPackage

import static extension hu.bme.mit.gamma.uppaal.util.Namings.*

class SynchronousChannelCreatorOfAsynchronousInstances {
	// NTA target model
	final NTA nta
	// Transformation rule-related extensions
	protected extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
	// UPPAAL packages
	protected final extension DeclarationsPackage declPackage = DeclarationsPackage.eINSTANCE
	protected final extension TypesPackage typPackage = TypesPackage.eINSTANCE
	// Traceability package
	protected final extension TraceabilityPackage trPackage = TraceabilityPackage.eINSTANCE
	// Trace
	protected final extension Trace modelTrace
	// Auxiliary objects
	protected final extension NtaBuilder ntaBuilder
	// Rules
	protected BatchTransformationRule<TopWrapperComponents.Match, TopWrapperComponents.Matcher> topWrapperSyncChannelRule
	protected BatchTransformationRule<SimpleWrapperInstances.Match, SimpleWrapperInstances.Matcher> instanceWrapperSyncChannelRule
	
	new(NtaBuilder ntaBuilder, Trace modelTrace) {
		this.nta = ntaBuilder.nta
		this.ntaBuilder = ntaBuilder
		this.modelTrace = modelTrace
	}
	
	def getTopWrapperSyncChannelRule() {
		if (topWrapperSyncChannelRule === null) {
			topWrapperSyncChannelRule = createRule(TopWrapperComponents.instance).action [
				val asyncChannel = nta.globalDeclarations.createSynchronization(true, false, it.wrapper.asyncSchedulerChannelName)
				val syncChannel = nta.globalDeclarations.createSynchronization(false, false, it.wrapper.syncSchedulerChannelName)
				val isInitializedVar = nta.globalDeclarations.createVariable(DataVariablePrefix.NONE, nta.bool,  it.wrapper.initializedVariableName)
				addToTrace(it.wrapper, #{asyncChannel, syncChannel, isInitializedVar}, trace)
			].build
		}
		return topWrapperSyncChannelRule
	}
	
	def getInstanceWrapperSyncChannelRule() {
		if (instanceWrapperSyncChannelRule === null) {
			instanceWrapperSyncChannelRule = createRule(SimpleWrapperInstances.instance).action [
				val asyncChannel = nta.globalDeclarations.createSynchronization(true, false, it.instance.asyncSchedulerChannelName)
				val syncChannel = nta.globalDeclarations.createSynchronization(false, false, it.instance.syncSchedulerChannelName)
				val isInitializedVar = nta.globalDeclarations.createVariable(DataVariablePrefix.NONE, nta.bool,  it.instance.initializedVariableName)
				addToTrace(it.instance, #{asyncChannel, syncChannel, isInitializedVar}, trace) // No instanceTrace as it would be harder to retrieve the elements
			].build
		}
		return instanceWrapperSyncChannelRule
	}
	
}
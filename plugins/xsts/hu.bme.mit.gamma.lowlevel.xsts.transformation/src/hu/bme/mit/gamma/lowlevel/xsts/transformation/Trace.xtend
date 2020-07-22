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

import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.ChoiceTransitionTrace
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.EventTrace
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.ForkTransitionTrace
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.JoinTransitionTrace
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.MergeTransitionTrace
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.RegionTrace
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.SimpleTransitionTrace
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.StateTrace
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.TypeDeclarationTrace
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.VariableTrace
import hu.bme.mit.gamma.lowlevel.xsts.transformation.traceability.L2STrace
import hu.bme.mit.gamma.lowlevel.xsts.transformation.traceability.TraceabilityFactory
import hu.bme.mit.gamma.statechart.lowlevel.model.ChoiceState
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.ForkState
import hu.bme.mit.gamma.statechart.lowlevel.model.JoinState
import hu.bme.mit.gamma.statechart.lowlevel.model.MergeState
import hu.bme.mit.gamma.statechart.lowlevel.model.Package
import hu.bme.mit.gamma.statechart.lowlevel.model.Region
import hu.bme.mit.gamma.statechart.lowlevel.model.State
import hu.bme.mit.gamma.statechart.lowlevel.model.Transition
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.ParallelAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XTransition
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

import static com.google.common.base.Preconditions.checkArgument
import static com.google.common.base.Preconditions.checkState

package class Trace {
	// Trace model factory
	protected final extension TraceabilityFactory traceabilityFactory = TraceabilityFactory.eINSTANCE
	// Trace model
	protected final L2STrace trace
	// Tracing engine
	protected final ViatraQueryEngine tracingEngine
	
	new(Package _package, XSTS xSts) {
		this.trace = createL2STrace => [
			it.lowlevelPackage = _package
			it.XSts = xSts
		]
		this.tracingEngine = ViatraQueryEngine.on(new EMFScope(trace))
	}
	
	// Statechart - xSTS	
	def getXSts() {
		return trace.XSts
	}
	
	def getLowlevelPackage() {
		return trace.lowlevelPackage
	}
	
	// Type declaration - type declaration
	def put(TypeDeclaration lowlevelTypeDeclaration, TypeDeclaration xStsTypeDeclaration) {
		checkArgument(lowlevelTypeDeclaration !== null)
		checkArgument(xStsTypeDeclaration !== null)
		trace.traces += createTypeDeclarationTrace => [
			it.lowlevelTypeDeclaration = lowlevelTypeDeclaration
			it.XStsTypeDeclaration = xStsTypeDeclaration
		]
	}
	
	def isTraced(TypeDeclaration lowlevelTypeDeclaration) {
		checkArgument(lowlevelTypeDeclaration !== null)
		return TypeDeclarationTrace.Matcher.on(tracingEngine).hasMatch(lowlevelTypeDeclaration, null)
	}
	
	def getXStsTypeDeclaration(TypeDeclaration lowlevelTypeDeclaration) {
		checkArgument(lowlevelTypeDeclaration !== null)
		val matches = TypeDeclarationTrace.Matcher.on(tracingEngine).getAllValuesOfxStsTypeDeclaration(lowlevelTypeDeclaration)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getLowlevelTypeDeclaration(TypeDeclaration xStsTypeDeclaration) {
		checkArgument(xStsTypeDeclaration !== null)
		val matches = TypeDeclarationTrace.Matcher.on(tracingEngine).getAllValuesOflowlevelTypeDeclaration(xStsTypeDeclaration)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	// Event - variable
	def put(EventDeclaration lowlevelEvent, VariableDeclaration xStsVariable) {
		checkArgument(lowlevelEvent !== null)
		checkArgument(xStsVariable !== null)
		trace.traces += createEventTrace => [
			it.lowlevelEvent = lowlevelEvent
			it.XStsVariable = xStsVariable
		]
	}
	
	def getXStsVariable(EventDeclaration lowlevelEvent) {
		checkArgument(lowlevelEvent !== null)
		val matches = EventTrace.Matcher.on(tracingEngine).getAllValuesOfxStsVariable(lowlevelEvent)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getLowlevelEvent(VariableDeclaration xStsVariable) {
		checkArgument(xStsVariable !== null)
		val matches = EventTrace.Matcher.on(tracingEngine).getAllValuesOflowlevelEvent(xStsVariable)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	// Variable - variable
	def put(VariableDeclaration lowlevelVariable, VariableDeclaration xStsVariable) {
		checkArgument(lowlevelVariable !== null)
		checkArgument(xStsVariable !== null)
		trace.traces += createVariableTrace => [
			it.lowlevelVariable = lowlevelVariable
			it.XStsVariable = xStsVariable
		]
	}
	
	def getXStsVariable(VariableDeclaration lowlevelVariable) {
		checkArgument(lowlevelVariable !== null)
		val matches = VariableTrace.Matcher.on(tracingEngine).getAllValuesOfxStsVariable(lowlevelVariable)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getLowlevelVariable(VariableDeclaration xStsVariable) {
		checkArgument(xStsVariable !== null)
		val matches = VariableTrace.Matcher.on(tracingEngine).getAllValuesOflowlevelVariable(xStsVariable)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	// Region - variable
	def put(Region lowlevelRegion, VariableDeclaration xStsVariable) {
		checkArgument(lowlevelRegion !== null)
		checkArgument(xStsVariable !== null)
		trace.traces += createRegionTrace => [
			it.lowlevelRegion = lowlevelRegion
			it.XStsRegionVariable = xStsVariable
		]
	}
	
	def isTraced(Region lowlevelRegion) {
		checkArgument(lowlevelRegion !== null)
		return RegionTrace.Matcher.on(tracingEngine).hasMatch(lowlevelRegion, null)
	}
	
	def getXStsVariable(Region lowlevelRegion) {
		checkArgument(lowlevelRegion !== null)
		val matches = RegionTrace.Matcher.on(tracingEngine).getAllValuesOfxStsVariable(lowlevelRegion)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getLowlevelRegion(VariableDeclaration xStsVariable) {
		checkArgument(xStsVariable !== null)
		val matches = RegionTrace.Matcher.on(tracingEngine).getAllValuesOflowlevelRegion(xStsVariable)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	// Region - __Deactivated__ enum literal
	def getXStsInactiveEnumLiteral(Region lowlevelRegion) {
		val xStsRegionVariable = lowlevelRegion.XStsVariable
		val type = xStsRegionVariable.type
		val enumType = if (type instanceof EnumerationTypeDefinition) {
			type
		}
		else if (type instanceof TypeReference) {
			val typeDeclaration = type.reference
			checkState(typeDeclaration.type instanceof EnumerationTypeDefinition)
			typeDeclaration.type as EnumerationTypeDefinition
		}
		return enumType.getXStsInactiveEnumLiteral
	}
	
	def getXStsInactiveEnumLiteral(EnumerationTypeDefinition enumType) {
		val enumLiterals = enumType.literals.filter[it.name.equals(Namings.INACTIVE_ENUM_LITERAL)]
		checkState(enumLiterals.size == 1, enumLiterals)
		return enumLiterals.head
	}
	
	// State of Region - enum literal
	def put(State lowlevelState, EnumerationLiteralDefinition xStsEnumLiteral) {
		checkArgument(lowlevelState !== null)
		checkArgument(xStsEnumLiteral !== null)
		trace.traces += createStateTrace => [
			it.lowlevelState= lowlevelState
			it.XStsEnumLiteral = xStsEnumLiteral
		]
	}
	
	def getXStsEnumLiteral(State lowlevelState) {
		checkArgument(lowlevelState !== null)
		val matches = StateTrace.Matcher.on(tracingEngine).getAllValuesOfxStsEnumLiteral(lowlevelState)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getLowlevelState(EnumerationLiteralDefinition xStsEnumLiteral) {
		checkArgument(xStsEnumLiteral !== null)
		val matches = StateTrace.Matcher.on(tracingEngine).getAllValuesOflowlevelState(xStsEnumLiteral)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	
	def getXStsPrecondition(XTransition xStsTransition) {
		checkArgument(xStsTransition !== null)
		var matches = SimpleTransitionTrace.Matcher.on(tracingEngine).getAllValuesOfxStsPrecondition(null, xStsTransition)
		if (matches.size < 1) {
			matches = ChoiceTransitionTrace.Matcher.on(tracingEngine).getAllValuesOfxStsPrecondition(null, xStsTransition, null)
		}
		// No else
		if (matches.size < 1) {
			matches = MergeTransitionTrace.Matcher.on(tracingEngine).getAllValuesOfxStsPrecondition(null, xStsTransition, null)
		}
		if (matches.size < 1) {
			matches = ForkTransitionTrace.Matcher.on(tracingEngine).getAllValuesOfxStsPrecondition(null, xStsTransition, null)
		}
		if (matches.size < 1) {
			matches = JoinTransitionTrace.Matcher.on(tracingEngine).getAllValuesOfxStsPrecondition(null, xStsTransition, null)
		}
		// TODO additional traces
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	// Simple transition - xTransition
	def put(Transition lowlevelSimpleTransition, XTransition xStsTransition, Expression xStsPrecondition) {
		checkArgument(lowlevelSimpleTransition !== null)
		checkArgument(xStsTransition !== null)
		trace.traces += createSimpleTransitionTrace => [
			it.lowlevelTransition = lowlevelSimpleTransition
			it.XStsTransition= xStsTransition
			it.XStsPrecondition = xStsPrecondition
		]
	}
	
	def isTraced(Transition lowlevelSimpleTransition) {
		checkArgument(lowlevelSimpleTransition !== null)
		return SimpleTransitionTrace.Matcher.on(tracingEngine).hasMatch(lowlevelSimpleTransition, null, null)
	}
	
	def getXStsTransition(Transition lowlevelSimpleTransition) {
		checkArgument(lowlevelSimpleTransition !== null)
		val matches = SimpleTransitionTrace.Matcher.on(tracingEngine).getAllValuesOfxStsTransition(lowlevelSimpleTransition, null)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getLowlevelSimpleTransition(XTransition xStsTransition) {
		checkArgument(xStsTransition !== null)
		val matches = SimpleTransitionTrace.Matcher.on(tracingEngine).getAllValuesOflowlevelSimpleTransition(xStsTransition, null)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	// Choice transition - xTransition
	def put(ChoiceState lowlevelChoiceState, XTransition xStsTransition, Expression xStsPrecondition, NonDeterministicAction xStsChoiceAction) {
		checkArgument(lowlevelChoiceState !== null)
		checkArgument(xStsTransition !== null)
		checkArgument(xStsChoiceAction !== null)
		checkArgument(xStsPrecondition !== null)
		trace.traces += createChoiceTransitionTrace => [
			it.lowlevelChoiceState = lowlevelChoiceState
			it.XStsTransition= xStsTransition
			it.XStsChoiceAction = xStsChoiceAction
			it.XStsPrecondition = xStsPrecondition
		]
	}
	
	def isTraced(ChoiceState lowlevelChoiceState) {
		checkArgument(lowlevelChoiceState !== null)
		return ChoiceTransitionTrace.Matcher.on(tracingEngine).hasMatch(lowlevelChoiceState, null, null, null)
	}
	
	def getXStsTransition(ChoiceState lowlevelChoiceState) {
		checkArgument(lowlevelChoiceState !== null)
		val matches = ChoiceTransitionTrace.Matcher.on(tracingEngine).getAllValuesOfxStsTransition(lowlevelChoiceState, null, null)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getXStsChoiceAction(ChoiceState lowlevelChoiceState) {
		checkArgument(lowlevelChoiceState !== null)
		val matches = ChoiceTransitionTrace.Matcher.on(tracingEngine).getAllValuesOfxStsChoiceAction(lowlevelChoiceState, null, null)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getLowlevelChoiceState(XTransition xStsTransition) {
		checkArgument(xStsTransition !== null)
		val matches = ChoiceTransitionTrace.Matcher.on(tracingEngine).getAllValuesOflowlevelChoiceState(xStsTransition, null, null)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	// Merge transition - xTransition
	def put(MergeState lowlevelMergeState, XTransition xStsTransition, Expression xStsPrecondition, NonDeterministicAction xStsMergeAction) {
		checkArgument(lowlevelMergeState !== null)
		checkArgument(xStsTransition !== null)
		checkArgument(xStsMergeAction !== null)
		checkArgument(xStsPrecondition !== null)
		trace.traces += createMergeTransitionTrace => [
			it.lowlevelMergeState = lowlevelMergeState
			it.XStsTransition= xStsTransition
			it.XStsMergeAction = xStsMergeAction
			it.XStsPrecondition = xStsPrecondition
		]
	}
	
	def isTraced(MergeState lowlevelMergeState) {
		checkArgument(lowlevelMergeState !== null)
		return MergeTransitionTrace.Matcher.on(tracingEngine).hasMatch(lowlevelMergeState, null, null, null)
	}
	
	def getXStsTransition(MergeState lowlevelMergeState) {
		checkArgument(lowlevelMergeState !== null)
		val matches = MergeTransitionTrace.Matcher.on(tracingEngine).getAllValuesOfxStsTransition(lowlevelMergeState, null, null)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getXStsMergeAction(MergeState lowlevelMergeState) {
		checkArgument(lowlevelMergeState !== null)
		val matches = MergeTransitionTrace.Matcher.on(tracingEngine).getAllValuesOfxStsMergeAction(lowlevelMergeState, null, null)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getLowlevelMergeState(XTransition xStsTransition) {
		checkArgument(xStsTransition !== null)
		val matches = MergeTransitionTrace.Matcher.on(tracingEngine).getAllValuesOflowlevelMergeState(xStsTransition, null, null)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	// Fork transition - xTransition
	def put(ForkState lowlevelForkState, XTransition xStsTransition, Expression xStsPrecondition, ParallelAction xStsParallelAction) {
		checkArgument(lowlevelForkState !== null)
		checkArgument(xStsTransition !== null)
		checkArgument(xStsParallelAction !== null)
		checkArgument(xStsPrecondition !== null)
		trace.traces += createForkTransitionTrace => [
			it.lowlevelForkState = lowlevelForkState
			it.XStsTransition= xStsTransition
			it.XStsParallelAction = xStsParallelAction
			it.XStsPrecondition = xStsPrecondition
		]
	}
	
	def isTraced(ForkState lowlevelForkState) {
		checkArgument(lowlevelForkState !== null)
		return ForkTransitionTrace.Matcher.on(tracingEngine).hasMatch(lowlevelForkState, null, null, null)
	}
	
	def getXStsTransition(ForkState lowlevelForkState) {
		checkArgument(lowlevelForkState !== null)
		val matches = ForkTransitionTrace.Matcher.on(tracingEngine).getAllValuesOfxStsTransition(lowlevelForkState, null, null)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getXStsParallelAction(ForkState lowlevelForkState) {
		checkArgument(lowlevelForkState !== null)
		val matches = ForkTransitionTrace.Matcher.on(tracingEngine).getAllValuesOfxStsForkAction(lowlevelForkState, null, null)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getLowlevelForkState(XTransition xStsTransition) {
		checkArgument(xStsTransition !== null)
		val matches = ForkTransitionTrace.Matcher.on(tracingEngine).getAllValuesOflowlevelForkState(xStsTransition, null, null)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
		
	// Join transition - xTransition
	def put(JoinState lowlevelJoinState, XTransition xStsTransition, Expression xStsPrecondition, ParallelAction xStsParallelAction) {
		checkArgument(lowlevelJoinState !== null)
		checkArgument(xStsTransition !== null)
		checkArgument(xStsParallelAction !== null)
		checkArgument(xStsPrecondition !== null)
		trace.traces += createJoinTransitionTrace => [
			it.lowlevelJoinState = lowlevelJoinState
			it.XStsTransition= xStsTransition
			it.XStsParallelAction = xStsParallelAction
			it.XStsPrecondition = xStsPrecondition
		]
	}
	
	def isTraced(JoinState lowlevelJoinState) {
		checkArgument(lowlevelJoinState !== null)
		return JoinTransitionTrace.Matcher.on(tracingEngine).hasMatch(lowlevelJoinState, null, null, null)
	}
	
	def getXStsTransition(JoinState lowlevelJoinState) {
		checkArgument(lowlevelJoinState !== null)
		val matches = JoinTransitionTrace.Matcher.on(tracingEngine).getAllValuesOfxStsTransition(lowlevelJoinState, null, null)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getXStsParallelAction(JoinState lowlevelJoinState) {
		checkArgument(lowlevelJoinState !== null)
		val matches = JoinTransitionTrace.Matcher.on(tracingEngine).getAllValuesOfxStsForkAction(lowlevelJoinState, null, null)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getLowlevelJoinState(XTransition xStsTransition) {
		checkArgument(xStsTransition !== null)
		val matches = JoinTransitionTrace.Matcher.on(tracingEngine).getAllValuesOflowlevelJoinState(xStsTransition, null, null)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getTrace() {
		return trace;
	}
	
}
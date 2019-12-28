package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.uppaal.composition.transformation.queries.SimpleWrapperInstances
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopWrapperComponents
import hu.bme.mit.gamma.uppaal.transformation.traceability.TraceabilityPackage
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRule
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory
import uppaal.NTA
import uppaal.declarations.DataVariablePrefix
import uppaal.declarations.DeclarationsPackage
import uppaal.types.TypesPackage

import static extension hu.bme.mit.gamma.uppaal.composition.transformation.Namings.*

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
	
	protected def getTopWrapperSyncChannelRule() {
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
	protected def getInstanceWrapperSyncChannelRule() {
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
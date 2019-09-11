package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.uppaal.composition.transformation.queries.SimpleWrapperInstances
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopWrapperComponents
import hu.bme.mit.gamma.uppaal.transformation.traceability.TraceabilityPackage
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRule
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory
import uppaal.NTA
import uppaal.declarations.ChannelVariableDeclaration
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.DataVariablePrefix
import uppaal.declarations.Declarations
import uppaal.declarations.DeclarationsPackage
import uppaal.declarations.Variable
import uppaal.declarations.VariableContainer
import uppaal.types.PredefinedType
import uppaal.types.TypeReference
import uppaal.types.TypesPackage

import static extension hu.bme.mit.gamma.uppaal.composition.transformation.Namings.*

class SynchronousChannelCreatorOfAsynchronousInstances {
	// NTA target model
	final NTA target
	// Transformation rule-related extensions
	protected extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
	protected extension IModelManipulations manipulation
	// UPPAAL packages
	protected final extension DeclarationsPackage declPackage = DeclarationsPackage.eINSTANCE
	protected final extension TypesPackage typPackage = TypesPackage.eINSTANCE
	// Traceability package
    protected final extension TraceabilityPackage trPackage = TraceabilityPackage.eINSTANCE
	// Trace
	protected final extension Trace modelTrace
	// Rules
	protected BatchTransformationRule<TopWrapperComponents.Match, TopWrapperComponents.Matcher> topWrapperSyncChannelRule
	protected BatchTransformationRule<SimpleWrapperInstances.Match, SimpleWrapperInstances.Matcher> instanceWrapperSyncChannelRule
	
	new(NTA target, Trace modelTrace) {
		this.target = target
		this.modelTrace = modelTrace
	}
	
	protected def getTopWrapperSyncChannelRule() {
		if (topWrapperSyncChannelRule === null) {
			topWrapperSyncChannelRule = createRule(TopWrapperComponents.instance).action [
				val asyncChannel = target.globalDeclarations.createSynchronization(false, false, it.wrapper.asyncSchedulerChannelName)
				val syncChannel = target.globalDeclarations.createSynchronization(false, false, it.wrapper.syncSchedulerChannelName)
				val isInitializedVar = target.globalDeclarations.createVariable(DataVariablePrefix.NONE, target.bool,  it.wrapper.initializedVariableName)
				addToTrace(it.wrapper, #{asyncChannel, syncChannel, isInitializedVar}, trace)
			].build
		}
		return topWrapperSyncChannelRule
	}
	protected def getInstanceWrapperSyncChannelRule() {
		if (instanceWrapperSyncChannelRule === null) {
			instanceWrapperSyncChannelRule = createRule(SimpleWrapperInstances.instance).action [
				val asyncChannel = target.globalDeclarations.createSynchronization(false, false, it.instance.asyncSchedulerChannelName)
				val syncChannel = target.globalDeclarations.createSynchronization(false, false, it.instance.syncSchedulerChannelName)
				val isInitializedVar = target.globalDeclarations.createVariable(DataVariablePrefix.NONE, target.bool,  it.instance.initializedVariableName)
				addToTrace(it.instance, #{asyncChannel, syncChannel, isInitializedVar}, trace) // No instanceTrace as it would be harder to retrieve the elements
			].build
		}
		return instanceWrapperSyncChannelRule
	}
	
	/**
	 * This method is responsible for creating the variables in the resource depending on the received parameters.
	 * It also creates the traces.
	 */
	private def ChannelVariableDeclaration createSynchronization(Declarations decl, boolean isBroadcast, boolean isUrgent, String name) {
		val syncContainer = decl.createChild(declarations_Declaration, channelVariableDeclaration) as ChannelVariableDeclaration => [
			it.broadcast = isBroadcast
			it.urgent = isUrgent
		]
		syncContainer.createTypeAndVariable(target.chan, name)
		return syncContainer
	}
	
	/**
	 * This method is responsible for creating the variables in the resource depending on the received parameters.
	 * It also creates the traces.
	 */
	private def DataVariableDeclaration createVariable(Declarations decl, DataVariablePrefix prefix, PredefinedType type, String name) {
		val varContainer = decl.createChild(declarations_Declaration, dataVariableDeclaration) as DataVariableDeclaration => [
			it.prefix = prefix
		]
		varContainer.createTypeAndVariable(type, name)		
		return varContainer
	}
	
	/**
	 * This method creates the variables of the given containers based on the given predefined type and name.
	 */
	private def createTypeAndVariable(VariableContainer container, PredefinedType type, String name) {		
		container.createChild(variableContainer_TypeDefinition, typeReference) as TypeReference => [
			it.referredType = type
		]
		// Creating variables for all statechart instances
		container.createChild(variableContainer_Variable, declPackage.variable) as Variable => [
			it.container = container
			it.name = name
		]
	}
	

	
}
package hu.bme.mit.gamma.uppaal.composition.transformation

import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
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

class NtaBuilder {
	// NTA target model
	final NTA nta
	protected final extension IModelManipulations manipulation
	// UPPAAL packages
	protected final extension DeclarationsPackage declPackage = DeclarationsPackage.eINSTANCE
	protected final extension TypesPackage typPackage = TypesPackage.eINSTANCE
	
	new(NTA nta, IModelManipulations manipulation) {
		this.nta = nta
		this.manipulation = manipulation
	}
	
	/**
	 * This method is responsible for creating the variables in the resource depending on the received parameters.
	 * It also creates the traces.
	 */
	def createSynchronization(Declarations decl, boolean isBroadcast, boolean isUrgent, String name) {
		val syncContainer = decl.createChild(declarations_Declaration, channelVariableDeclaration) as ChannelVariableDeclaration => [
			it.broadcast = isBroadcast
			it.urgent = isUrgent
		]
		syncContainer.createTypeAndVariable(nta.chan, name)
		return syncContainer
	}
	
	/**
	 * This method is responsible for creating the variables in the resource depending on the received parameters.
	 * It also creates the traces.
	 */
	def createVariable(Declarations decl, DataVariablePrefix prefix, PredefinedType type, String name) {
		val varContainer = decl.createChild(declarations_Declaration, dataVariableDeclaration) as DataVariableDeclaration => [
			it.prefix = prefix
		]
		varContainer.createTypeAndVariable(type, name)		
		return varContainer
	}
	
	/**
	 * This method creates the variables of the given containers based on the given predefined type and name.
	 */
	def createTypeAndVariable(VariableContainer container, PredefinedType type, String name) {		
		container.createChild(variableContainer_TypeDefinition, typeReference) as TypeReference => [
			it.referredType = type
		]
		// Creating variables for all statechart instances
		container.createChild(variableContainer_Variable, declPackage.variable) as Variable => [
			it.container = container
			it.name = name
		]
	}
	
	def getNta() {
		return nta
	}
	
}
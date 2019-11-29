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
import uppaal.expressions.ExpressionsPackage
import uppaal.expressions.IdentifierExpression
import uppaal.templates.Edge
import uppaal.templates.Location
import uppaal.templates.LocationKind
import uppaal.templates.Synchronization
import uppaal.templates.SynchronizationKind
import uppaal.templates.TemplatesPackage
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
	protected final extension TemplatesPackage temPackage = TemplatesPackage.eINSTANCE
	protected final extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
	
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
	
	/**
	 * Responsible for creating an edge in the given template with the given source and target.
	 */
	def Edge createEdge(Location source, Location target) {
		if (source.parentTemplate != target.parentTemplate) {
			throw new IllegalArgumentException("The source and the target are in different templates." + source + " " + target)
		}
		val template = source.parentTemplate
		template.createChild(template_Edge, edge) as Edge => [
			it.source = source
			it.target = target
		]
	}
	
	def Edge createEdgeCommittedTarget(Location target, String name) {
		val template = target.parentTemplate
		val syncLocation = template.createChild(template_Location, location) as Location => [
			it.name = name
			it.locationTimeKind = LocationKind.COMMITED
			it.comment = "Synchronization location."
		]
		val syncEdge = syncLocation.createEdge(target)
		return syncEdge		
	}
	
	
	/**
	 * Responsible for creating a ! synchronization on an edge and a committed location as the source of the edge.
	 * The target of the synchronized edge will be the given "target" location.
	 */
	def Edge createCommittedSyncTarget(Location target, Variable syncVar, String name) {
		val syncEdge = target.createEdgeCommittedTarget(name) => [
			it.comment = "Synchronization edge."
			it.setSynchronization(syncVar, SynchronizationKind.SEND)
		]
		return syncEdge		
	}
	
	/**
	 * Responsible for placing a synchronization onto the given edge: "channel?/channel!".
	 */
	def setSynchronization(Edge edge, Variable syncVar, SynchronizationKind syncType) {
		edge.createChild(edge_Synchronization, temPackage.synchronization) as Synchronization => [
			it.kind = syncType
			it.createChild(synchronization_ChannelExpression, identifierExpression) as IdentifierExpression => [
				it.identifier = syncVar
			]
		]	
	}
	
	/**
	 * Responsible for creating a synchronization edge from the given source to target with the given sync channel and snyc kind.
	 */
	def Edge createEdgeWithSync(Location sourceLoc, Location targetLoc, Variable syncVar, SynchronizationKind syncKind) {
		val loopEdge = sourceLoc.createEdge(targetLoc)
		loopEdge.setSynchronization(syncVar, syncKind)	
		return loopEdge
	}
		
	def getNta() {
		return nta
	}
	
}
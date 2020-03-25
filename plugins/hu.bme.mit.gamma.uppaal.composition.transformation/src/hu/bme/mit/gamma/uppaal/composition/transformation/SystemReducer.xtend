package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.CompositeElement
import hu.bme.mit.gamma.statechart.model.Package
import hu.bme.mit.gamma.statechart.model.Region
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.Transition
import hu.bme.mit.gamma.statechart.model.composite.BroadcastChannel
import hu.bme.mit.gamma.statechart.model.composite.SimpleChannel
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.SynchronousCompositeComponent
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.InstanceRegions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RemovableTransitions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.SimpleInstances
import java.util.logging.Level
import java.util.logging.Logger
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class SystemReducer {
	
	final ViatraQueryEngine engine
	
	final extension Logger logger = Logger.getLogger("GammaLogger")

	new(ResourceSet resourceSet) {
		this.engine = ViatraQueryEngine.on(new EMFScope(resourceSet))
	}
	
	def execute() {
		// Transition optimizing
		val transitionMatcher = RemovableTransitions.Matcher.on(engine)
		while (transitionMatcher.hasMatch) {
			for (transition : transitionMatcher.allValuesOftransition.reject[it.eContainer === null]) {
				transition.removeTransition
			}
		}
		// Region optimizing
		val regionMatcher = InstanceRegions.Matcher.on(engine)
		for (region : regionMatcher.allValuesOfregion) {
			region.removeUnnecessaryRegion
		}
		// Instance optimizing
		val simpleInstancesMatcher = SimpleInstances.Matcher.on(engine)
		for (instance : simpleInstancesMatcher.allValuesOfinstance) {
			instance.removeUnnecessaryStatechartInstance
		}
	}
	
	private def void removeTransition(Transition transition) {
		val statechart = transition.eContainer as StatechartDefinition
		val target = transition.targetState
		if (target.incomingTransitions.size == 1) {
			for (outgoingTransition : target.outgoingTransitions) {
				outgoingTransition.removeTransition
			}
			val region = target.parentRegion
			log(Level.INFO, "Removing state node" + target.name)
			region.stateNodes -= target
		}
		log(Level.INFO, "Removing transition" + transition.sourceState.name + " -> " + transition.targetState.name)
		statechart.transitions -= transition
	}
	
	private def void removeUnnecessaryRegion(Region region) {
		val states = region.states
		if (states.forall[!it.composite && it.outgoingTransitions.empty ||
				it.incomingTransitions.empty]) {
			// First, removing all related transitions (as otherwise nullptr exceptions are generated in incomingTransitions)
			val statechart = region.containingStatechart
			statechart.transitions -= (states.map[it.incomingTransitions].flatten + 
				states.map[it.outgoingTransitions].flatten).toList
			// Removing region
			val compositeElement = region.eContainer as CompositeElement
			compositeElement.regions -= region
			log(Level.INFO, "Removing region " + region.name)
		}
	}
	
	private def void removeUnnecessaryStatechartInstance(SynchronousComponentInstance instance) {
		val statechart = instance.type as StatechartDefinition
		if (statechart.regions.empty) {
			val container = instance.eContainer
			// It can be either an asynchronous adapter or a synchronous composite
			if (container instanceof SynchronousCompositeComponent) {
				container.components -= instance
				val _package = statechart.eContainer as Package
				_package.components -= statechart
				log(Level.INFO, "Removing statechart instance " + instance.name)
				// Port binding remover
				val unnecessaryPortBindings = container.portBindings
					.filter[it.instancePortReference.instance === instance].toList
				container.portBindings -= unnecessaryPortBindings
				// Channel remover
				val channels = container.channels
				val unnecessaryChannels = (channels.filter[it.providedPort.instance === instance] + 
					channels.filter(SimpleChannel).filter[it.requiredPort.instance === instance] +
					channels.filter(BroadcastChannel).filter[it.requiredPorts.exists[it.instance === instance]]).toList
				container.channels -= unnecessaryChannels
			}
		}
	}
	
}
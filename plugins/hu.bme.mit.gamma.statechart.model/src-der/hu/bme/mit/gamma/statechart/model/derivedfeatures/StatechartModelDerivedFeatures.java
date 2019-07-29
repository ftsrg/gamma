package hu.bme.mit.gamma.statechart.model.derivedfeatures;

import java.util.Collection;
import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.statechart.model.AnyPortEventReference;
import hu.bme.mit.gamma.statechart.model.ClockTickReference;
import hu.bme.mit.gamma.statechart.model.CompositeElement;
import hu.bme.mit.gamma.statechart.model.EventReference;
import hu.bme.mit.gamma.statechart.model.EventSource;
import hu.bme.mit.gamma.statechart.model.InterfaceRealization;
import hu.bme.mit.gamma.statechart.model.Port;
import hu.bme.mit.gamma.statechart.model.PortEventReference;
import hu.bme.mit.gamma.statechart.model.RealizationMode;
import hu.bme.mit.gamma.statechart.model.Region;
import hu.bme.mit.gamma.statechart.model.State;
import hu.bme.mit.gamma.statechart.model.StateNode;
import hu.bme.mit.gamma.statechart.model.StatechartDefinition;
import hu.bme.mit.gamma.statechart.model.TimeoutEventReference;
import hu.bme.mit.gamma.statechart.model.Transition;
import hu.bme.mit.gamma.statechart.model.composite.AbstractSynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter;
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.model.composite.Component;
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.model.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection;

public class StatechartModelDerivedFeatures {

	public static boolean isBroadcast(InterfaceRealization interfaceRealization) {
		return interfaceRealization.getRealizationMode() == RealizationMode.PROVIDED &&
				interfaceRealization.getInterface().getEvents().stream().allMatch(it -> it.getDirection() == EventDirection.OUT);
	}
	
	public static boolean isBroadcast(Port port) {
		return isBroadcast(port.getInterfaceRealization());
	}
	
	public static Collection<Port> getAllPorts(AsynchronousAdapter wrapper) {
		Collection<Port> allPorts = new HashSet<Port>(wrapper.getPorts());
		allPorts.addAll(wrapper.getWrappedComponent().getType().getPorts());
		return allPorts;
	}
	
	public static Collection<Port> getAllPorts(Component component) {
		if (component instanceof AsynchronousAdapter) {
			return getAllPorts((AsynchronousAdapter)component);
		}		
		return component.getPorts();
	}
	
	public static EventSource getEventSource(EventReference eventReference) {
		if (eventReference instanceof PortEventReference) {
			return ((PortEventReference) eventReference).getPort();
		}
		if (eventReference instanceof AnyPortEventReference) {
			return ((AnyPortEventReference) eventReference).getPort();
		}
		if (eventReference instanceof ClockTickReference) {
			return ((ClockTickReference) eventReference).getClock();
		}
		if (eventReference instanceof TimeoutEventReference) {
			return ((TimeoutEventReference) eventReference).getTimeout();
		}
		throw new IllegalArgumentException("Not known type: " + eventReference);
	}
	
	public static Component getDerivedType(ComponentInstance instance) {
		if (instance instanceof SynchronousComponentInstance) {
			return ((SynchronousComponentInstance) instance).getType();
		}
		if (instance instanceof AsynchronousComponentInstance) {
			return ((AsynchronousComponentInstance) instance).getType();
		}
		throw new IllegalArgumentException("Not known type: " + instance);
	}
	
	public static EList<? extends ComponentInstance> getDerivedComponents(CompositeComponent composite) {
		if (composite instanceof AbstractSynchronousCompositeComponent) {
			return ((AbstractSynchronousCompositeComponent) composite).getComponents();
		}
		if (composite instanceof AsynchronousCompositeComponent) {
			return ((AsynchronousCompositeComponent) composite).getComponents();
		}
		throw new IllegalArgumentException("Not known type: " + composite);
	}
	
	public static Collection<Transition> getOutgoingTransitions(StateNode node) {
		StatechartDefinition statechart = getContainingStatechart(node);
		return statechart.getTransitions().stream().filter(it -> it.getSourceState() == node).collect(Collectors.toSet());
	}
	
	public static Collection<Transition> getIncomingTransitions(StateNode node) {
		StatechartDefinition statechart = getContainingStatechart(node);
		return statechart.getTransitions().stream().filter(it -> it.getTargetState() == node).collect(Collectors.toSet());
	}
	
	public static Collection<StateNode> getStateNodes(CompositeElement compositeElement) {
		Set<StateNode> stateNodes = new HashSet<StateNode>();
		for (Region region : compositeElement.getRegions()) {
			for (StateNode stateNode : region.getStateNodes()) {
				stateNodes.add(stateNode);
				if (stateNode instanceof State) {
					State state = (State) stateNode;
					stateNodes.addAll(getStateNodes(state));
				}
			}
		}
		return stateNodes;
	}
	
	public static Collection<State> getStates(CompositeElement compositeElement) {
		Set<State> states = new HashSet<State>();
		for (StateNode stateNode : getStateNodes(compositeElement)) {
			if (stateNode instanceof State) {
				State state = (State) stateNode;
				states.add(state);
			}
		}
		return states;
	}
	
	public static Region getParentRegion(StateNode node) {
		return (Region) node.eContainer();
	}
	
	public static boolean isTopRegion(Region region) {
		return region.eContainer() instanceof StatechartDefinition;
	}
	
	public static boolean isSubregion(Region region) {
		return !isTopRegion(region);
	}
	
	public static State getParentState(Region region) {
		if (isTopRegion(region)) {
			throw new IllegalArgumentException("This region has no parent state: " + region);
		}
		return (State) region.eContainer();
	}
	
	public static State getParentState(StateNode node) {
		Region parentRegion = getParentRegion(node);
		return getParentState(parentRegion);
	}
	
	public static StatechartDefinition getContainingStatechart(EObject object) {
		if (object.eContainer() instanceof StatechartDefinition) {
			return (StatechartDefinition) object.eContainer();
		}
		return getContainingStatechart(object.eContainer());
	}
	
	public static Component getContainingComponent(EObject object) {
		if (object.eContainer() == null) {
			throw new IllegalArgumentException("Not contained by a component: " + object);
		}
		if (object instanceof Component) {
			return (Component) object;
		}
		return getContainingComponent(object.eContainer());
	}
	
}
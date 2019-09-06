package hu.bme.mit.gamma.statechart.model.derivedfeatures;

import java.util.Collection;
import java.util.HashSet;
import java.util.List;
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
	
	public static List<Transition> getOutgoingTransitions(StateNode node) {
		StatechartDefinition statechart = getContainingStatechart(node);
		return statechart.getTransitions().stream().filter(it -> it.getSourceState() == node).collect(Collectors.toList());
	}
	
	public static List<Transition> getIncomingTransitions(StateNode node) {
		StatechartDefinition statechart = getContainingStatechart(node);
		return statechart.getTransitions().stream().filter(it -> it.getTargetState() == node).collect(Collectors.toList());
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
	
	public static boolean isSameRegion(Transition transition) {
		return getParentRegion(transition.getSourceState()) == getParentRegion(transition.getTargetState());
	}
	
	public static boolean isToHigher(Transition transition) {
		return isToHigher(transition.getSourceState(), transition.getTargetState());
	}
	
	public static boolean isToHigher(StateNode source, StateNode target) {
		Region sourceParentRegion = getParentRegion(source);
		if (isTopRegion(sourceParentRegion)) {
			return false;
		}
		State sourceParentState = getParentState(source);
		if (getParentRegion(sourceParentState) == getParentRegion(target)) {
			return true;
		}
		return isToHigher(sourceParentState, target);
	}
	
	public static boolean isToLower(Transition transition) {
		return isToLower(transition.getSourceState(), transition.getTargetState());
	}
	
	public static boolean isToLower(StateNode source, StateNode target) {
		Region targetParentRegion = getParentRegion(target);
		if (isTopRegion(targetParentRegion)) {
			return false;
		}
		State targetParentState = getParentState(target);
		if (getParentRegion(source) == getParentRegion(targetParentState)) {
			return true;
		}
		return isToLower(source, targetParentState);
	}
	
	public static boolean isToHigherAndLower(Transition transition) {
		return isToLowerOrHigherAndLower(transition.getSourceState(), transition.getTargetState()) &&
				!isToLower(transition.getSourceState(), transition.getTargetState());
	}
	
	public static boolean isToLowerOrHigherAndLower(StateNode source, StateNode target) {
		if (isToLower(source, target)) {
			return true;
		}
		Region sourceParentRegion = getParentRegion(source);
		if (isTopRegion(sourceParentRegion)) {
			return false;
		}
		State sourceParentState = getParentState(source);
		return isToLower(sourceParentState, target);
	}
	
	public static boolean isToHigherOrHigherAndLower(StateNode source, StateNode target) {
		if (isToHigher(source, target)) {
			return true;
		}
		Region targetParentRegion = getParentRegion(target);
		if (isTopRegion(targetParentRegion)) {
			return false;
		}
		State targetParentState = getParentState(target);
		return isToLower(source, targetParentState);
	}
	
	public static StateNode getSourceAncestor(Transition transition) {
		return getSourceAncestor(transition.getSourceState(), transition.getTargetState());
	}
	
	public static StateNode getSourceAncestor(StateNode source, StateNode target) {
		if (isToLower(source, target)) {
			return source;
		}
		Region sourceParentRegion = getParentRegion(source);
		if (isTopRegion(sourceParentRegion)) {
			throw new IllegalArgumentException("No source ancestor!");
		}
		State sourceParentState = getParentState(source);
		return getSourceAncestor(sourceParentState, target);
	}
	
	public static StateNode getTargetAncestor(Transition transition) {
		return getTargetAncestor(transition.getSourceState(), transition.getTargetState());
	}
	
	public static StateNode getTargetAncestor(StateNode source, StateNode target) {
		if (isToHigher(source, target)) {
			return source;
		}
		Region targetParentRegion = getParentRegion(target);
		if (isTopRegion(targetParentRegion)) {
			throw new IllegalArgumentException("No target ancestor!");
		}
		State targetParentState = getParentState(target);
		return getTargetAncestor(source, targetParentState);
	}
	
}
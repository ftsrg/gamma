/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.lowlevel.derivedfeatures;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.action.derivedfeatures.ActionModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.lowlevel.model.CompositeElement;
import hu.bme.mit.gamma.statechart.lowlevel.model.DeepHistoryState;
import hu.bme.mit.gamma.statechart.lowlevel.model.EntryState;
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration;
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection;
import hu.bme.mit.gamma.statechart.lowlevel.model.HistoryState;
import hu.bme.mit.gamma.statechart.lowlevel.model.InitialState;
import hu.bme.mit.gamma.statechart.lowlevel.model.Region;
import hu.bme.mit.gamma.statechart.lowlevel.model.ShallowHistoryState;
import hu.bme.mit.gamma.statechart.lowlevel.model.State;
import hu.bme.mit.gamma.statechart.lowlevel.model.StateNode;
import hu.bme.mit.gamma.statechart.lowlevel.model.StatechartAnnotation;
import hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition;
import hu.bme.mit.gamma.statechart.lowlevel.model.Transition;

public class LowlevelStatechartModelDerivedFeatures extends ActionModelDerivedFeatures {
	
	public static StatechartDefinition getStatechart(EObject object) {
		if (object instanceof StatechartDefinition) {
			return (StatechartDefinition) object;
		}
		return getStatechart(object.eContainer());
	}
	
	public static boolean hasAnnotation(StatechartDefinition statechart,
			Class<? extends StatechartAnnotation> annotation) {
		return statechart.getAnnotations().stream().anyMatch(it -> annotation.isInstance(it));
	}
	
	public static boolean isInternal(EventDeclaration lowlevelEventDeclaration) {
		StatechartDefinition statechart = getStatechart(lowlevelEventDeclaration);
		List<EventDeclaration> internalEventDeclarations = statechart.getInternalEventDeclarations();
		return internalEventDeclarations.contains(lowlevelEventDeclaration);
	}
	
	public static EventDeclaration getInternalEventPair(EventDeclaration lowlevelEventDeclaration) {
		StatechartDefinition statechart = getStatechart(lowlevelEventDeclaration);
		
		List<EventDeclaration> internalEventDeclarations = statechart.getInternalEventDeclarations();
		List<EventDeclaration> inEventDeclarations = internalEventDeclarations.stream()
				.filter(it -> it.getDirection() == EventDirection.IN).collect(Collectors.toList());
		List<EventDeclaration> outEventDeclarations = internalEventDeclarations.stream()
				.filter(it -> it.getDirection() == EventDirection.OUT).collect(Collectors.toList());
		
		int inIndex = inEventDeclarations.indexOf(lowlevelEventDeclaration);
		if (inIndex >= 0) {
			return outEventDeclarations.get(inIndex);
		}
		else {
			int outIndex = outEventDeclarations.indexOf(lowlevelEventDeclaration);
			return inEventDeclarations.get(outIndex);
		}
	}
	
	public static boolean hasOrthogonalRegion(Region lowlevelRegion) {
		return !getOrthogonalRegions(lowlevelRegion).isEmpty();
	}

	public static List<Region> getOrthogonalRegions(Region lowlevelRegion) {
		return lowlevelRegion.getParentElement().getRegions().stream()
				.filter(it-> it != lowlevelRegion).collect(Collectors.toList());
	}
	
	public static boolean hasInitialState(Region lowlevelRegion) {
		return lowlevelRegion.getStateNodes().stream()
				.anyMatch(it -> it instanceof InitialState);
	}
	
	public static boolean hasShallowHistoryState(Region lowlevelRegion) {
		return lowlevelRegion.getStateNodes().stream()
				.anyMatch(it -> it instanceof ShallowHistoryState);
	}
	
	public static boolean hasDeepHistoryState(Region lowlevelRegion) {
		return lowlevelRegion.getStateNodes().stream()
				.anyMatch(it -> it instanceof DeepHistoryState);
	}
	
	public static boolean hasHistoryState(Region lowlevelRegion) {
		return lowlevelRegion.getStateNodes().stream()
				.anyMatch(it -> it instanceof HistoryState);
	}
	
	public static EntryState getEntryState(Region region) {
		Collection<StateNode> entryStates = region.getStateNodes().stream()
				.filter(it -> it instanceof EntryState)
				.collect(Collectors.toList());
		Optional<StateNode> entryState = entryStates.stream().filter(it -> it instanceof InitialState).findFirst();
		if (entryState.isPresent()) {
			return (EntryState) entryState.get();
		}
		entryState = entryStates.stream().filter(it -> it instanceof DeepHistoryState).findFirst();
		if (entryState.isPresent()) {
			return (EntryState) entryState.get();
		}
		entryState = entryStates.stream().filter(it -> it instanceof ShallowHistoryState).findFirst();
		if (entryState.isPresent()) {
			return (EntryState) entryState.get();
		}
		throw new IllegalArgumentException("Not found entry states in the region: " +
				region.getName() + ": " + entryStates);
	}
	
	public static boolean hasHistory(Region lowlevelRegion) {
		return hasHistoryState(lowlevelRegion) || hasDeepHistoryAbove(lowlevelRegion);
	}
	
	public static boolean hasDeepHistoryAbove(Region lowlevelRegion) {
		if (isTopRegion(lowlevelRegion)) {
			return false;
		}
		Region parentRegion = getParentRegion(lowlevelRegion);
		return parentRegion.getStateNodes().stream()
				.anyMatch(it -> it instanceof DeepHistoryState) ||
				hasDeepHistoryAbove(parentRegion);
	}
	
	public static List<State> getStates(Region lowlevelRegion) {
		List<State> states = new ArrayList<State>();
		for (StateNode node : lowlevelRegion.getStateNodes()) {
			if (node instanceof State) {
				states.add((State) node);
			}
		}
		return states;
	}
	
	public static Region getParentRegion(Region lowlevelRegion) {
		CompositeElement parentElement = lowlevelRegion.getParentElement();
		if (parentElement instanceof State) {
			State state = (State) parentElement;
			return state.getParentRegion();
		}
		throw new IllegalArgumentException("Incorrect region: " + lowlevelRegion);
	}
	
	public static List<Region> getParentRegionsRecursively(StateNode lowlevelState) {
		return getParentRegionsRecursively(lowlevelState, null);
	}
	
	public static List<Region> getParentRegionsRecursively(StateNode lowlevelState, State topLowlevelState) {
		List<Region> lowlevelParentRegions = new ArrayList<Region>();
		if (lowlevelState == topLowlevelState) {
			return lowlevelParentRegions;
		}
		Region lowlevelParentRegion = lowlevelState.getParentRegion();
		lowlevelParentRegions.add(lowlevelParentRegion);
		if (isTopRegion(lowlevelParentRegion)) {
			return lowlevelParentRegions;
		}
		State lowlevelParentState = getParentState(lowlevelState);
		lowlevelParentRegions.addAll(
				getParentRegionsRecursively(lowlevelParentState, topLowlevelState));
		return lowlevelParentRegions;
	}
	
	public static List<Region> getSubregionsRecursively(StateNode lowlevelStateNode) {
		List<Region> lowlevelSubregions = new ArrayList<Region>();
		if (lowlevelStateNode instanceof State) {
			State lowlevelState = (State) lowlevelStateNode;
			List<Region> regions = lowlevelState.getRegions();
			lowlevelSubregions.addAll(regions);
			for (Region lowlevelSubregion : regions) {
				for (StateNode lowlevelSubstateNode : lowlevelSubregion.getStateNodes()) {
					if (lowlevelSubstateNode instanceof State) {
						lowlevelSubregions.addAll(
								getSubregionsRecursively(lowlevelSubstateNode));
					}
				}
			}
		}
		return lowlevelSubregions;
	}
	
	public static List<List<Region>> getTopDownRegionGroups(CompositeElement element) {
		List<List<Region>> lowlevelSamePriorityRegionGroups = new ArrayList<List<Region>>();
		
		List<Region> lowlevelOrthogonalRegions = new ArrayList<Region>();
		List<Region> lowlevelSubregions = element.getRegions();
		lowlevelOrthogonalRegions.addAll(lowlevelSubregions);
		
		lowlevelSamePriorityRegionGroups.add(lowlevelOrthogonalRegions);
		
		for (Region lowlevelSubregion : lowlevelSubregions) {
			for (State state : getStates(lowlevelSubregion)) {
				if (isComposite(state)) {
					lowlevelSamePriorityRegionGroups.addAll(
							getTopDownRegionGroups(state));
				}
			}
		}
		
		return lowlevelSamePriorityRegionGroups;
	}
	
	public static List<List<Region>> getBottomUpRegionGroups(CompositeElement element) {
		List<List<Region>> topDownRegionGroups = getTopDownRegionGroups(element);
		Collections.reverse(topDownRegionGroups);
		return topDownRegionGroups;
	}
	
	public static List<Region> getAllRegions(CompositeElement element) {
		List<Region> lowlevelSubregions = new ArrayList<Region>();
		for (List<Region> regions : getTopDownRegionGroups(element)) {
			lowlevelSubregions.addAll(regions);
		}
		return lowlevelSubregions;
	}
	
	public static List<Region> getAllRegions(Region region) {
		List<Region> lowlevelSubregions = new ArrayList<Region>();
		for (State state : getStates(region)) {
			if (isComposite(state)) {
				lowlevelSubregions.addAll(
						getAllRegions(state));
			}
		}
		return lowlevelSubregions;
	}
	
	public static List<State> getStates(CompositeElement composite) {
		List<State> lowlevelStates = new ArrayList<State>();
		
		for (Region region : composite.getRegions()) {
			List<StateNode> stateNodes = region.getStateNodes();
			for (StateNode stateNode : stateNodes) {
				if (stateNode instanceof State state) {
					lowlevelStates.add(state);
				}
			}
		}
		
		return lowlevelStates;
	}
	
	public static List<State> getAllStates(CompositeElement composite) {
		List<State> lowlevelStates = new ArrayList<State>();
		
		for (Region region : composite.getRegions()) {
			List<StateNode> stateNodes = region.getStateNodes();
			for (StateNode stateNode : stateNodes) {
				if (stateNode instanceof State state) {
					lowlevelStates.add(state);
					lowlevelStates.addAll(
							getAllStates(state));
				}
			}
		}
		
		return lowlevelStates;
	}
	
	public static List<Region> getSelfAndAllRegions(Region region) {
		List<Region> allRegions = getAllRegions(region);
		allRegions.add(region);
		return allRegions;
	}
	
	public static boolean isTopRegion(Region lowlevelRegion) {
		return lowlevelRegion.getParentElement() instanceof StatechartDefinition;
	}
	
	public static boolean isComposite(State state) {
		return !state.getRegions().isEmpty();
	}
	
	public static State getParentState(StateNode lowlevelState) {
		CompositeElement parentElement = lowlevelState.getParentRegion().getParentElement();
		if (parentElement instanceof State) {
			return (State) parentElement;
		}
		throw new IllegalArgumentException("Incorrect state node: " + lowlevelState);
	}

	public static boolean isLeaf(Region lowlevelRegion) {
		return lowlevelRegion.getStateNodes().stream()
				.filter(it -> it instanceof State)
				.allMatch(it -> ((State) it).getRegions().isEmpty());
	}
	
	public static Transition getInitialTransition(Region region) {
		EntryState entryState = getEntryState(region);
		List<Transition> outgoingTransitions = getOutgoingTransitions(entryState);
		if (outgoingTransitions.size() != 1) {
			throw new IllegalArgumentException(outgoingTransitions.toString());
		}
		return outgoingTransitions.get(0);
	}
	
	public static List<Transition> getOutgoingTransitions(StateNode node) {
		StatechartDefinition statechart = getStatechart(node);
		return statechart.getTransitions().stream().filter(it -> it.getSource() == node)
				.collect(Collectors.toList());
	}
	
	public static List<Transition> getHigherPriorityTransitions(Transition lowlevelTransition) {
		int priority = lowlevelTransition.getPriority();
		StateNode source = lowlevelTransition.getSource();
		List<Transition> outgoingTransitions = source.getOutgoingTransitions();
		List<Transition> higherPriorityTransitions =  outgoingTransitions.stream()
			.filter(it -> it.getPriority() > priority)
			.collect(Collectors.toList());
		return higherPriorityTransitions;
	}
	
	public static List<Transition> getAncestorTransitions(Transition lowlevelTransition) {
		StateNode source = lowlevelTransition.getSource();
		List<State> parentStates = ecoreUtil.getAllContainersOfType(source, State.class);
		List<Transition> outgoingTransition = new ArrayList<Transition>();
		for (State parentState : parentStates) {
			outgoingTransition.addAll(parentState.getOutgoingTransitions());
		}
		return outgoingTransition;
	}
	
	public static List<Transition> getDescendantTransitions(Transition lowlevelTransition) {
		StateNode source = lowlevelTransition.getSource();
		List<State> childStates = ecoreUtil.getAllContentsOfType(source, State.class);
		List<Transition> outgoingTransition = new ArrayList<Transition>();
		for (State childState : childStates) {
			outgoingTransition.addAll(childState.getOutgoingTransitions());
		}
		return outgoingTransition;
	}
	
	public static List<Transition> getSortingAccordingToPriority(
			Collection<? extends Transition> lowlevelTransitions) {
		List<Transition> sortedTransitions = new ArrayList<Transition>();
		sortedTransitions.addAll(lowlevelTransitions);
		sortedTransitions.sort(
			new Comparator<Transition>() {
				public int compare(Transition lhs, Transition rhs) {
					Integer l = lhs.getPriority();
					Integer r = rhs.getPriority();
					return r.compareTo(l);
				}
			}
		);
		return sortedTransitions;
	}
	
	public static boolean arePrioritiesUnique(
			Collection<? extends Transition> lowlevelTransitions) {
		Set<Integer> priorites = new HashSet<Integer>();
		// Watch out for join nodes
		for (Transition lowlevelTransition : lowlevelTransitions) {
			priorites.add(lowlevelTransition.getPriority());
		}
		return lowlevelTransitions.size() == priorites.size();
	}
	
	public static boolean arePrioritiesSame(
			Collection<? extends Transition> lowlevelTransitions) {
		Set<Integer> priorites = new HashSet<Integer>();
		// Watch out for join nodes
		for (Transition lowlevelTransition : lowlevelTransitions) {
			priorites.add(lowlevelTransition.getPriority());
		}
		return priorites.size() == 1;
	}
	
}

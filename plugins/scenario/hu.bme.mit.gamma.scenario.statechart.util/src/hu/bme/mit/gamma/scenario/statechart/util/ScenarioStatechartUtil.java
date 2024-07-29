/********************************************************************************
 * Copyright (c) 2020-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.statechart.util;

import java.util.LinkedList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import hu.bme.mit.gamma.scenario.model.InteractionDirection;
import hu.bme.mit.gamma.scenario.model.LoopCombinedFragment;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.EventReference;
import hu.bme.mit.gamma.statechart.interface_.EventTrigger;
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.interface_.Trigger;
import hu.bme.mit.gamma.statechart.statechart.PortEventReference;
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory;
import hu.bme.mit.gamma.statechart.statechart.Transition;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ScenarioStatechartUtil {
	// Singleton
	public static final ScenarioStatechartUtil INSTANCE = new ScenarioStatechartUtil();
	protected ScenarioStatechartUtil() {}
	//
	protected final String hotComponentViolation = "hotComponentViolation";
	protected final String hotEnvironmentViolation = "hotEnvironmentViolation";
	
	private final String stateName = "state";
	private final String choiceName = "Choice";
	private final String reversed = "Reversed";
	private final String coldViolation = "coldViolation";
	private final String hotViolation = "hotViolation";
	private final String Accepting = "AcceptingState";
	private final String initial = "Initial";
	private final String LoopVariable = "LoopIteratingVariable";
	private final String result = "result";
	private final String IteratingVariable = "IteratingVariable";
	private final String firstRegionName = "region";
	private final String firstStateName = "initialState";
	private final String mergeName = "merge";
	private final String delayName = "delay";
	
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final StatechartModelFactory statechartFactory = StatechartModelFactory.eINSTANCE;
	protected final InterfaceModelFactory interfaceFactory = InterfaceModelFactory.eINSTANCE;

	public String getDelayName(int delayCount) {
		return delayName + delayCount;
	}

	public String getMergeName() {
		return mergeName;
	}

	public String getFirstStateName() {
		return firstStateName;
	}

	public String getFirstRegionName() {
		return firstRegionName;
	}

	public String getIteratingVariable() {
		return IteratingVariable;
	}

	public String getResult() {
		return result;
	}

	public boolean isTurnedOut(Port port) {
		return port.getName().endsWith(reversed);
	}

	public String getTurnedOutPortName(Port port) {
		if (isTurnedOut(port)) {
			return port.getName().substring(0, port.getName().length() - reversed.length());
		}
		return port.getName() + reversed;
	}

	public String getColdViolation() {
		return coldViolation;
	}

	public String getHotViolation() {
		return hotViolation;
	}

	public String getStateName() {
		return stateName;
	}

	public String getChoiceName() {
		return choiceName;
	}

	public String getAccepting() {
		return Accepting;
	}

	public String getInitial() {
		return initial;
	}

	public int getLoopDepth(LoopCombinedFragment loop) {
		return ecoreUtil.getAllContainersOfType(loop, LoopCombinedFragment.class).size();
	}

	public String getLoopvariableNameForDepth(int depth) {
		return LoopVariable + depth;
	}

	public String getHotComponentViolation() {
		return hotComponentViolation;
	}

	public String getHotEnvironmentViolation() {
		return hotEnvironmentViolation;
	}

	public String getCombinedStateAcceptingName(String name) {
		return name + "__" + Accepting;
	}

	public String getNameOfNewPort(Port port, boolean isSend) {
		return isSend ? getTurnedOutPortName(port) : port.getName();
	}

	public List<EventReference> getAllInputEventReferencesForDirection(Component automaton, boolean isSentByComponent) {
		List<EventReference> eventRefs = new LinkedList<EventReference>();
		List<Port> correctPorts = automaton.getPorts().stream()
				.filter(it -> !StatechartModelDerivedFeatures.isInternal(it)) 
				.filter(it -> !StatechartModelDerivedFeatures.getInputEvents(it).isEmpty())
				.collect(Collectors.toList());
		for (Port port : correctPorts) {
			if ((isTurnedOut(port) && isSentByComponent) || (!isTurnedOut(port) && !isSentByComponent)) {
				for (Event event : StatechartModelDerivedFeatures.getInputEvents(port)) { // Changed from getAllEvents
					PortEventReference eventRef = statechartFactory.createPortEventReference();
					eventRef.setEvent(event);
					eventRef.setPort(port);
					eventRefs.add(eventRef);
				}
			}
		}
		return eventRefs;
	}

	public List<Trigger> getAllTriggersForDirection(Component automaton, boolean isSentByComponent) {
		List<Trigger> triggers = new LinkedList<Trigger>();
		
		List<EventReference> eventRefs = getAllInputEventReferencesForDirection(automaton, isSentByComponent);
		for (EventReference ref : eventRefs) {
			EventTrigger eventTrigger = interfaceFactory.createEventTrigger();
			eventTrigger.setEventReference(ref);
			triggers.add(eventTrigger);
		}
		
		return triggers;
	}

	public InteractionDirection getDirection(Transition transition) {
		Optional<EventTrigger> optionalTrigger = ecoreUtil
				.getAllContentsOfType(transition.getTrigger(), EventTrigger.class).stream()
				.filter((it) -> it.getEventReference() instanceof PortEventReference).findAny();
		if (!optionalTrigger.isPresent()) {
			return InteractionDirection.RECEIVE;
		}
		EventTrigger eventTrigger = optionalTrigger.get();
		PortEventReference portEventReference = (PortEventReference) eventTrigger.getEventReference();
		if (isTurnedOut(portEventReference.getPort())) {
			return InteractionDirection.SEND;
		}
		else {
			return InteractionDirection.RECEIVE;
		}
	}
}

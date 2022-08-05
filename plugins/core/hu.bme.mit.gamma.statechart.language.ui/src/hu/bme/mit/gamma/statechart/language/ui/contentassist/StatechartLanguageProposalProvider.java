/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.language.ui.contentassist;

import java.math.BigInteger;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.Optional;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.Assignment;
import org.eclipse.xtext.CrossReference;
import org.eclipse.xtext.resource.IEObjectDescription;
import org.eclipse.xtext.ui.editor.contentassist.ContentAssistContext;
import org.eclipse.xtext.ui.editor.contentassist.ICompletionProposalAcceptor;

import com.google.common.base.Predicate;

import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.composite.MessageQueue;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.EventDirection;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.interface_.RealizationMode;
import hu.bme.mit.gamma.statechart.statechart.PortEventReference;
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction;

/**
 * See
 * https://www.eclipse.org/Xtext/documentation/304_ide_concepts.html#content-assist
 * on how to customize the content assistant.
 */
public class StatechartLanguageProposalProvider extends AbstractStatechartLanguageProposalProvider {
	
	public void completeMessageQueue_Priority(MessageQueue model, Assignment assignment,
			ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		AsynchronousAdapter wrapper = (AsynchronousAdapter) model.eContainer();
        if (wrapper.getMessageQueues().size() <= 1) {
        	acceptor.accept(createCompletionProposal("1", context));
        	return;
        }
        Collection<BigInteger> priorities = wrapper.getMessageQueues().stream()
        		.map(it -> it.getPriority())
        		.filter(it -> it != null)
        		.collect(Collectors.toSet());
        Integer next = priorities.stream().max((a, b) -> a.compareTo(b)).get().intValue() + 1;
        Integer previous = priorities.stream().min((a, b) -> a.compareTo(b)).get().intValue() - 1;
        acceptor.accept(createCompletionProposal(next.toString(), context));
        acceptor.accept(createCompletionProposal(previous.toString(), context));
	}
	
	public void completeMessageQueue_Capacity(MessageQueue model, Assignment assignment,
			ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
        for (Integer value : new Integer[] {4, 8, 16})
		acceptor.accept(createCompletionProposal(value.toString(), context));
	}
	
	/**
	 * If the model is a CompositeComponent, the default scoping does not work well.
	 */
	public void completeInstancePortReference_Port(CompositeComponent model, Assignment assignment,
			ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		lookupCrossReference(((CrossReference) assignment.getTerminal()), context, acceptor,
			new Predicate<IEObjectDescription>() {
				@Override
				public boolean apply(IEObjectDescription arg) {
					EObject port = arg.getEObjectOrProxy();
					// Previous: ".", previous-previous: name of the component instance - see the grammar
					String instanceName = context.getCurrentNode().getPreviousSibling().getPreviousSibling().getText();
					ComponentInstance instance = StatechartModelDerivedFeatures.getDerivedComponents(model).stream()
													.filter(it -> it.getName().equals(instanceName)).findFirst().get();
					Collection<Port> ports = StatechartModelDerivedFeatures
								.getAllPorts(StatechartModelDerivedFeatures.getDerivedType(instance));
					return ports.contains(port);
				}
			});
	}
	
	public void completePortEventReference_Event(PortEventReference model, Assignment assignment,
			ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		lookupCrossReference(((CrossReference) assignment.getTerminal()), context, acceptor,
			new Predicate<IEObjectDescription>() {
				@Override
				public boolean apply(IEObjectDescription arg) {
					EObject event = arg.getEObjectOrProxy();
					if (event instanceof Event) {
						Port port = model.getPort();
						return isCorrectEvent(port, (Event) event, EventDirection.IN);
					}
					return false;
				}
			});
	}
	
	public void completePortEventReference_Event(EObject model, Assignment assignment,
			ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		lookupCrossReference(((CrossReference) assignment.getTerminal()), context, acceptor,
			new Predicate<IEObjectDescription>() {
				@Override
				public boolean apply(IEObjectDescription arg) {
					EObject event = arg.getEObjectOrProxy();
					if (event instanceof Event) {
						Event trueEvent = (Event) event;
						// Previous: ".", previous-previous: name of the port - see the grammar
						// Does not work with .getPreviousSibling().getPreviousSibling().getText(), as first sibling is null
						String portName = context.getLastCompleteNode().getPreviousSibling().getText();
						Component component = StatechartModelDerivedFeatures.getContainingComponent(model);
						Collection<Port> ports = StatechartModelDerivedFeatures.getAllPorts(component);
						Port port = null;
						Optional<Port> optionalPort = ports.stream().filter(it -> it.getName().equals(portName)).findFirst();
						if (optionalPort.isPresent()) {
							port = optionalPort.get();
						}
						if (port != null) {
							if (event.eIsProxy()) {
								// For some reason, wrappers return proxys, which do not work normally
								String interfaceName = getInterfaceNameInWrappers(arg);
								String eventName = getEventNameInWrappers(arg);
								Interface portInterface = port.getInterfaceRealization().getInterface();
								if (portInterface.getName().equals(interfaceName)) {
									Optional<Event> optional = portInterface.getEvents().stream().map(it -> it.getEvent())
															.filter(it -> it.getName().equals(eventName)).findAny();
									if (optional.isPresent()) {
										trueEvent = optional.get();
									}
								}
							}
							return isCorrectEvent(port, trueEvent, EventDirection.IN);
						}
					}
					return false;
				}
			});
	}
	
	private String getInterfaceNameInWrappers(IEObjectDescription arg) {
		int segmentCount = arg.getName().getSegmentCount();
		String fullName = arg.getName().getSegment(segmentCount - 2); // interface.BroadcastInterface.c
		return fullName; // BroadcastInterface
	}
	
	private String getEventNameInWrappers(IEObjectDescription arg) {
		String eventName = arg.getName().getLastSegment(); // interface.BroadcastInterface.c
		return eventName; // c
	}

	public void completeRaiseEventAction_Event(RaiseEventAction model, Assignment assignment,
			ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		lookupCrossReference(((CrossReference) assignment.getTerminal()), context, acceptor,
			new Predicate<IEObjectDescription>() {
				@Override
				public boolean apply(IEObjectDescription arg) {
					EObject event = arg.getEObjectOrProxy();
					if (event instanceof Event) {
						Port port = model.getPort();
						return isCorrectEvent(port, (Event) event, EventDirection.OUT);
					}
					return false;
				}
			});
	}
	
	private boolean isCorrectEvent(Port port, Event event, EventDirection direction) {
		Collection<Event> events = getSemanticEvents(Collections.singletonList(port), direction);
		return events.contains(event);
	}

	private Collection<Event> getSemanticEvents(Collection<? extends Port> ports, EventDirection direction) {
		Collection<Event> events = new HashSet<Event>();
		for (Interface anInterface : ports.stream()
				.filter(it -> it.getInterfaceRealization().getRealizationMode() == RealizationMode.PROVIDED)
				.map(it -> it.getInterfaceRealization().getInterface()).collect(Collectors.toSet())) {
			events.addAll(getAllEvents(anInterface, getOppositeDirection(direction)));
		}
		for (Interface anInterface : ports.stream()
				.filter(it -> it.getInterfaceRealization().getRealizationMode() == RealizationMode.REQUIRED)
				.map(it -> it.getInterfaceRealization().getInterface()).collect(Collectors.toSet())) {
			events.addAll(getAllEvents(anInterface, direction));
		}
		return events;
	}

	private EventDirection getOppositeDirection(EventDirection direction) {
		switch (direction) {
			case IN:
				return EventDirection.OUT;
			case OUT:
				return EventDirection.IN;
			default:
				throw new IllegalArgumentException("Not known direction: " + direction);
		}
	}

	/**
	 * The parent interfaces are taken into considerations as well.
	 */
	private Collection<Event> getAllEvents(Interface anInterface, EventDirection oppositeDirection) {
		if (anInterface == null) {
			return Collections.emptySet();
		}
		Collection<Event> eventSet = new HashSet<Event>();
		for (Interface parentInterface : anInterface.getParents()) {
			eventSet.addAll(getAllEvents(parentInterface, oppositeDirection));
		}
		for (Event event : anInterface.getEvents().stream().filter(it -> it.getDirection() != oppositeDirection)
				.map(it -> it.getEvent()).collect(Collectors.toSet())) {
			eventSet.add(event);
		}
		return eventSet;
	}

}

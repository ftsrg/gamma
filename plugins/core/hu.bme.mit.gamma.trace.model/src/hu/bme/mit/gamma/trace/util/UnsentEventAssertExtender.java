/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.util;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.trace.model.Assert;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.model.NegatedAssert;
import hu.bme.mit.gamma.trace.model.RaiseEventAct;
import hu.bme.mit.gamma.trace.model.Step;
import hu.bme.mit.gamma.trace.model.TraceModelFactory;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class UnsentEventAssertExtender {
	//
	protected TraceModelFactory traceFactory = TraceModelFactory.eINSTANCE;
	protected GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	//
	List<Step> steps = new ArrayList<Step>();
	List<Port> ports = new ArrayList<Port>();
	
	Component component = null;

	boolean allSteps = false;
	//
	public UnsentEventAssertExtender(List<Step> steps, boolean allSteps) {
		this.steps = steps;
		this.allSteps = allSteps;
	}

	public UnsentEventAssertExtender(Step step) {
		this.steps.add(step);
	}

	public void execute() {
		Step firstStep = steps.get(0);
		ExecutionTrace trace = ecoreUtil.getContainerOfType(firstStep, ExecutionTrace.class);
		component = trace.getComponent();
		ports = component.getPorts();
		
		for (Step step : steps) {
			List<NegatedAssert> negatedAsserts = new ArrayList<NegatedAssert>();
			for (Port port : ports) {
				for (Event event : StatechartModelDerivedFeatures.getOutputEvents(port)) {
					if (event.getParameterDeclarations().isEmpty()) {
						NegatedAssert negatedAssert = traceFactory.createNegatedAssert();
						RaiseEventAct raise = traceFactory.createRaiseEventAct();
						raise.setPort(port);
						raise.setEvent(event);
						negatedAssert.setNegatedAssert(raise);
						negatedAsserts.add(negatedAssert);
					}
				}
			}

			List<Assert> baseAsserts = step.getAsserts();

			for (Assert assertion : baseAsserts) {
				Set<Assert> removable = new HashSet<Assert>();
				if (assertion instanceof RaiseEventAct) {
					RaiseEventAct raise = (RaiseEventAct) assertion;
					Port aPort = raise.getPort();
					Event aEvent = raise.getEvent();
					for (NegatedAssert negatedAssert : negatedAsserts) {
						if (negatedAssert.getNegatedAssert() instanceof RaiseEventAct) {
							RaiseEventAct raiseEvent = (RaiseEventAct) negatedAssert.getNegatedAssert();
							if (equals(aPort, aEvent, raiseEvent)) {
								removable.add(negatedAssert);
							}
						}
					}
				}
				negatedAsserts.removeAll(removable);
			}
			step.getAsserts().addAll(negatedAsserts);
		}
	}

	private boolean equals(Port aPort, Event aEvent, RaiseEventAct raiseEvent) {
		return raiseEvent.getPort().getName().equals(aPort.getName())
				&& raiseEvent.getEvent().getName().equals(aEvent.getName());
	}

}

/********************************************************************************
 * Copyright (c) 2020-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.statechart.util;

import hu.bme.mit.gamma.scenario.model.LoopCombinedFragment;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ScenarioStatechartUtil {

	public static final ScenarioStatechartUtil INSTANCE = new ScenarioStatechartUtil();

	protected ScenarioStatechartUtil() {
	}

	protected final String hotComponentViolation = "hotComponentViolation";

	protected final String hotEnvironmentViolation = "hotEnvironmentViolation";

	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;

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

	private final String firstStateName = "firstState";

	private final String mergeName = "merge";
	
	private final String delayName = "delay";
	
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

	public boolean isTurnedOut(Port p) {
		return p.getName().endsWith(reversed);
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

}

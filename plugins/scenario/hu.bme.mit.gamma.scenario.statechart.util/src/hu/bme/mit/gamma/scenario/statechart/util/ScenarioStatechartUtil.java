package hu.bme.mit.gamma.scenario.statechart.util;

import hu.bme.mit.gamma.statechart.interface_.Port;

public class ScenarioStatechartUtil {

	public static final ScenarioStatechartUtil INSTANCE = new ScenarioStatechartUtil();

	protected ScenarioStatechartUtil() {
	}

	private final String reversed = "REVERSED";

	private final String coldViolation = "coldViolation";

	private final String hotViolation = "hotViolation";

	private final String Accepting = "AcceptingState";

	private final String initial = "init";

	public boolean isTurnedOut(Port p) {
		return p.getName().endsWith(reversed);
	}

	public String getTurnedOutPortName(Port p) {
		if (isTurnedOut(p)) {
			return p.getName().substring(0, p.getName().length() - reversed.length());
		}
		return p.getName() + reversed;
	}

	public String getColdViolation() {
		return coldViolation;
	}

	public String getHotViolation() {
		return hotViolation;
	}

	public String getAccepting() {
		return Accepting;
	}

	public String getInitial() {
		return initial;
	}

}

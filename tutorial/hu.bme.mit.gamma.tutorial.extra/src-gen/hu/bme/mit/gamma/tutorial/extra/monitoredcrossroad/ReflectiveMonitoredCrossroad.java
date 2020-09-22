package hu.bme.mit.gamma.tutorial.extra.monitoredcrossroad;

import hu.bme.mit.gamma.tutorial.extra.*;
import hu.bme.mit.gamma.tutorial.extra.tutorial.*;
import hu.bme.mit.gamma.tutorial.extra.monitor.*;

public class ReflectiveMonitoredCrossroad implements ReflectiveComponentInterface {
	
	private MonitoredCrossroad wrappedComponent;
	// Wrapped contained components
	private ReflectiveComponentInterface crossroad = null;
	private ReflectiveComponentInterface monitor = null;
	
	public ReflectiveMonitoredCrossroad(UnifiedTimerInterface timer) {
		this();
		wrappedComponent.setTimer(timer);
	}
	
	public ReflectiveMonitoredCrossroad() {
		wrappedComponent = new MonitoredCrossroad();
	}
	
	public ReflectiveMonitoredCrossroad(MonitoredCrossroad wrappedComponent) {
		this.wrappedComponent = wrappedComponent;
	}
	
	public void reset() {
		wrappedComponent.reset();
	}
	
	public MonitoredCrossroad getWrappedComponent() {
		return wrappedComponent;
	}
	
	public String[] getPorts() {
		return new String[] { "police", "priorityOutput", "secondaryOutput", "monitorOutput" };
	}
	
	public String[] getEvents(String port) {
		switch (port) {
			case "police":
				return new String[] { "police" };
			case "priorityOutput":
				return new String[] { "displayNone", "displayYellow", "displayRed", "displayGreen" };
			case "secondaryOutput":
				return new String[] { "displayNone", "displayYellow", "displayRed", "displayGreen" };
			case "monitorOutput":
				return new String[] { "error" };
			default:
				throw new IllegalArgumentException("Not known port: " + port);
		}
	}
	
	public void raiseEvent(String port, String event, Object[] parameters) {
		String portEvent = port + "." + event;
		switch (portEvent) {
			case "police.police":
				wrappedComponent.getPolice().raisePolice();
				break;
			default:
				throw new IllegalArgumentException("Not known port-in event combination: " + portEvent);
		}
	}
	
	public boolean isRaisedEvent(String port, String event, Object[] parameters) {
		String portEvent = port + "." + event;
		switch (portEvent) {
			case "priorityOutput.displayNone":
				if (wrappedComponent.getPriorityOutput().isRaisedDisplayNone()) {
					return true;
				}
				break;
			case "priorityOutput.displayYellow":
				if (wrappedComponent.getPriorityOutput().isRaisedDisplayYellow()) {
					return true;
				}
				break;
			case "priorityOutput.displayRed":
				if (wrappedComponent.getPriorityOutput().isRaisedDisplayRed()) {
					return true;
				}
				break;
			case "priorityOutput.displayGreen":
				if (wrappedComponent.getPriorityOutput().isRaisedDisplayGreen()) {
					return true;
				}
				break;
			case "secondaryOutput.displayNone":
				if (wrappedComponent.getSecondaryOutput().isRaisedDisplayNone()) {
					return true;
				}
				break;
			case "secondaryOutput.displayYellow":
				if (wrappedComponent.getSecondaryOutput().isRaisedDisplayYellow()) {
					return true;
				}
				break;
			case "secondaryOutput.displayRed":
				if (wrappedComponent.getSecondaryOutput().isRaisedDisplayRed()) {
					return true;
				}
				break;
			case "secondaryOutput.displayGreen":
				if (wrappedComponent.getSecondaryOutput().isRaisedDisplayGreen()) {
					return true;
				}
				break;
			case "monitorOutput.error":
				if (wrappedComponent.getMonitorOutput().isRaisedError()) {
					return true;
				}
				break;
			default:
				throw new IllegalArgumentException("Not known port-out event combination: " + portEvent);
		}
		return false;
	}
	
	public boolean isStateActive(String region, String state) {
		return false;
	}
	
	public String[] getRegions() {
		return new String[] {  };
	}
	
	public String[] getStates(String region) {
		switch (region) {
		}
		throw new IllegalArgumentException("Not known region: " + region);
	}
	
	public void schedule(String instance) {
		wrappedComponent.runCycle();
	}
	
	public String[] getVariables() {
		return new String[] {  };
	}
	
	public Object getValue(String variable) {
		switch (variable) {
		}
		throw new IllegalArgumentException("Not known variable: " + variable);
	}
	
	public String[] getComponents() {
		return new String[] { "crossroad", "monitor"};
	}
	
	public ReflectiveComponentInterface getComponent(String component) {
		switch (component) {
			case "crossroad":
				if (crossroad == null) {
					crossroad = new ReflectiveCrossroad(wrappedComponent.getCrossroad());
				}
				return crossroad;
			case "monitor":
				if (monitor == null) {
					monitor = new ReflectiveMonitor(wrappedComponent.getMonitor());
				}
				return monitor;
		}
		throw new IllegalArgumentException("Not known component: " + component);
	}
	
}

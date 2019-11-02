package hu.bme.mit.gamma.tutorial.finish.controller;

import hu.bme.mit.gamma.tutorial.finish.*;

public class ReflectiveControllerStatechart implements ReflectiveComponentInterface {
	
	private ControllerStatechart wrappedComponent;
	// Wrapped contained components
	
	public ReflectiveControllerStatechart(UnifiedTimerInterface timer) {
		this();
		wrappedComponent.setTimer(timer);
	}
	
	public ReflectiveControllerStatechart() {
		wrappedComponent = new ControllerStatechart();
	}
	
	public ReflectiveControllerStatechart(ControllerStatechart wrappedComponent) {
		this.wrappedComponent = wrappedComponent;
	}
	
	public void reset() {
		wrappedComponent.reset();
	}
	
	public ControllerStatechart getWrappedComponent() {
		return wrappedComponent;
	}
	
	public String[] getPorts() {
		return new String[] { "PoliceInterrupt", "PriorityPolice", "PriorityControl", "SecondaryControl", "SecondaryPolice" };
	}
	
	public String[] getEvents(String port) {
		switch (port) {
			case "PoliceInterrupt":
				return new String[] { "police" };
			case "PriorityPolice":
				return new String[] { "police" };
			case "PriorityControl":
				return new String[] { "toggle" };
			case "SecondaryControl":
				return new String[] { "toggle" };
			case "SecondaryPolice":
				return new String[] { "police" };
			default:
				throw new IllegalArgumentException("Not known port: " + port);
		}
	}
	
	public void raiseEvent(String port, String event, Object[] parameters) {
		String portEvent = port + "." + event;
		switch (portEvent) {
			case "PoliceInterrupt.police":
				wrappedComponent.getPoliceInterrupt().raisePolice();
				break;
			default:
				throw new IllegalArgumentException("Not known port-in event combination: " + portEvent);
		}
	}
	
	public boolean isRaisedEvent(String port, String event, Object[] parameters) {
		String portEvent = port + "." + event;
		switch (portEvent) {
			case "PriorityPolice.police":
				if (wrappedComponent.getPriorityPolice().isRaisedPolice()) {
					return true;
				}
				break;
			case "PriorityControl.toggle":
				if (wrappedComponent.getPriorityControl().isRaisedToggle()) {
					return true;
				}
				break;
			case "SecondaryControl.toggle":
				if (wrappedComponent.getSecondaryControl().isRaisedToggle()) {
					return true;
				}
				break;
			case "SecondaryPolice.police":
				if (wrappedComponent.getSecondaryPolice().isRaisedPolice()) {
					return true;
				}
				break;
			default:
				throw new IllegalArgumentException("Not known port-out event combination: " + portEvent);
		}
		return false;
	}
	
	public boolean isStateActive(String region, String state) {
		return wrappedComponent.isStateActive(region, state);
	}
	
	public String[] getRegions() {
		return new String[] { "operating", "main_region" };
	}
	
	public String[] getStates(String region) {
		switch (region) {
			case "operating":
				return new String[] { "Priority", "Secondary", "SecondaryPrepares", "PriorityPrepares", "Init" };
			case "main_region":
				return new String[] { "Operating", "Interrupted" };
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
		return new String[] { };
	}
	
	public ReflectiveComponentInterface getComponent(String component) {
		switch (component) {
		}
		throw new IllegalArgumentException("Not known component: " + component);
	}
	
}

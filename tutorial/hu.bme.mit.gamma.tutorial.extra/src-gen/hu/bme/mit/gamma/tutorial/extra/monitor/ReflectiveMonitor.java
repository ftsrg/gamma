package hu.bme.mit.gamma.tutorial.extra.monitor;

import hu.bme.mit.gamma.tutorial.extra.*;

public class ReflectiveMonitor implements ReflectiveComponentInterface {
	
	private Monitor wrappedComponent;
	// Wrapped contained components
	
	
	public ReflectiveMonitor() {
		wrappedComponent = new Monitor();
	}
	
	public ReflectiveMonitor(Monitor wrappedComponent) {
		this.wrappedComponent = wrappedComponent;
	}
	
	public void reset() {
		wrappedComponent.reset();
	}
	
	public Monitor getWrappedComponent() {
		return wrappedComponent;
	}
	
	public String[] getPorts() {
		return new String[] { "LightInputs", "Error" };
	}
	
	public String[] getEvents(String port) {
		switch (port) {
			case "LightInputs":
				return new String[] { "displayNone", "displayYellow", "displayRed", "displayGreen" };
			case "Error":
				return new String[] { "error" };
			default:
				throw new IllegalArgumentException("Not known port: " + port);
		}
	}
	
	public void raiseEvent(String port, String event, Object[] parameters) {
		String portEvent = port + "." + event;
		switch (portEvent) {
			case "LightInputs.displayNone":
				wrappedComponent.getLightInputs().raiseDisplayNone();
				break;
			case "LightInputs.displayYellow":
				wrappedComponent.getLightInputs().raiseDisplayYellow();
				break;
			case "LightInputs.displayRed":
				wrappedComponent.getLightInputs().raiseDisplayRed();
				break;
			case "LightInputs.displayGreen":
				wrappedComponent.getLightInputs().raiseDisplayGreen();
				break;
			default:
				throw new IllegalArgumentException("Not known port-in event combination: " + portEvent);
		}
	}
	
	public boolean isRaisedEvent(String port, String event, Object[] parameters) {
		String portEvent = port + "." + event;
		switch (portEvent) {
			case "Error.error":
				if (wrappedComponent.getError().isRaisedError()) {
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
		return new String[] { "main_region" };
	}
	
	public String[] getStates(String region) {
		switch (region) {
			case "main_region":
				return new String[] { "Green", "Error", "Other", "Red" };
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
			// If the class name is given, then it will return itself
			case "Monitor":
				return this;
		}
		throw new IllegalArgumentException("Not known component: " + component);
	}
	
}

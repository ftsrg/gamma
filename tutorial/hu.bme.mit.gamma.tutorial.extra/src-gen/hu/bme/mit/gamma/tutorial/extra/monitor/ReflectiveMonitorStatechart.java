package hu.bme.mit.gamma.tutorial.extra.monitor;

import hu.bme.mit.gamma.tutorial.extra.*;

public class ReflectiveMonitorStatechart implements ReflectiveComponentInterface {
	
	private MonitorStatechart wrappedComponent;
	// Wrapped contained components
	
	
	public ReflectiveMonitorStatechart() {
		wrappedComponent = new MonitorStatechart();
	}
	
	public ReflectiveMonitorStatechart(MonitorStatechart wrappedComponent) {
		this.wrappedComponent = wrappedComponent;
	}
	
	public void reset() {
		wrappedComponent.reset();
	}
	
	public MonitorStatechart getWrappedComponent() {
		return wrappedComponent;
	}
	
	public String[] getPorts() {
		return new String[] { "Monitor", "LightInputs" };
	}
	
	public String[] getEvents(String port) {
		switch (port) {
			case "Monitor":
				return new String[] { "error" };
			case "LightInputs":
				return new String[] { "displayNone", "displayYellow", "displayRed", "displayGreen" };
			default:
				throw new IllegalArgumentException("Not known port: " + port);
		}
	}
	
	public void raiseEvent(String port, String event, Object[] parameters) {
		String portEvent = port + "." + event;
		switch (portEvent) {
			case "LightInputs.displayRed":
				wrappedComponent.getLightInputs().raiseDisplayRed();
				break;
			case "LightInputs.displayYellow":
				wrappedComponent.getLightInputs().raiseDisplayYellow();
				break;
			case "LightInputs.displayGreen":
				wrappedComponent.getLightInputs().raiseDisplayGreen();
				break;
			case "LightInputs.displayNone":
				wrappedComponent.getLightInputs().raiseDisplayNone();
				break;
			default:
				throw new IllegalArgumentException("Not known port-in event combination: " + portEvent);
		}
	}
	
	public boolean isRaisedEvent(String port, String event, Object[] parameters) {
		String portEvent = port + "." + event;
		switch (portEvent) {
			case "Monitor.error":
				if (wrappedComponent.getMonitor().isRaisedError()) {
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
				return new String[] { "Red", "Error", "Green", "Other" };
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

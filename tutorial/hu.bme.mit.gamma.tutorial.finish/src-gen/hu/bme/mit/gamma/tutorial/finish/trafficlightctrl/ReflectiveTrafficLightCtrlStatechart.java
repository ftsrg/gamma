package hu.bme.mit.gamma.tutorial.finish.trafficlightctrl;

import hu.bme.mit.gamma.tutorial.finish.*;

public class ReflectiveTrafficLightCtrlStatechart implements ReflectiveComponentInterface {
	
	private TrafficLightCtrlStatechart wrappedComponent;
	// Wrapped contained components
	
	public ReflectiveTrafficLightCtrlStatechart(UnifiedTimerInterface timer) {
		this();
		wrappedComponent.setTimer(timer);
	}
	
	public ReflectiveTrafficLightCtrlStatechart() {
		wrappedComponent = new TrafficLightCtrlStatechart();
	}
	
	public ReflectiveTrafficLightCtrlStatechart(TrafficLightCtrlStatechart wrappedComponent) {
		this.wrappedComponent = wrappedComponent;
	}
	
	public void reset() {
		wrappedComponent.reset();
	}
	
	public TrafficLightCtrlStatechart getWrappedComponent() {
		return wrappedComponent;
	}
	
	public String[] getPorts() {
		return new String[] { "Control", "PoliceInterrupt", "LightCommands" };
	}
	
	public String[] getEvents(String port) {
		switch (port) {
			case "Control":
				return new String[] { "toggle" };
			case "PoliceInterrupt":
				return new String[] { "police" };
			case "LightCommands":
				return new String[] { "displayRed", "displayYellow", "displayGreen", "displayNone" };
			default:
				throw new IllegalArgumentException("Not known port: " + port);
		}
	}
	
	public void raiseEvent(String port, String event, Object[] parameters) {
		String portEvent = port + "." + event;
		switch (portEvent) {
			case "Control.toggle":
				wrappedComponent.getControl().raiseToggle();
				break;
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
			case "LightCommands.displayNone":
				if (wrappedComponent.getLightCommands().isRaisedDisplayNone()) {
					return true;
				}
				break;
			case "LightCommands.displayYellow":
				if (wrappedComponent.getLightCommands().isRaisedDisplayYellow()) {
					return true;
				}
				break;
			case "LightCommands.displayGreen":
				if (wrappedComponent.getLightCommands().isRaisedDisplayGreen()) {
					return true;
				}
				break;
			case "LightCommands.displayRed":
				if (wrappedComponent.getLightCommands().isRaisedDisplayRed()) {
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
		return new String[] { "normal", "main_region", "interrupted" };
	}
	
	public String[] getStates(String region) {
		switch (region) {
			case "normal":
				return new String[] { "Green", "Red", "Yellow" };
			case "main_region":
				return new String[] { "Normal", "Interrupted" };
			case "interrupted":
				return new String[] { "BlinkingYellow", "Black" };
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

package hu.bme.mit.gamma.tutorial.extra.controller;

import hu.bme.mit.gamma.tutorial.extra.*;

public class ReflectiveController implements ReflectiveComponentInterface {
	
	private Controller wrappedComponent;
	// Wrapped contained components
	
	public ReflectiveController(UnifiedTimerInterface timer) {
		this();
		wrappedComponent.setTimer(timer);
	}
	
	public ReflectiveController() {
		wrappedComponent = new Controller();
	}
	
	public ReflectiveController(Controller wrappedComponent) {
		this.wrappedComponent = wrappedComponent;
	}
	
	public void reset() {
		wrappedComponent.reset();
	}
	
	public Controller getWrappedComponent() {
		return wrappedComponent;
	}
	
	public String[] getPorts() {
		return new String[] { "SecondaryControl", "PriorityControl", "PoliceInterrupt", "SecondaryPolice", "PriorityPolice" };
	}
	
	public String[] getEvents(String port) {
		switch (port) {
			case "SecondaryControl":
				return new String[] { "toggle" };
			case "PriorityControl":
				return new String[] { "toggle" };
			case "PoliceInterrupt":
				return new String[] { "police" };
			case "SecondaryPolice":
				return new String[] { "police" };
			case "PriorityPolice":
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
			case "SecondaryControl.toggle":
				if (wrappedComponent.getSecondaryControl().isRaisedToggle()) {
					return true;
				}
				break;
			case "PriorityControl.toggle":
				if (wrappedComponent.getPriorityControl().isRaisedToggle()) {
					return true;
				}
				break;
			case "SecondaryPolice.police":
				if (wrappedComponent.getSecondaryPolice().isRaisedPolice()) {
					return true;
				}
				break;
			case "PriorityPolice.police":
				if (wrappedComponent.getPriorityPolice().isRaisedPolice()) {
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
		return new String[] { "main_region", "operating" };
	}
	
	public String[] getStates(String region) {
		switch (region) {
			case "main_region":
				return new String[] { "Operating", "Interrupted" };
			case "operating":
				return new String[] { "SecondaryPrepares", "Priority", "Secondary", "Init", "PriorityPrepares" };
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
			case "Controller":
				return this;
		}
		throw new IllegalArgumentException("Not known component: " + component);
	}
	
}

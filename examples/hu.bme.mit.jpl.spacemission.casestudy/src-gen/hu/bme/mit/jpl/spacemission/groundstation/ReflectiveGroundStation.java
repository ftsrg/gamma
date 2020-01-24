package hu.bme.mit.jpl.spacemission.groundstation;

import hu.bme.mit.jpl.spacemission.*;

public class ReflectiveGroundStation implements ReflectiveComponentInterface {
	
	private GroundStation wrappedComponent;
	// Wrapped contained components
	
	public ReflectiveGroundStation(UnifiedTimerInterface timer) {
		this();
		wrappedComponent.setTimer(timer);
	}
	
	public ReflectiveGroundStation() {
		wrappedComponent = new GroundStation();
	}
	
	public ReflectiveGroundStation(GroundStation wrappedComponent) {
		this.wrappedComponent = wrappedComponent;
	}
	
	public void reset() {
		wrappedComponent.reset();
	}
	
	public GroundStation getWrappedComponent() {
		return wrappedComponent;
	}
	
	public String[] getPorts() {
		return new String[] { "connection", "control" };
	}
	
	public String[] getEvents(String port) {
		switch (port) {
			case "connection":
				return new String[] { "data", "ping" };
			case "control":
				return new String[] { "start", "shutdown" };
			default:
				throw new IllegalArgumentException("Not known port: " + port);
		}
	}
	
	public void raiseEvent(String port, String event, Object[] parameters) {
		String portEvent = port + "." + event;
		switch (portEvent) {
			case "connection.data":
				wrappedComponent.getConnection().raiseData();
				break;
			case "control.start":
				wrappedComponent.getControl().raiseStart();
				break;
			case "control.shutdown":
				wrappedComponent.getControl().raiseShutdown();
				break;
			default:
				throw new IllegalArgumentException("Not known port-in event combination: " + portEvent);
		}
	}
	
	public boolean isRaisedEvent(String port, String event, Object[] parameters) {
		String portEvent = port + "." + event;
		switch (portEvent) {
			case "connection.ping":
				if (wrappedComponent.getConnection().isRaisedPing()) {
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
		return new String[] { "ReceiveData", "Main" };
	}
	
	public String[] getStates(String region) {
		switch (region) {
			case "ReceiveData":
				return new String[] { "Waiting" };
			case "Main":
				return new String[] { "Idle", "Operation" };
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

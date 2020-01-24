package hu.bme.mit.jpl.spacemission.spacecraft;

import hu.bme.mit.jpl.spacemission.*;

public class ReflectiveSpacecraft implements ReflectiveComponentInterface {
	
	private Spacecraft wrappedComponent;
	// Wrapped contained components
	
	public ReflectiveSpacecraft(UnifiedTimerInterface timer) {
		this();
		wrappedComponent.setTimer(timer);
	}
	
	public ReflectiveSpacecraft() {
		wrappedComponent = new Spacecraft();
	}
	
	public ReflectiveSpacecraft(Spacecraft wrappedComponent) {
		this.wrappedComponent = wrappedComponent;
	}
	
	public void reset() {
		wrappedComponent.reset();
	}
	
	public Spacecraft getWrappedComponent() {
		return wrappedComponent;
	}
	
	public String[] getPorts() {
		return new String[] { "connection" };
	}
	
	public String[] getEvents(String port) {
		switch (port) {
			case "connection":
				return new String[] { "data", "ping" };
			default:
				throw new IllegalArgumentException("Not known port: " + port);
		}
	}
	
	public void raiseEvent(String port, String event, Object[] parameters) {
		String portEvent = port + "." + event;
		switch (portEvent) {
			case "connection.ping":
				wrappedComponent.getConnection().raisePing();
				break;
			default:
				throw new IllegalArgumentException("Not known port-in event combination: " + portEvent);
		}
	}
	
	public boolean isRaisedEvent(String port, String event, Object[] parameters) {
		String portEvent = port + "." + event;
		switch (portEvent) {
			case "connection.data":
				if (wrappedComponent.getConnection().isRaisedData()) {
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
		return new String[] { "ConsumePower", "Communication", "Battery", "SendData" };
	}
	
	public String[] getStates(String region) {
		switch (region) {
			case "ConsumePower":
				return new String[] { "Consuming" };
			case "Communication":
				return new String[] { "Transmitting", "WaitingPing" };
			case "Battery":
				return new String[] { "NotRecharging", "Recharging" };
			case "SendData":
				return new String[] { "Sending" };
		}
		throw new IllegalArgumentException("Not known region: " + region);
	}
	
	public void schedule(String instance) {
		wrappedComponent.runCycle();
	}
	
	public String[] getVariables() {
		return new String[] { "batteryVariable", "recharging", "data" };
	}
	
	public Object getValue(String variable) {
		switch (variable) {
			case "batteryVariable":
				return wrappedComponent.getBatteryVariable();
			case "recharging":
				return wrappedComponent.getRecharging();
			case "data":
				return wrappedComponent.getData();
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

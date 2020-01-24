package hu.bme.mit.jpl.spacemission.mission;

import hu.bme.mit.jpl.spacemission.*;
import hu.bme.mit.jpl.spacemission.groundstation.*;
import hu.bme.mit.jpl.spacemission.spacecraft.*;

public class ReflectiveMission implements ReflectiveComponentInterface {
	
	private Mission wrappedComponent;
	// Wrapped contained components
	private ReflectiveComponentInterface station = null;
	private ReflectiveComponentInterface satellite = null;
	
	public ReflectiveMission(UnifiedTimerInterface timer) {
		this();
		wrappedComponent.setTimer(timer);
	}
	
	public ReflectiveMission() {
		wrappedComponent = new Mission();
	}
	
	public ReflectiveMission(Mission wrappedComponent) {
		this.wrappedComponent = wrappedComponent;
	}
	
	public void reset() {
		wrappedComponent.reset();
	}
	
	public Mission getWrappedComponent() {
		return wrappedComponent;
	}
	
	public String[] getPorts() {
		return new String[] { "control" };
	}
	
	public String[] getEvents(String port) {
		switch (port) {
			case "control":
				return new String[] { "start", "shutdown" };
			default:
				throw new IllegalArgumentException("Not known port: " + port);
		}
	}
	
	public void raiseEvent(String port, String event, Object[] parameters) {
		String portEvent = port + "." + event;
		switch (portEvent) {
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
			default:
				throw new IllegalArgumentException("Not known port-out event combination: " + portEvent);
		}
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
		return new String[] { "station", "satellite"};
	}
	
	public ReflectiveComponentInterface getComponent(String component) {
		switch (component) {
			case "station":
				if (station == null) {
					station = new ReflectiveGroundStation(wrappedComponent.getStation());
				}
				return station;
			case "satellite":
				if (satellite == null) {
					satellite = new ReflectiveSpacecraft(wrappedComponent.getSatellite());
				}
				return satellite;
		}
		throw new IllegalArgumentException("Not known component: " + component);
	}
	
}

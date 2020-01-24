package hu.bme.mit.jpl.spacemission.mission;

import hu.bme.mit.jpl.spacemission.*;

import static org.junit.Assert.assertTrue;

import org.junit.Before;
import org.junit.After;
import org.junit.Test;

public class ExecutionTraceSimulation5 {
	
	private static ReflectiveComponentInterface reflectiveMission;
	private static VirtualTimerService timer;
	
	@Before
	public void init() {
		timer = new VirtualTimerService();
		reflectiveMission = new ReflectiveMission(timer);  // Virtual timer is automatically set
		reflectiveMission.reset();
	}
	
	@After
	public void tearDown() {
		stop();
	}
	
	// Only for override by potential subclasses
	protected void stop() {
		timer = null;
		reflectiveMission = null;				
	}
	
	public void step0() {
		// Act
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 100));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 100));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "WaitingPing"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Idle"));
	}
	
	@Test
	public void step1() {
		step0();
		// Act
		timer.elapse(30000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 100));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 100));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "WaitingPing"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Operation"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("ReceiveData", "Waiting"));
	}
	
}

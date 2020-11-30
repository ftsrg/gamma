package hu.bme.mit.gamma.tutorial.extra.monitoredcrossroad;

import hu.bme.mit.gamma.tutorial.extra.*;

import static org.junit.Assert.assertTrue;

import org.junit.Before;
import org.junit.After;
import org.junit.Test;

public class ExecutionTraceSimulation1 {
	
	private static ReflectiveMonitoredCrossroad reflectiveMonitoredCrossroad;
	private static VirtualTimerService timer;
	
	@Before
	public void init() {
		timer = new VirtualTimerService();
		reflectiveMonitoredCrossroad = new ReflectiveMonitoredCrossroad(timer);  // Virtual timer is automatically set
	}
	
	@After
	public void tearDown() {
		stop();
	}
	
	// Only for override by potential subclasses
	protected void stop() {
		timer = null;
		reflectiveMonitoredCrossroad = null;				
	}
	
	@Test
	public void test() {
		finalStep0();
		return;
	}
	public void step0() {
		// Act
		timer.reset(); // Timer before the system
		reflectiveMonitoredCrossroad.reset();
		// Checking out events
		assertTrue(reflectiveMonitoredCrossroad.isRaisedEvent("secondaryOutput", "displayRed", new Object[] {}));
		assertTrue(reflectiveMonitoredCrossroad.isRaisedEvent("priorityOutput", "displayRed", new Object[] {}));
		// Checking variables
		// Checking of states
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("controller").isStateActive("operating", "Init"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("controller").isStateActive("main_region", "Operating"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("prior").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("prior").isStateActive("normal", "Red"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("secondary").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("secondary").isStateActive("normal", "Red"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("monitor").isStateActive("main_region", "Other"));
	}
	
	public void step1() {
		step0();
		// Act
		timer.elapse(2000);
		reflectiveMonitoredCrossroad.schedule(null);
		// Checking out events
		assertTrue(reflectiveMonitoredCrossroad.isRaisedEvent("priorityOutput", "displayGreen", new Object[] {}));
		// Checking variables
		// Checking of states
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("controller").isStateActive("main_region", "Operating"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("controller").isStateActive("operating", "PriorityPrepares"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("prior").isStateActive("normal", "Green"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("prior").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("secondary").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("secondary").isStateActive("normal", "Red"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("monitor").isStateActive("main_region", "Red"));
	}
	
	public void step2() {
		step1();
		// Act
		timer.elapse(1000);
		reflectiveMonitoredCrossroad.schedule(null);
		// Checking out events
		assertTrue(reflectiveMonitoredCrossroad.isRaisedEvent("priorityOutput", "displayYellow", new Object[] {}));
		// Checking variables
		// Checking of states
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("controller").isStateActive("main_region", "Operating"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("controller").isStateActive("operating", "Secondary"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("prior").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("prior").isStateActive("normal", "Yellow"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("secondary").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("secondary").isStateActive("normal", "Red"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("monitor").isStateActive("main_region", "Green"));
	}
	
	public void finalStep0() {
		step2();
		// Act
		timer.elapse(2000);
		reflectiveMonitoredCrossroad.schedule(null);
		// Checking out events
		assertTrue(reflectiveMonitoredCrossroad.isRaisedEvent("secondaryOutput", "displayGreen", new Object[] {}));
		assertTrue(reflectiveMonitoredCrossroad.isRaisedEvent("priorityOutput", "displayRed", new Object[] {}));
		// Checking variables
		// Checking of states
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("controller").isStateActive("main_region", "Operating"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("controller").isStateActive("operating", "SecondaryPrepares"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("prior").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("prior").isStateActive("normal", "Red"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("secondary").isStateActive("normal", "Green"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("crossroad").getComponent("secondary").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveMonitoredCrossroad.getComponent("monitor").isStateActive("main_region", "Other"));
	}
	
}

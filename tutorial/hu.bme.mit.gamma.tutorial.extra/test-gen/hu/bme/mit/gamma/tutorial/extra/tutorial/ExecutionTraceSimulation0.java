package hu.bme.mit.gamma.tutorial.extra.tutorial;

import hu.bme.mit.gamma.tutorial.extra.VirtualTimerService;

import static org.junit.Assert.assertTrue;
import static org.junit.Assert.assertEquals;

import org.junit.Before;
import org.junit.After;
import org.junit.Test;

public class ExecutionTraceSimulation0 {
	
	private static ReflectiveCrossroad reflectiveCrossroad;
	private static VirtualTimerService timer;
	
	@Before
	public void init() {
		timer = new VirtualTimerService();
		reflectiveCrossroad = new ReflectiveCrossroad(timer);  // Virtual timer is automatically set
		reflectiveCrossroad.reset();
	}
	
	@After
	public void tearDown() {
		// Only for override by potential subclasses
		timer = null;
		reflectiveCrossroad = null;
	}
	
	@Test
	public void step0() {
		// Act
		// Checking out events
		assertTrue(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayRed", new Object[] {}));
		assertTrue(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayRed", new Object[] {}));
		// Checking variables
		// Checking of states
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("operating", "Init"));
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("main_region", "Operating"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("normal", "Red"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("normal", "Red"));
	}
	
	@Test
	public void step1() {
		step0();
		// Act
		reflectiveCrossroad.raiseEvent("police", "police", new Object[] {});
		reflectiveCrossroad.schedule(null);
		// Checking out events
		assertTrue(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayGreen", new Object[] {}));
		// Checking variables
		// Checking of states
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("operating", "Init"));
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("main_region", "Operating"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("normal", "Green"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("normal", "Red"));
	}
	
	@Test
	public void step2() {
		step1();
		// Act
		timer.elapse(2000);
		reflectiveCrossroad.schedule(null);
		// Checking out events
		assertTrue(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayYellow", new Object[] {}));
		assertTrue(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayYellow", new Object[] {}));
		// Checking variables
		// Checking of states
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("main_region", "Operating"));
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("operating", "PriorityPrepares"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("interrupted", "BlinkingYellow"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("main_region", "Interrupted"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("interrupted", "BlinkingYellow"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("main_region", "Interrupted"));
	}
	
	@Test
	public void step3() {
		step2();
		// Act
		timer.elapse(1000);
		reflectiveCrossroad.schedule(null);
		// Checking out events
		assertTrue(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayNone", new Object[] {}));
		assertTrue(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayNone", new Object[] {}));
		// Checking variables
		// Checking of states
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("main_region", "Operating"));
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("operating", "Secondary"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("interrupted", "Black"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("main_region", "Interrupted"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("interrupted", "Black"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("main_region", "Interrupted"));
	}
	
	@Test
	public void step4() {
		step3();
		// Act
		reflectiveCrossroad.raiseEvent("police", "police", new Object[] {});
		reflectiveCrossroad.schedule(null);
		// Checking out events
		// Checking variables
		// Checking of states
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("main_region", "Operating"));
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("operating", "Secondary"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("interrupted", "Black"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("main_region", "Interrupted"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("interrupted", "Black"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("main_region", "Interrupted"));
	}
	
	@Test
	public void step5() {
		step4();
		// Act
		timer.elapse(2000);
		reflectiveCrossroad.schedule(null);
		// Checking out events
		assertTrue(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayRed", new Object[] {}));
		assertTrue(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayGreen", new Object[] {}));
		// Checking variables
		// Checking of states
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("main_region", "Operating"));
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("operating", "SecondaryPrepares"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("normal", "Green"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("normal", "Red"));
	}
	
	@Test
	public void step6() {
		step5();
		// Act
		reflectiveCrossroad.schedule(null);
		// Checking out events
		assertTrue(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayGreen", new Object[] {}));
		// Checking variables
		// Checking of states
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("main_region", "Operating"));
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("operating", "SecondaryPrepares"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("normal", "Green"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("normal", "Green"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("main_region", "Normal"));
	}
	
}

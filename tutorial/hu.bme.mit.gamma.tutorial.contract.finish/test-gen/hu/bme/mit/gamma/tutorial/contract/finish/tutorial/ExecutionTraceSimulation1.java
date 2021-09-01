package hu.bme.mit.gamma.tutorial.contract.finish.tutorial;

import hu.bme.mit.gamma.tutorial.contract.finish.*;

import static org.junit.Assert.assertTrue;

import org.junit.Before;
import org.junit.After;
import org.junit.Test;

public class ExecutionTraceSimulation1 {
	
	private static ReflectiveCrossroad reflectiveCrossroad;
	private static VirtualTimerService timer;
	
	@Before
	public void init() {
		timer = new VirtualTimerService();
		reflectiveCrossroad = new ReflectiveCrossroad(timer);  // Virtual timer is automatically set
	}
	
	@After
	public void tearDown() {
		stop();
	}
	
	// Only for override by potential subclasses
	protected void stop() {
		timer = null;
		reflectiveCrossroad = null;				
	}
	
	@Test
	public void test() {
		finalStep0();
		return;
	}
	public void step0() {
		// Act
		timer.reset(); // Timer before the system
		reflectiveCrossroad.reset();
		// Assert
	}
	
	public void step1() {
		step0();
		// Act
		timer.elapse(2000);
		reflectiveCrossroad.schedule();
		// Assert
	}
	
	public void step2() {
		step1();
		// Act
		timer.elapse(2000);
		reflectiveCrossroad.schedule();
		// Assert
		assertTrue(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayRed", new Object[] {}));
		assertTrue(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayGreen", new Object[] {}));
		assertTrue(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayYellow", new Object[] {}));
	}
	
	public void finalStep0() {
		step2();
		// Act
		timer.elapse(2000);
		reflectiveCrossroad.schedule();
		// Assert
		assertTrue(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayYellow", new Object[] {}));
		assertTrue(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayRed", new Object[] {}));
		assertTrue(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayGreen", new Object[] {}));
	}
	
}

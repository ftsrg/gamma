package hu.bme.mit.gamma.tutorial.finish.tutorial;

import hu.bme.mit.gamma.tutorial.finish.*;

import java.util.Objects;

import static org.junit.Assert.assertTrue;

import org.junit.Before;
import org.junit.After;
import org.junit.Test;

public class ExecutionTrace0 {
	
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
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayNone", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayGreen", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayYellow", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayNone", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayGreen", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayYellow", null)));
		assertTrue(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayRed", null));
		assertTrue(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayRed", null));
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("main_region", "Operating"));
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("operating", "Init"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("normal", "Red"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("normal", "Red"));
		assertTrue(Objects.deepEquals(reflectiveCrossroad.getComponent("prior").getValue("brightness"), new int[][] { new int[] { 2, 3 }, new int[] { 3, 4 } }));
		assertTrue(Objects.deepEquals(reflectiveCrossroad.getComponent("secondary").getValue("brightness"), new int[][] { new int[] { 2, 3 }, new int[] { 3, 4 } }));
	}
	
	public void step1() {
		step0();
		// Act
		timer.elapse(2000);
		reflectiveCrossroad.schedule();
		// Assert
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayNone", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayGreen", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayYellow", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayRed", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayNone", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayYellow", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayRed", null)));
		assertTrue(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayGreen", null));
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("main_region", "Operating"));
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("operating", "PriorityPrepares"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("normal", "Green"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("normal", "Red"));
		assertTrue(Objects.deepEquals(reflectiveCrossroad.getComponent("prior").getValue("brightness"), new int[][] { new int[] { 2, 3 }, new int[] { 3, 4 } }));
		assertTrue(Objects.deepEquals(reflectiveCrossroad.getComponent("secondary").getValue("brightness"), new int[][] { new int[] { 2, 3 }, new int[] { 3, 4 } }));
	}
	
	public void step2() {
		step1();
		// Act
		timer.elapse(1000);
		reflectiveCrossroad.schedule();
		// Assert
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayNone", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayGreen", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayYellow", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayRed", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayNone", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayGreen", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayRed", null)));
		assertTrue(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayYellow", null));
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("main_region", "Operating"));
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("operating", "Secondary"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("normal", "Yellow"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("normal", "Red"));
		assertTrue(Objects.deepEquals(reflectiveCrossroad.getComponent("prior").getValue("brightness"), new int[][] { new int[] { 2, 3 }, new int[] { 1, 3 } }));
		assertTrue(Objects.deepEquals(reflectiveCrossroad.getComponent("secondary").getValue("brightness"), new int[][] { new int[] { 2, 3 }, new int[] { 3, 4 } }));
	}
	
	public void step3() {
		step2();
		// Act
		timer.elapse(2000);
		reflectiveCrossroad.schedule();
		// Assert
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayNone", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayYellow", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayRed", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayNone", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayGreen", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayYellow", null)));
		assertTrue(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayRed", null));
		assertTrue(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayGreen", null));
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("main_region", "Operating"));
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("operating", "SecondaryPrepares"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("normal", "Red"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("normal", "Green"));
		assertTrue(Objects.deepEquals(reflectiveCrossroad.getComponent("prior").getValue("brightness"), new int[][] { new int[] { 2, 3 }, new int[] { 3, 4 } }));
		assertTrue(Objects.deepEquals(reflectiveCrossroad.getComponent("secondary").getValue("brightness"), new int[][] { new int[] { 2, 3 }, new int[] { 3, 4 } }));
	}
	
	public void finalStep0() {
		step3();
		// Act
		timer.elapse(1000);
		reflectiveCrossroad.schedule();
		// Assert
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayNone", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayGreen", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayRed", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayNone", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayGreen", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayYellow", null)));
		assertTrue(!(reflectiveCrossroad.isRaisedEvent("priorityOutput", "displayRed", null)));
		assertTrue(reflectiveCrossroad.isRaisedEvent("secondaryOutput", "displayYellow", null));
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("main_region", "Operating"));
		assertTrue(reflectiveCrossroad.getComponent("controller").isStateActive("operating", "Priority"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveCrossroad.getComponent("prior").isStateActive("normal", "Red"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("main_region", "Normal"));
		assertTrue(reflectiveCrossroad.getComponent("secondary").isStateActive("normal", "Yellow"));
		assertTrue(Objects.deepEquals(reflectiveCrossroad.getComponent("prior").getValue("brightness"), new int[][] { new int[] { 2, 3 }, new int[] { 3, 4 } }));
		assertTrue(Objects.deepEquals(reflectiveCrossroad.getComponent("secondary").getValue("brightness"), new int[][] { new int[] { 2, 3 }, new int[] { 1, 3 } }));
	}
	
	
}

package hu.bme.mit.gamma.tutorial.extra.tutorial;

import static org.junit.Assert.assertTrue;
import static org.junit.Assert.assertEquals;

import org.junit.Before;
import org.junit.Test;

import hu.bme.mit.gamma.tutorial.extra.VirtualTimerService;

/**
 * Note, that this is no longer a valid trace due to the fix in Controller.sct.
*/
public class ExecutionTraceSimulation0 {
	
	private static Crossroad crossroad;
	private static VirtualTimerService timer;
	
	@Before
	public void init() {
		timer = new VirtualTimerService();
		crossroad = new Crossroad(timer);  // Virtual timer is automatically set
		crossroad.reset();
	}
	
	@Test
	public void step0() {
		// Act
		// Checking out events
		assertTrue(crossroad.getPriorityOutput().isRaisedDisplayRed());
		assertTrue(crossroad.getSecondaryOutput().isRaisedDisplayRed());
		// Checking variables
		// Checking of states
		assertTrue(crossroad.getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating_operating_Init));
		assertTrue(crossroad.getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating));
		assertTrue(crossroad.getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal));
		assertTrue(crossroad.getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal_normal_Red));
		assertTrue(crossroad.getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal));
		assertTrue(crossroad.getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal_normal_Red));
	}
	@Test
	public void step1() {
		step0();
		// Act
		crossroad.getPolice().raisePolice();
		crossroad.runCycle();
		// Checking out events
		assertTrue(crossroad.getPriorityOutput().isRaisedDisplayGreen());
		// Checking variables
		// Checking of states
		assertTrue(crossroad.getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating_operating_Init));
		assertTrue(crossroad.getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating));
		assertTrue(crossroad.getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal_normal_Green));
		assertTrue(crossroad.getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal));
		assertTrue(crossroad.getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal));
		assertTrue(crossroad.getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal_normal_Red));
	}
	@Test
	public void step2() {
		step1();
		// Act
		timer.elapse(2000);
		crossroad.runCycle();
		// Checking out events
		assertTrue(crossroad.getPriorityOutput().isRaisedDisplayYellow());
		assertTrue(crossroad.getSecondaryOutput().isRaisedDisplayYellow());
		// Checking variables
		// Checking of states
		assertTrue(crossroad.getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating));
		assertTrue(crossroad.getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating_operating_PriorityPrepares));
		assertTrue(crossroad.getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Interrupted_interrupted_BlinkingYellow));
		assertTrue(crossroad.getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Interrupted));
		assertTrue(crossroad.getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Interrupted_interrupted_BlinkingYellow));
		assertTrue(crossroad.getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Interrupted));
	}
	@Test
	public void step3() {
		step2();
		// Act
		timer.elapse(1000);
		crossroad.runCycle();
		// Checking out events
		assertTrue(crossroad.getPriorityOutput().isRaisedDisplayNone());
		assertTrue(crossroad.getSecondaryOutput().isRaisedDisplayNone());
		// Checking variables
		// Checking of states
		assertTrue(crossroad.getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating));
		assertTrue(crossroad.getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating_operating_Secondary));
		assertTrue(crossroad.getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Interrupted_interrupted_Black));
		assertTrue(crossroad.getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Interrupted));
		assertTrue(crossroad.getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Interrupted_interrupted_Black));
		assertTrue(crossroad.getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Interrupted));
	}
	@Test
	public void step4() {
		step3();
		// Act
		crossroad.getPolice().raisePolice();
		crossroad.runCycle();
		// Checking out events
		// Checking variables
		// Checking of states
		assertTrue(crossroad.getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating));
		assertTrue(crossroad.getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating_operating_Secondary));
		assertTrue(crossroad.getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Interrupted_interrupted_Black));
		assertTrue(crossroad.getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Interrupted));
		assertTrue(crossroad.getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Interrupted_interrupted_Black));
		assertTrue(crossroad.getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Interrupted));
	}
	@Test
	public void step5() {
		step4();
		// Act
		timer.elapse(2000);
		crossroad.runCycle();
		// Checking out events
		assertTrue(crossroad.getPriorityOutput().isRaisedDisplayGreen());
		assertTrue(crossroad.getSecondaryOutput().isRaisedDisplayRed());
		// Checking variables
		// Checking of states
		assertTrue(crossroad.getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating));
		assertTrue(crossroad.getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating_operating_SecondaryPrepares));
		assertTrue(crossroad.getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal_normal_Green));
		assertTrue(crossroad.getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal));
		assertTrue(crossroad.getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal));
		assertTrue(crossroad.getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal_normal_Red));
	}
	@Test
	public void step6() {
		step5();
		// Act
		crossroad.runCycle();
		// Checking out events
		assertTrue(crossroad.getSecondaryOutput().isRaisedDisplayGreen());
		// Checking variables
		// Checking of states
		assertTrue(crossroad.getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating));
		assertTrue(crossroad.getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating_operating_SecondaryPrepares));
		assertTrue(crossroad.getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal_normal_Green));
		assertTrue(crossroad.getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal));
		assertTrue(crossroad.getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal_normal_Green));
		assertTrue(crossroad.getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal));
	}
}

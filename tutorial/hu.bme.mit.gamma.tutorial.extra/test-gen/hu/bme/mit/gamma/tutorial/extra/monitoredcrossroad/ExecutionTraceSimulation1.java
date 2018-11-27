package hu.bme.mit.gamma.tutorial.extra.monitoredcrossroad;

import hu.bme.mit.gamma.tutorial.extra.VirtualTimerService;

import static org.junit.Assert.assertTrue;
import static org.junit.Assert.assertEquals;

import org.junit.Before;
import org.junit.Test;

public class ExecutionTraceSimulation1 {
	
	private static MonitoredCrossroad monitoredCrossroad;
	private static VirtualTimerService timer;
	
	@Before
	public void init() {
		timer = new VirtualTimerService();
		monitoredCrossroad = new MonitoredCrossroad(timer);  // Virtual timer is automatically set
		monitoredCrossroad.reset();
	}
	
	@Test
	public void step0() {
		// Act
		// Checking out events
		assertTrue(monitoredCrossroad.getPriorityOutput().isRaisedDisplayRed());
		assertTrue(monitoredCrossroad.getSecondaryOutput().isRaisedDisplayRed());
		// Checking variables
		// Checking of states
		assertTrue(monitoredCrossroad.getCrossroad().getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating_operating_Init));
		assertTrue(monitoredCrossroad.getCrossroad().getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating));
		assertTrue(monitoredCrossroad.getCrossroad().getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal));
		assertTrue(monitoredCrossroad.getCrossroad().getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal_normal_Red));
		assertTrue(monitoredCrossroad.getCrossroad().getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal));
		assertTrue(monitoredCrossroad.getCrossroad().getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal_normal_Red));
		assertTrue(monitoredCrossroad.getMonitor().isStateActive(hu.bme.mit.gamma.tutorial.extra.monitor.MonitorStatemachine.State.main_region_Other));
	}
	@Test
	public void step1() {
		step0();
		// Act
		timer.elapse(2000);
		monitoredCrossroad.runCycle();
		// Checking out events
		assertTrue(monitoredCrossroad.getPriorityOutput().isRaisedDisplayGreen());
		// Checking variables
		// Checking of states
		assertTrue(monitoredCrossroad.getCrossroad().getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating));
		assertTrue(monitoredCrossroad.getCrossroad().getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating_operating_PriorityPrepares));
		assertTrue(monitoredCrossroad.getCrossroad().getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal_normal_Green));
		assertTrue(monitoredCrossroad.getCrossroad().getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal));
		assertTrue(monitoredCrossroad.getCrossroad().getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal));
		assertTrue(monitoredCrossroad.getCrossroad().getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal_normal_Red));
		assertTrue(monitoredCrossroad.getMonitor().isStateActive(hu.bme.mit.gamma.tutorial.extra.monitor.MonitorStatemachine.State.main_region_Red));
	}
	@Test
	public void step2() {
		step1();
		// Act
		timer.elapse(1000);
		monitoredCrossroad.runCycle();
		// Checking out events
		assertTrue(monitoredCrossroad.getPriorityOutput().isRaisedDisplayYellow());
		// Checking variables
		// Checking of states
		assertTrue(monitoredCrossroad.getCrossroad().getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating));
		assertTrue(monitoredCrossroad.getCrossroad().getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating_operating_Secondary));
		assertTrue(monitoredCrossroad.getCrossroad().getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal));
		assertTrue(monitoredCrossroad.getCrossroad().getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal_normal_Yellow));
		assertTrue(monitoredCrossroad.getCrossroad().getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal));
		assertTrue(monitoredCrossroad.getCrossroad().getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal_normal_Red));
		assertTrue(monitoredCrossroad.getMonitor().isStateActive(hu.bme.mit.gamma.tutorial.extra.monitor.MonitorStatemachine.State.main_region_Green));
	}
	@Test
	public void step3() {
		step2();
		// Act
		timer.elapse(2000);
		monitoredCrossroad.runCycle();
		// Checking out events
		assertTrue(monitoredCrossroad.getSecondaryOutput().isRaisedDisplayGreen());
		assertTrue(monitoredCrossroad.getPriorityOutput().isRaisedDisplayRed());
		// Checking variables
		// Checking of states
		assertTrue(monitoredCrossroad.getCrossroad().getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating));
		assertTrue(monitoredCrossroad.getCrossroad().getController().isStateActive(hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State.main_region_Operating_operating_SecondaryPrepares));
		assertTrue(monitoredCrossroad.getCrossroad().getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal));
		assertTrue(monitoredCrossroad.getCrossroad().getPrior().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal_normal_Red));
		assertTrue(monitoredCrossroad.getCrossroad().getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal_normal_Green));
		assertTrue(monitoredCrossroad.getCrossroad().getSecondary().isStateActive(hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State.main_region_Normal));
		assertTrue(monitoredCrossroad.getMonitor().isStateActive(hu.bme.mit.gamma.tutorial.extra.monitor.MonitorStatemachine.State.main_region_Other));
	}
}

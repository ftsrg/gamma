package hu.bme.mit.jpl.spacemission.mission;

import hu.bme.mit.jpl.spacemission.*;

import static org.junit.Assert.assertTrue;

import org.junit.Before;
import org.junit.After;
import org.junit.Test;

public class ExecutionTraceSimulation8 {
	
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
	
	public void step2() {
		step1();
		// Act
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 100));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 100));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Operation"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("ReceiveData", "Waiting"));
	}
	
	public void step3() {
		step2();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 99));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 100));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Operation"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("ReceiveData", "Waiting"));
	}
	
	public void step4() {
		step3();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 98));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 99));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Operation"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("ReceiveData", "Waiting"));
	}
	
	public void step5() {
		step4();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 97));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 99));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Operation"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("ReceiveData", "Waiting"));
	}
	
	public void step6() {
		step5();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 96));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 98));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Operation"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("ReceiveData", "Waiting"));
	}
	
	public void step7() {
		step6();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 95));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 98));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Operation"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("ReceiveData", "Waiting"));
	}
	
	public void step8() {
		step7();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 94));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 97));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Operation"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("ReceiveData", "Waiting"));
	}
	
	public void step9() {
		step8();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 93));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 97));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Operation"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("ReceiveData", "Waiting"));
	}
	
	public void step10() {
		step9();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 92));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 96));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Operation"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("ReceiveData", "Waiting"));
	}
	
	public void step11() {
		step10();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 91));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 96));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Operation"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("ReceiveData", "Waiting"));
	}
	
	public void step12() {
		step11();
		// Act
		timer.elapse(1000);
		reflectiveMission.raiseEvent("control", "shutdown", new Object[] {});
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 90));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 95));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Idle"));
	}
	
	public void step13() {
		step12();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 89));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 95));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Idle"));
	}
	
	public void step14() {
		step13();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 88));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 94));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Idle"));
	}
	
	public void step15() {
		step14();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 87));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 94));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Idle"));
	}
	
	public void step16() {
		step15();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 86));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 93));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Idle"));
	}
	
	public void step17() {
		step16();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 85));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 93));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Idle"));
	}
	
	public void step18() {
		step17();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 84));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 92));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Idle"));
	}
	
	public void step19() {
		step18();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 83));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 92));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Idle"));
	}
	
	public void step20() {
		step19();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 82));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 91));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Idle"));
	}
	
	public void step21() {
		step20();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 81));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 91));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Idle"));
	}
	
	public void step22() {
		step21();
		// Act
		timer.elapse(1000);
		reflectiveMission.schedule(null);
		// Checking out events
		// Checking variables
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("batteryVariable", (long) 80));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("recharging", false));
		assertTrue(reflectiveMission.getComponent("satellite").checkVariableValue("data", (long) 90));
		// Checking of states
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("ConsumePower", "Consuming"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Battery", "NotRecharging"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("SendData", "Sending"));
		assertTrue(reflectiveMission.getComponent("satellite").isStateActive("Communication", "Transmitting"));
		assertTrue(reflectiveMission.getComponent("station").isStateActive("Main", "Idle"));
	}
	
}

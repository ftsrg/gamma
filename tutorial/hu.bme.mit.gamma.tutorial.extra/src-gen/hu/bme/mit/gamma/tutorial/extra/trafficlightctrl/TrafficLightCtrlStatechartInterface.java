package hu.bme.mit.gamma.tutorial.extra.trafficlightctrl;

import hu.bme.mit.gamma.tutorial.extra.interfaces.LightCommandsInterface;
import hu.bme.mit.gamma.tutorial.extra.interfaces.PoliceInterruptInterface;
import hu.bme.mit.gamma.tutorial.extra.interfaces.ControlInterface;

public interface TrafficLightCtrlStatechartInterface {
	
	LightCommandsInterface.Provided getLightCommands();
	PoliceInterruptInterface.Required getPoliceInterrupt();
	ControlInterface.Required getControl();
	
	void reset();
	
	void runCycle();
	
}

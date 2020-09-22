package hu.bme.mit.gamma.tutorial.extra.trafficlightctrl;

import hu.bme.mit.gamma.tutorial.extra.*;
import hu.bme.mit.gamma.tutorial.extra.interfaces.LightCommandsInterface;
import hu.bme.mit.gamma.tutorial.extra.interfaces.ControlInterface;
import hu.bme.mit.gamma.tutorial.extra.interfaces.PoliceInterruptInterface;

public interface TrafficLightCtrlInterface {
	
	LightCommandsInterface.Provided getLightCommands();
	ControlInterface.Required getControl();
	PoliceInterruptInterface.Required getPoliceInterrupt();
	
	void reset();
	
	void runCycle();
	
}

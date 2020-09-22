package hu.bme.mit.gamma.tutorial.finish.trafficlightctrl;

import hu.bme.mit.gamma.tutorial.finish.*;
import hu.bme.mit.gamma.tutorial.finish.interfaces.ControlInterface;
import hu.bme.mit.gamma.tutorial.finish.interfaces.PoliceInterruptInterface;
import hu.bme.mit.gamma.tutorial.finish.interfaces.LightCommandsInterface;

public interface TrafficLightCtrlInterface {
	
	ControlInterface.Required getControl();
	PoliceInterruptInterface.Required getPoliceInterrupt();
	LightCommandsInterface.Provided getLightCommands();
	
	void reset();
	
	void runCycle();
	
}

package hu.bme.mit.gamma.tutorial.extra.trafficlightctrl;

import hu.bme.mit.gamma.tutorial.extra.interfaces.ControlInterface;
import hu.bme.mit.gamma.tutorial.extra.interfaces.LightCommandsInterface;
import hu.bme.mit.gamma.tutorial.extra.interfaces.PoliceInterruptInterface;

public interface TrafficLightCtrlStatechartInterface {
	
	ControlInterface.Required getControl();
	LightCommandsInterface.Provided getLightCommands();
	PoliceInterruptInterface.Required getPoliceInterrupt();
	
	void reset();
	
	void runCycle();
	
} 

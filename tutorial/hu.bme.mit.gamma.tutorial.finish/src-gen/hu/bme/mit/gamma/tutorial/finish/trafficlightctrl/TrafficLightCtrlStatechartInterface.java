package hu.bme.mit.gamma.tutorial.finish.trafficlightctrl;

import hu.bme.mit.gamma.tutorial.finish.interfaces.ControlInterface;
import hu.bme.mit.gamma.tutorial.finish.interfaces.LightCommandsInterface;
import hu.bme.mit.gamma.tutorial.finish.interfaces.PoliceInterruptInterface;

public interface TrafficLightCtrlStatechartInterface {
	
	ControlInterface.Required getControl();
	LightCommandsInterface.Provided getLightCommands();
	PoliceInterruptInterface.Required getPoliceInterrupt();
	
	void reset();
	
	void runCycle();
	
}

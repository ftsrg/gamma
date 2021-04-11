package hu.bme.mit.gamma.tutorial.contract.finish.trafficlightctrl;

import hu.bme.mit.gamma.tutorial.contract.finish.interfaces.*;

public interface TrafficLightCtrlInterface {

	public PoliceInterruptInterface.Required getPoliceInterrupt();
	public LightCommandsInterface.Provided getLightCommands();
	public ControlInterface.Required getControl();
	
	void runCycle();
	void reset();

}

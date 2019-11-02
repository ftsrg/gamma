package hu.bme.mit.gamma.tutorial.finish.controller;

import hu.bme.mit.gamma.tutorial.finish.interfaces.ControlInterface;
import hu.bme.mit.gamma.tutorial.finish.interfaces.PoliceInterruptInterface;

public interface ControllerStatechartInterface {
	
	ControlInterface.Provided getSecondaryControl();
	PoliceInterruptInterface.Provided getSecondaryPolice();
	PoliceInterruptInterface.Provided getPriorityPolice();
	ControlInterface.Provided getPriorityControl();
	PoliceInterruptInterface.Required getPoliceInterrupt();
	
	void reset();
	
	void runCycle();
	
}

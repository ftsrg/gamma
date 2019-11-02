package hu.bme.mit.gamma.tutorial.extra.controller;

import hu.bme.mit.gamma.tutorial.extra.interfaces.PoliceInterruptInterface;
import hu.bme.mit.gamma.tutorial.extra.interfaces.ControlInterface;

public interface ControllerStatechartInterface {
	
	PoliceInterruptInterface.Provided getSecondaryPolice();
	ControlInterface.Provided getPriorityControl();
	PoliceInterruptInterface.Provided getPriorityPolice();
	ControlInterface.Provided getSecondaryControl();
	PoliceInterruptInterface.Required getPoliceInterrupt();
	
	void reset();
	
	void runCycle();
	
}

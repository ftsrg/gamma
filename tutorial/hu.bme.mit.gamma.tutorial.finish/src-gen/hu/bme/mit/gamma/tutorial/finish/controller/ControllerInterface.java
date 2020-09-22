package hu.bme.mit.gamma.tutorial.finish.controller;

import hu.bme.mit.gamma.tutorial.finish.*;
import hu.bme.mit.gamma.tutorial.finish.interfaces.ControlInterface;
import hu.bme.mit.gamma.tutorial.finish.interfaces.PoliceInterruptInterface;

public interface ControllerInterface {
	
	ControlInterface.Provided getPriorityControl();
	ControlInterface.Provided getSecondaryControl();
	PoliceInterruptInterface.Required getPoliceInterrupt();
	PoliceInterruptInterface.Provided getPriorityPolice();
	PoliceInterruptInterface.Provided getSecondaryPolice();
	
	void reset();
	
	void runCycle();
	
}

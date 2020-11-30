package hu.bme.mit.gamma.tutorial.extra.controller;

import hu.bme.mit.gamma.tutorial.extra.*;
import hu.bme.mit.gamma.tutorial.extra.interfaces.PoliceInterruptInterface;
import hu.bme.mit.gamma.tutorial.extra.interfaces.ControlInterface;

public interface ControllerInterface {
	
	PoliceInterruptInterface.Provided getSecondaryPolice();
	PoliceInterruptInterface.Required getPoliceInterrupt();
	PoliceInterruptInterface.Provided getPriorityPolice();
	ControlInterface.Provided getSecondaryControl();
	ControlInterface.Provided getPriorityControl();
	
	void reset();
	
	void runCycle();
	
}

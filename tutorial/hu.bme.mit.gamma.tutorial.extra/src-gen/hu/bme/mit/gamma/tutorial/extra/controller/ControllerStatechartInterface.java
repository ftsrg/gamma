package hu.bme.mit.gamma.tutorial.extra.controller;

import hu.bme.mit.gamma.tutorial.extra.interfaces.ControlInterface;
import hu.bme.mit.gamma.tutorial.extra.interfaces.PoliceInterruptInterface;

public interface ControllerStatechartInterface {
	
	ControlInterface.Provided getSecondaryControl();
	PoliceInterruptInterface.Provided getSecondaryPolice();
	PoliceInterruptInterface.Required getPoliceInterrupt();
	PoliceInterruptInterface.Provided getPriorityPolice();
	ControlInterface.Provided getPriorityControl();
	
	void reset();
	
	void runCycle();
	
} 

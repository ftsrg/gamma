package hu.bme.mit.gamma.tutorial.finish.controller;

import hu.bme.mit.gamma.tutorial.finish.interfaces.ControlInterface;
import hu.bme.mit.gamma.tutorial.finish.interfaces.PoliceInterruptInterface;

public interface ControllerStatechartInterface {
	
	ControlInterface.Provided getPriorityControl();
	PoliceInterruptInterface.Required getPoliceInterrupt();
	PoliceInterruptInterface.Provided getSecondaryPolice();
	ControlInterface.Provided getSecondaryControl();
	PoliceInterruptInterface.Provided getPriorityPolice();
	
	void reset();
	
	void runCycle();
	
} 

package hu.bme.mit.gamma.tutorial.finish.controller;

import hu.bme.mit.gamma.tutorial.finish.interfaces.PoliceInterruptInterface;
import hu.bme.mit.gamma.tutorial.finish.interfaces.ControlInterface;

public interface ControllerStatechartInterface {
	
	PoliceInterruptInterface.Provided getPriorityPolice();
	ControlInterface.Provided getSecondaryControl();
	ControlInterface.Provided getPriorityControl();
	PoliceInterruptInterface.Provided getSecondaryPolice();
	PoliceInterruptInterface.Required getPoliceInterrupt();
	
	void reset();
	
	void runCycle();
	
} 

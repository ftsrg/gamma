package hu.bme.mit.gamma.tutorial.extra.tutorial;

import hu.bme.mit.gamma.tutorial.extra.interfaces.LightCommandsInterface;
import hu.bme.mit.gamma.tutorial.extra.interfaces.PoliceInterruptInterface;

public interface CrossroadInterface {
	
	LightCommandsInterface.Provided getSecondaryOutput();
	PoliceInterruptInterface.Required getPolice();
	LightCommandsInterface.Provided getPriorityOutput();
	
	void reset();
	
	void runCycle();
	void runFullCycle();
	
} 

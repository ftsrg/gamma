package hu.bme.mit.gamma.tutorial.finish.tutorial;

import hu.bme.mit.gamma.tutorial.finish.interfaces.LightCommandsInterface;
import hu.bme.mit.gamma.tutorial.finish.interfaces.PoliceInterruptInterface;

public interface CrossroadInterface {
	
	LightCommandsInterface.Provided getSecondaryOutput();
	PoliceInterruptInterface.Required getPolice();
	LightCommandsInterface.Provided getPriorityOutput();
	
	void reset();
	
	void runCycle();
	void runFullCycle();
	
} 

package hu.bme.mit.gamma.tutorial.finish.tutorial;

import hu.bme.mit.gamma.tutorial.finish.*;
import hu.bme.mit.gamma.tutorial.finish.interfaces.LightCommandsInterface;
import hu.bme.mit.gamma.tutorial.finish.interfaces.PoliceInterruptInterface;

public interface CrossroadInterface {
	
	LightCommandsInterface.Provided getPriorityOutput();
	LightCommandsInterface.Provided getSecondaryOutput();
	PoliceInterruptInterface.Required getPolice();
	
	void reset();
	
	void runCycle();
	void runFullCycle();
	
}

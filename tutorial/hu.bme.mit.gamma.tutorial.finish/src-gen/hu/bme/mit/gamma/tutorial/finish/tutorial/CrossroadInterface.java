package hu.bme.mit.gamma.tutorial.finish.tutorial;

import hu.bme.mit.gamma.tutorial.finish.interfaces.PoliceInterruptInterface;
import hu.bme.mit.gamma.tutorial.finish.interfaces.LightCommandsInterface;

public interface CrossroadInterface {
	
	PoliceInterruptInterface.Required getPolice();
	LightCommandsInterface.Provided getPriorityOutput();
	LightCommandsInterface.Provided getSecondaryOutput();
	
	void reset();
	
	void runCycle();
	void runFullCycle();
	
}

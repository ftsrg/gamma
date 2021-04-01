package hu.bme.mit.gamma.tutorial.contract.finish.tutorial;

import hu.bme.mit.gamma.tutorial.contract.finish.*;
import hu.bme.mit.gamma.tutorial.contract.finish.interfaces.PoliceInterruptInterface;
import hu.bme.mit.gamma.tutorial.contract.finish.interfaces.LightCommandsInterface;

public interface CrossroadInterface {
	
	PoliceInterruptInterface.Required getPolice();
	LightCommandsInterface.Provided getSecondaryOutput();
	LightCommandsInterface.Provided getPriorityOutput();
	
	void reset();
	
	void runCycle();
	void runFullCycle();
	
}

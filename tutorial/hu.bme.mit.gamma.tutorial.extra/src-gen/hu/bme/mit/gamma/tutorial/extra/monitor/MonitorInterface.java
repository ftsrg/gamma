package hu.bme.mit.gamma.tutorial.extra.monitor;

import hu.bme.mit.gamma.tutorial.extra.*;
import hu.bme.mit.gamma.tutorial.extra.interfaces.ErrorInterface;
import hu.bme.mit.gamma.tutorial.extra.interfaces.LightCommandsInterface;

public interface MonitorInterface {
	
	ErrorInterface.Provided getError();
	LightCommandsInterface.Required getLightInputs();
	
	void reset();
	
	void runCycle();
	
}

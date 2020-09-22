package hu.bme.mit.gamma.tutorial.extra.monitoredcrossroad;

import hu.bme.mit.gamma.tutorial.extra.*;
import hu.bme.mit.gamma.tutorial.extra.interfaces.PoliceInterruptInterface;
import hu.bme.mit.gamma.tutorial.extra.interfaces.LightCommandsInterface;
import hu.bme.mit.gamma.tutorial.extra.interfaces.ErrorInterface;

public interface MonitoredCrossroadInterface {
	
	PoliceInterruptInterface.Required getPolice();
	LightCommandsInterface.Provided getPriorityOutput();
	ErrorInterface.Provided getMonitorOutput();
	LightCommandsInterface.Provided getSecondaryOutput();
	
	void reset();
	
	void runCycle();
	void runFullCycle();
	
}

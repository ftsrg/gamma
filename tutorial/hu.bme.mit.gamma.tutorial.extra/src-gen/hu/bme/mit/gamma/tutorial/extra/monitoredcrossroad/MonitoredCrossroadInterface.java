package hu.bme.mit.gamma.tutorial.extra.monitoredcrossroad;

import hu.bme.mit.gamma.tutorial.extra.interfaces.LightCommandsInterface;
import hu.bme.mit.gamma.tutorial.extra.interfaces.MonitorInterface;
import hu.bme.mit.gamma.tutorial.extra.interfaces.PoliceInterruptInterface;

public interface MonitoredCrossroadInterface {
	
	LightCommandsInterface.Provided getSecondaryOutput();
	MonitorInterface.Provided getMonitorOutput();
	LightCommandsInterface.Provided getPriorityOutput();
	PoliceInterruptInterface.Required getPolice();
	
	void reset();
	
	void runCycle();
	void runFullCycle();
	
}

package hu.bme.mit.gamma.tutorial.extra.monitor;

import hu.bme.mit.gamma.tutorial.extra.interfaces.MonitorInterface;
import hu.bme.mit.gamma.tutorial.extra.interfaces.LightCommandsInterface;

public interface MonitorStatechartInterface {
	
	MonitorInterface.Provided getMonitor();
	LightCommandsInterface.Required getLightInputs();
	
	void reset();
	
	void runCycle();
	
} 

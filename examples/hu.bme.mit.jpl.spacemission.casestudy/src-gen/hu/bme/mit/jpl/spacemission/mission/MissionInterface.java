package hu.bme.mit.jpl.spacemission.mission;

import hu.bme.mit.jpl.spacemission.interfaces.StationControlInterface;

public interface MissionInterface {
	
	StationControlInterface.Required getControl();
	
	void reset();
	
	void runCycle();
	void runFullCycle();
	
}

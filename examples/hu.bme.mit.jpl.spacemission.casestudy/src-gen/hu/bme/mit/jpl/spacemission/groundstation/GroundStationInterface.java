package hu.bme.mit.jpl.spacemission.groundstation;

import hu.bme.mit.jpl.spacemission.interfaces.*;

public interface GroundStationInterface {

	public DataSourceInterface.Required getConnection();
	public StationControlInterface.Required getControl();
	
	void runCycle();
	void reset();

}

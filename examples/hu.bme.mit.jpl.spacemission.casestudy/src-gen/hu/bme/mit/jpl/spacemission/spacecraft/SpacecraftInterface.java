package hu.bme.mit.jpl.spacemission.spacecraft;

import hu.bme.mit.jpl.spacemission.interfaces.*;

public interface SpacecraftInterface {

	public DataSourceInterface.Provided getConnection();
	
	void runCycle();
	void reset();

}

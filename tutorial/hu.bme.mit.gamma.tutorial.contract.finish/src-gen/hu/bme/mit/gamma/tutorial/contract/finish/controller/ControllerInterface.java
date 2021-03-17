package hu.bme.mit.gamma.tutorial.contract.finish.controller;

import hu.bme.mit.gamma.tutorial.contract.finish.interfaces.*;

public interface ControllerInterface {

	public PoliceInterruptInterface.Required getPoliceInterrupt();
	public PoliceInterruptInterface.Provided getSecondaryPolice();
	public ControlInterface.Provided getSecondaryControl();
	public ControlInterface.Provided getPriorityControl();
	public PoliceInterruptInterface.Provided getPriorityPolice();
	
	void runCycle();
	void reset();

}

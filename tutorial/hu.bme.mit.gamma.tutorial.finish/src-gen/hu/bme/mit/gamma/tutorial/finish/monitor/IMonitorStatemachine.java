package hu.bme.mit.gamma.tutorial.finish.monitor;

import hu.bme.mit.gamma.tutorial.finish.IStatemachine;

public interface IMonitorStatemachine extends IStatemachine {

	public interface SCILightInputs {
	
		public void raiseDisplayRed();
		
		public void raiseDisplayGreen();
		
		public void raiseDisplayYellow();
		
		public void raiseDisplayNone();
		
	}
	
	public SCILightInputs getSCILightInputs();
	
}

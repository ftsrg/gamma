package hu.bme.mit.gamma.tutorial.extra.monitor;

import java.util.List;
import hu.bme.mit.gamma.tutorial.extra.IStatemachine;

public interface IMonitorStatemachine extends IStatemachine {

	public interface SCILightInputs {
	
		public void raiseDisplayRed();
		
		public void raiseDisplayGreen();
		
		public void raiseDisplayYellow();
		
		public void raiseDisplayNone();
		
	}
	
	public SCILightInputs getSCILightInputs();
	
	public interface SCIMonitor {
	
		public boolean isRaisedError();
		
	public List<SCIMonitorListener> getListeners();
	}
	
	public interface SCIMonitorListener {
	
		public void onErrorRaised();
		}
	
	public SCIMonitor getSCIMonitor();
	
}

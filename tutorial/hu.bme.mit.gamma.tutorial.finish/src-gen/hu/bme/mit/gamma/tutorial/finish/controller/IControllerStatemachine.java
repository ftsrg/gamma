package hu.bme.mit.gamma.tutorial.finish.controller;

import hu.bme.mit.gamma.tutorial.finish.IStatemachine;
import hu.bme.mit.gamma.tutorial.finish.ITimerCallback;
import java.util.List;

public interface IControllerStatemachine extends ITimerCallback,IStatemachine {
	public interface SCIPoliceInterrupt {
	
		public void raisePolice();
		
	}
	
	public SCIPoliceInterrupt getSCIPoliceInterrupt();
	
	public interface SCIPriorityPolice {
	
		public boolean isRaisedPolice();
		
	public List<SCIPriorityPoliceListener> getListeners();
	}
	
	public interface SCIPriorityPoliceListener {
	
		public void onPoliceRaised();
		}
	
	public SCIPriorityPolice getSCIPriorityPolice();
	
	public interface SCISecondaryPolice {
	
		public boolean isRaisedPolice();
		
	public List<SCISecondaryPoliceListener> getListeners();
	}
	
	public interface SCISecondaryPoliceListener {
	
		public void onPoliceRaised();
		}
	
	public SCISecondaryPolice getSCISecondaryPolice();
	
	public interface SCIPriorityControl {
	
		public boolean isRaisedToggle();
		
	public List<SCIPriorityControlListener> getListeners();
	}
	
	public interface SCIPriorityControlListener {
	
		public void onToggleRaised();
		}
	
	public SCIPriorityControl getSCIPriorityControl();
	
	public interface SCISecondaryControl {
	
		public boolean isRaisedToggle();
		
	public List<SCISecondaryControlListener> getListeners();
	}
	
	public interface SCISecondaryControlListener {
	
		public void onToggleRaised();
		}
	
	public SCISecondaryControl getSCISecondaryControl();
	
}

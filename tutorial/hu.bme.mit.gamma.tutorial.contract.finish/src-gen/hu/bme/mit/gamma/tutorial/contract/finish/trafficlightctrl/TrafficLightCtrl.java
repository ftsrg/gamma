package hu.bme.mit.gamma.tutorial.contract.finish.trafficlightctrl;

import java.util.List;
import java.util.Queue;
import java.util.LinkedList;
import hu.bme.mit.gamma.tutorial.contract.finish.*;
import hu.bme.mit.gamma.tutorial.contract.finish.TimerInterface.*;
import hu.bme.mit.gamma.tutorial.contract.finish.interfaces.*;
import hu.bme.mit.gamma.tutorial.contract.finish.trafficlightctrl.TrafficLightCtrlStatemachine.*;

public class TrafficLightCtrl implements TrafficLightCtrlInterface {
	// Port instances
	private PoliceInterrupt policeInterrupt = new PoliceInterrupt();
	private LightCommands lightCommands = new LightCommands();
	private Control control = new Control();
	// Wrapped statemachine
	private TrafficLightCtrlStatemachine trafficLightCtrl;
	// Indicates which queue is active in a cycle
	private boolean insertQueue = true;
	private boolean processQueue = false;
	// Event queues for the synchronization of statecharts
	private Queue<Event> eventQueue1 = new LinkedList<Event>();
	private Queue<Event> eventQueue2 = new LinkedList<Event>();
	// Clocks
	private TimerInterface timer = new OneThreadedTimer();
	
	public TrafficLightCtrl() {
		trafficLightCtrl = new TrafficLightCtrlStatemachine();
	}
	
	public void reset() {
		// Clearing the in events
		insertQueue = true;
		processQueue = false;
		eventQueue1.clear();
		eventQueue2.clear();
		//
		trafficLightCtrl.reset();
		timer.saveTime(this);
		notifyListeners();
	}

	/** Changes the event queues of the component instance. Should be used only be the container (composite system) class. */
	public void changeEventQueues() {
		insertQueue = !insertQueue;
		processQueue = !processQueue;
	}
	
	/** Changes the event queues to which the events are put. Should be used only be a cascade container (composite system) class. */
	public void changeInsertQueue() {
		insertQueue = !insertQueue;
	}
	
	/** Returns whether the eventQueue containing incoming messages is empty. Should be used only be the container (composite system) class. */
	public boolean isEventQueueEmpty() {
		return getInsertQueue().isEmpty();
	}
	
	/** Returns the event queue into which events should be put in the particular cycle. */
	private Queue<Event> getInsertQueue() {
		if (insertQueue) {
			return eventQueue1;
		}
		return eventQueue2;
	}
	
	/** Returns the event queue from which events should be inspected in the particular cycle. */
	private Queue<Event> getProcessQueue() {
		if (processQueue) {
			return eventQueue1;
		}
		return eventQueue2;
	}
	
	public class PoliceInterrupt implements PoliceInterruptInterface.Required {
		private List<PoliceInterruptInterface.Listener.Required> listeners = new LinkedList<PoliceInterruptInterface.Listener.Required>();
		@Override
		public void raisePolice() {
			getInsertQueue().add(new Event("PoliceInterrupt.police"));
		}
		@Override
		public void registerListener(PoliceInterruptInterface.Listener.Required listener) {
			listeners.add(listener);
		}
		@Override
		public List<PoliceInterruptInterface.Listener.Required> getRegisteredListeners() {
			return listeners;
		}
	}
	
	public PoliceInterrupt getPoliceInterrupt() {
		return policeInterrupt;
	}
	
	public class LightCommands implements LightCommandsInterface.Provided {
		private List<LightCommandsInterface.Listener.Provided> listeners = new LinkedList<LightCommandsInterface.Listener.Provided>();
		@Override
		public boolean isRaisedDisplayNone() {
			return trafficLightCtrl.getLightCommands_displayNone_Out();
		}
		@Override
		public boolean isRaisedDisplayRed() {
			return trafficLightCtrl.getLightCommands_displayRed_Out();
		}
		@Override
		public boolean isRaisedDisplayGreen() {
			return trafficLightCtrl.getLightCommands_displayGreen_Out();
		}
		@Override
		public boolean isRaisedDisplayYellow() {
			return trafficLightCtrl.getLightCommands_displayYellow_Out();
		}
		@Override
		public void registerListener(LightCommandsInterface.Listener.Provided listener) {
			listeners.add(listener);
		}
		@Override
		public List<LightCommandsInterface.Listener.Provided> getRegisteredListeners() {
			return listeners;
		}
	}
	
	public LightCommands getLightCommands() {
		return lightCommands;
	}
	
	public class Control implements ControlInterface.Required {
		private List<ControlInterface.Listener.Required> listeners = new LinkedList<ControlInterface.Listener.Required>();
		@Override
		public void raiseToggle() {
			getInsertQueue().add(new Event("Control.toggle"));
		}
		@Override
		public void registerListener(ControlInterface.Listener.Required listener) {
			listeners.add(listener);
		}
		@Override
		public List<ControlInterface.Listener.Required> getRegisteredListeners() {
			return listeners;
		}
	}
	
	public Control getControl() {
		return control;
	}
	
	public void runCycle() {
		changeEventQueues();
		runComponent();
	}
	
	public void runComponent() {
		Queue<Event> eventQueue = getProcessQueue();
		while (!eventQueue.isEmpty()) {
			Event event = eventQueue.remove();
			switch (event.getEvent()) {
				case "PoliceInterrupt.police": 
					trafficLightCtrl.setPoliceInterrupt_police_In(true);
				break;
				case "Control.toggle": 
					trafficLightCtrl.setControl_toggle_In(true);
				break;
				default:
					throw new IllegalArgumentException("No such event: " + event);
			}
		}
		executeStep();
	}
	
	private void executeStep() {
		int elapsedTime = (int) timer.getElapsedTime(this, TimeUnit.MILLISECOND);
		trafficLightCtrl.setBlackTimeout3(trafficLightCtrl.getBlackTimeout3() + elapsedTime);
		trafficLightCtrl.runCycle();
		timer.saveTime(this);
		notifyListeners();
	}
	
	/** Interface method, needed for composite component initialization chain. */
	public void notifyAllListeners() {
		notifyListeners();
	}
	
	public void notifyListeners() {
		if (lightCommands.isRaisedDisplayNone()) {
			for (LightCommandsInterface.Listener.Provided listener : lightCommands.getRegisteredListeners()) {
				listener.raiseDisplayNone();
			}
		}
		if (lightCommands.isRaisedDisplayRed()) {
			for (LightCommandsInterface.Listener.Provided listener : lightCommands.getRegisteredListeners()) {
				listener.raiseDisplayRed();
			}
		}
		if (lightCommands.isRaisedDisplayGreen()) {
			for (LightCommandsInterface.Listener.Provided listener : lightCommands.getRegisteredListeners()) {
				listener.raiseDisplayGreen();
			}
		}
		if (lightCommands.isRaisedDisplayYellow()) {
			for (LightCommandsInterface.Listener.Provided listener : lightCommands.getRegisteredListeners()) {
				listener.raiseDisplayYellow();
			}
		}
	}
	
	public void setTimer(TimerInterface timer) {
		this.timer = timer;
	}
	
	public boolean isStateActive(String region, String state) {
		switch (region) {
			case "interrupted":
				return trafficLightCtrl.getInterrupted() == Interrupted.valueOf(state);
			case "main_region":
				return trafficLightCtrl.getMain_region() == Main_region.valueOf(state);
			case "normal":
				return trafficLightCtrl.getNormal() == Normal.valueOf(state);
		}
		return false;
	}
	
	
	@Override
	public String toString() {
		return trafficLightCtrl.toString();
	}
}

package hu.bme.mit.gamma.tutorial.contract.finish.controller;

import java.util.List;
import java.util.Queue;
import java.util.LinkedList;
import hu.bme.mit.gamma.tutorial.contract.finish.*;
import hu.bme.mit.gamma.tutorial.contract.finish.TimerInterface.*;
import hu.bme.mit.gamma.tutorial.contract.finish.interfaces.*;
import hu.bme.mit.gamma.tutorial.contract.finish.controller.ControllerStatemachine.*;

public class Controller implements ControllerInterface {
	// Port instances
	private PoliceInterrupt policeInterrupt = new PoliceInterrupt();
	private SecondaryPolice secondaryPolice = new SecondaryPolice();
	private SecondaryControl secondaryControl = new SecondaryControl();
	private PriorityControl priorityControl = new PriorityControl();
	private PriorityPolice priorityPolice = new PriorityPolice();
	// Wrapped statemachine
	private ControllerStatemachine controller;
	// Indicates which queue is active in a cycle
	private boolean insertQueue = true;
	private boolean processQueue = false;
	// Event queues for the synchronization of statecharts
	private Queue<Event> eventQueue1 = new LinkedList<Event>();
	private Queue<Event> eventQueue2 = new LinkedList<Event>();
	// Clocks
	private TimerInterface timer = new OneThreadedTimer();
	
	public Controller() {
		controller = new ControllerStatemachine();
	}
	
	public void reset() {
		// Clearing the in events
		insertQueue = true;
		processQueue = false;
		eventQueue1.clear();
		eventQueue2.clear();
		//
		controller.reset();
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
	
	public class SecondaryPolice implements PoliceInterruptInterface.Provided {
		private List<PoliceInterruptInterface.Listener.Provided> listeners = new LinkedList<PoliceInterruptInterface.Listener.Provided>();
		@Override
		public boolean isRaisedPolice() {
			return controller.getSecondaryPolice_police_Out();
		}
		@Override
		public void registerListener(PoliceInterruptInterface.Listener.Provided listener) {
			listeners.add(listener);
		}
		@Override
		public List<PoliceInterruptInterface.Listener.Provided> getRegisteredListeners() {
			return listeners;
		}
	}
	
	public SecondaryPolice getSecondaryPolice() {
		return secondaryPolice;
	}
	
	public class SecondaryControl implements ControlInterface.Provided {
		private List<ControlInterface.Listener.Provided> listeners = new LinkedList<ControlInterface.Listener.Provided>();
		@Override
		public boolean isRaisedToggle() {
			return controller.getSecondaryControl_toggle_Out();
		}
		@Override
		public void registerListener(ControlInterface.Listener.Provided listener) {
			listeners.add(listener);
		}
		@Override
		public List<ControlInterface.Listener.Provided> getRegisteredListeners() {
			return listeners;
		}
	}
	
	public SecondaryControl getSecondaryControl() {
		return secondaryControl;
	}
	
	public class PriorityControl implements ControlInterface.Provided {
		private List<ControlInterface.Listener.Provided> listeners = new LinkedList<ControlInterface.Listener.Provided>();
		@Override
		public boolean isRaisedToggle() {
			return controller.getPriorityControl_toggle_Out();
		}
		@Override
		public void registerListener(ControlInterface.Listener.Provided listener) {
			listeners.add(listener);
		}
		@Override
		public List<ControlInterface.Listener.Provided> getRegisteredListeners() {
			return listeners;
		}
	}
	
	public PriorityControl getPriorityControl() {
		return priorityControl;
	}
	
	public class PriorityPolice implements PoliceInterruptInterface.Provided {
		private List<PoliceInterruptInterface.Listener.Provided> listeners = new LinkedList<PoliceInterruptInterface.Listener.Provided>();
		@Override
		public boolean isRaisedPolice() {
			return controller.getPriorityPolice_police_Out();
		}
		@Override
		public void registerListener(PoliceInterruptInterface.Listener.Provided listener) {
			listeners.add(listener);
		}
		@Override
		public List<PoliceInterruptInterface.Listener.Provided> getRegisteredListeners() {
			return listeners;
		}
	}
	
	public PriorityPolice getPriorityPolice() {
		return priorityPolice;
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
					controller.setPoliceInterrupt_police_In(true);
				break;
				default:
					throw new IllegalArgumentException("No such event: " + event);
			}
		}
		executeStep();
	}
	
	private void executeStep() {
		int elapsedTime = (int) timer.getElapsedTime(this, TimeUnit.MILLISECOND);
		controller.setInitTimeout3(controller.getInitTimeout3() + elapsedTime);
		controller.setSecondaryPreparesTimeout2(controller.getSecondaryPreparesTimeout2() + elapsedTime);
		controller.runCycle();
		timer.saveTime(this);
		notifyListeners();
	}
	
	/** Interface method, needed for composite component initialization chain. */
	public void notifyAllListeners() {
		notifyListeners();
	}
	
	public void notifyListeners() {
		if (secondaryPolice.isRaisedPolice()) {
			for (PoliceInterruptInterface.Listener.Provided listener : secondaryPolice.getRegisteredListeners()) {
				listener.raisePolice();
			}
		}
		if (secondaryControl.isRaisedToggle()) {
			for (ControlInterface.Listener.Provided listener : secondaryControl.getRegisteredListeners()) {
				listener.raiseToggle();
			}
		}
		if (priorityControl.isRaisedToggle()) {
			for (ControlInterface.Listener.Provided listener : priorityControl.getRegisteredListeners()) {
				listener.raiseToggle();
			}
		}
		if (priorityPolice.isRaisedPolice()) {
			for (PoliceInterruptInterface.Listener.Provided listener : priorityPolice.getRegisteredListeners()) {
				listener.raisePolice();
			}
		}
	}
	
	public void setTimer(TimerInterface timer) {
		this.timer = timer;
	}
	
	public boolean isStateActive(String region, String state) {
		switch (region) {
			case "main_region":
				return controller.getMain_region() == Main_region.valueOf(state);
			case "operating":
				return controller.getOperating() == Operating.valueOf(state);
		}
		return false;
	}
	
	
	@Override
	public String toString() {
		return controller.toString();
	}
}

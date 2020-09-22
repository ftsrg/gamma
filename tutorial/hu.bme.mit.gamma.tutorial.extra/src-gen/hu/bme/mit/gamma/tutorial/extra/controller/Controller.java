package hu.bme.mit.gamma.tutorial.extra.controller;

import java.util.Queue;
import java.util.List;
import java.util.LinkedList;

import hu.bme.mit.gamma.tutorial.extra.interfaces.*;
// Yakindu listeners
import hu.bme.mit.gamma.tutorial.extra.controller.IControllerStatemachine.*;
import hu.bme.mit.gamma.tutorial.extra.*;
import hu.bme.mit.gamma.tutorial.extra.controller.ControllerStatemachine.State;

public class Controller implements ControllerInterface {
	// The wrapped Yakindu statemachine
	private ControllerStatemachine controllerStatemachine;
	// Port instances
	private SecondaryControl secondaryControl;
	private PriorityControl priorityControl;
	private PoliceInterrupt policeInterrupt;
	private SecondaryPolice secondaryPolice;
	private PriorityPolice priorityPolice;
	// Indicates which queue is active in a cycle
	private boolean insertQueue = true;
	private boolean processQueue = false;
	// Event queues for the synchronization of statecharts
	private Queue<Event> eventQueue1 = new LinkedList<Event>();
	private Queue<Event> eventQueue2 = new LinkedList<Event>();
	
	public Controller() {
		controllerStatemachine = new ControllerStatemachine();
		secondaryControl = new SecondaryControl();
		priorityControl = new PriorityControl();
		policeInterrupt = new PoliceInterrupt();
		secondaryPolice = new SecondaryPolice();
		priorityPolice = new PriorityPolice();
		controllerStatemachine.setTimer(new TimerService());
	}
	
	/** Resets the statemachine. Must be called to initialize the component. */
	@Override
	public void reset() {
		// Clearing the in events
		insertQueue = true;
		processQueue = false;
		eventQueue1.clear();
		eventQueue2.clear();
		//
		controllerStatemachine.init();
		controllerStatemachine.enter();
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
	
	/** Changes event queues and initiating a cycle run. */
	@Override
	public void runCycle() {
		changeEventQueues();
		runComponent();
	}
	
	/** Changes the insert queue and initiates a run. */
	public void runAndRechangeInsertQueue() {
		// First the insert queue is changed back, so self-event sending can work
		changeInsertQueue();
		runComponent();
	}
	
	/** Initiates a cycle run without changing the event queues. It is needed if this component is contained (wrapped) by another component.
	Should be used only be the container (composite system) class. */
	public void runComponent() {
		Queue<Event> eventQueue = getProcessQueue();
		while (!eventQueue.isEmpty()) {
				Event event = eventQueue.remove();
				switch (event.getEvent()) {
					case "PoliceInterrupt.Police": 
						controllerStatemachine.getSCIPoliceInterrupt().raisePolice();
					break;
					default:
						throw new IllegalArgumentException("No such event!");
				}
		}
		controllerStatemachine.runCycle();
		notifyListeners();
	}
	
	// Inner classes representing Ports
	public class SecondaryControl implements ControlInterface.Provided {
		private List<ControlInterface.Listener.Provided> registeredListeners = new LinkedList<ControlInterface.Listener.Provided>();


		@Override
		public boolean isRaisedToggle() {
			return controllerStatemachine.getSCISecondaryControl().isRaisedToggle();
		}
		@Override
		public void registerListener(final ControlInterface.Listener.Provided listener) {
			registeredListeners.add(listener);
		}
		
		@Override
		public List<ControlInterface.Listener.Provided> getRegisteredListeners() {
			return registeredListeners;
		}
		
		/** Notifying the registered listeners. */
		public void notifyListeners() {
			if (isRaisedToggle()) {
				for (ControlInterface.Listener.Provided listener : registeredListeners) {
					listener.raiseToggle();
				}
			}
		}

	}
	
	@Override
	public SecondaryControl getSecondaryControl() {
		return secondaryControl;
	}
	
	public class PriorityControl implements ControlInterface.Provided {
		private List<ControlInterface.Listener.Provided> registeredListeners = new LinkedList<ControlInterface.Listener.Provided>();


		@Override
		public boolean isRaisedToggle() {
			return controllerStatemachine.getSCIPriorityControl().isRaisedToggle();
		}
		@Override
		public void registerListener(final ControlInterface.Listener.Provided listener) {
			registeredListeners.add(listener);
		}
		
		@Override
		public List<ControlInterface.Listener.Provided> getRegisteredListeners() {
			return registeredListeners;
		}
		
		/** Notifying the registered listeners. */
		public void notifyListeners() {
			if (isRaisedToggle()) {
				for (ControlInterface.Listener.Provided listener : registeredListeners) {
					listener.raiseToggle();
				}
			}
		}

	}
	
	@Override
	public PriorityControl getPriorityControl() {
		return priorityControl;
	}
	
	public class PoliceInterrupt implements PoliceInterruptInterface.Required {
		private List<PoliceInterruptInterface.Listener.Required> registeredListeners = new LinkedList<PoliceInterruptInterface.Listener.Required>();

		@Override
		public void raisePolice() {
			getInsertQueue().add(new Event("PoliceInterrupt.Police"));
		}

		@Override
		public void registerListener(final PoliceInterruptInterface.Listener.Required listener) {
			registeredListeners.add(listener);
		}
		
		@Override
		public List<PoliceInterruptInterface.Listener.Required> getRegisteredListeners() {
			return registeredListeners;
		}
		
		/** Notifying the registered listeners. */
		public void notifyListeners() {
		}

	}
	
	@Override
	public PoliceInterrupt getPoliceInterrupt() {
		return policeInterrupt;
	}
	
	public class SecondaryPolice implements PoliceInterruptInterface.Provided {
		private List<PoliceInterruptInterface.Listener.Provided> registeredListeners = new LinkedList<PoliceInterruptInterface.Listener.Provided>();


		@Override
		public boolean isRaisedPolice() {
			return controllerStatemachine.getSCISecondaryPolice().isRaisedPolice();
		}
		@Override
		public void registerListener(final PoliceInterruptInterface.Listener.Provided listener) {
			registeredListeners.add(listener);
		}
		
		@Override
		public List<PoliceInterruptInterface.Listener.Provided> getRegisteredListeners() {
			return registeredListeners;
		}
		
		/** Notifying the registered listeners. */
		public void notifyListeners() {
			if (isRaisedPolice()) {
				for (PoliceInterruptInterface.Listener.Provided listener : registeredListeners) {
					listener.raisePolice();
				}
			}
		}

	}
	
	@Override
	public SecondaryPolice getSecondaryPolice() {
		return secondaryPolice;
	}
	
	public class PriorityPolice implements PoliceInterruptInterface.Provided {
		private List<PoliceInterruptInterface.Listener.Provided> registeredListeners = new LinkedList<PoliceInterruptInterface.Listener.Provided>();


		@Override
		public boolean isRaisedPolice() {
			return controllerStatemachine.getSCIPriorityPolice().isRaisedPolice();
		}
		@Override
		public void registerListener(final PoliceInterruptInterface.Listener.Provided listener) {
			registeredListeners.add(listener);
		}
		
		@Override
		public List<PoliceInterruptInterface.Listener.Provided> getRegisteredListeners() {
			return registeredListeners;
		}
		
		/** Notifying the registered listeners. */
		public void notifyListeners() {
			if (isRaisedPolice()) {
				for (PoliceInterruptInterface.Listener.Provided listener : registeredListeners) {
					listener.raisePolice();
				}
			}
		}

	}
	
	@Override
	public PriorityPolice getPriorityPolice() {
		return priorityPolice;
	}
	
	/** Interface method, needed for composite component initialization chain. */
	public void notifyAllListeners() {
		notifyListeners();
	}
	
	/** Notifies all registered listeners in each contained port. */
	public void notifyListeners() {
		getSecondaryControl().notifyListeners();
		getPriorityControl().notifyListeners();
		getPoliceInterrupt().notifyListeners();
		getSecondaryPolice().notifyListeners();
		getPriorityPolice().notifyListeners();
	}
	
	
	/** Checks whether the wrapped statemachine is in the given state. */
	public boolean isStateActive(State state) {
		return controllerStatemachine.isStateActive(state);
	}
	
	public boolean isStateActive(String region, String state) {
		switch (region) {
			case "main_region":
				switch (state) {
					case "Operating":
						return isStateActive(State.main_region_Operating);
					case "Interrupted":
						return isStateActive(State.main_region_Interrupted);
				}
			case "operating":
				switch (state) {
					case "SecondaryPrepares":
						return isStateActive(State.main_region_Operating_operating_SecondaryPrepares);
					case "Priority":
						return isStateActive(State.main_region_Operating_operating_Priority);
					case "Secondary":
						return isStateActive(State.main_region_Operating_operating_Secondary);
					case "Init":
						return isStateActive(State.main_region_Operating_operating_Init);
					case "PriorityPrepares":
						return isStateActive(State.main_region_Operating_operating_PriorityPrepares);
				}
		}
		return false;
	}

	
	
	public void setTimer(ITimer timer) {
		controllerStatemachine.setTimer(timer);
	}
	
}

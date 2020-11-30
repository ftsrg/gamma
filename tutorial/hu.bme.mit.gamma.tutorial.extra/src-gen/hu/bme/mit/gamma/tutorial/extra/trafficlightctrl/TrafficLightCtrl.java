package hu.bme.mit.gamma.tutorial.extra.trafficlightctrl;

import java.util.Queue;
import java.util.List;
import java.util.LinkedList;

import hu.bme.mit.gamma.tutorial.extra.interfaces.*;
// Yakindu listeners
import hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.ITrafficLightCtrlStatemachine.*;
import hu.bme.mit.gamma.tutorial.extra.*;
import hu.bme.mit.gamma.tutorial.extra.trafficlightctrl.TrafficLightCtrlStatemachine.State;

public class TrafficLightCtrl implements TrafficLightCtrlInterface {
	// The wrapped Yakindu statemachine
	private TrafficLightCtrlStatemachine trafficLightCtrlStatemachine;
	// Port instances
	private LightCommands lightCommands;
	private Control control;
	private PoliceInterrupt policeInterrupt;
	// Indicates which queue is active in a cycle
	private boolean insertQueue = true;
	private boolean processQueue = false;
	// Event queues for the synchronization of statecharts
	private Queue<Event> eventQueue1 = new LinkedList<Event>();
	private Queue<Event> eventQueue2 = new LinkedList<Event>();
	
	public TrafficLightCtrl() {
		trafficLightCtrlStatemachine = new TrafficLightCtrlStatemachine();
		lightCommands = new LightCommands();
		control = new Control();
		policeInterrupt = new PoliceInterrupt();
		trafficLightCtrlStatemachine.setTimer(new TimerService());
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
		trafficLightCtrlStatemachine.init();
		trafficLightCtrlStatemachine.enter();
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
					case "Control.Toggle": 
						trafficLightCtrlStatemachine.getSCIControl().raiseToggle();
					break;
					case "PoliceInterrupt.Police": 
						trafficLightCtrlStatemachine.getSCIPoliceInterrupt().raisePolice();
					break;
					default:
						throw new IllegalArgumentException("No such event!");
				}
		}
		trafficLightCtrlStatemachine.runCycle();
		notifyListeners();
	}
	
	// Inner classes representing Ports
	public class LightCommands implements LightCommandsInterface.Provided {
		private List<LightCommandsInterface.Listener.Provided> registeredListeners = new LinkedList<LightCommandsInterface.Listener.Provided>();


		@Override
		public boolean isRaisedDisplayNone() {
			return trafficLightCtrlStatemachine.getSCILightCommands().isRaisedDisplayNone();
		}
		@Override
		public boolean isRaisedDisplayYellow() {
			return trafficLightCtrlStatemachine.getSCILightCommands().isRaisedDisplayYellow();
		}
		@Override
		public boolean isRaisedDisplayRed() {
			return trafficLightCtrlStatemachine.getSCILightCommands().isRaisedDisplayRed();
		}
		@Override
		public boolean isRaisedDisplayGreen() {
			return trafficLightCtrlStatemachine.getSCILightCommands().isRaisedDisplayGreen();
		}
		@Override
		public void registerListener(final LightCommandsInterface.Listener.Provided listener) {
			registeredListeners.add(listener);
		}
		
		@Override
		public List<LightCommandsInterface.Listener.Provided> getRegisteredListeners() {
			return registeredListeners;
		}
		
		/** Notifying the registered listeners. */
		public void notifyListeners() {
			if (isRaisedDisplayNone()) {
				for (LightCommandsInterface.Listener.Provided listener : registeredListeners) {
					listener.raiseDisplayNone();
				}
			}
			if (isRaisedDisplayYellow()) {
				for (LightCommandsInterface.Listener.Provided listener : registeredListeners) {
					listener.raiseDisplayYellow();
				}
			}
			if (isRaisedDisplayRed()) {
				for (LightCommandsInterface.Listener.Provided listener : registeredListeners) {
					listener.raiseDisplayRed();
				}
			}
			if (isRaisedDisplayGreen()) {
				for (LightCommandsInterface.Listener.Provided listener : registeredListeners) {
					listener.raiseDisplayGreen();
				}
			}
		}

	}
	
	@Override
	public LightCommands getLightCommands() {
		return lightCommands;
	}
	
	public class Control implements ControlInterface.Required {
		private List<ControlInterface.Listener.Required> registeredListeners = new LinkedList<ControlInterface.Listener.Required>();

		@Override
		public void raiseToggle() {
			getInsertQueue().add(new Event("Control.Toggle"));
		}

		@Override
		public void registerListener(final ControlInterface.Listener.Required listener) {
			registeredListeners.add(listener);
		}
		
		@Override
		public List<ControlInterface.Listener.Required> getRegisteredListeners() {
			return registeredListeners;
		}
		
		/** Notifying the registered listeners. */
		public void notifyListeners() {
		}

	}
	
	@Override
	public Control getControl() {
		return control;
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
	
	/** Interface method, needed for composite component initialization chain. */
	public void notifyAllListeners() {
		notifyListeners();
	}
	
	/** Notifies all registered listeners in each contained port. */
	public void notifyListeners() {
		getLightCommands().notifyListeners();
		getControl().notifyListeners();
		getPoliceInterrupt().notifyListeners();
	}
	
	
	/** Checks whether the wrapped statemachine is in the given state. */
	public boolean isStateActive(State state) {
		return trafficLightCtrlStatemachine.isStateActive(state);
	}
	
	public boolean isStateActive(String region, String state) {
		switch (region) {
			case "normal":
				switch (state) {
					case "Green":
						return isStateActive(State.main_region_Normal_normal_Green);
					case "Yellow":
						return isStateActive(State.main_region_Normal_normal_Yellow);
					case "Red":
						return isStateActive(State.main_region_Normal_normal_Red);
				}
			case "main_region":
				switch (state) {
					case "Normal":
						return isStateActive(State.main_region_Normal);
					case "Interrupted":
						return isStateActive(State.main_region_Interrupted);
				}
			case "interrupted":
				switch (state) {
					case "BlinkingYellow":
						return isStateActive(State.main_region_Interrupted_interrupted_BlinkingYellow);
					case "Black":
						return isStateActive(State.main_region_Interrupted_interrupted_Black);
				}
		}
		return false;
	}

	
	
	public void setTimer(ITimer timer) {
		trafficLightCtrlStatemachine.setTimer(timer);
	}
	
}

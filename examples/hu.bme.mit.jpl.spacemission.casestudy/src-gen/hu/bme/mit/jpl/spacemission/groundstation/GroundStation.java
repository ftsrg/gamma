package hu.bme.mit.jpl.spacemission.groundstation;

import java.util.List;
import java.util.Queue;
import java.util.LinkedList;
import hu.bme.mit.jpl.spacemission.*;
import hu.bme.mit.jpl.spacemission.TimerInterface.*;
import hu.bme.mit.jpl.spacemission.interfaces.*;
import hu.bme.mit.jpl.spacemission.groundstation.GroundstationStatemachine.*;

public class GroundStation implements GroundStationInterface {
	// Port instances
	private Connection connection = new Connection();
	private Control control = new Control();
	// Wrapped statemachine
	private GroundstationStatemachine groundstation;
	// Indicates which queue is active in a cycle
	private boolean insertQueue = true;
	private boolean processQueue = false;
	// Event queues for the synchronization of statecharts
	private Queue<Event> eventQueue1 = new LinkedList<Event>();
	private Queue<Event> eventQueue2 = new LinkedList<Event>();
	// Clocks
	private TimerInterface timer = new OneThreadedTimer();
	
	public GroundStation() {
		groundstation = new GroundstationStatemachine();
	}
	
	public void reset() {
		groundstation.reset();
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
	
	public class Connection implements DataSourceInterface.Required {
		private List<DataSourceInterface.Listener.Required> listeners = new LinkedList<DataSourceInterface.Listener.Required>();
		@Override
		public void raiseData() {
			getInsertQueue().add(new Event("connection.data"));
		}
		@Override
		public boolean isRaisedPing() {
			return groundstation.getConnection_ping();
		}
		@Override
		public void registerListener(DataSourceInterface.Listener.Required listener) {
			listeners.add(listener);
		}
		@Override
		public List<DataSourceInterface.Listener.Required> getRegisteredListeners() {
			return listeners;
		}
	}
	
	public Connection getConnection() {
		return connection;
	}
	
	public class Control implements StationControlInterface.Required {
		private List<StationControlInterface.Listener.Required> listeners = new LinkedList<StationControlInterface.Listener.Required>();
		@Override
		public void raiseShutdown() {
			getInsertQueue().add(new Event("control.shutdown"));
		}
		@Override
		public void raiseStart() {
			getInsertQueue().add(new Event("control.start"));
		}
		@Override
		public void registerListener(StationControlInterface.Listener.Required listener) {
			listeners.add(listener);
		}
		@Override
		public List<StationControlInterface.Listener.Required> getRegisteredListeners() {
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
				case "connection.data": 
					groundstation.setConnection_data(true);
				break;
				case "control.shutdown": 
					groundstation.setControl_shutdown(true);
				break;
				case "control.start": 
					groundstation.setControl_start(true);
				break;
				default:
					throw new IllegalArgumentException("No such event: " + event);
			}
		}
		executeStep();
	}
	
	private void executeStep() {
		int elapsedTime = (int) timer.getElapsedTime(this, TimeUnit.MILLISECOND);
		groundstation.setPingTimeout(groundstation.getPingTimeout() + elapsedTime);
		groundstation.setAutoStart(groundstation.getAutoStart() + elapsedTime);
		groundstation.runCycle();
		timer.saveTime(this);
		notifyListeners();
	}
	
	private void notifyListeners() {
		if (connection.isRaisedPing()) {
			for (DataSourceInterface.Listener.Required listener : connection.getRegisteredListeners()) {
				listener.raisePing();
			}
		}
	}
	
	public void setTimer(TimerInterface timer) {
		this.timer = timer;
	}
	
	public boolean isStateActive(String region, String state) {
		switch (region) {
			case "ReceiveData":
				return groundstation.getReceiveData() == ReceiveData.valueOf(state);
			case "Main":
				return groundstation.getMain() == Main.valueOf(state);
		}
		return false;
	}
	
	
	@Override
	public String toString() {
		return groundstation.toString();
	}
}

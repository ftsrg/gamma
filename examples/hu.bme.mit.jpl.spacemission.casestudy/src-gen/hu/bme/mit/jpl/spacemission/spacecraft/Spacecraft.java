package hu.bme.mit.jpl.spacemission.spacecraft;

import java.util.List;
import java.util.Queue;
import java.util.LinkedList;
import hu.bme.mit.jpl.spacemission.*;
import hu.bme.mit.jpl.spacemission.TimerInterface.*;
import hu.bme.mit.jpl.spacemission.interfaces.*;
import hu.bme.mit.jpl.spacemission.spacecraft.SpacecraftStatemachine.*;

public class Spacecraft implements SpacecraftInterface {
	// Port instances
	private Connection connection = new Connection();
	// Wrapped statemachine
	private SpacecraftStatemachine spacecraft;
	// Indicates which queue is active in a cycle
	private boolean insertQueue = true;
	private boolean processQueue = false;
	// Event queues for the synchronization of statecharts
	private Queue<Event> eventQueue1 = new LinkedList<Event>();
	private Queue<Event> eventQueue2 = new LinkedList<Event>();
	// Clocks
	private TimerInterface timer = new OneThreadedTimer();
	
	public Spacecraft() {
		spacecraft = new SpacecraftStatemachine();
	}
	
	public void reset() {
		spacecraft.reset();
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
	
	public class Connection implements DataSourceInterface.Provided {
		private List<DataSourceInterface.Listener.Provided> listeners = new LinkedList<DataSourceInterface.Listener.Provided>();
		@Override
		public void raisePing() {
			getInsertQueue().add(new Event("connection.ping"));
		}
		@Override
		public boolean isRaisedData() {
			return spacecraft.getConnection_data();
		}
		@Override
		public void registerListener(DataSourceInterface.Listener.Provided listener) {
			listeners.add(listener);
		}
		@Override
		public List<DataSourceInterface.Listener.Provided> getRegisteredListeners() {
			return listeners;
		}
	}
	
	public Connection getConnection() {
		return connection;
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
				case "connection.ping": 
					spacecraft.setConnection_ping(true);
				break;
				default:
					throw new IllegalArgumentException("No such event: " + event);
			}
		}
		executeStep();
	}
	
	private void executeStep() {
		int elapsedTime = (int) timer.getElapsedTime(this, TimeUnit.MILLISECOND);
		spacecraft.setRechargeTimeout(spacecraft.getRechargeTimeout() + elapsedTime);
		spacecraft.setConsumeTimeout(spacecraft.getConsumeTimeout() + elapsedTime);
		spacecraft.setTransmitTimeout(spacecraft.getTransmitTimeout() + elapsedTime);
		spacecraft.runCycle();
		timer.saveTime(this);
		notifyListeners();
	}
	
	private void notifyListeners() {
		if (connection.isRaisedData()) {
			for (DataSourceInterface.Listener.Provided listener : connection.getRegisteredListeners()) {
				listener.raiseData();
			}
		}
	}
	
	public void setTimer(TimerInterface timer) {
		this.timer = timer;
	}
	
	public boolean isStateActive(String region, String state) {
		switch (region) {
			case "ConsumePower":
				return spacecraft.getConsumePower() == ConsumePower.valueOf(state);
			case "Communication":
				return spacecraft.getCommunication() == Communication.valueOf(state);
			case "Battery":
				return spacecraft.getBattery() == Battery.valueOf(state);
			case "SendData":
				return spacecraft.getSendData() == SendData.valueOf(state);
		}
		return false;
	}
	
	public long getBatteryVariable() {
		return spacecraft.getBatteryVariable();
	}
	
	public boolean getRecharging() {
		return spacecraft.getRecharging();
	}
	
	public long getData() {
		return spacecraft.getData();
	}
	
	@Override
	public String toString() {
		return spacecraft.toString();
	}
}

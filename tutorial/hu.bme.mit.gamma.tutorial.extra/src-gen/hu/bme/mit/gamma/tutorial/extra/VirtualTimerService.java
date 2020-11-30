package hu.bme.mit.gamma.tutorial.extra;

import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;

/**
 * Virtual timer service implementation.
 */
public class VirtualTimerService implements UnifiedTimerInterface {
	// Yakindu timer
	private final List<TimeEventTask> timerTaskList = new ArrayList<TimeEventTask>();
	// Gamma timer
	private Map<Object, Long> elapsedTime = new HashMap<Object, Long>();
	
	/**
	 * Timer task that reflects a time event. It's internally used by TimerService.
	 */
	private class TimeEventTask {
	
		private ITimerCallback callback;
	
		int eventID;
		
		private boolean periodic;
		private final long time;
		private long timeLeft;
	
		/**
		 * Constructor for a time event.
		 * 
		 * @param callback: Set to true if event should be repeated periodically.
		 * @param eventID: index position within the state machine's timeEvent array.
		 */
		public TimeEventTask(ITimerCallback callback, int eventID, long time, boolean isPeriodic) {
			this.callback = callback;
			this.eventID = eventID;
			this.time = time;
			this.timeLeft = time;
			this.periodic = isPeriodic;
		}
	
		public void run() {
			callback.timeElapsed(eventID);
		}
	
		public boolean equals(Object obj) {
			if (obj instanceof TimeEventTask) {
				return ((TimeEventTask) obj).callback.equals(callback)
						&& ((TimeEventTask) obj).eventID == eventID;
			}
			return super.equals(obj);
		}
		
		public void elapse(long amount) {				
			if (timeLeft <= 0) {
				return;
			}
			timeLeft -= amount;
			if (timeLeft <= 0) {
				run();
				if (periodic) {
					timeLeft = time + timeLeft;
				}
			}
		}
	}
	
	public void setTimer(ITimerCallback callback, int eventID, long time, boolean isPeriodic) {	
		// Creating a new TimerTask for given event and storing it
		TimeEventTask timerTask = new TimeEventTask(callback, eventID, time, isPeriodic);
		timerTaskList.add(timerTask);
	}
	
	public void unsetTimer(ITimerCallback callback, int eventID) {
		for (TimeEventTask timer : new ArrayList<TimeEventTask>(timerTaskList)) {
			if (timer.callback.equals(callback) && timer.eventID == eventID) {
				timerTaskList.remove(timer);
			}
		}
	}
	
	public void elapse(long amount) {
		for (TimeEventTask timer : timerTaskList) {
			timer.elapse(amount);
		}
		for (Object object : elapsedTime.keySet()) {
			elapsedTime.put(object, elapsedTime.get(object) + amount);
		}
	}
	
	public void saveTime(Object object) {
		elapsedTime.put(object, Long.valueOf(0));
	}
	
	public long getElapsedTime(Object object, TimeUnit timeUnit) {
		long elapsedTime = this.elapsedTime.get(object);
		switch (timeUnit) {
			case MILLISECOND:
				return elapsedTime;
			default:
				throw new IllegalArgumentException("Not supported time unit: " + timeUnit);
		}
	}

	public void reset() {
		timerTaskList.clear();
		elapsedTime.clear();
	}

}

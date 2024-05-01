/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.codegeneration.java.util

class VirtualTimerServiceCodeGenerator {
	
	protected final String PACKAGE_NAME
	protected final String CLASS_NAME = "VirtualTimerService"
	protected final String UNIFIED_TIMER_INTERFACE_NAME = Namings.UNIFIED_TIMER_INTERFACE
	protected final String ITIMER_CALLBACK_INTERFACE_NAME = Namings.TIMER_CALLBACK_INTERFACE
	
	new(String packageName) {
		this.PACKAGE_NAME = packageName
	}
	
	/**
	 * Creates the virtual timer class for the timings in the generated test cases.
	 */
	def createVirtualTimerClassCode() '''
		package «PACKAGE_NAME»;
		
		import java.util.List;
		import java.util.ArrayList;
		import java.util.Map;
		import java.util.HashMap;
		
		/**
		 * Virtual timer service implementation.
		 */
		public class «CLASS_NAME» implements «UNIFIED_TIMER_INTERFACE_NAME» {
			// Yakindu timer
			private final List<TimeEventTask> timerTaskList = new ArrayList<TimeEventTask>();
			// Gamma timer
			private Map<Object, Long> elapsedTime = new HashMap<Object, Long>();
			
			/**
			 * Timer task that reflects a time event. It's internally used by TimerService.
			 */
			private class TimeEventTask {
			
				private «ITIMER_CALLBACK_INTERFACE_NAME» callback;
			
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
				public TimeEventTask(«ITIMER_CALLBACK_INTERFACE_NAME» callback, int eventID, long time, boolean isPeriodic) {
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
						TimeEventTask timeEventTask = (TimeEventTask) obj;
						return timeEventTask.callback.equals(callback)
								&& timeEventTask.eventID == eventID;
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
							timeLeft = time; // And not timeLeft = time + timeLeft;
						}
					}
				}
			}
			
			public void setTimer(«ITIMER_CALLBACK_INTERFACE_NAME» callback, int eventID, long time, boolean isPeriodic) {	
				// Creating a new TimerTask for given event and storing it
				TimeEventTask timerTask = new TimeEventTask(callback, eventID, time, isPeriodic);
				timerTaskList.add(timerTask);
			}
			
			public void unsetTimer(«ITIMER_CALLBACK_INTERFACE_NAME» callback, int eventID) {
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
			
			public void elapse(long amount, TimeUnit timeUnit) {
				long adjustedAmount = amount;
				switch (timeUnit) {
					case NANOSECOND:
						// No operation;
						break;
					case MICROSECOND:
						adjustedAmount *= 1000;
						break;
					case MILLISECOND:
						adjustedAmount *= 1000000;
						break;
					case SECOND:
						adjustedAmount *= 1000000000;
						break;
					default:
						throw new IllegalArgumentException("Not supported time unit: " + timeUnit);
				}
				this.elapse(adjustedAmount);
			}
			
			public void saveTime(Object object) {
				elapsedTime.put(object, Long.valueOf(0));
			}
			
			public long getElapsedTime(Object object, TimeUnit timeUnit) {
				long elapsedTime = this.elapsedTime.get(object);
				switch (timeUnit) {
					case NANOSECOND:
						return elapsedTime;
					case MICROSECOND:
						return elapsedTime / 1000;
					case MILLISECOND:
						return elapsedTime / 1000000;
					case SECOND:
						return elapsedTime / 1000000000;
					default:
						throw new IllegalArgumentException("Not supported time unit: " + timeUnit);
				}
			}
		
			public void reset() {
				timerTaskList.clear();
				elapsedTime.clear();
			}
		
		}
	'''
	
	def getClassName() {
		return CLASS_NAME
	}
	
}

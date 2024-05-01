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

import hu.bme.mit.gamma.codegeneration.java.util.Namings

class TimerServiceCodeGenerator {
	
	protected final String PACKAGE_NAME
	protected final String YAKINDU_CLASS_NAME = Namings.YAKINDU_TIMER_CLASS
	protected final String GAMMA_CLASS_NAME = Namings.GAMMA_TIMER_CLASS
	protected final String UNIFIED_TIMER_CLASS_NAME = Namings.UNIFIED_TIMER_CLASS
	
	new(String packageName) {
		this.PACKAGE_NAME = packageName
	}
	
	def createTimerServiceClassCode() '''
		package «PACKAGE_NAME»;
		
		import java.util.ArrayList;
		import java.util.List;
		import java.util.Timer;
		import java.util.TimerTask;
		import java.util.concurrent.locks.Lock;
		import java.util.concurrent.locks.ReentrantLock;
		
		public class «YAKINDU_CLASS_NAME» implements «Namings.YAKINDU_TIMER_INTERFACE» {
		
			private final Timer timer = new Timer();
			private final List<TimeEventTask> timerTaskList = new ArrayList<TimeEventTask>();
			private final Lock lock = new ReentrantLock();
			
			/**
			 * Timer task that reflects a time event. It's internally used by
			 * {@link TimerService}.
			 *
			 */
			private class TimeEventTask extends TimerTask {
			
				private «Namings.TIMER_CALLBACK_INTERFACE» callback;
				int eventID;
			
				/**
				 * Constructor for a time event.
				 *
				 * @param callback: Object that implements ITimerCallback, is called when the timer expires.
				 * @param eventID: Index position within the state machine's timeEvent array.
				 */
				public TimeEventTask(«Namings.TIMER_CALLBACK_INTERFACE» callback, int eventID) {
					this.callback = callback;
					this.eventID = eventID;
				}
			
				public void run() {
					callback.timeElapsed(eventID);
				}
				
				@Override
				public boolean equals(Object obj) {
					if (obj instanceof TimeEventTask timeEventTask) {
						return timeEventTask.callback.equals(callback)
								&& timeEventTask.eventID == eventID;
					}
					return super.equals(obj);
				}
				
				@Override
				public int hashCode() {
					int prime = 37;
					int result = 1;
					
					int c = (int) this.eventID;
					result = prime * result + c;
					c = this.callback.hashCode();
					result = prime * result + c;
					return result;
				}
				
			}
			
			public void setTimer(«Namings.TIMER_CALLBACK_INTERFACE» callback, int eventID,
					long time, boolean isPeriodic) {
			
				// Create a new TimerTask for given event and store it.
				TimeEventTask timerTask = new TimeEventTask(callback, eventID);
				lock.lock();
				timerTaskList.add(timerTask);
			
				// start scheduling the timer
				if (isPeriodic) {
					timer.scheduleAtFixedRate(timerTask, time, time);
				} else {
					timer.schedule(timerTask, time);
				}
				lock.unlock();
			}
			
			public void unsetTimer(«Namings.TIMER_CALLBACK_INTERFACE» callback, int eventID) {
				lock.lock();
				int index = timerTaskList.indexOf(new TimeEventTask(callback, eventID));
				if (index != -1) {
					timerTaskList.get(index).cancel();
					timer.purge();
					timerTaskList.remove(index);
				}
				lock.unlock();
			}
			
			/**
			 * Cancel timer service. Use this to end possible timing threads and free
			 * memory resources.
			 */
			public void cancel() {
				lock.lock();
				timer.cancel();
				timer.purge();
				lock.unlock();
			}
			
			public void reset() {
				timerTaskList.clear();
			}
			
		}
	'''

	def createGammaTimerClassCode() '''
		package «PACKAGE_NAME»;
		
		import java.util.Map;
		import java.util.HashMap;
		
		public class «GAMMA_CLASS_NAME» implements «Namings.GAMMA_TIMER_INTERFACE» {
			
			private Map<Object, Long> elapsedTime = new HashMap<Object, Long>();
			
			public void saveTime(Object object) {
				elapsedTime.put(object, System.nanoTime());
			}
			
			public long getElapsedTime(Object object, TimeUnit timeUnit) {
				long elapsedTime = System.nanoTime() - this.elapsedTime.get(object);
				switch (timeUnit) {
					case SECOND:
						return elapsedTime / 1000000000;
					case MILLISECOND:
						return elapsedTime / 1000000;
					case MICROSECOND:
						return elapsedTime / 1000;
					case NANOSECOND:
						return elapsedTime;
					default:
						throw new IllegalArgumentException("Not known time unit: " + timeUnit);
				}
			}
			
			public void reset() {
				elapsedTime.clear();
			}
			
		}
	'''
	
	def createUnifiedTimerClassCode() '''
		package «PACKAGE_NAME»;
		
		public class «UNIFIED_TIMER_CLASS_NAME» implements «Namings.UNIFIED_TIMER_INTERFACE» {
			
			private «Namings.YAKINDU_TIMER_INTERFACE» yakinduTimer = new «Namings.YAKINDU_TIMER_CLASS»();
			private «Namings.GAMMA_TIMER_INTERFACE» gammaTimer = new «Namings.GAMMA_TIMER_CLASS»();
			
			public void setTimer(«Namings.TIMER_CALLBACK_INTERFACE» callback, int eventID, long time, boolean isPeriodic) {
				yakinduTimer.setTimer(callback, eventID, time, isPeriodic);
			}
		
			public void unsetTimer(«Namings.TIMER_CALLBACK_INTERFACE» callback, int eventID) {
				yakinduTimer.unsetTimer(callback, eventID);
			}
		
			public void saveTime(Object object) {
				gammaTimer.saveTime(object);
			}
		
			public long getElapsedTime(Object object, TimeUnit timeUnit) {
				return gammaTimer.getElapsedTime(object, timeUnit);
			}
			
		}
	'''
	
	def getYakinduClassName() {
		return YAKINDU_CLASS_NAME
	}
	
	def getGammaClassName() {
		return GAMMA_CLASS_NAME
	}
	
	def getUnifiedClassName() {
		return UNIFIED_TIMER_CLASS_NAME
	}
	
}

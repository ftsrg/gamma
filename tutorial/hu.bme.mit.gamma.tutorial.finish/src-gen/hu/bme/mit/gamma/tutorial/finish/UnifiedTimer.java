package hu.bme.mit.gamma.tutorial.finish;

public class UnifiedTimer implements UnifiedTimerInterface {
	
	private ITimer yakinduTimer = new TimerService();
	private TimerInterface gammaTimer = new OneThreadedTimer();
	
	public void setTimer(ITimerCallback callback, int eventID, long time, boolean isPeriodic) {
		yakinduTimer.setTimer(callback, eventID, time, isPeriodic);
	}

	public void unsetTimer(ITimerCallback callback, int eventID) {
		yakinduTimer.unsetTimer(callback, eventID);
	}

	public void saveTime(Object object) {
		gammaTimer.saveTime(object);
	}

	public long getElapsedTime(Object object, TimeUnit timeUnit) {
		return gammaTimer.getElapsedTime(object, timeUnit);
	}
	
}

package hu.bme.mit.jpl.spacemission;

public interface TimerInterface {
	
	void saveTime(Object object);
	long getElapsedTime(Object object, TimeUnit timeUnit);
	
	public enum TimeUnit {
		SECOND, MILLISECOND, MICROSECOND, NANOSECOND
	}
	
}

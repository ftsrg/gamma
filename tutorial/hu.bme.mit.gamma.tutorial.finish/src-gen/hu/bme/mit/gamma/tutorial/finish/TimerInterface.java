package hu.bme.mit.gamma.tutorial.finish;

public interface TimerInterface {
	
	public void saveTime(Object object);
	public long getElapsedTime(Object object, TimeUnit timeUnit);
	
	public enum TimeUnit {
		SECOND, MILLISECOND, MICROSECOND, NANOSECOND
	}
	
}

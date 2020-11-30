package hu.bme.mit.gamma.tutorial.finish;

public class Event {
	private String event;
	private Object[] value;
	
	public Event(String event) {
		this.event = event;
	}
	
	public Event(String event, Object... value) {
		this.event = event;
		this.value = value;
	}
	
	public String getEvent() {
		return event;
	}
	
	public Object[] getValue() {
		return value;
	}
}

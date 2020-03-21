package hu.bme.mit.gamma.tutorial.extra;

public interface ReflectiveComponentInterface {
	
	public void reset();
			
	public String[] getPorts();
			
	public String[] getEvents(String port);
			
	public void raiseEvent(String port, String event, Object[] parameters);
			
	public boolean isRaisedEvent(String port, String event, Object[] parameters);
	
	public void schedule(String instance);
	
	public boolean isStateActive(String region, String state);
	
	public String[] getRegions();
	
	public String[] getStates(String region);
	
	public String[] getVariables();
	
	public Object getValue(String variable);
	
	public String[] getComponents();
	
	public ReflectiveComponentInterface getComponent(String component);
	
}

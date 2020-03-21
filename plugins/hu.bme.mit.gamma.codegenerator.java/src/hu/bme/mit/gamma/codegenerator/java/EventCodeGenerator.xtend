package hu.bme.mit.gamma.codegenerator.java

class EventCodeGenerator {
	
	protected final String PACKAGE_NAME
	protected final String CLASS_NAME = Namings.GAMMA_EVENT_CLASS
	
	new(String packageName) {
		this.PACKAGE_NAME = packageName
	}
	
	protected def createEventClass() '''
		package «PACKAGE_NAME»;
		
		public class «CLASS_NAME» {
			private String event;
			private Object value;
			
			public Event(String event) {
				this.event = event;
			}
			
			public Event(String event, Object value) {
				this.event = event;
				this.value = value;
			}
			
			public String getEvent() {
				return event;
			}
			
			public Object getValue() {
				return value;
			}
		}
	'''
	
	def getClassName() {
		return CLASS_NAME
	}
	
}
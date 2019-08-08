package hu.bme.mit.gamma.codegenerator.java

class EventCodeGenerator {
	
	final String BASE_PACKAGE_NAME
	
	new(String basePackageName) {
		this.BASE_PACKAGE_NAME = basePackageName
	}
	
	protected def createEventClass() '''
		package «BASE_PACKAGE_NAME»;
		
		public class «Namings.GAMMA_EVENT_CLASS» {
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
		return Namings.GAMMA_EVENT_CLASS
	}
	
}
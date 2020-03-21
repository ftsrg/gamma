package hu.bme.mit.gamma.codegenerator.java

class TimerCallbackInterfaceGenerator {
		
	protected final String PACKAGE_NAME
	protected final String INTERFACE_NAME = Namings.TIMER_CALLBACK_INTERFACE
	
	new(String packageName) {
		this.PACKAGE_NAME = packageName
	}
	
	protected def createITimerCallbackInterfaceCode() '''
		package «PACKAGE_NAME»;
		
		public interface «INTERFACE_NAME» {
			
			void timeElapsed(int eventID);
			
		}
	'''
	
	def getInterfaceName() {
		return INTERFACE_NAME
	}
	
}

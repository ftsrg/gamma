package hu.bme.mit.gamma.codegenerator.java

class TimerInterfaceGenerator {
	
	final String PACKAGE_NAME
	
	new(String packageName) {
		this.PACKAGE_NAME = packageName
	}
	
	protected def createITimerInterfaceCode() '''
		package «PACKAGE_NAME»;
		
		public interface «Namings.YAKINDU_TIMER_INTERFACE» {
			
			void setTimer(«Namings.TIMER_CALLBACK_INTERFACE» callback, int eventID, long time, boolean isPeriodic);
			void unsetTimer(«Namings.TIMER_CALLBACK_INTERFACE» callback, int eventID);
			
		}
	'''
	
	protected def createGammaTimerInterfaceCode() '''
		package «PACKAGE_NAME»;
		
		public interface «Namings.GAMMA_TIMER_INTERFACE» {
			
			public void saveTime(Object object);
			public long getElapsedTime(Object object, TimeUnit timeUnit);
			
			public enum TimeUnit {
				SECOND, MILLISECOND, MICROSECOND, NANOSECOND
			}
			
		}
	'''
	
	protected def createUnifiedTimerInterfaceCode() '''
		package «PACKAGE_NAME»;
		
		public interface «Namings.UNIFIED_TIMER_INTERFACE» extends «Namings.YAKINDU_TIMER_INTERFACE», «Namings.GAMMA_TIMER_INTERFACE» {
			
		}
	'''
	
	def getYakinduInterfaceName() {
		return Namings.YAKINDU_TIMER_INTERFACE
	}
	
	def getGammaInterfaceName() {
		return Namings.GAMMA_TIMER_INTERFACE
	}
	
	def getUnifiedInterfaceName() {
		return Namings.UNIFIED_TIMER_INTERFACE
	}
	
}

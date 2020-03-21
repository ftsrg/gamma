package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.statechart.model.interface_.Interface

class ChannelInterfaceGenerator {
	
	protected final String PACKAGE_NAME
	//
	protected final extension NameGenerator nameGenerator
	
	new(String packageName) {
		this.PACKAGE_NAME = packageName
		this.nameGenerator = new NameGenerator(this.PACKAGE_NAME)
	}
	
	 /**
	 * Returns the Java interface code of the Channel class.
	 */
	protected def createChannelInterfaceCode(Interface _interface) '''
		package «PACKAGE_NAME».«Namings.CHANNEL_PACKAGE_POSTFIX»;
		
		import «PACKAGE_NAME».«Namings.INTERFACE_PACKAGE_POSTFIX».«_interface.generateName»;
		
		public interface «_interface.generateChannelInterfaceName» {			
			
			void registerPort(«_interface.generateName».Provided providedPort);
			
			void registerPort(«_interface.generateName».Required requiredPort);
		
		}
	'''
}
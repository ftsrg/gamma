package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.statechart.model.interface_.Interface

class ChannelCodeGenerator {
	
	protected final String PACKAGE_NAME
	//
	protected final extension NameGenerator nameGenerator
	
	new(String packageName) {
		this.PACKAGE_NAME = packageName
		this.nameGenerator = new NameGenerator(this.PACKAGE_NAME)
	}
	
	 /**
	 * Returns the Java class code of the Channel class.
	 */
	protected def createChannelClassCode(Interface _interface) '''
		package «PACKAGE_NAME».«Namings.CHANNEL_PACKAGE_POSTFIX»;
		
		import «PACKAGE_NAME».«Namings.INTERFACE_PACKAGE_POSTFIX».«_interface.generateName»;
		import java.util.List;
		import java.util.LinkedList;
		
		public class «_interface.generateChannelName» implements «_interface.generateChannelInterfaceName» {
			
			private «_interface.generateName».Provided providedPort;
			private List<«_interface.generateName».Required> requiredPorts = new LinkedList<«_interface.generateName».Required>();
			
			public «_interface.generateChannelName»() {}
			
			public «_interface.generateChannelName»(«_interface.generateName».Provided providedPort) {
				this.providedPort = providedPort;
			}
			
			public void registerPort(«_interface.generateName».Provided providedPort) {
				// Former port is forgotten
				this.providedPort = providedPort;
				// Registering the listeners
				for («_interface.generateName».Required requiredPort : requiredPorts) {
					providedPort.registerListener(requiredPort);
					requiredPort.registerListener(providedPort);
				}
			}
			
			public void registerPort(«_interface.generateName».Required requiredPort) {
				requiredPorts.add(requiredPort);
				// Checking whether a provided port is already given
				if (providedPort != null) {
					providedPort.registerListener(requiredPort);
					requiredPort.registerListener(providedPort);
				}
			}
		
		}
	'''
	
}
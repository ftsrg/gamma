package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.codegenerator.java.queries.BroadcastChannels
import hu.bme.mit.gamma.codegenerator.java.queries.SimpleChannels
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousCompositeComponent

class AsynchronousCompositeComponentCodeGenerator {
	
	final String PACKAGE_NAME
	// 
	final extension TimingDeterminer timingDeterminer = new TimingDeterminer
	final extension Trace trace
	final extension NameGenerator nameGenerator
	final extension TypeTransformer typeTransformer
	final extension ComponentCodeGenerator componentCodeGenerator
	final extension CompositeComponentCodeGenerator compositeComponentCodeGenerator

	new(String packageName, Trace trace) {
		this.PACKAGE_NAME = packageName
		this.trace = trace
		this.nameGenerator = new NameGenerator(this.PACKAGE_NAME)
		this.typeTransformer = new TypeTransformer(trace)
		this.componentCodeGenerator = new ComponentCodeGenerator(this.trace)
		this.compositeComponentCodeGenerator = new CompositeComponentCodeGenerator(this.PACKAGE_NAME, this.trace)
	}
	
	/**
	* Creates the Java code of the asynchronous composite class, containing asynchronous components.
	*/
	protected def createAsynchronousCompositeComponentClass(AsynchronousCompositeComponent component, int channelId1, int channelId2) '''
		package «component.generateComponentPackageName»;
		
		«component.generateCompositeSystemImports»
		
		public class «component.generateComponentClassName» implements «component.generatePortOwnerInterfaceName» {
			// Component instances
			«FOR instance : component.components»
				private «instance.type.generateComponentClassName» «instance.name»;
			«ENDFOR»
			// Port instances
			«FOR port : component.portBindings.map[it.compositeSystemPort]»
				private «port.name.toFirstUpper» «port.name.toFirstLower» = new «port.name.toFirstUpper»();
			«ENDFOR»
			// Channel instances
			«FOR channel : SimpleChannels.Matcher.on(engine).getAllValuesOfsimpleChannel(component, null, null)»
				private «channel.providedPort.port.interfaceRealization.interface.generateChannelInterfaceName» channel«channel.providedPort.port.name.toFirstUpper»Of«channel.providedPort.instance.name.toFirstUpper»;
			«ENDFOR»
			«FOR channel : BroadcastChannels.Matcher.on(engine).getAllValuesOfbroadcastChannel(component, null, null)»
				private «channel.providedPort.port.interfaceRealization.interface.generateChannelInterfaceName» channel«channel.providedPort.port.name.toFirstUpper»Of«channel.providedPort.instance.name.toFirstUpper»;
			«ENDFOR»
			«component.generateParameterDeclarationFields»
			
			«IF component.needTimer»
				public «component.generateComponentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", " AFTER ", "»«parameter.type.transformType» «parameter.name»«ENDFOR»«Namings.YAKINDU_TIMER_INTERFACE» timer) {
					«component.createInstances»
					setTimer(timer);
					init(); // Init is not called in setTimer like in the wrapper as it would be unnecessary
				}
			«ENDIF»
			
			public «component.generateComponentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", "»«parameter.type.transformType» «parameter.name»«ENDFOR») {
				«component.createInstances»
				init();
			}
			
			/** Resets the contained statemachines recursively. Must be called to initialize the component. */
			@Override
			public void reset() {
				«FOR instance : component.components»
					«instance.name».reset();
				«ENDFOR»
			}
			
			/** Creates the channel mappings and enters the wrapped statemachines. */
			private void init() {				
				// Registration of simple channels
				«FOR channelMatch : SimpleChannels.Matcher.on(engine).getAllMatches(component, null, null, null)»
					channel«channelMatch.providedPort.port.name.toFirstUpper»Of«channelMatch.providedPort.instance.name.toFirstUpper» = new «channelMatch.providedPort.port.interfaceRealization.interface.generateChannelName»(«channelMatch.providedPort.instance.name».get«channelMatch.providedPort.port.name.toFirstUpper»());
					channel«channelMatch.providedPort.port.name.toFirstUpper»Of«channelMatch.providedPort.instance.name.toFirstUpper».registerPort(«channelMatch.requiredPort.instance.name».get«channelMatch.requiredPort.port.name.toFirstUpper»());
				«ENDFOR»
				// Registration of broadcast channels
				«FOR channel : BroadcastChannels.Matcher.on(engine).getAllValuesOfbroadcastChannel(component, null, null)»
					channel«channel.providedPort.port.name.toFirstUpper»Of«channel.providedPort.instance.name.toFirstUpper» = new «channel.providedPort.port.interfaceRealization.interface.generateChannelName»(«channel.providedPort.instance.name».get«channel.providedPort.port.name.toFirstUpper»());
«««					Broadcast channels can have incoming messages in case of asynchronous components
					«FOR channelMatch : BroadcastChannels.Matcher.on(engine).getAllMatches(component, channel, null, null)»
						channel«channelMatch.providedPort.port.name.toFirstUpper»Of«channelMatch.providedPort.instance.name.toFirstUpper».registerPort(«channelMatch.requiredPort.instance.name».get«channelMatch.requiredPort.port.name.toFirstUpper»());
					«ENDFOR»
				«ENDFOR»
			}
			
			// Inner classes representing Ports
			«FOR portDef : component.portBindings SEPARATOR "\n"»
				public class «portDef.compositeSystemPort.name.toFirstUpper» implements «portDef.compositeSystemPort.interfaceRealization.interface.generateName».«portDef.compositeSystemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» {
				
					«portDef.delegateRaisingMethods» 
					
					«portDef.delegateOutMethods»
					
					@Override
					public void registerListener(«portDef.compositeSystemPort.interfaceRealization.interface.generateName».Listener.«portDef.compositeSystemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» listener) {
						«portDef.instancePortReference.instance.name».get«portDef.instancePortReference.port.name.toFirstUpper»().registerListener(listener);
					}
					
					@Override
					public List<«portDef.compositeSystemPort.interfaceRealization.interface.generateName».Listener.«portDef.compositeSystemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»> getRegisteredListeners() {
						return «portDef.instancePortReference.instance.name».get«portDef.instancePortReference.port.name.toFirstUpper»().getRegisteredListeners();
					}
					
				}
				
				@Override
				public «portDef.compositeSystemPort.name.toFirstUpper» get«portDef.compositeSystemPort.name.toFirstUpper»() {
					return «portDef.compositeSystemPort.name.toFirstLower»;
				}
			«ENDFOR»
			
			/** Starts the running of the asynchronous component. */
			@Override
			public void start() {
				«FOR instance : component.components»
					«instance.name».start();
				«ENDFOR»
			}
			
			public boolean isWaiting() {
				return «FOR instance : component.components SEPARATOR " && "»«instance.name».isWaiting()«ENDFOR»;
			}
			
			«IF component.needTimer»
				/** Setter for the timer e.g., a virtual timer. */
				public void setTimer(«Namings.YAKINDU_TIMER_INTERFACE» timer) {
					«FOR instance : component.components»
						«IF instance.type.needTimer»
							«instance.name».setTimer(timer);
						«ENDIF»
					«ENDFOR»
				}
			«ENDIF»
			
			/**  Getter for component instances, e.g., enabling to check their states. */
			«FOR instance : component.components SEPARATOR "\n"»
				public «instance.type.generateComponentClassName» get«instance.name.toFirstUpper»() {
					return «instance.name»;
				}
			«ENDFOR»
			
		}
	'''
	
}
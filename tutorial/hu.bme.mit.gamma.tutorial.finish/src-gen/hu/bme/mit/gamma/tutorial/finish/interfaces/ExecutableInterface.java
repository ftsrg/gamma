package hu.bme.mit.gamma.tutorial.finish.interfaces;

import java.util.List;

public interface ExecutableInterface {
	
	interface Provided extends Listener.Required {
		
		
		void registerListener(Listener.Provided listener);
		List<Listener.Provided> getRegisteredListeners();
	}
	
	interface Required extends Listener.Provided {
		
		public boolean isRaisedExecute();
		
		void registerListener(Listener.Required listener);
		List<Listener.Required> getRegisteredListeners();
	}
	
	interface Listener {
		
		interface Provided  {
		}
		
		interface Required   {
			void raiseExecute();
		}
		
	}
} 

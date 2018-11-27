package hu.bme.mit.gamma.tutorial.finish.interfaces;

import java.util.List;

public interface LightCommandsInterface {
	
	interface Provided extends Listener.Required {
		
		public boolean isRaisedDisplayRed();
		public boolean isRaisedDisplayNone();
		public boolean isRaisedDisplayYellow();
		public boolean isRaisedDisplayGreen();
		
		void registerListener(Listener.Provided listener);
		List<Listener.Provided> getRegisteredListeners();
	}
	
	interface Required extends Listener.Provided {
		
		
		void registerListener(Listener.Required listener);
		List<Listener.Required> getRegisteredListeners();
	}
	
	interface Listener {
		
		interface Provided  {
			void raiseDisplayRed();
			void raiseDisplayNone();
			void raiseDisplayYellow();
			void raiseDisplayGreen();
		}
		
		interface Required   {
		}
		
	}
} 

package hu.bme.mit.gamma.tutorial.finish.interfaces;

import java.util.List;

public interface LightCommandsInterface {
	
	interface Provided extends Listener.Required {
		
		public boolean isRaisedDisplayRed();
		public boolean isRaisedDisplayYellow();
		public boolean isRaisedDisplayGreen();
		public boolean isRaisedDisplayNone();
		
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
			void raiseDisplayYellow();
			void raiseDisplayGreen();
			void raiseDisplayNone();
		}
		
		interface Required  {
		}
		
	}
}

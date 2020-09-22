package hu.bme.mit.gamma.tutorial.extra.interfaces;

import hu.bme.mit.gamma.tutorial.extra.*;
import java.util.List;

public interface LightCommandsInterface {
	
	interface Provided extends Listener.Required {
		
		public boolean isRaisedDisplayNone();
		public boolean isRaisedDisplayYellow();
		public boolean isRaisedDisplayRed();
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
			void raiseDisplayNone();
			void raiseDisplayYellow();
			void raiseDisplayRed();
			void raiseDisplayGreen();
		}
		
		interface Required  {
		}
		
	}
}

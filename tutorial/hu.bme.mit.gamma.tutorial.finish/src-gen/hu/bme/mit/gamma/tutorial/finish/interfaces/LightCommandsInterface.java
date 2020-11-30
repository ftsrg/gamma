package hu.bme.mit.gamma.tutorial.finish.interfaces;

import hu.bme.mit.gamma.tutorial.finish.*;
import java.util.List;

public interface LightCommandsInterface {
	
	interface Provided extends Listener.Required {
		
		public boolean isRaisedDisplayGreen();
		public boolean isRaisedDisplayYellow();
		public boolean isRaisedDisplayRed();
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
			void raiseDisplayGreen();
			void raiseDisplayYellow();
			void raiseDisplayRed();
			void raiseDisplayNone();
		}
		
		interface Required  {
		}
		
	}
}

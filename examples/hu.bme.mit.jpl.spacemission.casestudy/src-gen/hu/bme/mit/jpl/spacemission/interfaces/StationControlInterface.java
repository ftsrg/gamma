package hu.bme.mit.jpl.spacemission.interfaces;

import java.util.List;

public interface StationControlInterface {
	
	interface Provided extends Listener.Required {
		
		public boolean isRaisedStart();
		public boolean isRaisedShutdown();
		
		void registerListener(Listener.Provided listener);
		List<Listener.Provided> getRegisteredListeners();
	}
	
	interface Required extends Listener.Provided {
		
		
		void registerListener(Listener.Required listener);
		List<Listener.Required> getRegisteredListeners();
	}
	
	interface Listener {
		
		interface Provided  {
			void raiseStart();
			void raiseShutdown();
		}
		
		interface Required  {
		}
		
	}
}

package hu.bme.mit.jpl.spacemission.interfaces;

import java.util.List;

public interface DataSourceInterface {

	interface Provided extends Listener.Required {
		
		boolean isRaisedData();
		
		void registerListener(Listener.Provided listener);
		List<Listener.Provided> getRegisteredListeners();
	}
	
	interface Required extends Listener.Provided {
		
		boolean isRaisedPing();
		
		void registerListener(Listener.Required listener);
		List<Listener.Required> getRegisteredListeners();
	}
	
	interface Listener {
		
		interface Provided {
			void raiseData();
		}
		
		interface Required {
			void raisePing();
		}
		
	}

}

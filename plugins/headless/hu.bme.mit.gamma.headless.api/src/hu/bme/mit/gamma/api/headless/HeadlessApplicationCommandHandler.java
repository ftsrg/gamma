package hu.bme.mit.gamma.api.headless;

import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.equinox.app.IApplicationContext;

// Abstract class for all Headless Gamma application options
public abstract class HeadlessApplicationCommandHandler {
	//
	final IApplicationContext context;
	final String[] appArgs;
	final Level level;
	//
	protected Logger logger = Logger.getLogger("GammaLogger");
	//

	public HeadlessApplicationCommandHandler(IApplicationContext context, String[] appArgs, Level level) {
		this.context = context;
		this.appArgs = appArgs;
		this.level = level;
	}

	public abstract void execute() throws Exception;
	
}

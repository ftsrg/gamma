package hu.bme.mit.gamma.api.headless;

import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.equinox.app.IApplicationContext;

// Abstract class for all Headless Gamma application options
public abstract class HeadlessApplicationCommandHandler {
	final IApplicationContext context;
	final String[] appArgs;
	protected Logger logger = Logger.getLogger("GammaLogger");
	final Level level;

	public HeadlessApplicationCommandHandler(IApplicationContext context, String[] appArgs, Level level) {
		this.context = context;
		this.appArgs = appArgs;
		this.level = level;
	}

	public void execute() throws Exception {
	}
}

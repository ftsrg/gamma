package hu.bme.mit.gamma.api.headless;

import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;

// The application that gets executed and exported as Headless Gamma
public class Application implements IApplication {

	private GammaEntryPoint gammaEntryPoint;
	private ProjectImporter projectImporter;
	private WorkspaceGenerator workspaceGenerator;
	protected Logger logger = Logger.getLogger("GammaLogger");

	@Override
	public Object start(final IApplicationContext context) throws Exception {

		final Map<?, ?> args = context.getArguments();
		final String[] appArgs = (String[]) args.get(IApplicationContext.APPLICATION_ARGS);

		Level level = Level.INFO;
		/*
		 * Checks the number of arguments, which decide the operation the Headless Gamma
		 * executes Note that these arguments are passed through the web server, not by
		 * the user, so this error should not appear, as the server always passes these
		 * arguments
		 */
		if (appArgs.length == 0) {
			logger.log(Level.WARNING,
					"Arguments must be given! Either a \"workspace\", \"import\" or \"gamma\" argument is expected.");
			return null;
		} else {
			// The second argument is the log level. This is INFO by default. This can be
			// modified through the web server. Throws and exception if the setting is
			// incorrect.
			switch (appArgs[1]) {
			case "info":
				level = Level.INFO;
				break;
			case "warning":
				level = Level.WARNING;
				break;
			case "severe":
				level = Level.SEVERE;
				break;
			case "off":
				level = Level.OFF;
				break;
			default:
				throw new IllegalArgumentException("Invalid argument for setting log level: " + appArgs[1]);
			}
			// The first argument is the operation type: creating workspace, importing
			// project or executing Gamma .ggen file
			switch (appArgs[0]) {
			case "workspace":
				workspaceGenerator = new WorkspaceGenerator(context, appArgs, level);
				workspaceGenerator.execute();
				break;
			case "import":
				projectImporter = new ProjectImporter(context, appArgs, level);
				projectImporter.execute();
				break;
			case "gamma":
				gammaEntryPoint = new GammaEntryPoint(context, appArgs, level);
				gammaEntryPoint.execute();
				break;
			}

		}

		return IApplication.EXIT_OK;
	}

	@Override
	public void stop() {

	}

}
package hu.bme.mit.gamma.api.headless;

import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;

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

		if (appArgs.length == 0) {
			logger.log(Level.WARNING,
					"Arguments must be given! Either a \"workspace\", \"import\" or \"gamma\" argument is expected.");
			return null;
		} else {

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
				level = Level.INFO;
				break;
			}

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
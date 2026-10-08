Gamma Headless Application
==========================

Run the Eclipse-based Gamma application from a terminal (or Git Bash).

GENERAL USAGE
-------------

The Eclipse launcher consumes the workspace location with `-data`. Gamma then receives its own command and command arguments.

Typical invocation:

    eclipse -data <workspace-folder> <command> <log-level> <arguments...>

Example:

    ./eclipse.exe -data ./ws gamma info ./GenmodelFile.ggen

The `<workspace-folder>` is an Eclipse workspace directory. It is selected by the `-data` launcher argument, rather than by the Gamma command itself.

COMMANDS
--------

1. help
-------

Display this help message.

Accepted forms:

    help
    -h
    --help

Example:

    ./eclipse.exe help

`help` takes no additional arguments.

If an unknown command is supplied, the application reports an invalid operation and prints the list of accepted command names.

Supported command names are:

    workspace
    import
    gamma
    session
    exit
    help

In addition, `-h` and `--help` are accepted as aliases for `help`.

2. workspace
------------

Create or initialize the Eclipse workspace selected by the `-data` argument.

Usage:

    workspace

Example:

    ./eclipse.exe -data ./ws workspace

The command obtains the Eclipse workspace associated with the `-data` directory. If the workspace does not yet exist, Eclipse creates the necessary workspace structures.

The command does not require a workspace path after `workspace`; the path is provided to Eclipse itself:

    eclipse -data <workspace-folder> workspace

A successful execution logs:

    Workspace generated successfully

3. import
----------

Import a project into the selected workspace from a ZIP archive.

Usage:

    import <log-level> <project-name>

Example:

    ./eclipse.exe -data ./ws import info MyProject

The project name is used in two ways:

1. It becomes the Eclipse project name.
2. The application looks for a ZIP archive named:

       <workspace>/MyProject.zip

Therefore, for:

    import info MyProject

the expected archive is:

    <workspace>/MyProject.zip

The archive contents are imported into the newly created project.

Existing files are overwritten during the import.

The project is created and opened in the workspace before the archive is imported.

Notes:

* The project name is required.
* The ZIP file must be located at the root of the selected workspace and must use the project name followed by `.zip`.
* The ZIP archive is read directly by the application.
* The import operation recursively processes files below the archive root.
* Additional arguments are not interpreted as named options; command-line arguments are handled positionally.

Example complete workflow:

    ./eclipse.exe -data ./ws import info ExampleProject

expects:

    ./ws/ExampleProject.zip

4. gamma
---------

Execute a Gamma generation/model-processing operation for a `.ggen` file.

Usage:

    gamma <log-level> <ggen-file> [project-descriptor]

Example:

    ./eclipse.exe -data ./ws gamma info ./GenmodelFile.ggen

With a project descriptor:

    ./eclipse.exe -data ./ws gamma info ./GenmodelFile.ggen ./projectDescriptor.json

Arguments:

    <log-level>
        Java logging level used by the headless command handler.

        Examples include the standard java.util.logging levels such as:

            SEVERE
            WARNING
            INFO
            CONFIG
            FINE
            FINER
            FINEST

        The value is parsed using java.util.logging.Level.parse(). The value is case-insensitive because it is converted to upper case before parsing.

        If the supplied value is not a valid Java logging level, the application logs a warning and falls back to:

            INFO

    <ggen-file>
        Path to the Gamma generation model (`.ggen`) file to execute.

        The path may be an absolute filesystem path or a path that can be resolved by the running application.

        The application locates the Eclipse project containing this file. A containing directory is considered a project when it contains a `.project` file.

    [project-descriptor]
        Optional path to `projectDescriptor.json`.

        When supplied and the file exists, the headless application updates its `underOperation` property to `false` after the Gamma operation completes.

Examples:

    ./eclipse.exe -data ./ws gamma info ./project/model.ggen

    ./eclipse.exe -data ./ws gamma fine ./project/model.ggen ./projectDescriptor.json

Gamma execution performs the required Gamma Xtext setup and invokes the Gamma API on the supplied generation-model file.

If the generation model is not already inside the selected Eclipse workspace, the containing project is copied into the workspace before execution.

Important:

    The command expects the `.ggen` file as the third Gamma application argument:

        gamma <log-level> <ggen-file>

    Consequently, the log level must occupy the second command-line position even when the default `INFO` level is desired.

5. session
----------

Start an interactive session in which multiple Gamma headless commands can be executed without restarting the Eclipse application.

Usage:

    session

Example:

    ./eclipse.exe -data ./ws session

When session mode starts, the application first initializes the workspace and then waits for commands on standard input.

The prompt is reported as:

    Waiting for input...

Commands entered subsequently are interpreted as Gamma commands.

Example interactive session:

    ./eclipse.exe -data ./ws session

    workspace
    import info ExampleProject
    gamma info /path/to/ExampleProject/model.ggen
    exit

Session mode is intended for callers that need to perform several operations against the same running Eclipse/Gamma process.

Behavior in session mode:

* The workspace is initialized when the session starts.
* Commands are read one line at a time from standard input.
* Arguments are separated using whitespace.
* If a command fails, the application attempts to remain in session mode and wait for the next command.
* The session ends when `exit` is entered.
* A command entered after the session starts must begin with one of the recognized command names.

The `session` keyword itself is used to start the interactive mode; it is not normally entered again while the session is already running.

6. exit
-------

Terminate an interactive `session`.

Usage:

    exit

Example:

    ./eclipse.exe -data ./ws session

    ...

    exit

Outside session mode, `exit` is accepted by the command dispatcher as a no-op/dummy operation and does not perform a substantive Gamma action.

Inside session mode, however, `exit` is the command that stops command processing and returns from the interactive loop.

LOGGING
-------

Most commands accept a Java Util Logging level as their second application argument.

General form:

    <command> <log-level> ...

For example:

    gamma info ./model.ggen
    gamma warning ./model.ggen
    gamma fine ./model.ggen

The logging level is parsed with `java.util.logging.Level.parse()`.

If the level is omitted or cannot be parsed, the application uses:

    INFO

For `gamma` and `import`, a log-level argument is effectively required by the current positional argument layout because their handlers read later arguments (`appArgs[2]`) as mandatory command data.

ECLIPSE WORKSPACE
-----------------

The workspace is specified with Eclipse's `-data` launcher option:

    eclipse -data <workspace-folder> ...

For example:

    ./eclipse.exe -data ./ws gamma info ./GenmodelFile.ggen

The headless application obtains the Eclipse workspace from this location.

The same workspace is reused for all commands executed by a session.

COMMAND SUMMARY
---------------

    help
        Show this help.

    -h
        Alias for `help`.

    --help
        Alias for `help`.

    workspace
        Create/initialize the Eclipse workspace selected by `-data`.

    import <log-level> <project-name>
        Create a project and import `<workspace>/<project-name>.zip`.

    gamma <log-level> <ggen-file> [project-descriptor]
        Execute the Gamma generation model in the specified `.ggen` file.

    session
        Start an interactive command session.

    exit
        End an interactive session.

COMMON EXAMPLES
---------------

Show help:

    ./eclipse.exe help

Initialize a workspace:

    ./eclipse.exe -data ./ws workspace

Import a project:

    ./eclipse.exe -data ./ws import info DemoProject

This expects:

    ./ws/DemoProject.zip

Run a Gamma generation model:

    ./eclipse.exe -data ./ws gamma info ./DemoProject/model.ggen

Run Gamma and update a project descriptor afterwards:

    ./eclipse.exe -data ./ws gamma info \
        ./DemoProject/model.ggen \
        ./DemoProject/projectDescriptor.json

Run with verbose logging:

    ./eclipse.exe -data ./ws gamma info ./DemoProject/model.ggen

Start an interactive session:

    ./eclipse.exe -data ./ws session

Then enter, one command per line:

    gamma info ./DemoProject/model.ggen
    exit

INVALID COMMANDS
----------------

If the first argument is not a recognized command, the application reports:

    Invalid argument for operation type: <argument>

and lists the accepted command names.

The accepted primary command names are:

    workspace
    import
    gamma
    session
    exit
    help

NOTES ABOUT ARGUMENT PARSING
----------------------------

The headless application uses positional arguments rather than GNU-style named options for its own commands.

In particular:

    gamma <log-level> <ggen-file> [project-descriptor]

is positional, as is:

    import <log-level> <project-name>

The Eclipse launcher options such as `-data` are handled separately by Eclipse.

In interactive session mode, each input line is split on whitespace. Paths containing spaces therefore require special care because the session parser does not implement shell-style quoting.

RETURN STATUS
-------------

The application normally returns an Eclipse success status.

If an exception escapes normal command execution, the headless application sets its exit code to `1`.

In session mode, an exception in an individual command does not immediately terminate the interactive session; the application attempts to continue waiting for another command.

For further information about Gamma generation itself, consult the Gamma project documentation and the documentation for the `.ggen` language.
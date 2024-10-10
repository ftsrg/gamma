# Exporting Gamma as headless Eclipse

This document describes how to export Gamma as a headless Eclipse application.

## Step 1 - Setting up the environment

The processes and steps described in this document were executed on Windows 10 and Ubuntu, version 20.04.

**Required applications**

 - Eclipse - this document uses the required plugins and Eclipse version detailed in the Gamma setup tutorial, which can be found [here](https://github.com/ftsrg/gamma). Please note that installing Gamma is also required. The installation is detailed in the aformentioned link.

**Required packages**

These packages can be installed on Ubuntu using the `apt-get install <package>` command:

 - Java 17 - `openjdk-17-jdk`, `openjdk-17-jre`,
 - SWT - `libswt-gtk*`,
 - (Optionally) Maven - `maven`.

Note that these packages are probably not required if you have functioning (buildable, with no error markers) Gamma plugins in your workspace.

## Step 2 - Importing the headless project

Import the `hu.bme.mit.gamma.headless.api` project to your workspace, which already contains the necessary Gamma plugins that you want to export.

## Step 3 - Setting the content of exported plugins

The `hu.bme.mit.gamma.headless.api` creates the headless version of Gamma. This application can be exported using the product file found in the `product` folder of the plugin, named `gamma.api.headless.product`. Make sure that the `Contents` page contains every
 - **Gamma** plugin (imported to the current workspace from the official Gamma repository), and
 - **Xtext** plugin (installed via the official update site of Xtext).
 
That is, click on the `Add` button on the right, start typing _*gamma_ and later again, _*xtext_ in the search field and make sure no plugin pops up in the *Plug-in Selection* window.

Also, make sure that every required plugin is added by clicking on the `Add Required Plug-ins` button on the right. Make sure that `org.eclipse.search` is included  as it is an Xtext dependency not declared by Xtext explicitly.

## Step 4 - Setting up the Start Levels of plugins

In the `gamma.api.headless.product` file, it must explicitly be set that the `org.apache.felix.scr` shall be started automatically, i.e., on the `Source` page of the file, you have to find the following entry in the `configurations` XML element: `<plugin id="org.apache.felix.scr" autoStart="true" startLevel="<N>" />`; add it if it is not there. Altogether, the configurations part should look something like this:

```
<configurations>
 <plugin id="org.apache.felix.scr" autoStart="true" startLevel="3" />
 <plugin id="org.eclipse.core.runtime" autoStart="true" startLevel="2" />
 <plugin id="org.eclipse.equinox.common" autoStart="true" startLevel="4" />
 <plugin id="org.eclipse.equinox.event" autoStart="true" startLevel="3" />
 <plugin id="org.eclipse.equinox.simpleconfigurator" autoStart="true" startLevel="3" />
</configurations>
```

This setup is required for the correct functioning of the Eclipse platform including fundamental capabilities, e.g., to create Eclipse workspaces (in the context of which the input models - given via the command line - are processed).

## Step 5 - Setting the target platform

Open the target platform via `Window > Preferences > Plug-in Development > Target Platform`.

We have created target platforms for Windows and Linux operating systems (see the `target-platform` folder in `hu.bme.mit.gamma.headless.api`) that can be used to properly export and run the headless version of Gamma. **We recommend using these as target platforms for the official Gamma releases.** Nevertheless, if you wish to create your *own* target platform, the necessary modifications are elaborated in the following paragraphs.

 - Create or export your current target platform by clicking on the `Share` button (inside `Window > Preferences > Plug-in Development > Target Platform`) and giving it a valid filename ending in a `.target` extension.
 - Edit the target platform by modifying its content. For *each and every* plugin, select **only** a single version, and deselect other versions (remove the tick from the box next to them). Make sure to select the version that is depended on the Gamma plugins. You can experiment with the (de)selection of the versions and reloading the emergent target platform; see if you get errors in the workspace after rebuilding Gamma.
   - Note: this probably has to be done only for the actual plugins depended on by Gamma. Nonetheless, it is safer to have a *single* version for each plugin in the target platform.
 
**If you have Gamma installed into your host Eclipse:**

Make sure to remove the Gamma plugins from the required plugin list of your target platform. You can do this by removing them from the `Content list` of the product file, or deleting the corresponding lines in the source file.

## Step 6 - Set Java compliance level

Go to `Window > Preferences > Java > Compiler` and set the `Compiler compliance level` to `17`.

## Step 7 - Exporting the product

Select the product file named `gamma.api.headless.product` to begin the exporting process. It can be found in the `product` folder inside the `hu.bme.mit.gamma.headless.api` project.

In the Overview tab, under `Product Definition`, check if the appropriate `Application` is selected for the `Product`. The application is `gamma.api.headless.application` for `hu.bme.mit.gamma.headless.api.product`.

Still in the Overview tab, under `Exporting`, select the `Eclipse Product export wizard` option. Make sure that the `Root directory` option is `eclipse`.

The `Directory` under `Destination` should be the `headless_eclipse` folder in `hu.bme.mit.gamma.headless.server`.

In the Export pop-up window, deselect the `Synchronise before exporting` and `Generate p2 repository` options.

To summarize, the selection of options in the `Exporting` tab should look like this:

 - [ ] Synchronise before exporting
 - [ ] Export source: [..]
 - [ ] Generate p2 repository
 - [x] Allow for binary cycles in target platform

Finally, select `Finish`, and the exporting process should begin.

## Notable errors

The following paragraphs include some notable errors users tend to stumble upon and the methods to resolve them. First, we suggest checking whether you have carried out the following crucial steps:

 - Make sure that the `Contents` page contains every **Gamma** and **Xtext** plugin, as well as all the required plugins (see corresponding part of Step 2).
 - Make sure that the `gamma.api.headless.product` file (on the `Source` page) sets autoStart for the `org.apache.felix.scr` plugin: `<plugin id="org.apache.felix.scr" autoStart="true" startLevel="<N>" />` (see corresponding part of Step 3).
 - Make sure that the target platform contains a *single version* of each referenced plugin (see corresponding part of Step 4).
 
If the above modifications do not solve the issue, you should move onto the following points.

**Unresolved requirement**

After exporting and running the Headless Eclipse, it is possible that an error will occur stating "*An error has occured. See the log file [...]*". After inspecting the log file, it is possible that the exported Eclipse can't resolve the module, because some bundles are missing ("*Unresolved requirement: Require-Bundle: [...]*").

To resolve this, add the missing plugin(s) to the contents of the product file, in the Contents tab.

**Application could not be found in registry**

This error can occur upon launching the headless Eclipse.

In the workspace, select the product file which was exported. Under `Product Definition`, check if the Application is corresponding to the product. After selecting the corresponding application, export again, and the headless Eclipse should run the correct application now.

Alternatively, check if all required plug-ins are listed in the `gamma.api.headless.product` product definition.

**The product's defining plug-in could not be found**

This error occurs when the `Synchronise before exporting` option remains checked when exporting. Uncheck this option, and export again.

**"Export product" has encountered a problem**

This error occurs when the `Generate p2 repository` option remains checked when exporting. Uncheck this option, and export again.

**Problems with SWT**

This problem can occur mainly in the Docker version of Gamma. The two parts that make up the headless version of Gamma, the generator and the API can run into errors with SWT in a new Linux environment. These errors prevent normal functioning.

The first notable thing about SWT is that it is platform-dependent. This means that in the product file, the platform-specific SWT plugins have to be imported (and possibly removed) according to the platform. For example, when moving from Windows to Linux, on the Content tab of the products, the Windows-specific plugins will be missing, which is indicated with an error icon. These have to be replaced with the Linux-specific plugins, which have the same name, with the operating system being a difference (instead of "*win32*", "*linux*" is in the name).

The following solutions resolved these issues:

- API
	- Adding `org.eclipse.swt.browser.chromium.gtk.linux.x86_64.source` and `org.eclipse.swt.gtk.linux.x86_64.source` (or equivalent, in the case of a 32-bit system) fixed SWT-related issues. These plugins have to be imported manually, after importing the required plugins with the `Add Required Plug-Ins` button.
	- Some SWT errors can still persist even after removing the `hu.bme.mit.gamma.dialog` project. The following steps provided solution for this problem.
	- Adding `org.eclipse.swt.browser.chromium.gtk.linux.x86_64.source` and `org.eclipse.swt.gtk.linux.x86_64.source` (or equivalent, in the case of a 32-bit system) fixed SWT-related issues. These plugins have to be imported manually, after importing the reuqired plugins with the `Add Required Plug-Ins` button.
	- In the Docker container, `libswt-gtk*` has to be installed, even with Java 17 installed in the container. This can be done with the `apt-get install libswt-gtk` command. This fixed the Docker-specific SWT errors.

**The exported plug-in jars do not contain any .class file**

Check if there is a `logs.zip` file generated next to the target root directory folder. If there is, then refer to the section `Java compiler compliance level`.

**Java compiler compliance level**

This error can occur after exporting the Headless Gamma. A `logs.zip` archive is created next to the exported plug-ins. Inside the archive, one or more (depending on the exported product) folders can be found named after exported plugins. The logs found inside these folders contain text similar to this:

```
5/10/21, 2:32:41 PM CEST 
Eclipse Compiler for Java(TM) v20210223-0522, 3.25.0, Copyright IBM Corp 2000, 2020. All rights reserved. 
Compliance level '17' is incompatible with target level '21'. A compliance level '21' or better is required
``` 

This means that the compiler compliance level is set too high. Open the Eclipse IDE, select `Window -> Preferences -> Java -> Compiler`, and under `JDK Compliance`, set the `Compiler compliance level` to 17. After this, export the products again, and the problem should be resolved.

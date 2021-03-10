# eclipse-headless-project-import-tool
Imports an eclipse project from archive file into an existing workspace

HOW TO USE:

Import this project in your eclipse IDE and extract the product using the Product Export Wizard.
You should get a headless eclipse.
Pass the workspace as -data and the project name which should be the same as the archive file name, the archive file should already be in the workspace.
Example:
eclipse -consoleLog -data C:\workspace1 project.myfirstproject

Tip:
if you want to create a new workspace just pass the -data argument with the name of the workspace you want to create and do not pass any project names.

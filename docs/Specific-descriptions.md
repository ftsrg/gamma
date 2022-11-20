## Adding a new Task type to the genmodel language
You have to add the following to the Gamma plugins:
- Find the genmodel.ecore file under `model` in `hu.bme.mit.gamma.genmodel.model` and add a new model element under `model`, which has Task or any subtypes of Task as its ESuper Type. Also add the properties and child elements you need (similarly to other elements, e.g.\ Verification)
- Regenerate the model and language plugins just like when building Gamma (preferably with the mwe2 workflows)
- Add the new element to the grammar as well: find `GenModel.xtext` in `hu.bme.mit.genmodel.language` and add your new task similarly to other tasks (as its own element and under `Task` as well)
- Open `GammaApi.java` in `hu.bme.mit.gamma.ui` and add your new task to the switch case in `public void run(String fileWorkspaceRelativePath, ResourceSetCreator resourceSetCreator, TaskHook hook)`. Also add it to the filter (`private List<Task> orderTasks(GenModel genmodel, int iteration)`) as well, so it won't be filtered out.
- Now you can start writing the functionality itself by creating a new Handler in `hu.bme.mit.gamma.ui.taskhandler` extending `TaskHandler` and implementing the proper `execute` method. Again, you can use existing classes as a reference, such as `VerificationHandler` or anything else that might be more similar to your task.

/*
 * generated by Xtext
 */
package hu.bme.mit.gamma.statechart.language.ui.wizard

import org.eclipse.jdt.core.JavaCore
import org.eclipse.xtext.ui.XtextProjectHelper
import org.eclipse.xtext.ui.util.PluginProjectFactory
import org.eclipse.xtext.ui.wizard.template.IProjectGenerator
import org.eclipse.xtext.ui.wizard.template.IProjectTemplateProvider
import org.eclipse.xtext.ui.wizard.template.ProjectTemplate
import hu.bme.mit.gamma.util.FileUtil
import org.eclipse.core.runtime.Platform
import org.eclipse.core.runtime.FileLocator
import java.nio.file.Files
import java.nio.file.Paths
import java.util.stream.Collectors
import org.eclipse.core.runtime.Path

/**
 * Create a list with all project templates to be shown in the template new project wizard.
 * 
 * Each template is able to generate one or more projects. Each project can be configured such that any number of files are included.
 */
class StatechartLanguageProjectTemplateProvider implements IProjectTemplateProvider {
	override getProjectTemplates() {
		#[new GenericStochasticGammaProject, new CrossroadGammaProject]
	}
}

@ProjectTemplate(label="Gamma Statechart Composition Modeling", icon="gamma-icon-16.png", description="<p><b>Gamma Statechart Composition Modeling</b></p>
<p>This is a wizard to create a Gamma Statechart Composition Modeling project.</p>")
final class GenericStochasticGammaProject {
	val advanced = check("Custom model name:", false)
	val advancedGroup = group("Properties")
	val name = text("Model name:", "gamma_system", advancedGroup)

	override protected updateVariables() {
		name.enabled = advanced.value
		if (!advanced.value) {
			name.value = "Model"
		}
	}

	override protected validate() {
		null
	}

	override generateProjects(IProjectGenerator generator) {
		generator.generate(new PluginProjectFactory => [
			projectName = projectInfo.projectName
			location = projectInfo.locationPath
			projectNatures += #[JavaCore.NATURE_ID, "org.eclipse.pde.PluginNature", XtextProjectHelper.NATURE_ID]
			builderIds += #[JavaCore.BUILDER_ID, XtextProjectHelper.BUILDER_ID]
			folders += "src"
			folders += "src-gen"

			addFile('''model/system/«name.toString».gcd''', '''
				package «name»
				import "interfaces"
				async «name.toString.toFirstUpper» [
					port port1 : requires EventStream
					port port2 : provides EventStream
				] {
					
				}
			''')
			addFile('''model/interfaces/interfaces.gcd''', '''
				package interfaces
				interface EventStream {
					out event newEvent
				}
				
			''')
		])
	}
}

@ProjectTemplate(label="Crossroad Example", icon="gamma-icon-16.png", description="<p><b>Crossroad Example Project</b></p>
<p>This is a wizard to create Gamma Statechart Composition Project of the Crossroad control system.</p>")
final class CrossroadGammaProject {
	override protected updateVariables() {
	}

	override protected validate() {
		null
	}

	override generateProjects(IProjectGenerator generator) {
		generator.generate(new PluginProjectFactory => [
			projectName = projectInfo.projectName
			location = projectInfo.locationPath
			projectNatures += #[JavaCore.NATURE_ID, "org.eclipse.pde.PluginNature", XtextProjectHelper.NATURE_ID]
			builderIds += #[JavaCore.BUILDER_ID, XtextProjectHelper.BUILDER_ID]
			folders += "src"
			folders += "src-gen"
			var futil = FileUtil.INSTANCE;
			var bundle = Platform.getBundle("hu.bme.mit.gamma.statechart.language.ui")
			var url_m = FileLocator.find(bundle, new Path("/resources/model"));
			var urls = Files.list(Paths.get(FileLocator.toFileURL(url_m).toURI)).collect(Collectors.toList())
			for (url : urls) {
				var file = url.toFile
				var filename = file.name
				if (file.file) {
					var contents = futil.loadString(file);
					addFile("model/" + filename, contents)
				} else {
					var urls2 = Files.list(Paths.get(FileLocator.toFileURL(file.toURL).toURI)).collect(
						Collectors.toList())
					for (url2 : urls2) {
						var file2 = url2.toFile
						var filename2 = file2.name
						if (file2.file) {
							var contents = futil.loadString(file2);
							addFile("model/" + filename + "/" + filename2, contents)
						}
					}
				}
			}
		])
	}

}

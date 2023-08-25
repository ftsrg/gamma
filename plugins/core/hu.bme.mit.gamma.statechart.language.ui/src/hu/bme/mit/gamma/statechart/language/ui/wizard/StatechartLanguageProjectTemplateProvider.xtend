/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.language.ui.wizard

import hu.bme.mit.gamma.util.FileUtil
import java.io.File
import java.nio.file.Files
import java.nio.file.Paths
import org.eclipse.core.runtime.FileLocator
import org.eclipse.core.runtime.Path
import org.eclipse.core.runtime.Platform
import org.eclipse.jdt.core.JavaCore
import org.eclipse.xtext.ui.XtextProjectHelper
import org.eclipse.xtext.ui.util.PluginProjectFactory
import org.eclipse.xtext.ui.wizard.template.IProjectGenerator
import org.eclipse.xtext.ui.wizard.template.IProjectTemplateProvider
import org.eclipse.xtext.ui.wizard.template.ProjectTemplate

/**
 * Create a list with all project templates to be shown in the template new project wizard.
 * 
 * Each template is able to generate one or more projects. Each project can be configured such that any number of files are included.
 */
class StatechartLanguageProjectTemplateProvider implements IProjectTemplateProvider {
	override getProjectTemplates() {
		#[new CrossroadGammaProject, new GenericStochasticGammaProject]
	}
}

@ProjectTemplate(label="Gamma Statechart Composition Modeling",
	icon="gamma-icon-16.png",
	description="<p><b>Gamma Statechart Composition Modeling</b></p>
<p>This is a wizard to create a Gamma Statechart Composition Modeling project.</p>")
final class GenericStochasticGammaProject {
	
	val advanced = check("Custom model name:", false)
	val advancedGroup = group("Properties")
	val name = text("Model name:", "StochasticCompositeComponent", advancedGroup)

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
		generator.generate(
			new PluginProjectFactory => [
				projectName = projectInfo.projectName
				location = projectInfo.locationPath
				projectNatures += #[JavaCore.NATURE_ID, "org.eclipse.pde.PluginNature", XtextProjectHelper.NATURE_ID]
				builderIds += #[JavaCore.BUILDER_ID, XtextProjectHelper.BUILDER_ID]
				folders += "src"
				folders += "src-gen"
	
				addFile('''model/system/«name.toString».gcd''', '''
					package «name»
					import "interfaces/Interfaces"
					async «name.toString.toFirstUpper» [
						port port1 : requires EventStream
						port port2 : provides EventStream
					] {
						
					}
				''')
				addFile('''model/interfaces/Interfaces.gcd''', '''
					package interfaces
					interface EventStream {
						out event newEvent
					}
				''')
			]
		)
	}
}

@ProjectTemplate(label="Crossroads Example",
	icon="gamma-icon-16.png",
	description="<p><b>Crossroads Example Project</b></p>
<p>This is a wizard to create a Gamma Statechart Composition Project of the Crossroads control system.</p>")
final class CrossroadGammaProject {
	
	override protected updateVariables() { }

	override protected validate() {
		return null
	}
	
	override generateProjects(IProjectGenerator generator) {
		generator.generate(
			new PluginProjectFactory => [
				projectName = projectInfo.projectName
				location = projectInfo.locationPath
				projectNatures += #[JavaCore.NATURE_ID, "org.eclipse.pde.PluginNature", XtextProjectHelper.NATURE_ID]
				builderIds += #[JavaCore.BUILDER_ID, XtextProjectHelper.BUILDER_ID]
				folders += "src"
				folders += "src-gen"
				val futil = FileUtil.INSTANCE;
				val bundle = Platform.getBundle("hu.bme.mit.gamma.statechart.language.ui")
				val url_m = FileLocator.find(bundle, new Path("/resources/model"));
				val toUri = FileLocator.toFileURL(url_m).toURI
				val urls = Files.list(Paths.get(toUri)).toList
				for (url : urls) {
					val file = url.toFile
					val filename = file.name
					if (file.file) {
						val contents = futil.loadString(file);
						addFile("model" + File.separator + filename, contents)
					} else {
						val toUrl = file.toURL
						val uri = FileLocator.toFileURL(toUrl).toURI
						val paths = Paths.get(uri)
						val urls2 = Files.list(paths).toList
						for (url2 : urls2) {
							val file2 = url2.toFile
							val filename2 = file2.name
							if (file2.file) {
								val contents = futil.loadString(file2);
								addFile("model" + File.separator + filename + File.separator + filename2, contents)
							}
						}
					}
				}
			]
		)
	}

}

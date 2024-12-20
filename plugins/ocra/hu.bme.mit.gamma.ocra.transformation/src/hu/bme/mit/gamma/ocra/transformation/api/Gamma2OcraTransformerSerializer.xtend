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
package hu.bme.mit.gamma.ocra.transformation.api

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.ocra.transformation.ModelSerializer
import hu.bme.mit.gamma.ocra.transformation.util.OcraUtil
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.nuxmv.transformation.Gamma2XstsNuxmvTransformerSerializer
import java.io.File
import java.util.List
import java.util.Map
import java.util.Set

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.ocra.transformation.NamingSerializer.*
import java.util.Scanner
import java.util.logging.Logger

class Gamma2OcraTransformerSerializer {
	//
	protected final Component component
	protected List<? extends Expression> arguments
	protected final String targetFolderUri
	protected final String fileName
	protected final Integer minSchedulingConstraint
	protected final Integer maxSchedulingConstraint
	protected final String PROXY_INSTANCE_NAME = "_"
	
	//
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension OcraUtil ocraUtil = OcraUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	protected final extension ExpressionModelFactory constraintModelFactory = ExpressionModelFactory.eINSTANCE
	//
	
	
	
	new(Component component, String targetFolderUri, String fileName) {
		this(component, #[], targetFolderUri, fileName, null, null)
	}
	
	new(Component component, List<? extends Expression> arguments,
			String targetFolderUri, String fileName, Integer minSchedulingConstraint, Integer maxSchedulingConstraint) {
		this.component = component
		this.arguments = arguments
		this.targetFolderUri = targetFolderUri
		this.fileName = fileName
		this.minSchedulingConstraint = minSchedulingConstraint
		this.maxSchedulingConstraint = maxSchedulingConstraint
	}
	
	def execute() {
		//Organize to Subfolder	
		//val subfolder = targetFolderUri + File.separator + "ocra"
		// Normal transformation
		val gammaToOcraTransformer = ModelSerializer.INSTANCE
		
		val contracts = ocraUtil.parseContractsFromFile(targetFolderUri + File.separator + "." +fileName.ocraContractsFileName)
		val ocraString = gammaToOcraTransformer.execute(component.containingPackage, contracts)
		
		//val serialize

		val ocraFile = new File(targetFolderUri + File.separator + fileName.ocraFileName)
		ocraFile.saveString(ocraString)
		createImplementationTemplates(ocraFile)
		//
		
		// SMV transformation for each component
		if (!arguments.empty) {
			val constants = statechartUtil.extractParameters(component, getConstantDeclerationNameList(arguments.size), arguments)
			val _package = component.containingPackage
			_package.constantDeclarations += constants
			_package.save
		}
		
		val statechartInstanceReferences = component.allSimpleInstanceReferences
		for (statechartInstanceReference : statechartInstanceReferences) {
			val statechartInstance = statechartInstanceReference.lastInstance
			val statechart = statechartInstance.derivedType
			val fqnInstanceName = statechartInstanceReference.customizeComponentName
			
			val originalName = statechart.name
			val name = fqnInstanceName + "_TEMP"
			val List<Expression> arguments = statechartInstance.arguments.map[evaluateExpression(it)]
			statechart.name = fqnInstanceName
						
			val transformer = new Gamma2XstsNuxmvTransformerSerializer(statechart, arguments , targetFolderUri, name, minSchedulingConstraint)
			transformer.execute()
			statechart.name = originalName
			
		}
		///
		
		//Extract and Copy SMV serializations into respective template		
		val Map<String, Set<String>> inVars = extractInVars(ocraString)
		for (entry : inVars.entrySet()) {
	    	val componentName = entry.getKey()
	    	val inVarSet = entry.getValue()
	    
	    	parseIntoTemplate(targetFolderUri, inVarSet, componentName)
		}
		deleteTempFiles(targetFolderUri)
		///
					
	}
	
	def createImplementationTemplates(File ocraFile) {
		
		//TODO add the OCRA_HOME variable to your system path
		val ocraPath = System.getenv("OCRA_HOME") + File.separator + "ocra-win64.exe"
		val parentPath = ocraFile.parent
		val commandFile = new File(parentPath + File.separator + '''.ocra-commands-«Thread.currentThread.name».cmd''')
		commandFile.deleteOnExit
		val serializedCommand = '''
			set on_failure_script_quits
			set ocra_timed 1
			ocra_check_syntax -i «ocraFile.absolutePath»
			ocra_print_implementation_template -F
			quit
		'''
		fileUtil.saveString(commandFile, serializedCommand)
		
				
		try {
			
			val ocraCommand = #[ocraPath] + #["-source", commandFile.absolutePath]
	        val process = Runtime.getRuntime().exec(ocraCommand, null, ocraFile.parentFile)
	        val successRegex = ".*" + "Success:" + ".*"
	        val failureRegex = ".*" + "Error at line " + ".*"
	        
	        processImplementationTemplateGenerationLogs(process.inputReader, process.errorReader, successRegex, failureRegex)
	    } catch (Exception e) {
	    	throw e
	    }
		
	}
	
	def List<String> getConstantDeclerationNameList(int size) {
		val constantNames = CollectionLiterals.newArrayList
	    for (i : 1..size) {
	        constantNames.add("constant" + i)
	    }
	    return constantNames
	}
	
}

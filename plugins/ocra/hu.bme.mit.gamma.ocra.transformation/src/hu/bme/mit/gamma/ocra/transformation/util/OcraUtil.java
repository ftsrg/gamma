package hu.bme.mit.gamma.ocra.transformation.util;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Scanner;
import java.util.Set;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class OcraUtil {
	
	// Singleton
	public static final OcraUtil INSTANCE = new OcraUtil();
	protected OcraUtil() {}
	
	protected final Logger logger = Logger.getLogger("GammaLogger");
	
	public Map<String, String> parseContractsFromFile(String fileUrl) {
	    Map<String, String> componentContractsMap = new HashMap<>();

	    try {
	        // Read the file content
	        List<String> lines = Files.readAllLines(Paths.get(fileUrl));

	        String currentComponent = null;
	        StringBuilder contractBuilder = null;

	        // Patterns to match the start and end of a component's contract block
	        Pattern startPattern = Pattern.compile("START_CONTRACTS_FOR\\s+(.+)");
	        Pattern endPattern = Pattern.compile("END_CONTRACTS_FOR\\s+(.+)");

	        for (String line : lines) {
	            Matcher startMatcher = startPattern.matcher(line);
	            Matcher endMatcher = endPattern.matcher(line);

	            // Detect the start of a contract block for a component
	            if (startMatcher.find()) {
	                currentComponent = startMatcher.group(1);  // Get the component name
	                contractBuilder = new StringBuilder();     // Initialize contract builder
	            } 
	            // Detect the end of a contract block for a component
	            else if (endMatcher.find() && currentComponent != null) {
	                // Add the contract block to the map without the START/END lines
	                componentContractsMap.put(currentComponent, contractBuilder.toString().trim());
	                currentComponent = null;  // Reset after the end of a component block
	                contractBuilder = null;
	            } 
	            // Continue adding lines to the contract block
	            else if (contractBuilder != null) {
	                contractBuilder.append(line).append("\n");  // Append the contract lines
	            }
	        }
	    } catch (IOException e) {
	        e.printStackTrace();
	    }

	    return componentContractsMap;
	}

    public Map<String, Set<String>> extractInVars(String input) {
        Pattern pattern = Pattern.compile("(?s)COMPONENT\\s+(\\w+)\\s+INTERFACE\\s+(.*?)(?:REFINEMENT|COMPONENT|$)");
        Matcher matcher = pattern.matcher(input);

        Map<String, Set<String>> componentValues = new HashMap<>();

        while (matcher.find()) {
            String componentName = matcher.group(1);
            String componentContent = matcher.group(2);

            Pattern inputPortPattern = Pattern.compile("INPUT\\s+PORT\\s+(\\w+)\\s*:\\s*(\\w+);");
            Matcher inputPortMatcher = inputPortPattern.matcher(componentContent);

            Pattern parameterPattern = Pattern.compile("PARAMETER\\s+(\\w+)\\s*:\\s*(\\w+);");
            Matcher parameterMatcher = parameterPattern.matcher(componentContent);

            Set<String> values = new HashSet<>();

            while (inputPortMatcher.find()) {
                String portName = inputPortMatcher.group(1);
                values.add(portName);
            }

            while (parameterMatcher.find()) {
                String paramName = parameterMatcher.group(1);
                values.add(paramName);
            }

            componentValues.computeIfAbsent(componentName, k -> new HashSet<>()).addAll(values);
        }

        return componentValues;
    }
    
    public void processImplementationTemplateGenerationLogs(BufferedReader inputReader, BufferedReader errorReader, String successRegex, String failureRegex) {
        try (Scanner resultReader = new Scanner(inputReader); Scanner errorReaderScanner = new Scanner(errorReader)) {
            while (resultReader.hasNextLine()) {
                String line = resultReader.nextLine();
                if (line.matches(successRegex)) {
                	System.out.println("Ocra: " + line);
                    return;
                }
            }
            
            resultReader.close();

            while (errorReaderScanner.hasNextLine()) {
                String line = errorReaderScanner.nextLine();
                if (line.matches(failureRegex)) {
                	System.out.println("Ocra: " + line);
                }
            }
            
            errorReaderScanner.close();
        }
    }


    public void parseIntoTemplate(String basePath, Set<String> inVars, String componentName) {
        String tempFileName = componentName + "_TEMP.smv";
        String nonTempFileName = componentName + ".smv";
        java.nio.file.Path tempFilePath = Paths.get(basePath, tempFileName);
        java.nio.file.Path nonTempFilePath = Paths.get(basePath, nonTempFileName);

        try {
        	try {
	            List<String> tempContent = Files.readAllLines(tempFilePath);
	            List<String> nonTempContent = Files.readAllLines(nonTempFilePath);
	
	            int nonTempVarIndex = -1;
	            for (int i = 0; i < nonTempContent.size(); i++) {
	                if (nonTempContent.get(i).startsWith("MODULE " + componentName)) {
	                    nonTempVarIndex = i + 1;
	                }
	            }
	
	            StringBuilder copiedContentBuilder = new StringBuilder();
	            boolean foundVar = false;
	            for (String line : tempContent) {
	                if (foundVar) {
	                    copiedContentBuilder.append(line).append("\n");
	                } else if (line.startsWith("VAR")) {
	                    copiedContentBuilder.append(line).append("\n");
	                    foundVar = true;
	                }
	            }
	
	            String[] copiedContent = copiedContentBuilder.toString().split("\n");
	
	            for (String inVar : inVars) {
	                for (int i = 0; i < copiedContent.length; i++) {
	                    if (copiedContent[i].contains(inVar)) {
	                        copiedContent[i] = "";
	                        break;
	                    }
	                }
	            }
	
	            nonTempContent.subList(nonTempVarIndex, nonTempContent.size()).clear();
	            for (String content : copiedContent) {
	                nonTempContent.add(nonTempVarIndex++, content);
	            }
	
	            Files.write(nonTempFilePath, nonTempContent);
        	} catch (NoSuchFileException e) {
        		System.out.println("No Temp file found on path: " + tempFilePath.toString());
    		}
        } catch (IOException e) {
            e.printStackTrace();
        } 
    }

    public void deleteTempFiles(String folderPath) {
        File folder = new File(folderPath);
		if (folder.exists() && folder.isDirectory()) {
		    File[] files = folder.listFiles();
		    if (files != null) {
		        for (File file : files) {
		            if (file.isFile() && file.getName().contains("_TEMP")) {
		                file.delete();
		                System.out.println("Deleted temp file: " + file.getName());
		            }
		        }
		    }
		} else {
			System.out.println("Folder does not exist or is not a directory: " + folderPath);
		}
    }
    
}

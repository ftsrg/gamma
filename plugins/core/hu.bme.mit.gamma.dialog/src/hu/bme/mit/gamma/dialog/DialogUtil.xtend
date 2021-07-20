/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.dialog

import org.eclipse.core.runtime.IStatus
import org.eclipse.core.runtime.MultiStatus
import org.eclipse.core.runtime.Status
import org.eclipse.jface.dialogs.ErrorDialog
import org.eclipse.jface.dialogs.MessageDialog
import org.eclipse.swt.widgets.Display
import org.eclipse.swt.widgets.Shell
import org.eclipse.ui.PlatformUI

class DialogUtil {
	
	static boolean toShow = true

	private enum Severity {
		WARNING,
		INFO,
		ERROR,
		EXCEPTION
	}

	static val PLUGIN_ID = '''hu.bme.mit.gamma.dialog'''
	static val TITLE = '''Gamma'''

	static def void showError(String message) {
		if (toShow) {
			return
		}
		showDialog(Severity.ERROR, message, null)
	}

	static def void showWarning(String message) {
		showDialog(Severity.WARNING, message, null)
	}

	static def void showInfo(String message) {
		showDialog(Severity.INFO, message, null)
	}

	static def void showErrorWithStackTrace(String message, Throwable exception) {
		val Status[] statuses = exception.stackTrace.fold(newArrayList, [ accumulator, actual |
			val status = new Status(IStatus.ERROR, PLUGIN_ID, actual.toString)
			accumulator.add(status)
			accumulator
		])
		val multiStatus = new MultiStatus(PLUGIN_ID, IStatus.ERROR, statuses, exception.toString, exception)
		showDialog(Severity.EXCEPTION, message, multiStatus)
	}

	private static def void showDialog(Severity severity, String message, IStatus status) {
		// A dialog is shown only if graphical dialogs are permitted
		if (!toShow) {
			return
		}
		val Runnable dialog = switch (severity) {
			case INFO: [MessageDialog.openInformation(activeShell, TITLE, message)]
			case WARNING: [MessageDialog.openWarning(activeShell, TITLE, message)]
			case ERROR: [MessageDialog.openError(activeShell, TITLE, message)]
			case EXCEPTION: [ErrorDialog.openError(activeShell, TITLE, message, status)]
		}
		Display.^default.asyncExec(dialog)
	}
	
	private static def Shell getActiveShell() {
		PlatformUI.workbench.display.activeShell
	}
	
}

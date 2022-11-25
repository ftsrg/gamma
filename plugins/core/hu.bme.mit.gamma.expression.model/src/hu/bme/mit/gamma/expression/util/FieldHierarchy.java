/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.expression.util;

import java.util.ArrayList;
import java.util.List;

import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.FieldDeclaration;

public class FieldHierarchy {
	//
	protected final ComplexTypeUtil util = ComplexTypeUtil.INSTANCE;
	//
	private List<FieldDeclaration> fields = new ArrayList<FieldDeclaration>();
	//
	
	public FieldHierarchy(FieldHierarchy fields) {
		this.fields.addAll(fields.getFields());
	}
	
	public FieldHierarchy(List<FieldDeclaration> fields) {
		this.fields.addAll(fields);
	}
	
	public FieldHierarchy(FieldDeclaration field) {
		this.fields.add(field);
	}
	
	public FieldHierarchy() {}
	
	//
	
	public List<FieldDeclaration> getFields() {
		return fields;
	}
	
	public void prepend(FieldDeclaration field) {
		fields.add(0, field);
	}
	
	public void prepend(FieldHierarchy fieldHierarchy) {
		fields.addAll(0, fieldHierarchy.getFields());
	}
	
	public void add(FieldDeclaration field) {
		fields.add(field);
	}
	
	public void add(List<FieldDeclaration> fields) {
		fields.addAll(fields);
	}
	
	public void add(FieldHierarchy fieldHierarchy) {
		fields.addAll(fieldHierarchy.getFields());
	}
	
	public FieldDeclaration getFirst() {
		return fields.get(0);
	}
	
	public FieldDeclaration getLast() {
		int size = fields.size();
		return fields.get(size - 1);
	}
	
	public boolean isEmpty() {
		return fields.isEmpty();
	}
	
	public FieldDeclaration removeFirst() {
		return fields.remove(0);
	}
	
	public List<FieldHierarchy> getExtensions(Declaration declaration) {
		if (fields.isEmpty()) {
			// If this is empty, we return all field hierarchies
			return util.getFieldHierarchies(declaration);
		}
		// Otherwise we return the extensions
		return this.getExtensions();
	}

	public List<FieldHierarchy> getExtensions() {
		if (fields.isEmpty()) {
			return List.of(this);
		}
		// Possible hierarchies: a.b.c and a.b.d
		// This: a.b
		FieldDeclaration last = getLast(); // b
		List<FieldHierarchy> extensions = util.getFieldHierarchies(last); // c and d
		for (FieldHierarchy extension : extensions) {
			extension.prepend(this);
		}
		// a.b.c and a.b.d
		return extensions;
	}
	
	public FieldHierarchy clone() {
		return new FieldHierarchy(this);
	}
	
	public FieldHierarchy cloneAndRemoveFirst() {
		FieldHierarchy fieldHierarchy = clone();
		fieldHierarchy.removeFirst();
		return fieldHierarchy;
	}
	
	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((fields == null) ? 0 : fields.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj) {
			return true;
		}
		if (obj == null) {
			return false;
		}
		if (getClass() != obj.getClass()) {
			return false;
		}
		FieldHierarchy other = (FieldHierarchy) obj;
		if (fields == null) {
			if (other.fields != null) {
				return false;
			}
		}
		else if (!fields.equals(other.fields)) {
			return false;
		}
		return true;
	}
	
}

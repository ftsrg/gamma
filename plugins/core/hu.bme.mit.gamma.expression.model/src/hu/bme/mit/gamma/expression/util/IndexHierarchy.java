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

public class IndexHierarchy {
	//
	private List<Integer> indexes = new ArrayList<Integer>();
	//
	
	public IndexHierarchy(IndexHierarchy indexHierarchy) {
		this.indexes.addAll(indexHierarchy.getIndexes());
	}
	
	public IndexHierarchy(List<Integer> indexes) {
		this.indexes.addAll(indexes);
	}
	
	public IndexHierarchy(Integer indexes) {
		this.indexes.add(indexes);
	}
	
	public IndexHierarchy() {}
	
	//
	
	public List<Integer> getIndexes() {
		return indexes;
	}
	
	public int getSize() {
		return indexes.size();
	}
	
	public void prepend(Integer index) {
		indexes.add(0, index);
	}
	
	public void prepend(IndexHierarchy indexHierarchy) {
		indexes.addAll(0, indexHierarchy.getIndexes());
	}
	
	public void add(Integer field) {
		indexes.add(field);
	}
	
	public void add(List<Integer> fields) {
		indexes.addAll(fields);
	}
	
	public void add(IndexHierarchy indexHierarchy) {
		indexes.addAll(indexHierarchy.getIndexes());
	}
	
	public Integer getFirst() {
		return indexes.get(0);
	}
	
	public Integer getLast() {
		int size = indexes.size();
		return indexes.get(size - 1);
	}
	
	public boolean isEmpty() {
		return indexes.isEmpty();
	}
	
	public Integer removeFirst() {
		return indexes.remove(0);
	}
	
	public void removeFirstIfNotEmpty() {
		if (!isEmpty()) {
			removeFirst();
		}
	}
	
	public IndexHierarchy clone() {
		return new IndexHierarchy(this);
	}
	
	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((indexes == null) ? 0 : indexes.hashCode());
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
		IndexHierarchy other = (IndexHierarchy) obj;
		if (indexes == null) {
			if (other.indexes != null) {
				return false;
			}
		}
		else if (!indexes.equals(other.indexes)) {
			return false;
		}
		return true;
	}
}

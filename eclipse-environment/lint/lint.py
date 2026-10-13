#!/usr/bin/env python3
"""Detects Oomph .setup elements that EMF silently drops (wrong feature name)."""
import re, subprocess, sys, tempfile, os, collections
import xml.etree.ElementTree as ET
HERE = os.path.dirname(os.path.abspath(__file__))
BUILD = os.path.join(HERE, ".build")
CP = open(os.path.join(BUILD, "cp.txt")).read().strip()

def tags(path):
    c = collections.Counter()
    for el in ET.parse(path).getroot().iter():
        c[el.tag.split('}')[-1]] += 1
    return c

def lint(path):
    src = open(path, encoding='utf-8').read()
    # RepositoryPredicate.project resolves a live workspace IProject; unresolvable headlessly.
    stripped = re.sub(r'(<(?:predicate|operand)\b[^>]*?)\s+project="[^"]*"', r'\1', src)
    with tempfile.TemporaryDirectory() as d:
        a, b = os.path.join(d, "in.setup"), os.path.join(d, "out.setup")
        open(a, 'w', encoding='utf-8').write(stripped)
        p = subprocess.run(["java", "-cp", CP + ":" + BUILD, "Roundtrip", a, b],
                           capture_output=True, text=True)
        if p.returncode != 0:
            print(f"FAIL  {path}\n        load error: {p.stderr.strip().splitlines()[0]}")
            return 1
        before, after = tags(a), tags(b)
        lost = {t: before[t] - after.get(t, 0) for t in before if before[t] > after.get(t, 0)}
        if not lost:
            print(f"OK    {path}")
            return 0
        print(f"FAIL  {path}")
        for t, n in sorted(lost.items()):
            for m in re.finditer(r'<%s[ />]' % re.escape(t), stripped):
                print(f"        line {stripped[:m.start()].count(chr(10))+1}: <{t}> dropped on load "
                      f"- not a feature of its container (check singular/plural)")
            print(f"        ({n}x total)")
        return 1

sys.exit(sum(lint(f) for f in sys.argv[1:]))

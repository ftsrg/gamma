# Oomph setup model lint

Validates `*.setup` models against the real, generated Oomph EPackages.

```
./validate-setup.sh ../hu.bme.mit.gamma.oomph/gamma.setup
P2_POOL=/path/to/eclipse/plugins ./validate-setup.sh <file.setup> ...
```

Exit code is non-zero if any file fails.

## Why this exists

XML well-formedness is not enough, and neither is "does Oomph load it". Oomph
renames plural features to singular XML element names through `extendedMetaData`
(`setupTasks` -> `setupTask`, `excludedPaths` -> `excludedPath`), and its resource
implementation ignores unrecognised elements *silently*. A misnamed element is
therefore dropped on load with no error anywhere — the setup still runs, it just
quietly does less than it says.

That is not hypothetical: a `<excludedPaths>` element (correct name:
`<excludedPath>`) would disable a source locator's exclusions, pulling the
deprecated Yakindu plugins into the targlet. Those require `org.yakindu.*`
bundles that are in none of the repository lists, so the failure would surface
much later as an unrelated-looking target platform resolution error.

The check loads each file with the generated packages registered, writes it
straight back out, and reports any element that did not survive the round trip.

## Requirements

Java 21 and Python 3, plus an Eclipse p2 plugin pool to source the Oomph and EMF
jars from — `~/.p2/pool/plugins` by default, overridable with `P2_POOL`. Every
`org.eclipse.oomph.*` bundle found in the pool is added automatically;
`bundles.txt` lists the additional platform bundles needed at class-init time.

## Known limitation

`RepositoryPredicate.project` resolves a live workspace `IProject`, which cannot
be done outside a running Eclipse. Those attributes are stripped before loading,
so they are not validated.

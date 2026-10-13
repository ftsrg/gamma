#!/usr/bin/env bash
#
# Runs the MWE2 code generation a clean checkout needs before it can compile.
# Neither src-gen nor xtend-gen is in version control (each such directory has a
# .gitignore that excludes everything but itself), so without this there is
# nothing for the compiler to work on.
#
#   ./generate.sh              clean, then generate metamodels and languages
#   ./generate.sh --no-clean   generate without emptying src-gen first
#
# This stops short of the Xtend sources: compiling the 962 .xtend files needs
# the full target platform, which only Tycho can assemble, so that belongs to
# the Maven build. The split is:
#
#   generate.sh  ->  src-gen     (EMF metamodels + Xtext languages)
#   mvn          ->  xtend-gen, Java compilation, packaging
#
# Consequently this needs no Eclipse installation and no target platform: a
# plain JDK and Maven are enough, which is what the build container will have.
set -euo pipefail

PLUGINS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP="$PLUGINS/setup/hu.bme.mit.gamma.setup"
POM="$PLUGINS/setup/generator-pom.xml"
BUILD="$PLUGINS/setup/target"
CP_FILE="$BUILD/generator-classpath.txt"
MODEL_CLASSES="$BUILD/model-classes"
MVN="$PLUGINS/mvnw"
LAUNCHER=org.eclipse.emf.mwe2.launch.runtime.Mwe2Launcher

CLEAN=true
[ "${1:-}" = "--no-clean" ] && CLEAN=false
[ -d "$SETUP" ] || { echo "setup project not found: $SETUP" >&2; exit 2; }

# Generator classpath comes from Maven Central via generator-pom.xml. Cached,
# because resolving it takes longer than the generation itself.
#
# The cache also has to be discarded when it points somewhere that does not
# exist: target/ lives inside the source tree, so a build container mounting
# that tree inherits a classpath full of the host's absolute paths.
cp_is_usable() {
  [ -f "$CP_FILE" ] || return 1
  [ "$POM" -nt "$CP_FILE" ] && return 1
  local first
  first="$(cut -d: -f1 < "$CP_FILE")"
  [ -n "$first" ] && [ -e "$first" ]
}

if ! cp_is_usable; then
  echo "==> resolving generator classpath"
  "$MVN" -B -q -f "$POM" dependency:build-classpath -Dmdep.outputFile="$CP_FILE"
fi
CP="$(cat "$CP_FILE")"

# The workflows resolve their paths as "../.." relative to the working
# directory, exactly as the .launch files in the language projects do, so this
# has to run from the setup project. src/ is on the classpath because
# Mwe2Launcher loads the .mwe2 modules as classpath resources.
cd "$SETUP"

run() {
  local module="$1"; shift
  echo "==> $module"
  java -Xmx2g -cp "$*:src" "$LAUNCHER" "$module" || { echo "FAILED in $module" >&2; exit 1; }
}

$CLEAN && run hu.bme.mit.gamma.setup.CleanAll "$CP"
run hu.bme.mit.gamma.setup.GenerateAllModels "$CP"

# The Xtext language generators need the metamodels as *compiled* EPackage
# classes, not just as .genmodel files, so the EMF code generated above has to
# be compiled first. Only src-gen is compiled: the handwritten src of those
# projects pulls in hu.bme.mit.gamma.util, which is Xtend and therefore not
# available this early. The generated EMF code needs nothing beyond EMF itself.
echo "==> compiling generated metamodel code"
rm -rf "$MODEL_CLASSES"; mkdir -p "$MODEL_CLASSES"
# Only the projects that own a .genmodel: their src-gen is pure EMF output and
# compiles against EMF alone. Compiling every src-gen instead would drag in
# whatever earlier runs left behind - the Xtext .ui content assist classes, for
# one - which need bundles this classpath deliberately does not have.
SOURCES="$BUILD/model-sources.txt"
: > "$SOURCES"
find "$PLUGINS" -path '*/model/*.genmodel' -not -path '*/target/*' -not -path '*/bin/*' \
  | sed 's|/model/[^/]*\.genmodel$||' | sort -u \
  | while read -r project; do
      find "$project/src-gen" -name '*.java' 2>/dev/null >> "$SOURCES"
    done
javac -nowarn -proc:none -encoding UTF-8 -d "$MODEL_CLASSES" -cp "$CP" "@$SOURCES"

# Grammar inheritance is resolved off the classpath, so every project holding an
# .xtext file contributes its source folder; without them a grammar that extends
# another - ActionLanguage extends ExpressionLanguage - cannot resolve its
# inherited rules.
# bin/ is excluded deliberately: Eclipse copies sources there, so a working
# copy carries a second .xtext and a second .mwe2 of everything. Those copies
# have no /src/ in their path, so the substitution below would leave the file
# path itself on the classpath, and the duplicate .mwe2 modules make MWE2 fail
# with "a different resource with the URI ... was already registered".
# The substitution is greedy on purpose, so it cuts at the *last* /src/ in the
# path. A non-greedy \(/src\)/.* cuts at the first one, which is the project
# source folder on a developer machine but the mount point itself when the tree
# is mounted at /src in a container - putting the whole tree on the classpath
# and making every .mwe2 reachable twice.
GRAMMAR_DIRS=$(find "$PLUGINS" -name '*.xtext' -not -path '*/target/*' -not -path '*/bin/*' \
  | sed 's|\(.*\)/src/.*|\1/src|' | sort -u | tr '\n' ':' | sed 's|:$||')

# GenerateAllLanguagesStandalone rather than GenerateAllLanguages: see the
# comment in that workflow for why the IDE variant cannot run outside Eclipse.
run hu.bme.mit.gamma.setup.GenerateAllLanguagesStandalone "$CP:$MODEL_CLASSES:$GRAMMAR_DIRS"

echo "==> generation finished"

#!/usr/bin/env python3
"""Write the .target file described by a targlet's TargetDefinitionGenerator annotation.

Oomph's own generator only runs when a targlet container update emits *both* a
ProfileUpdateSucceededEvent and a WorkspaceUpdateFinishedEvent. The second comes
from WorkspaceIUImporter, which stays quiet once every project is already in the
workspace, so a targlet that resolves cleanly on an established workspace never
writes its file. This reads the same annotation and the same resolved p2 profile
and writes the same output, without depending on those events.

Usage:
    ./generate-target.py --workspace ~/eclipse/gamma-test/ws [--output FILE] [--dry-run]
"""
import argparse, glob, gzip, os, re, sys, xml.etree.ElementTree as ET

ANNOTATION = "http://www.eclipse.org/oomph/targlets/TargetDefinitionGenerator"
WORKSPACE_PROP = "org.eclipse.oomph.targlet.workspace"
SYNTHETIC = re.compile(r"^(a\.jre|config\.a\.jre|toolingorg|toolingjre)")


def active_target(workspace):
    prefs = os.path.join(workspace, ".metadata/.plugins/org.eclipse.core.runtime/"
                                    ".settings/org.eclipse.pde.core.prefs")
    handle = ""
    for line in open(prefs, encoding="utf-8"):
        if line.startswith("workspace_target_handle="):
            handle = line.split("=", 1)[1].strip().replace("\\:", ":")
    if handle.startswith("local:"):
        return os.path.join(workspace, ".metadata/.plugins/org.eclipse.pde.core/"
                                       ".local_targets", handle[len("local:"):])
    if handle.startswith("resource:"):
        return os.path.join(workspace, handle[len("resource:"):].lstrip("/"))
    sys.exit(f"unsupported target handle: {handle or '(none)'}")


def read_targlet(target_file):
    """Pull the generator settings and the active repository list out of the targlet."""
    root = ET.parse(target_file).getroot()
    tg = root.find(".//{*}targlet")
    if tg is None:
        tg = root.find(".//targlet")
    if tg is None:
        sys.exit(f"no targlet in {target_file} - is the active target a Targlet container?")
    ann = next((a for a in tg.findall("annotation") if a.get("source") == ANNOTATION), None)
    if ann is None:
        sys.exit("the targlet carries no TargetDefinitionGenerator annotation")
    details = {}
    for d in ann.findall("detail"):
        v = d.find("value")
        details[d.get("key")] = (v.text if v is not None else d.get("value") or "").strip()
    active = tg.get("activeRepositoryList")
    repos = []
    for rl in tg.findall("repositoryList"):
        if rl.get("name") == active:
            repos = [r.get("url") for r in rl.findall("repository")]
    return details, repos


def newest_profile(workspace):
    reg = os.path.expanduser("~/.p2/org.eclipse.equinox.p2.engine/profileRegistry")
    tag = os.path.abspath(workspace).replace("/", "_")
    cands = glob.glob(os.path.join(reg, f"{tag}-*.profile", "*.profile.gz"))
    # Skip the tiny stubs p2 writes before a resolution completes, then take the newest.
    real = [c for c in cands if os.path.getsize(c) > 10240]
    if not real:
        sys.exit(f"no resolved targlet profile found for workspace {workspace}")
    return max(real, key=os.path.getmtime)


def units(profile_gz, include_source):
    with gzip.open(profile_gz, "rt", encoding="utf-8") as f:
        root = ET.parse(f).getroot()
    out = {}
    for u in root.iter("unit"):
        uid, ver = u.get("id"), u.get("version")
        if not uid or SYNTHETIC.match(uid):
            continue
        props = {p.get("name"): p.get("value") for p in u.iter("property")}
        if props.get(WORKSPACE_PROP) == "true":       # comes from the workspace, not the target
            continue
        if not include_source and (uid.endswith(".source") or uid.endswith(".source.feature.group")):
            continue
        out[uid] = ver
    return dict(sorted(out.items()))


def render(name, repos, ius, generate_versions):
    x = ['<?xml version="1.0" encoding="UTF-8" standalone="no"?>', '<?pde version="3.8"?>',
         f'<target name="{name}">', '  <locations>',
         '    <location includeAllPlatforms="false" includeConfigurePhase="false"'
         ' includeMode="planner" includeSource="false" type="InstallableUnit">']
    for uid, ver in ius.items():
        x.append(f'      <unit id="{uid}" version="{ver if generate_versions else "0.0.0"}"/>')
    for url in repos:
        x.append(f'      <repository location="{url}"/>')
    x += ['    </location>', '  </locations>',
          '  <environment>', '    <arch>x86_64</arch>', '    <os>linux</os>',
          '    <ws>gtk</ws>', '    <nl>en</nl>', '  </environment>', '</target>', '']
    return "\n".join(x)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--workspace", required=True)
    ap.add_argument("--output")
    ap.add_argument("--profile")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    ws = os.path.expanduser(a.workspace)

    tf = active_target(ws)
    details, repos = read_targlet(tf)
    out = a.output or details.get("location")
    if not out:
        sys.exit("no output path: pass --output or set the annotation's location detail")
    prof = a.profile or newest_profile(ws)
    ius = units(prof, details.get("includeSource", "false") == "true")
    text = render(details.get("name", "Generated Target"), repos, ius,
                  details.get("generateVersions", "false") == "true")

    print(f"active target : {tf}")
    print(f"profile       : {prof}")
    print(f"repositories  : {len(repos)}")
    print(f"units         : {len(ius)}")
    print(f"output        : {out}")
    if a.dry_run:
        print("(dry run, nothing written)")
        return
    os.makedirs(os.path.dirname(out), exist_ok=True)
    open(out, "w", encoding="utf-8").write(text)
    print("written")


if __name__ == "__main__":
    main()

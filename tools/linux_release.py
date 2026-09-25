"""Build and package the Linux release on Windows or Linux (Python standard library)."""
import argparse
import hashlib
import json
import re
import subprocess
import tarfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION = re.search(r'config/version="([0-9.]+)"', (ROOT / "project.godot").read_text()).group(1)
NAME = f"PuttAndPixel-{VERSION}-linux-x64"
PACKAGE = ROOT / "build/releases" / NAME
LOGS = ROOT / "tmp" / f"release-{VERSION}-linux"
FILES = ["PuttAndPixel.x86_64", "SPIELSTART.txt", "NEUERUNGEN.txt", "BAHNEDITOR.md",
         "UEBUNG.md", "GODOT-LIZENZEN.txt", "BUILD.json", "PRUEFBERICHT.txt"]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def run_logged(args, name):
    with (LOGS / name).open("w", encoding="utf-8") as log:
        subprocess.run(args, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, check=True)
    text = (LOGS / name).read_text(encoding="utf-8")
    if "SCRIPT ERROR" in text or "Parse Error" in text:
        raise RuntimeError(f"Script error in {name}")


def build(engine):
    PACKAGE.mkdir(parents=True, exist_ok=True)
    LOGS.mkdir(parents=True, exist_ok=True)
    binary = PACKAGE / FILES[0]
    run_logged([engine, "--headless", "--path", str(ROOT), "--export-release",
                "Linux x64", str(binary)], "export.log")
    if binary.read_bytes()[:6] != b"\x7fELF\x02\x01":
        raise RuntimeError("Expected a little-endian 64-bit ELF executable")
    binary.chmod(0o755)
    for source, target in [("release/SPIELSTART_LINUX.txt", "SPIELSTART.txt"),
                           ("release/NEUERUNGEN.txt", "NEUERUNGEN.txt"),
                           ("BAHNEDITOR.md", "BAHNEDITOR.md"), ("UEBUNG.md", "UEBUNG.md")]:
        text = (ROOT / source).read_text(encoding="utf-8")
        if target == "NEUERUNGEN.txt":
            text = text.replace("Eigenstaendiger Windows-x64-Build", "Eigenstaendiger Linux-x64-Build")
        (PACKAGE / target).write_text(text, encoding="utf-8", newline="\n")
    run_logged([engine, "--headless", "--path", str(ROOT), "--script",
                "res://tools/release_licenses.gd", "--", str(PACKAGE / "GODOT-LIZENZEN.txt")], "licenses.log")
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    dirty = bool(subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT, text=True).strip())
    (PACKAGE / "BUILD.json").write_text(json.dumps(dict(version=VERSION, platform="Linux x64",
        configuration="release", source_commit=commit, source_dirty=dirty,
        created_utc=datetime.now(timezone.utc).isoformat()), indent=2) + "\n", encoding="utf-8")
    print(f"Linux build: {binary}")


def package():
    for name in FILES:
        if not (PACKAGE / name).is_file():
            raise RuntimeError(f"Missing package file: {name}")
    if digest(PACKAGE / FILES[0]) not in (PACKAGE / "PRUEFBERICHT.txt").read_text(encoding="utf-8"):
        raise RuntimeError("Test report does not match this executable")
    if any(p.name not in FILES + ["SHA256SUMS.txt"] or not p.is_file() for p in PACKAGE.iterdir()):
        raise RuntimeError("Unexpected package contents")
    (PACKAGE / "SHA256SUMS.txt").write_text("".join(f"{digest(PACKAGE / n)}  {n}\n" for n in FILES), encoding="ascii")
    archive = PACKAGE.parent / (NAME + ".tar.gz")
    with tarfile.open(archive, "w:gz") as tar:
        for name in FILES + ["SHA256SUMS.txt"]:
            path = PACKAGE / name
            info = tar.gettarinfo(str(path), arcname=f"{NAME}/{name}")
            info.mode = 0o755 if name == FILES[0] else 0o644
            info.uid = info.gid = 0
            info.uname = info.gname = ""
            with path.open("rb") as stream:
                tar.addfile(info, stream)
    archive.with_name(archive.name + ".sha256").write_text(f"{digest(archive)}  {archive.name}\n", encoding="ascii")
    with tarfile.open(archive) as tar:
        for name in FILES:
            member = tar.getmember(f"{NAME}/{name}")
            if hashlib.sha256(tar.extractfile(member).read()).hexdigest().upper() != digest(PACKAGE / name):
                raise RuntimeError(f"Archive checksum mismatch: {name}")
            if name == FILES[0] and member.mode != 0o755:
                raise RuntimeError("Executable permission missing")
    print(f"Verified archive: {archive}\nSHA256: {digest(archive)}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["build", "package"])
    parser.add_argument("--engine")
    args = parser.parse_args()
    if args.action == "build":
        if not args.engine:
            parser.error("build requires --engine")
        build(str(Path(args.engine).resolve()))
    else:
        package()

#!/usr/bin/env python3
"""Manifest resolver and compatibility gate for pg-financial-stack."""

from __future__ import annotations

import argparse
import datetime as dt
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tomllib

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "stack" / "extensions.toml"
LOCK = ROOT / "stack" / "versions.lock"
CACHE = ROOT / ".stack" / "extensions"


class StackError(RuntimeError):
    pass


def run(*args: str, cwd: Path | None = None, capture: bool = False) -> str:
    result = subprocess.run(
        args, cwd=cwd, text=True, check=False,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )
    if result.returncode:
        detail = (result.stderr or result.stdout or "").strip()
        raise StackError(f"command failed ({' '.join(args)}): {detail}")
    return (result.stdout or "").strip()


def load(path: Path = MANIFEST) -> dict:
    with path.open("rb") as handle:
        return tomllib.load(handle)


def env_key(name: str, suffix: str) -> str:
    return f"PG_STACK_{name.upper()}_{suffix}"


def cargo_metadata(path: Path) -> tuple[str, str | None, set[int]]:
    cargo = path / "Cargo.toml"
    if not cargo.is_file():
        raise StackError(f"{path} has no Cargo.toml")
    data = load(cargo)
    package = data.get("package", {})
    dependencies = data.get("dependencies", {})
    pgrx = dependencies.get("pgrx", {})
    pgrx_version = pgrx if isinstance(pgrx, str) else pgrx.get("version")
    features = data.get("features", {})
    majors = {int(match.group(1)) for key in features for match in [re.fullmatch(r"pg(\d+)", key)] if match}
    return str(package.get("version", "unknown")), pgrx_version, majors


def version_tuple(value: str) -> tuple[int, ...]:
    match = re.match(r"^(\d+(?:\.\d+)*)", value.lstrip("=v"))
    if not match:
        raise StackError(f"invalid version: {value}")
    parts = tuple(int(part) for part in match.group(1).split("."))
    return parts + (0,) * (3 - len(parts))


def satisfies(version: str | int, requirement: str) -> bool:
    actual = version_tuple(str(version))
    for condition in requirement.split(","):
        condition = condition.strip()
        match = re.fullmatch(r"(>=|<=|>|<|=)?\s*(.+)", condition)
        if not match:
            raise StackError(f"invalid compatibility requirement: {requirement}")
        operator, expected_text = match.groups()
        expected = version_tuple(expected_text)
        if operator == ">=" and not actual >= expected:
            return False
        if operator == "<=" and not actual <= expected:
            return False
        if operator == ">" and not actual > expected:
            return False
        if operator == "<" and not actual < expected:
            return False
        if operator in (None, "=") and not actual == expected:
            return False
    return True


def compatible_set(lock: dict, postgres: int, manifest: dict) -> str | None:
    compatibility = load(ROOT / "stack" / "compatibility.toml")
    for candidate in compatibility.get("compatible", []):
        if not satisfies(postgres, candidate["postgres"]):
            continue
        if not satisfies(manifest["stack"]["pgrx_version"], candidate["pgrx"]):
            continue
        if all(name in lock and satisfies(lock[name]["version"], candidate[name])
               for name in manifest["extensions"]):
            return str(candidate.get("name", "unnamed"))
    return None


def resolve_one(name: str, cfg: dict, mode: str, refresh: bool) -> Path:
    override = os.getenv(env_key(name, "PATH"))
    sibling = ROOT.parent / name.replace("_", "-")
    if override:
        path = Path(override).expanduser().resolve()
    elif mode == "local":
        path = sibling.resolve()
    elif mode == "auto" and sibling.is_dir():
        path = sibling.resolve()
    else:
        path = CACHE / name
        reference = os.getenv(env_key(name, "REF"), cfg.get("tag") or cfg.get("branch") or "HEAD")
        if refresh and path.exists():
            shutil.rmtree(path)
        if not path.exists():
            path.parent.mkdir(parents=True, exist_ok=True)
            run("git", "clone", "--filter=blob:none", cfg["repo"], str(path))
        run("git", "fetch", "--tags", "origin", cwd=path)
        try:
            run("git", "checkout", "--detach", reference, cwd=path, capture=True)
        except StackError:
            run("git", "checkout", "--detach", f"origin/{reference}", cwd=path)
    if not path.is_dir():
        raise StackError(f"{name}: resolved path does not exist: {path}")
    if not (path / f"{name}.control").is_file():
        raise StackError(f"{name}: {path} does not contain {name}.control")
    return path


def lock_path(path: Path) -> str:
    """Use a portable path for sources mounted with the stack workspace."""
    try:
        path.relative_to(ROOT.parent)
    except ValueError:
        return str(path)
    return os.path.relpath(path, ROOT)


def source_path(value: str) -> Path:
    path = Path(value)
    return path if path.is_absolute() else (ROOT / path).resolve()


def quote(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def resolve(args: argparse.Namespace) -> None:
    manifest = load()
    required_pgrx = manifest["stack"]["pgrx_version"]
    required_pg = set(manifest["stack"]["postgres_versions"])
    records: list[tuple[str, Path, str, str, str | None, set[int]]] = []
    for name, cfg in manifest["extensions"].items():
        try:
            path = resolve_one(name, cfg, args.mode, args.refresh)
            version, pgrx, majors = cargo_metadata(path)
            commit = run("git", "rev-parse", "HEAD", cwd=path, capture=True) if (path / ".git").exists() else "local-unversioned"
            if pgrx and pgrx.lstrip("=") != required_pgrx:
                raise StackError(f"{name}: pgrx {pgrx} != required {required_pgrx}")
            missing = required_pg - majors
            if missing:
                raise StackError(f"{name}: missing Cargo features: {', '.join('pg' + str(v) for v in sorted(missing))}")
            records.append((name, path, commit, version, pgrx, majors))
        except StackError:
            if cfg.get("required", True):
                raise
    lines = [
        "# Generated; do not edit. Re-run `just resolve`.",
        "[stack]",
        f"version = {quote(str(manifest['stack']['version']))}",
        f"generated_at = {quote(dt.datetime.now(dt.timezone.utc).isoformat())}",
        "generated = true",
        "",
    ]
    for name, path, commit, version, pgrx, majors in records:
        lines.extend([
            f"[{name}]", f"commit = {quote(commit)}", f"version = {quote(version)}",
            f"path = {quote(lock_path(path))}", f"pgrx = {quote(pgrx or 'unknown')}",
            "postgres = [" + ", ".join(map(str, sorted(majors))) + "]", "",
        ])
    temporary = LOCK.with_suffix(".lock.tmp")
    temporary.write_text("\n".join(lines), encoding="utf-8")
    temporary.replace(LOCK)
    print(LOCK.read_text(encoding="utf-8"), end="")


def paths(_: argparse.Namespace) -> None:
    lock = load(LOCK)
    if not lock.get("stack", {}).get("generated"):
        raise StackError("versions.lock is unresolved; run `just resolve` first")
    for name in load()["extensions"]:
        if name in lock:
            print(f"{name}\t{source_path(lock[name]['path'])}")


def versions(_: argparse.Namespace) -> None:
    print(LOCK.read_text(encoding="utf-8"), end="")


def verify(args: argparse.Namespace) -> None:
    manifest = load()
    if args.postgres not in manifest["stack"]["postgres_versions"]:
        raise StackError(f"PostgreSQL {args.postgres} is unsupported")
    lock = load(LOCK)
    if not lock.get("stack", {}).get("generated"):
        raise StackError("versions.lock is unresolved")
    for name, cfg in manifest["extensions"].items():
        if cfg.get("required", True) and name not in lock:
            raise StackError(f"required extension {name} is absent from versions.lock")
        if name in lock and args.postgres not in set(lock[name].get("postgres", [])):
            raise StackError(f"{name} does not advertise pg{args.postgres}")
    compatibility_name = compatible_set(lock, args.postgres, manifest)
    if compatibility_name is None:
        versions = ", ".join(f"{name}={lock[name]['version']}" for name in manifest["extensions"] if name in lock)
        raise StackError(f"no compatible version set matches PostgreSQL {args.postgres}: {versions}")
    print(
        f"compatibility OK ({compatibility_name}): PostgreSQL {args.postgres}, "
        f"pgrx {manifest['stack']['pgrx_version']}"
    )


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser()
    sub = result.add_subparsers(dest="command", required=True)
    resolve_parser = sub.add_parser("resolve")
    resolve_parser.add_argument("--mode", choices=("auto", "local", "git"), default="auto")
    resolve_parser.add_argument("--refresh", action="store_true")
    resolve_parser.set_defaults(func=resolve)
    sub.add_parser("paths").set_defaults(func=paths)
    sub.add_parser("versions").set_defaults(func=versions)
    verify_parser = sub.add_parser("verify")
    verify_parser.add_argument("--postgres", type=int, required=True)
    verify_parser.set_defaults(func=verify)
    return result


def main() -> int:
    try:
        args = parser().parse_args()
        args.func(args)
        return 0
    except (StackError, OSError, tomllib.TOMLDecodeError) as error:
        print(f"stack: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Resolve env vars: prefer GitHub Variables (VARS_JSON), fall back to environments.<name> in variables.yml."""

from __future__ import annotations

import json
import os
import pathlib
import secrets
import sys

import yaml


def append_github_env(name: str, value: str) -> None:
    github_env = os.environ.get("GITHUB_ENV")
    if not github_env:
        print("GITHUB_ENV is not set (this script must run in a GitHub Actions step)", file=sys.stderr)
        sys.exit(1)

    delim = f"GHENV_{secrets.token_hex(16)}"
    with open(github_env, "a", encoding="utf-8") as out:
        out.write(f"{name}<<{delim}\n{value}\n{delim}\n")


def as_env_string(raw: object) -> str:
    if raw is None:
        return ""
    if isinstance(raw, bool):
        return "true" if raw else "false"
    return str(raw)


def nonempty(s: str) -> bool:
    return bool(s.strip())


def resolve_variables_path(rel: str) -> pathlib.Path:
    p = pathlib.Path(rel)
    if p.is_file():
        return p
    ws = os.environ.get("GITHUB_WORKSPACE")
    if ws:
        candidate = pathlib.Path(ws) / rel
        if candidate.is_file():
            return candidate
    return p


def main() -> None:
    if len(sys.argv) != 3:
        print("usage: load_env.py <variables_yml> <environment>", file=sys.stderr)
        sys.exit(2)

    variables_yml = resolve_variables_path(sys.argv[1])
    environment = sys.argv[2]

    raw = os.environ.get("VARS_JSON", "")
    try:
        gh_vars = json.loads(raw) if raw else {}
    except json.JSONDecodeError as e:
        print(f"Invalid VARS_JSON: {e}", file=sys.stderr)
        sys.exit(1)

    if not isinstance(gh_vars, dict):
        print("VARS_JSON must be a JSON object", file=sys.stderr)
        sys.exit(1)

    if not variables_yml.is_file():
        print(
            f"Missing variables file: {variables_yml} (cwd={os.getcwd()}, GITHUB_WORKSPACE={os.environ.get('GITHUB_WORKSPACE')})",
            file=sys.stderr,
        )
        sys.exit(1)

    with variables_yml.open("r", encoding="utf-8") as f:
        cfg = yaml.safe_load(f) or {}

    envs = cfg.get("environments") or {}
    template = envs.get(environment)
    if not isinstance(template, dict) or not template:
        print(f"No environments.{environment} mapping (non-empty) in {variables_yml}", file=sys.stderr)
        sys.exit(1)

    for key in template:
        if not isinstance(key, str):
            print(f"Invalid key (expected string): {key!r}", file=sys.stderr)
            sys.exit(1)

        raw_gh = gh_vars.get(key)
        gh_str = as_env_string(raw_gh) if raw_gh is not None else ""
        yaml_raw = template.get(key)
        yaml_str = as_env_string(yaml_raw) if yaml_raw is not None else ""

        if nonempty(gh_str):
            chosen = gh_str
        elif nonempty(yaml_str):
            chosen = yaml_str
            print(
                f"load-environment-variables: using variables.yml for {key} "
                f"(GitHub variable unset or empty; environments.{environment})",
                file=sys.stderr,
            )
        else:
            print(
                f"No value for {key}: set it as a GitHub Environment variable or under "
                f"environments.{environment} in {variables_yml}",
                file=sys.stderr,
            )
            sys.exit(1)

        append_github_env(key, chosen)


if __name__ == "__main__":
    main()

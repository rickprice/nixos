---
name: python-best-practices
description: Use whenever creating, modifying, or releasing a Python project (a pyproject.toml is present or about to be created) or editing any .py file. Covers running the linters/formatters/type-checker, keeping the lock file and README in sync with the code, and making PyPI releases line up cleanly with git tags. Triggers on "pyproject.toml", "pip install", "Python project", "PyPI", "publish to PyPI", ".py", "requirements.txt".
---

# Python project hygiene

Four things repeatedly go stale, get skipped, or get botched in Python
projects if nobody enforces them deliberately. Check all four whenever
you touch Python code, a project's dependencies, or cut a release.

## Linting, formatting, and type-checking

- Run the formatter and linters on every file you touch before calling
  the change done, not just when something looks wrong:
  `black .`, `pylint <changed files>`, `flake8 <changed files>`, and
  `mypy .` if the project has type hints (and it should — add them to
  new code even in an otherwise untyped project).
- `flake8`/`pylint` catch different things and both are worth running —
  `flake8` is close to pure PEP 8 plus pyflakes' unused-import/undefined-name
  checks, `pylint` goes further into design-level complaints (too many
  branches, missing docstrings, etc.). Don't silence a warning with
  `# noqa` or `# pylint: disable=...` without a comment saying why; an
  unexplained suppression is indistinguishable from "didn't understand
  the warning."
- If the project (or you, going forward) can adopt **Ruff**, prefer it:
  it reimplements flake8 + pyflakes + isort + pyupgrade + dozens of
  plugins as one Rust binary (`ruff check`, `ruff format`), runs orders
  of magnitude faster, and is what most new Python projects default to
  as of 2026. It's not a drop-in replacement for pylint's deeper
  design checks or mypy's type checking, so pairing `ruff` with `mypy`
  is a common modern baseline — don't treat adopting Ruff as license to
  drop type checking too.
- Don't hand-roll what the formatter would produce. Run `black`, don't
  manually match its style.

## pyproject.toml and the lock file

- Use `pyproject.toml` with the `[project]` table (PEP 621) for metadata
  — name, version, dependencies, `requires-python`. It's tool-agnostic:
  pip, uv, hatch, and poetry (recent versions) all read it the same way.
  Avoid adding project metadata to a tool-specific section
  (`[tool.poetry]`-only metadata, a bare `setup.py`) unless the build
  backend genuinely requires it.
- Put dev-only tooling (pytest, black, mypy, ...) in `[dependency-groups]`
  (PEP 735) rather than as regular `dependencies` or a tool-specific dev
  group — it's the portable spelling now that every major tool supports.
- **Commit the lock file** (`uv.lock`, `poetry.lock`, or equivalent).
  It's what makes `uv sync`/`poetry install` reproducible across
  machines and CI, the same reason `Cargo.lock` gets committed for Rust.
  Never hand-edit it — regenerate it through the tool that owns it.
- Whenever you add, remove, or bump a dependency, regenerate the lock
  file and commit the diff **in the same commit** as the
  `pyproject.toml` change — never let them drift apart across commits.
- In CI, install with the frozen/locked flag (`uv sync --frozen`,
  `poetry install --no-update`) so a drifted lock file fails the build
  instead of silently resolving different versions than what's
  committed.
- `pip-audit` (or `safety`) checks the resolved dependency set against
  known-vulnerability databases, the same role `cargo audit` plays for
  Rust — worth running before a release, and in CI if the project has
  any exposure (network-facing, parses untrusted input, etc.).

## README

- Treat README code examples as load-bearing, not decorative. When a
  public function signature, CLI flag, or subcommand changes, update
  the README's usage examples in the same change — and actually run the
  example rather than trusting it works from memory.
- Keep install instructions (`pip install`, `uv add`, `pipx install`)
  and CLI usage synced with what the code currently does.
- If the project has a `src/` layout or multiple packages, keep the
  "project layout" section in sync whenever modules are added, renamed,
  or removed.

## PyPI releases that line up with git tags

- Bump the version in `pyproject.toml`, regenerate the lock file, commit
  both together, and only then tag that commit (`vX.Y.Z` matching
  `project.version`) — never tag before the version-bump commit exists.
- Build both the wheel and the sdist (`python -m build`, or your
  backend's equivalent) and sanity-check the wheel's contents before
  publishing — a missing `packages`/`include` entry in `pyproject.toml`
  silently ships an empty or partial package.
- Prefer **Trusted Publishing (OIDC)** over a long-lived PyPI API token
  in CI. Register the GitHub repo + workflow filename as a trusted
  publisher on the PyPI project's settings page, give the publish job
  `permissions: id-token: write`, and publish via
  `pypa/gh-action-pypi-publish` — it exchanges the OIDC token for a
  short-lived upload credential itself, so there's no `PYPI_API_TOKEN`
  secret to leak or rotate. Keep the publish step in its own job,
  triggered on the GitHub Release/tag rather than every push to main,
  since it's the one step that needs the elevated `id-token` permission.
- Tag the repo at the exact commit you intend to publish, before any
  further changes — the GitHub Release's source archive and what gets
  uploaded to PyPI should be the same tree.
- **If the package has type hints, ship a `py.typed` marker file** and
  list it under the build backend's package-data/include config (e.g.
  hatchling's `[tool.hatch.build]` `include`, or setuptools'
  `package_data`). Without it, PEP 561 says type checkers must treat
  the installed package as untyped — your hints work perfectly in the
  source checkout and silently vanish for everyone who `pip install`s
  the wheel. Check the built wheel's file list
  (`unzip -l dist/*.whl` or `python -m zipfile -l dist/*.whl`) for
  `py.typed` before publishing, not after a user reports it missing.

# Project Title: <replace with your analysis question>

> **Purpose:** One sentence stating the question and the deliverable (HTML/PDF report).
> **Owner:** <name> · **Date:** <YYYY-MM-DD> · **Version:** v0.1.0

---

## Quick Start

```bash
conda env create -f environment.yml
conda activate analysis
pre-commit install
make all
```

Put source data under `data/raw/` (do not commit sensitive data).
Edit config in `config/parameters.yml`.
Explore in `notebooks/exploration/`.
When the method is chosen, build the polished notebook in `notebooks/analysis/`.
Export the final report with `make report`.

## Folder Guide (what goes where)

- `config/` — Parameters and settings that change per scenario.
- `data/raw/` — Original inputs (not committed). Use `src/01_load_data.py` to ingest.
- `data/processed/` — Derived datasets ready for modeling (optionally committed if sanitized).
- `notebooks/exploration/` — Scratch/EDA/notebook experiments. Use date-based filenames like `YYYYMMDD_exploration_<topic>.ipynb`.
- `notebooks/analysis/` — Clean, publication-ready notebook(s). Place `report.ipynb` here.
- `notebooks/archive/` — Auto-filled by `make archive`; stores exploration snapshots by timestamp.
- `src/` — Linear pipeline scripts (`01_…` → `04_…`). `src/sandbox/` for experimental scripts.
- `outputs/` — Figures, tables, and final report export.
- `tools/` — Utility scripts (e.g., `archive_exploration.py`).
- `tests/` — Minimal tests to keep structure sane.
- `DECISIONS.md` — Running log of choices, abandoned methods, and rationale.

## Reproducibility

- Environment: `environment.yml`
- One-click pipeline: `make all` or `python run.py all`
- CI builds lint/tests/report on push/PR (see `.github/workflows/ci.yml`)
- Tag deliverables: `vYYYY.MM.DD` (e.g., `v2026.03.16`)

## Project Lifecycle

1. **Start** — Clone this template; fill in `README.md` and `config/parameters.yml`.
2. **Explore** — Work in `notebooks/exploration/` and `src/sandbox/`.
3. **Decide** — Record rationale in `DECISIONS.md`.
4. **Finalize Methods** — Move stable code into `src/` and `notebooks/analysis/`.
5. **Archive Exploration** — `make archive` to move exploration notebooks into `notebooks/archive/<timestamp>/` and log it.
6. **Export Report** — `make report` to build HTML from `notebooks/analysis/report.ipynb`.
7. **Tag** — `git tag vYYYY.MM.DD_final && git push --tags`.

## Optional: Git Hooks (simple reminder)

What’s a git hook? A small script that runs at certain Git events.

Enable the reminder hook to nudge you to update `DECISIONS.md` when pushing:

```bash
make hooks
```

Disable anytime:

```bash
git config --unset core.hooksPath
```

## Contact

- Analyst:
- Stakeholders: <Names/Teams>
template that is tuned for risk-analysis workflow and makes it easy to keep final outputs clean while preserving my scientific trail.

.PHONY: all setup clean data process model analysis report test lint fmt hooks archive

all: setup data process model analysis report

setup:
	@echo "Creating kernel & installing pre-commit hooks..."
	python -m ipykernel install --user --name=analysis
	pre-commit install

data:
	@echo "Loading raw data..."
	python src/01_load_data.py

process:
	@echo "Processing data..."
	python src/02_clean_data.py

model:
	@echo "Running modeling..."
	python src/03_modeling.py

analysis:
	@echo "Running analysis..."
	python src/04_analysis.py

report:
	@echo "Exporting report from notebooks/analysis/report.ipynb..."
	if [ -f notebooks/analysis/report.ipynb ]; then \
		jupyter nbconvert --to html --output-dir outputs/report notebooks/analysis/report.ipynb; \
	else \
		echo "No notebooks/analysis/report.ipynb found. Create it first."; \
	fi

archive:
	@echo "Archiving exploration notebooks..."
	python tools/archive_exploration.py

test:
	pytest -q

lint:
	flake8 src tests
	isort --check src tests
	black --check src tests

fmt:
	isort src tests
	black src tests

hooks:
	@echo "Setting git hooks path to .githooks/"
	git config core.hooksPath .githooks

clean:
	rm -rf outputs/figures/* outputs/tables/* outputs/report/*

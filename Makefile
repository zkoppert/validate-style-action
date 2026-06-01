.PHONY: lint test clean

lint:
	python3 lint.py lint.py README.md action.yml bin/validate-style-action.sh

test:
	python3 tests.py

clean:
	find . -name __pycache__ -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name '*.pyc' -delete

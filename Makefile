PACKAGE_DIR=./


install:
	echo "hello"

build:
	python -m build --sdist --wheel "${PACKAGE_DIR}"
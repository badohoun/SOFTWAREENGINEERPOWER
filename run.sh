#!/bin/bash

set -e

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function load-dotenv {
    while read -r line; do
        export "$line"
    done < <(grep -v '^#' "$THIS_DIR/.env" | grep -v '^$')
}

function install {
  python -m pip install --upgrade pip
  python -m pip install --editable "$THIS_DIR/[dev]"
}

function lint {
     pre-commit run --all-files
}

function lint:ci {
    SKIP=no-commit-to-branch 
}

function test:quick {
    # save the exit status of tests 
    PYTEST_EXIT_STATUS=0
    python -m pytest -m 'not slow' "$THIS_DIR/tests/" \
    --cov "$THIS_DIR/packaging_demo" \
    --cov-report html \
    --cov-report term \
    --cov-report xml \
    --junit-xml "$THIS_DIR/test-reports/report.xml" \
    --cov-fail-under 50 || ((PYTEST_EXIT_STATUS+=$?))
    mv coverage.xml "$THIS_DIR/test-reports/"
    mv htmlcov "$THIS_DIR/test-reports/"
    return $PYTEST_EXIT_STATUS
}

# (example) ./run.sh test tests/tests_slow.py::test__slow_add
function test {
    # save the exit status of tests 
    PYTEST_EXIT_STATUS=0
    # run only specified tests , if none specified , run all
    python -m pytest "${@:-$THIS_DIR/tests/}" \
           --cov "$THIS_DIR/packaging_demo" \
           --cov-report html \
           --cov-report term \
           --cov-report xml \
           --junit-xml "$THIS_DIR/test-reports/report.xml" \
           --cov-fail-under 50 || ((PYTEST_EXIT_STATUS+=$?))
    mv coverage.xml "$THIS_DIR/test-reports/"
    mv htmlcov "$THIS_DIR/test-reports/"
    return $PYTEST_EXIT_STATUS

}

function test:ci {
    # save the exit status of tests 
    PYTEST_EXIT_STATUS=0
    INSTALLED_PKG_DIR="$(python -c 'import packaging_demo; print(packaging_demo.__path__[0])')"
    python -m pytest -m 'not slow' "$THIS_DIR/tests/" \
    --cov "$INSTALLED_PKG_DIR" \
    --cov-report html \
    --cov-report term \
    --cov-report xml \
    --junit-xml "$THIS_DIR/test-reports/report.xml" \
    --cov-fail-under 50 || ((PYTEST_EXIT_STATUS+=$?))
    mv coverage.xml "$THIS_DIR/test-reports/"
    mv htmlcov "$THIS_DIR/test-reports/"
    return $PYTEST_EXIT_STATUS
}

function test:wheel-locally {
    source deactivate || true
    rm -rf test-env || true 
    python -m venv test-venv
    source test-venv/bin/activate
    clean || true 
    pip install build 
    build 
    # save the exit status of tests 
    PYTEST_EXIT_STATUS=0
    pip install ./dist/*whl pytest pytest-cov 
    INSTALLED_PKG_DIR="$(python -c 'import packaging_demo; print(packaging_demo.__path__[0])')"
    python -m pytest -m 'not slow' "$THIS_DIR/tests/" \
    --cov "$INSTALLED_PKG_DIR" \
    --cov-report html \
    --cov-report term \
    --cov-report xml \
    --junit-xml "$THIS_DIR/test-reports/report.xml" \
    --cov-fail-under 50 || ((PYTEST_EXIT_STATUS+=$?))
    mv coverage.xml "$THIS_DIR/test-reports/"
    mv htmlcov "$THIS_DIR/test-reports/"

    test:ci
    deactivate
    return $PYTEST_EXIT_STATUS
}



function serve-coverage-report {
    python -m http.server --directory "$THIS_DIR/htmlcov/"
}

function test:all {
    # run only specified tests , if none specified , run all
    if [ $# -eq 0 ]; then  
       python -m pytest  "$THIS_DIR/tests/" \
        --cov="$THIS_DIR/packaging_demo" \
        --cov-report html 
    else 
       python -m pytest "$@"
    fi 
}

function build {
   python -m build --sdist --wheel "$THIS_DIR/"
}

function release:test {
    lint
    clean
    build
    publish:test
}


function release:prod {
    release:test
    publish:prod
}

function publish:test {
    try-load-dotenv  || true
    twine upload dist/* \
        --repository testpypi \
        --username=__token__ \
        --password="$TEST_PYPI_TOKEN"
}


function publish:prod {
    try-load-dotenv  || true
    twine upload dist/* \
        --repository pypi \
        --username=__token__ \
        --password="$PROD_PYPI_TOKEN" 
}


function clean {
    rm -rf dist build coverage.xml test-reports 
    find . \
      -type d \
      \( \
        -name "*cache*" \
        -o -name "*.dist-info" \
        -o -name "*.egg-info" \
        -o -name "*htmlcov" \
      \) \
      -not -path "*env/*" \
      -exec rm -r {} +
}

function try-load-dotenv {
    if [ ! -f "$THIS_DIR/.env" ]; then
        echo "no .env file found"
        return 1
    fi

    while read -r line; do
        export "$line"
    done < <(grep -v '^#' "$THIS_DIR/.env" | grep -v '^$')
}


function help {
    echo "$0 <task> <args>"
    echo "Tasks:"
    compgen -A function | cat -n
}

TIMEFORMAT="Task completed in %3lR"
time ${@:-install}

#echo $@

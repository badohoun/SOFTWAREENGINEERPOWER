from setuptools import setup , find_packages

setup(
    name='packaging',
    version='0.0.0',
    packages=find_packages(),
    # include any additional files needed by the package
    include_package_data=True,
    # specify the package metadata
    author='Espoir Badohoun',
    author_email="youremail@example.com",
    description='A simple package for packaging',
    license='MIT',
)
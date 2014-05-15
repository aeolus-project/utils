import os.path
from setuptools import setup, find_packages

install_requires = [
    'jsonschema'
]

setup(
    name='aeolus-json',
    version='0.1a',
    description="Aeolus json file tools",
    packages=find_packages(),
    install_requires=install_requires,
)

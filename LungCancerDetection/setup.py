from distutils.core import setup
from lung_cancer import VERSION, LICENSE

setup(
    name='lung-cancer-detection-sql-python',
    version=VERSION,
    packages=['lung_cancer'],
    url='https://github.com/Azure/sql_python_deep_learning',
    license=LICENSE
)
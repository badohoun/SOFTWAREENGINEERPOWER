import sys 
print(sys.path)
sys.path.insert(0, "/home/obs/packaging/")
from SOFTWAREENGINEERPOWER.my_other_file import CONSTANT as CONSTANT2

CONSTANT = "bienvenue"

print(CONSTANT2)
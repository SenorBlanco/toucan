#!/usr/bin/env python3

import json

with open('stanford-dragon.json', 'r') as file:
  data = json.load(file)

cells = data["cells"]
positions = data["positions"]

count = 0
print("var dragonTriangles : [" + str(len(cells)) + "][3]uint = {");
for cell in cells:
  count += 1
  possibleComma = "," if (count < len(cells)) else ""
  print("  {" + str(cell[0]) + ", " + str(cell[1]) + ", " + str(cell[2]) + "}" + possibleComma)

print("};");

count = 0;
print("var dragonVertices : [" + str(len(positions)) + "]float<3> = {");
for position in positions:
  count += 1
  possibleComma = "," if (count < len(positions)) else ""
  print("  {" + str(position[0]) + ", " + str(position[1]) + ", " + str(position[2]) + "}" + possibleComma)
print("};");

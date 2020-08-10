# ORBs
A collection of FIJI macros to analyse ORBs as per Dhaliwal et al., 2020

There are 5 macros:
A) Part 1 - 2D Cellfinder
B) Part 2 - ordermaker Win
C) Part 3 - Orb Analyser
D) Part 1 - 2D Cellfinder 2 channel
E) Part 2 - Overlap Finder


These can be used in several different workflows:
1) A --> B --> C
2) D --> E

Workflow 1 allows the user to A) find single cells in a XYZC image, saving these cells as individual images. B) Analyse the intensity of all of these cells, making a list of these values. C) Using data from B), allwos the user to analyse the presence and size of ORB-like particles in the images derived from A).

Workflow 2 allows the user to D) find single cells in an XYZC image, saving two fluorescent channels as separate images. E) Allows the identification of overlapping puncta in the individual channels isolated in D.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

Generate STL from OpenSCAD files:
```bash
openscad -o output.stl input.scad
```

## Repository Structure

Each library has its own directory containing examples:
```
library_name/
├── library_name.scad
└── examples/
```

Import with relative paths: `use <../library_name.scad>`

## Design Philosophy

### Reference Existing Standards

- Look up actual hardware specifications (connector standards, screw dimensions, etc.)
- Reference existing libraries and resources (NopSCADlib, community designs)
- Use real measurements, not approximations
- When designing for off-the-shelf parts (connectors, brackets, etc.), search for existing CAD models to reference or import

### Geometric Reasoning

When designing mechanical parts, calculate relationships properly:
- Derive angles and positions from geometry, not trial-and-error
- Consider how parts interact (e.g., hex nut edges relative to adjacent features)
- Document the reasoning in comments when the math is non-obvious

### Parametric Design

- Expose configurable parameters at file top
- Use lookup tables for hardware variants
- Create both specific modules (`de9_cutout()`) and generic versions (`dsub_cutout(type)`)

### Iterative Refinement with Physical Testing

- Print and test critical dimensions
- Adjust tolerances based on actual results
- Consider material behavior and printer accuracy

## 3D Print Conventions

- Include `tolerance` parameter (typically 0.2-0.4mm)
- Add small offsets (0.1mm) to boolean operations to avoid z-fighting
- Use `difference()` with cutout modules for subtractive operations

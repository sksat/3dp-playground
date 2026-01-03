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

### Side-Mounted Cutouts (垂直壁へのカットアウト配置)

水平パネル用に設計されたカットアウトを垂直壁に配置する場合、複数の変換が必要。

**よくある勘違い:**
- 180°回転で両端が入れ替わると思いがち → 回転は原点を固定するので Z=0 にあるものは Z=0 のまま
- 1つの回転で複数の要件（形状の向き、ナット位置、壁への向き）を満たそうとする → 各要件に対応する変換が必要

**正しいアプローチ:**
```openscad
// 前面壁へのDE-9配置例（広い側が上、ナットは内側）
translate([x, -0.1, z])
    rotate([-90, 0, 0])              // 3. 壁に向ける
        translate([0, 0, depth/2])
            rotate([0, 180, 0])      // 2. 中心で反転してナット/ブラケット入替
                translate([0, 0, -depth/2])
                    rotate([0, 0, 180])  // 1. D形状の向き調整
                        de9_cutout();
```

**ポイント:**
- 両端を入れ替えるには translate → rotate → translate（中心に移動→回転→戻す）
- 各変換の効果を論理的に追跡する（試行錯誤ではなく）
- OpenSCADの回転方向: `rotate([90,0,0])` で Y→+Z、`rotate([-90,0,0])` で Y→-Z

**より良いアプローチ: 独立パネルとして設計**

壁にカットアウトを配置するのではなく、パネルを独立したモジュールとして設計する:

```openscad
// パネルを水平状態で設計（板 + コネクタ穴 + ラベル）
module front_panel() {
    // 板本体
    color("white") difference() {
        cube([width, height, thickness]);
        // コネクタカットアウト
        for (i = [0:2]) translate([x, 0, 0]) de9_cutout();
        // ラベル凹み
        for (i = [0:2]) translate([x, y, z]) label_cutout();
    }
    // ラベル本体
    color("black") for (i = [0:2]) translate([x, y, z]) label_text();
}

// 箱本体からパネルの場所をくり抜き
module box_body() {
    difference() {
        cube([...]);
        // 前面壁をくり抜き（境界面を少しオーバーラップ）
        translate([0, -0.1, wall_thickness])
            cube([box_width, wall_thickness + 0.2, box_height]);
    }
}

// 組み立て: パネルを回転して配置
translate([x, y, z]) rotate([90, 0, 0]) front_panel();
```

**利点:**
- パネル内で板・穴・ラベルを一括管理
- モジュール内で `color()` を使えば呼び出し側はシンプル
- 配置時は単純な translate + rotate のみ
- くり抜き時は境界面をオーバーラップさせて Z-fighting を防止

### Multi-Color Printing

OpenSCAD 2024以降 + lazy-union で、`color()` で指定した色ごとに別オブジェクトとして3MF出力可能:

```bash
openscad --enable=lazy-union -O export-3mf/material-type=color \
  -o output.3mf input.scad
```

設計時の注意:
- 各パーツに `color()` を指定
- インレイ（埋め込み文字等）は凹みを少し大きく作り、Z-fightingを回避
- STL形式は単一メッシュのみ対応のため、マルチカラーには3MFを使用

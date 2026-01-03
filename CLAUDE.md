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

### Assembly-Time Features (組み立て時の形状追加)

複数パーツを組み合わせた後に追加形状（ボスなど）や差分（穴など）を適用する場合、操作の順番が重要。

**問題のパターン:**
```openscad
// 間違い: 各パーツ内でボスや穴を作成
module box_body() {
    difference() {
        union() {
            basic_box();
            bosses();  // ここでボスを作成
        }
        insert_holes();  // ここで穴を開ける
    }
}

// 組み立て
box_body();
front_panel();  // ← ボスや穴の後に追加されるため干渉する
```

**正しいアプローチ: 組み立てセクションで統合**
```openscad
// 各モジュールはシンプルに
module box_body() {
    difference() {
        cube([...]);
        // 内側くり抜きのみ
    }
}

module front_panel() {
    // 板 + コネクタ穴のみ
}

// 組み立てセクションで全体を統合してから追加形状を適用
color("white") difference() {
    union() {
        box_body();
        front_panel();  // パネルも含める
        // ボスを追加（全パーツが揃った後）
        for (pos = boss_positions)
            cylinder(...);
    }
    // 穴を開ける（全体に対して）
    for (pos = boss_positions)
        cylinder(...);
}
```

**ポイント:**
- モジュールはシンプルな形状のみ担当
- union/difference の順番を制御するには、組み立てセクションで統合
- 色分けが必要な場合、統合する部分と個別の部分を分ける

### Heat-Set Inserts (ヒートセットインサート)

M3ヒートセットインサート用の設計パラメータ:
```openscad
insert_hole_d = 4.2;      // 穴径（インサート外径4-5mmより少し小さめ）
insert_hole_depth = 6;    // 穴深さ（インサート長さ5mm + 余裕1mm）
boss_d = 8;               // ボス直径（穴 + 肉厚）
```

- 穴は上面から開ける（印刷後にインサートを熱圧入）
- ボス（柱）で薄い壁にも対応可能

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

### Parameterized Labels (配列によるラベル管理)

複数のラベルを個別にカスタマイズする場合、文字列配列で定義:

```openscad
// ラベル文字列（カスタマイズ可能）
top_labels = ["COM1", "COM2", "COM3"];
mid_labels = ["COM4", "COM5"];
bottom_labels = ["COM6", "COM7", "COM8"];

// ラベル配置（forループでインデックス参照）
for (i = [0:2]) {
    translate([x_positions[i], y, z])
        label_text(top_labels[i]);
}
```

**利点:**
- ラベル文字列をファイル先頭で一括管理
- コネクタの用途に応じたラベル付け（"COM1", "VIDEO", "CTRL"など）
- 配置ロジックとラベル内容を分離

### Fillets with BOSL2 (角丸・フィレット)

BOSL2 ライブラリの `cuboid()` で簡単に角丸を実現:

```bash
# インストール
git clone https://github.com/BelfrySCAD/BOSL2.git ~/.local/share/OpenSCAD/libraries/BOSL2
```

```openscad
include <BOSL2/std.scad>

// 垂直エッジのみ角丸（底面は印刷用に平ら）
cuboid([width, depth, height], rounding=3, edges="Z", anchor=BOTTOM+LEFT+FRONT);
```

**複数パーツの角丸を統一する場合:**

各パーツに個別のフィレットをかけると形状が合わない。`intersection()` で外形トリミング:

```openscad
difference() {
    intersection() {
        // 外形で全体をトリミング
        cuboid([w, d, h], rounding=r, edges="Z", anchor=BOTTOM+LEFT+FRONT);

        union() {
            box_body();
            front_panel();  // パネルは cube() でOK
        }
    }
    // 穴あけ
}
```

**ポイント:**
- 各パーツに個別フィレット → 形状不一致
- `intersection()` で外形トリミング → 統一された角丸
- `edges="Z"` で垂直エッジのみ（印刷向け）

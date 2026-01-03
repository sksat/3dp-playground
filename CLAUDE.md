# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

Each library has its own directory containing examples:
```
library_name/
├── library_name.scad
└── examples/
```

Import with relative paths: `use <../library_name.scad>`

## Build Commands

Generate STL from OpenSCAD files:
```bash
openscad -o output.stl input.scad
```

Makefile にパターンルール (`%.3mf: %.scad` 等) を定義しておくと `make foo.3mf` でビルドできる。

## Multi-Color Printing

OpenSCAD 2024以降 + lazy-union で、`color()` で指定した色ごとに別オブジェクトとして3MF出力可能:

```bash
openscad --enable=lazy-union -O export-3mf/material-type=color \
  -o output.3mf input.scad
```

設計時の注意:
- 各パーツに `color()` を指定
- インレイ（埋め込み文字等）は凹みを少し大きく作り、Z-fightingを回避
- STL形式は単一メッシュのみ対応のため、マルチカラーには3MFを使用

## File Structure (ファイル構造)

SCADファイルは以下の順序で構成する:

### 1. ヘッダーコメント

ファイル先頭に目的と仕様を記載:
- 目的: ファイルの役割（ライブラリ、サンプル、製品など）
- 外形サイズ: 出力モデルの寸法（幅 x 奥行き x 高さ）
- 使用パーツ: コネクタ、ネジ、ナットなど外部パーツの種類と数量
- 依存関係: 必要なライブラリ
- ビルドコマンド: 出力方法（マルチカラー等）

```openscad
// [タイトル]
// [簡単な説明]
//
// 外形: 120mm x 110mm x 8mm
// 使用コネクタ: DE-9 x7, DA-15 x1
// 使用ネジ: M3キャップボルト x4
// 依存: BOSL2, NopSCADlib
//
// ビルド:
//   openscad --enable=lazy-union -o output.3mf filename.scad
```

### 2. use / include 文

外部ファイルのインポート。`use` と `include` の使い分けは「Module Sharing with include」セクション参照。

### 3. Customizer 用パラメータ

OpenSCAD Customizer から編集可能にしたい変数。

**配列の扱い:**

OpenSCAD の Customizer は配列をサポートしていない。Customizer から編集可能にするには個別変数を使用:

```openscad
// Customizer で編集可能
top_label_1 = "COM1";
top_label_2 = "COM2";
top_label_3 = "COM3";
top_labels = [top_label_1, top_label_2, top_label_3];
```

配列リテラルで直接定義すると Customizer に表示されない:
```openscad
// Customizer に表示されない
top_labels = ["COM1", "COM2", "COM3"];
```

### 4. 一般パラメータ

内部で使用する寸法、計算値など。

### 5. モジュール定義

### 6. 組み立て / 出力

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

### Fit Checking with Component Models (既製品モデルによるフィットチェック)

既製品（コネクタ、ブラケット等）を使う設計では、実際のモデルを配置してフィットを確認する:

**NopSCADlib の利用:**

```bash
# インストール
git clone https://github.com/nophead/NopSCADlib.git ~/.local/share/OpenSCAD/libraries/NopSCADlib
```

```openscad
include <NopSCADlib/core.scad>
include <NopSCADlib/vitamins/d_connectors.scad>

// DCONN9, DCONN15, DCONN25, DCONN37 が利用可能
d_socket(DCONN9);  // メス（パネル取付側）
d_plug(DCONN9);    // オス（ケーブル側）
```

**フィットチェック用の配置:**

```openscad
show_connectors = true;  // フラグで表示切替

// 注意: intersection() や difference() の外に配置
// 内側に配置すると外形でクリップされる
if (show_connectors) {
    translate([...]) rotate([...])
        d_socket(DCONN9);
}
```

**よくある問題:**
- `intersection()` 内に配置 → 外形でクリップされてコネクタが消える
- 回転後の向きが想定と違う → パネルローカル座標での Y 軸方向に注意
- 六角ナット等の回転が合わない → ポケット形状に合わせて回転を追加
- Z 位置がずれる → モジュールの原点と描画方向を確認（例: `nut()` は Z=0 から上に伸びる）

**寸法の不一致が見つかった場合:**
1. まずミス（計算間違い、座標系の誤解など）を疑う
2. ミスでなければユーザーに方針を確認（どちらの寸法を信頼するか）

**モジュール構成のパターン:**

```openscad
// パネル本体（印刷対象）
module enclosure_top_panel() {
    color("white") main_panel();
    color("black") labels();
}

// フィットチェック用コネクタ（印刷対象外）
module panel_connectors() {
    d_socket(DCONN9);
    // ...
}

// 組み立て側で制御
if (show_top_panel) {
    translate([...]) {
        enclosure_top_panel();
        if (show_connectors) panel_connectors();
    }
}
```

**ポイント:**
- 印刷対象とフィットチェック用を別モジュールに分離
- 複数のフラグで個別に表示制御（天板全体 / コネクタのみ）
- Customizer から切り替え可能にして確認しやすく

**画像生成による確認:**

```bash
# 特定アングルで画像生成
openscad -o output.png --imgsize=800,600 \
  -D '$vpr=[70,0,30]; $vpt=[60,55,25]; $vpd=280;' \
  input.scad

# $vpr: 視点回転 [x,y,z]
# $vpt: 視点位置 [x,y,z]
# $vpd: 視点距離
```

フロントパネルを確認する場合は、カメラを正面寄りに配置する（$vpr の Z 成分を調整）。

### Module Sharing with include (include によるモジュール共有)

別ファイルで定義したモジュールと変数を共有する場合:

**`use` vs `include`:**
- `use`: モジュールと関数のみ取り込み、変数やトップレベルコードは実行されない
- `include`: ファイル全体を挿入、変数も共有される

**include パターンの例:**

```openscad
// panel.scad（include される側）
show_connectors = true;  // 単体で開いた時のデフォルト

module panel() { ... }
module panel_connectors() { ... }

// show_top_panel が未定義 = 単体で開いている
if (is_undef(show_top_panel)) {
    panel();
    if (show_connectors) panel_connectors();
}
```

```openscad
// enclosure.scad（include する側）
show_top_panel = true;  // include 前に定義 → Customizer に表示

include <panel.scad>

// include 後に再定義 → Customizer に表示 & 最終値として使用
show_connectors = true;

if (show_top_panel) {
    translate([...]) panel();
    if (show_connectors) panel_connectors();
}
```

**ポイント:**
- Customizer は変数定義の順序を見る。include 後に再定義すると表示される
- `is_undef(変数)` で include 元からの呼び出しを検出
- 共有したい変数は include 前後で同じ名前を使う

### Screw Fastening Design (ネジ固定の設計)

ネジとナットで部品を固定する際の設計上の考慮点:

**1. ネジ長とナット位置の関係**

ネジが届く範囲内にナットを配置する必要がある。ポストやスペーサーを使う場合、ネジ長との整合性を確認:

```openscad
// 例: ポスト高さ10mmに対しM2.5x8ネジ
// → ナットはポスト底部付近に配置（ネジが届く範囲）
```

**2. ナットのアクセス性**

組み立て時にナットを挿入できる経路が必要:
- 底面から貫通させる
- 側面からスロットを開ける
- 上面から落とし込む

```openscad
// 六角ナット凹み（底面から貫通してポスト底部へ）
translate([x, y, -0.1])
    cylinder(h = wall_thickness + nut_depth + 0.1, d = nut_width / cos(30), $fn = 6);
```

**3. ポスト形状の選択肢**

用途に応じて選択:
- **円柱**: シンプル、標準的
- **円錐形（底部が広い）**: 強度向上、印刷しやすさ、ナット収容スペース確保

```openscad
// 円錐形ポスト（強度重視の場合）
cylinder(h = post_h, d1 = base_d, d2 = top_d, $fn = 24);
```

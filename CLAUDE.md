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

新しいものを設計する前に、リポジトリ内の既存ライブラリを確認すること。
各ライブラリの `README.md` に機能と使い方が記載されている。

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

### Tolerance by Print Orientation (造形方向と公差)

造形方向によって必要な tolerance が異なる:
- **水平面**: 0.3mm（比較的正確）
- **垂直面**: 0.4〜0.5mm（オーバーハングで膨らむため大きめ）

ライブラリで tolerance を外部から指定可能にしておくと便利:
```openscad
module de9_cutout(tol = undef) { ... }
de9_cutout(tol = 0.5);  // 垂直面用
```

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

### D-SUB Connector Hole Orientation (D-SUBコネクタ穴の向き)

D-SUB（DE-9, DA-15等）のD形状穴を配置する際、向きを間違えやすい。

**標準の向き:**
- D形状の広い側（DE-9なら5ピン側）が**下**
- D形状の狭い側（DE-9なら4ピン側）が**上**
- これはコネクタを正面から見た時の標準的な向き

**よくある間違い:**
```openscad
// 間違い: 不要な180°回転でD形状が上下逆になる
rotate([90, 0, 0])
    linear_extrude(height = thickness)
        rotate([0, 0, 180])  // ← これが余計
            dsub_shape_2d("db9");
```

**正しいアプローチ:**
```openscad
// rotate([90,0,0]) で 2D の Y+ が 3D の Z+ になる
// dsub_shape_2d は広い側が Y+ なので、広い側が Z+（上）になる
// ...が、DE-9 の標準向きは広い側が下なので、
// 視線方向と組み合わせて考える必要がある

// Y+ 方向から見る面（背面パネルなど）の場合:
rotate([90, 0, 0])  // Z+→-Y（押出が視線と逆方向）
    linear_extrude(...)
        dsub_shape_2d("db9");  // 180°回転は不要
```

**確認方法:**
- NopSCADlib の `d_plug()` や `d_socket()` を配置してフィット確認
- 5ピン側（広い側）が下になっているか目視確認
- 嵌合相手との向きが一致しているか確認

**ポイント:**
- `dsub_shape_2d()` の標準出力は広い側が Y+
- `rotate([90,0,0])` で Y+ は Z+ に変換される
- 視線方向（どちらから見るか）で最終的な見え方が決まる
- 迷ったら NopSCADlib のコネクタモデルで確認

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

**ライブラリ変数へのアクセス:**

`use` ではモジュールと関数のみ取り込まれ、変数は取り込まれない。
ライブラリ内の変数（`tolerance`, `m3_nut_width` 等）を使いたい場合は `include` を使用:

```openscad
// use では変数にアクセスできない
use <../dsub_panel_mount.scad>
echo(tolerance);  // undefined

// include なら変数も使える
include <../dsub_panel_mount.scad>
echo(tolerance);  // 0.3
```

### Viewing Direction Design (視線方向を考慮した設計)

通常と異なる方向から見る面（底面、内側など）に形状を配置する場合:

**設計アプローチ:**
1. 最終的な視線方向を明確にする（下から見上げる、内側から見る、等）
2. その視線方向でどう見えるべきかを先に決める
3. OpenSCAD 座標系との対応を論理的に導出する

**ポイント:**
- 「左右」「上下」は最終的な見え方を基準に議論する
- OpenSCAD の座標軸（X, Y, Z）とは独立して考える
- 必要な変換（mirror、rotate）は見え方から逆算する

### Multi-Color Text and Z-Fighting (マルチカラーテキストと Z-fighting)

マルチカラー印刷で異なる色のテキストを壁に配置する場合、印刷時の造形方向によって適切なアプローチが異なる。

**Z-fighting の原因:**
壁表面とテキスト表面が同一平面を共有すると、レンダラーがどちらを表示すべきか判断できず「ちらつき」が発生する。

**印刷時の造形方向による分類:**

| 造形方向 | 例 | テキスト配置 | Z-fighting 対策 |
|---------|-----|-------------|----------------|
| 上面 | 底板のラベル（印刷時に上向き） | 0.1mm 突出 OK | くり抜きとテキストを同じ位置・深さに |
| 側面 | 垂直壁のタイトル（印刷時に垂直） | 壁と同一面必須 | くり抜きとテキストを同じ位置、押出長の差で回避 |

**上面テキスト（印刷時に上向き）:**

テキストが印刷時に上を向く場合、0.1mm 程度の突出はサポート不要で造形しやすい。

```openscad
// くり抜きとテキストを同じ位置・同じ深さに配置
// テキストは壁より 0.1mm 突出するが、上面なのでサポート不要

module label_cutout(txt) {
    linear_extrude(height = label_depth + 0.1)
        text(txt, ...);
}

// 壁の difference 内
translate([x, y, -0.1])  // 壁表面より 0.1mm 手前から
    label_cutout("Label");

// テキスト本体（同じ位置）
translate([x, y, -0.1])
    label_cutout("Label");  // 同じモジュールを使用
```

**側面テキスト（印刷時に垂直壁）:**

テキストが印刷時に垂直壁になる場合、突出はオーバーハングを生むため不可。くり抜きとテキストを**同じ位置**に配置し、押出長の差で Z-fighting を回避する。

```openscad
// テキストモジュール
module front_title_text(txt) {
    linear_extrude(height = label_depth)
        mirror([0, 1, 0])  // rotate([-90,0,0]) での反転を補正
            text(txt, ...);
}

// くり抜き（テキストと同じ形状、奥まで延長）
module front_title_cutout(txt) {
    linear_extrude(height = label_depth + 0.1)
        mirror([0, 1, 0])
            text(txt, ...);  // offset なし（テキストと同じ形状）
}

// 壁の difference 内（壁表面より手前から開始）
translate([x, -wall_y - 0.1, z])
    rotate([-90, 0, 0])
        front_title_cutout("Title");

// テキスト本体（くり抜きと同じ位置）
translate([x, -wall_y - 0.1, z])
    rotate([-90, 0, 0])
        front_title_text("Title");
```

**Z-fighting 回避の仕組み:**
- くり抜き: Y = -0.1 から Y = +label_depth（壁表面を超えて内部まで）
- テキスト: Y = -0.1 から Y = +label_depth - 0.1（壁表面で終端）
- 壁表面（Y = 0）では両方が「押出の途中」→ 前面を共有しない → Z-fighting なし

**重要なポイント:**
- くり抜きとテキストは**同じ位置**から開始する
- くり抜きは `label_depth + 0.1` で壁内部まで到達
- テキストは `label_depth` で壁表面に終端（突出しない）
- くり抜きとテキストは**同じ 2D 形状**にする（offset で大きくしない）

**よくある失敗:**
- くり抜きに `offset()` を追加 → テキスト周囲に隙間ができ見栄えが悪い
- テキストを壁表面に配置し、くり抜きだけ手前に → Z-fighting が発生
- 側面テキストを突出させる → 印刷時にオーバーハングが発生

### Customizer JSON Presets (プリセットファイル)

OpenSCAD Customizer のパラメータをJSONファイルで管理し、GUI や CLI から適用できる。

**ファイル配置:**
- JSON ファイル名は SCAD ファイルと同名にする
- 例: `expansion_top.scad` → `expansion_top.json`
- 複数ファイルで同じプリセットを使う場合はコピーを配置

**JSON 形式:**
```json
{
    "fileFormatVersion": "1",
    "parameterSets": {
        "preset-name": {
            "variable_name": "value",
            "numeric_var": "123",
            "bool_var": "false"
        }
    }
}
```

**GUI での使用:**
1. View → Customizer でパネル表示
2. プリセットドロップダウンから選択

**CLI での使用:**
```bash
openscad -p preset.json -P "preset-name" -o output.3mf input.scad
```

**マルチカラー 3MF 出力:**
```bash
openscad --enable=lazy-union -O export-3mf/material-type=color \
  -p preset.json -P "preset-name" -o output.3mf input.scad
```

### Design for Reusability (再利用性を考慮した設計)

複数ファイルで共通の設定を使いたい場合（Customizer プリセット共有など）:

**設計アプローチ:**
1. 共有したい項目を事前に洗い出す
2. 変数名を統一する（後から変更は影響範囲が大きい）
3. include 時の変数上書き挙動を理解しておく

**変数名の統一例:**
```openscad
// multi_connector_panel.scad
top_label_1 = "COM1";
top_label_2 = "COM2";
panel_title = "Panel v0.1";

// expansion_top.scad（同じ変数名を使用）
top_label_1 = "EXT1";  // デフォルト値は異なってもOK
top_label_2 = "EXT2";
panel_title = "Expansion v0.1";
```

同じ変数名を使えば、1つの JSON プリセットで両方のファイルに同じ値を適用できる。

**トレードオフ:**
- 同じ変数名: プリセット共有可能、ただし include 時に衝突
- 異なる変数名: 衝突なし、ただしプリセット個別管理
- 独自の値が必要な変数（例: lid_title）は別名にする

### Modeling from Datasheets (データシートからのモデリング)

既製品（モーター、コネクタ等）をデータシートから正確にモデリングする際の注意点:

**1. 基準点を明確にする**

データシートの寸法は「何を含むか」が重要:
- 「ホルダー込み」vs「ホルダー除く」
- 「金属部のみ」vs「プラスチック部含む」
- 「突出部含む」vs「本体のみ」

```
例: FA-130 モーター
- 全長25.0mm = プラスチック部底面 〜 金属部天面（ホルダー除く）
- 金属ハウジング: 19.8mm
- プラスチックキャップ: 5.2mm
- 軸受けホルダー: 1.7mm（全長に含まない）
```

**2. 層構成を整理する**

複合構造は層として整理し、各層の高さと位置を明確にする:

```
FA-130 モーター（シャフト側から）:
┌────────────────┐ ← シャフト先端 (Z = 7.7)
│    シャフト     │
├────────────────┤ ← 金属ハウジング天面 (Z = -1.7)
│ 軸受けホルダー  │ h = 1.7
├────────────────┤ ← 原点 (Z = 0)
│                │
│ 金属ハウジング  │ h = 19.8
│                │
├────────────────┤ ← プラスチック部天面
│ プラスチック部  │ h = 5.2
├────────────────┤
│ ブラシカバー   │ h = 2.3
└────────────────┘ ← シャフト下端 (Z = -30.3)
```

**3. 貫通部品は全体計算で配置**

シャフトなど複数の層を通過する部品は、個別に両端から描画するのではなく、全体寸法から位置を計算:

```openscad
// 間違い: 両端から別々に描画
cylinder(h = shaft_len_top, ...);      // 上側
cylinder(h = shaft_len_bottom, ...);   // 下側

// 正しい: 全体寸法から計算
shaft_total = 38.0;
shaft_tip_z = metal_top_z + shaft_len;  // 先端位置
shaft_bottom_z = shaft_tip_z - shaft_total;  // 底端位置
translate([0, 0, shaft_bottom_z])
    cylinder(h = shaft_total, ...);  // 1本の円柱
```

**4. 2D図面と3D座標の対応**

データシートの図面視点と OpenSCAD の座標を論理的に対応させる:
- 「正面図」「上面図」「側面図」がどの軸方向か確認
- 図面上の「下」が 3D モデルのどの方向か明確にする
- 回転や反転が必要な場合は段階的に適用

**よくある失敗:**
- 基準点の解釈違いで全体がずれる（ホルダー込み/除く）
- 「〜から〜まで」の範囲を間違える
- 突出部の向きを 45° などと誤解（実際はフラット面方向など）
- 複数の寸法を足し合わせた時に重複や漏れがある

**確認方法:**
- 主要な基準点の Z 座標をコメントで記録
- echo() で計算結果を出力して検証
- 全体寸法が公称値と一致するか確認

### Incremental Model Construction (インクリメンタルなモデル構築)

複雑なモデルを一度に完成させようとすると、位置や向きの問題が積み重なり修正が困難になる。

**推奨アプローチ:**
1. 最も基本的な部品から始める（例: 本体の円柱）
2. 一つ部品を追加するごとにレンダリングして確認
3. 問題があればその場で修正
4. 次の部品に進む

```openscad
// ステップ1: 基本形状
cylinder(h = 5.2, d = 20.1);

// ステップ2: D形状にする（上下を削る）
difference() {
    cylinder(...);
    translate(...) cube(...);  // 上を削る
    translate(...) cube(...);  // 下を削る
}

// ステップ3: 次の部品を追加
// ...
```

**利点:**
- 問題の原因が明確（直前の変更が原因）
- 回転方向や位置のミスを早期発見
- 最終的なコードも段階的で理解しやすい

### Cylinder Rotation for X-Axis Extrusion (X軸方向への円柱伸長)

`cylinder()` はデフォルトで Z 軸方向に伸びる。X 軸方向に伸ばすには Y 軸周りに回転:

```openscad
// +X 方向に伸ばす（Z+ → X+）
rotate([0, 90, 0])
    cylinder(h = length, d = diameter);

// -X 方向に伸ばす（Z+ → X-）
rotate([0, -90, 0])
    cylinder(h = length, d = diameter);
```

**回転の仕組み:**
- `rotate([0, 90, 0])`: Y軸周りに+90°回転 → Z+ が X+ になる
- `rotate([0, -90, 0])`: Y軸周りに-90°回転 → Z+ が X- になる

**よくある間違い:**
- 符号を間違えると部品が逆方向に伸びる
- `linear_extrude` も同様の原理で回転が必要

### Angled Geometry with Trigonometry (三角関数による斜め構造)

斜めに伸びる構造（端子など）は三角関数で角度を計算:

```openscad
// 例: 長さ 4.0mm の端子が Z 方向に 1.4mm 上昇する場合
terminal_len = 4.0;
terminal_rise = 1.4;  // Z方向の上昇量

// Z軸からの傾き角度
terminal_angle = acos(terminal_rise / terminal_len);  // ≈ 69.5°

// 外側（+Y方向）に傾ける場合
rotate([-terminal_angle, 0, 0])  // 負の角度で +Y 方向に傾く
    translate([0, 0, terminal_len/2])
        cube([width, thickness, terminal_len], center = true);
```

**角度計算の選択:**
- `acos(Δz / length)`: Z軸からの角度（斜めに倒れる角度）
- `asin(Δz / length)`: 水平からの角度（仰角）

**回転符号の決定:**
- X軸周りの回転 `rotate([θ, 0, 0])`:
  - 正の角度: Z+ が Y- 方向に傾く
  - 負の角度: Z+ が Y+ 方向に傾く
- 外側に傾けるか内側に傾けるかで符号を決める

### Mating Structure Design (嵌合構造の設計)

既存パーツ（コネクタ、ブラケット等）と嵌合する構造を設計する場合:

**設計アプローチ:**
1. 嵌合相手の寸法を正確に把握する（データシート、NopSCADlib 等）
2. 各部位の役割を明確にする（位置決め、固定、収容など）
3. 層構造として整理し、各層の厚さを導出する

**例: コネクタ嵌合パネルの層構造**
```
┌─────────────────────┐
│   内部空間          │  ← 側壁
├─────────────────────┤  ← パネル構造（ブラケット凹み + D穴）
│ ▼ポケット（突出収容）│  ← 相手コネクタ突出部が入る
└─────────────────────┘  ← 底面（相手パネルに接地）
```

**寸法の導出:**
- 相手部品の突出量から必要なポケット深さを計算
- ブラケット厚からザグリ深さを決定
- 余裕（公差）は用途に応じて加算

### Screw Fastening Design (ネジ固定の設計)

ネジとナットで部品を固定する際の設計上の考慮点:

**1. ネジ長の目安**

理想的なネジ長さ ≒ ポスト高さ + ベース厚 + 材料厚（PCB等）

```openscad
// 例: post_h=15, base=3, pcb=1.6 → 19.6mm → 20mm のネジを使用
```

**2. ナットポケットの設計**

ネジ穴（細い円）は常に貫通。ナットポケット（六角）の深さは状況による:
- **ベース厚 >= ナット厚 + 0.6mm**: ポケットはベース内に収まる（ポスト底面まで掘らない）
- **ベース厚が薄い**: ポケットがポスト底面を貫通
- **ネジが短い**: ナットがポスト内に入る必要があり、深く掘る

```
ネジ穴（貫通）    ナットポケット（ベース内に収まる例）
    │                ┌───┐
    │                │   │ ← 六角（ベース底面から）
────┴────        ────┴───┴──── ← ベース上面に 0.6mm 残る
```

**3. ナットのアクセス性**

組み立て時にナットを挿入できる経路が必要:
- 底面から（最も一般的）
- 側面からスロット
- 上面から落とし込み

**4. ポスト形状の選択肢**

用途に応じて選択:
- **円柱**: シンプル、標準的
- **円錐形（底部が広い）**: 強度向上、印刷しやすさ

```openscad
// 円錐形ポスト
cylinder(h = post_h, d1 = base_d, d2 = top_d, $fn = 24);
```

### Shaft Hole Tolerance (シャフト穴の公差)

モーターシャフト等に嵌合する穴の tolerance は印刷テストで調整が必要:

| クリアランス | 結果 |
|-------------|------|
| 0.1mm | 小さすぎて入らない |
| 0.3mm | 大きすぎてガタつく |
| 0.2mm | ちょうど良い（FA-130 φ2mm シャフトの場合） |

**注意: これらの値は 3D プリント特有のもの。** 以下の要因で変わる:
- プリンターの機種・キャリブレーション
- フィラメント材質（PLA, PETG, ABS 等）
- 印刷方向（穴が水平か垂直か）
- 層高さ・インフィル設定

**教訓:**
- 最初の値が正しいとは限らない
- 小さすぎ/大きすぎの中間値を試す
- Customizer パラメータで調整可能にしておくと便利

```openscad
// シャフト穴クリアランス
shaft_tolerance = 0.2; // [0.1:0.1:0.5]

// シャフト穴
cylinder(h = hub_h, d = shaft_d + shaft_tolerance, $fn = 24);
```

### Fit Check Model Separation (フィットチェック用モデルの分離)

マウント内にフィットチェック用のモーターを表示する場合、マウントモジュール内に含めると親の `color()` に影響される:

```openscad
// 問題: マウント全体に color("white") を適用するとモーターも白くなる
color("white")
    mabuchi_motor_fa130_mount(show_motor = true);  // モーターも白い
```

**解決策: フィットチェック用モデルを別モジュールに分離**

```openscad
// マウント本体
if (show_mount) {
    color("white")
    translate([...]) rotate([...])
        mabuchi_motor_fa130_mount(...);
}

// フィットチェック用モーター（別モジュール、同じ変換を適用）
if (show_motor) {
    translate([...]) rotate([...])
        mabuchi_motor_fa130_in_mount(base = base);  // 色はモジュール内で指定
}
```

### Part Export Flags (パーツ個別出力フラグ)

複数パーツを含むデモファイルで、個別パーツを出力できるようにする:

```openscad
/* [表示設定] */
show_motor = false;     // フィットチェック用（デフォルト false）
show_propeller = true;
show_mount = true;
show_stand = true;

// 個別出力例: プロペラだけ
// openscad -o propeller.stl -D 'show_mount=false' -D 'show_stand=false' demo.scad
```

**ポイント:**
- `show_motor` はデフォルト `false`（印刷対象外）
- パーツ位置は `show_mount` 等の状態で切り替え（組み立て位置 or Z=0）

### Z-Fighting as Clearance Indicator (Z-fighting はクリアランス問題のサイン)

フィットチェック用モデルを表示した時に Z-fighting（面のちらつき）が発生する場合、クリアランスが正しく適用されていない可能性がある:

```openscad
// 問題: モーター位置が収納部とずれていて Z-fighting
module motor_in_mount() {
    translate([body_len, 0, 0])  // base を考慮していない
        rotate([0, 180, 0])
            motor();
}

// 修正: base を考慮
module motor_in_mount(base = 3) {
    translate([base + body_len, 0, 0])
        rotate([0, 180, 0])
            motor();
}
```

**確認方法:**
- 半透明（`%`）でマウントを表示し、モーターとの隙間を確認
- Z-fighting が見えたら位置計算を見直す

### Retention Clip Design (リテンションクリップ・爪の設計)

はめ込み式マウントの爪（カエシ）を設計する際の注意点:

**1. 爪先端の厚さを確保する**

爪先端が薄すぎると強度不足になる:
```openscad
// 悪い例: 先端が 0.1mm で細すぎる
cube([0.1, tab_depth, clip_width]);

// 良い例: 先端を 1mm 以上確保
cube([tab_tip, tab_depth, clip_width]);  // tab_tip = 1.0
```

**2. 爪の角度パラメータで挿入しやすさを調整**

爪先端を +X 方向（挿入口側）にオフセットすることで、パーツ挿入時に爪が開きやすくなる:
```openscad
// tab_angle で先端位置を調整
translate([mount_len + clip_length - tab_tip + tab_angle, ...])
    cube([tab_tip, tab_depth, clip_width]);
```
- `tab_angle = 2〜4mm` 程度が目安
- 大きすぎると保持力が弱くなる

**3. 爪の根元を適切に接続する**

爪の根元は外周（outer_d）に合わせ、X始点はケース終点に合わせる:
```openscad
// 爪根元のY位置を外周に合わせる
tab_base_y = dy * outer_d/2;

// X始点をケース終点（mount_len）に合わせる
hull() {
    translate([mount_len - 0.1, tab_base_y + ..., -clip_width/2])
        cube([0.1, arm_thickness, clip_width]);
    // 爪先端...
}
```

**4. flex_wall で根元の壁厚を調整**

スリットで挟まれた部分を内側から削ることで、爪の根元が曲げやすくなる:
```openscad
// flex_wall: スリット間の壁厚（wall より小さい値）
// 内側から (wall - flex_wall) 分削る
if (flex_wall > 0 && flex_wall < wall) {
    flex_cut_depth = wall - flex_wall;
    // 内側から円弧状に削る
}
```

**5. 内側から削る際の Z-fighting 対策**

内側から削るカットアウトは、隣接面と 0.1〜0.2mm オーバーラップさせる:
```openscad
// 内側の円は 0.2mm 小さく（オーバーラップ）
difference() {
    circle(d = inner_d + flex_cut_depth * 2);
    circle(d = inner_d - 0.2);  // ← オーバーラップ
}

// スリット方向（Z方向）にもオーバーラップ
square([clip_width + 0.2, ...]);  // ← 0.2mm 広げる
```

**パラメータ設計の指針:**
- 調整可能な箇所は個別パラメータ化する
- デフォルト値は印刷テスト後に調整
- 複数パラメータの相互作用を考慮（例: tab_angle と tab_depth）

### Module Reuse with Include (include によるモジュール再利用)

モジュールを単体でプレビュー可能にしつつ、他ファイルから include して使いたい場合がある。

**設計上の課題:**
- 単体で開いた時: トップレベルでレンダリングしてプレビューしたい
- include された時: トップレベルのレンダリングは不要（呼び出し側が配置する）

**解決策:**
- include する側でフラグ変数を定義してから include
- include される側は `is_undef(フラグ)` でスタンドアロン実行を検出
- トップレベルのレンダリングコードを条件分岐で囲む

**注意点:**
- `use` ではなく `include` を使う（変数も共有したい場合）
- フラグは include 文より前に定義する必要がある

### Multi-Axis Part Placement (多軸パーツ配置)

同一のパーツを複数の軸方向に配置する場合（3軸マウント等）の設計アプローチ。

**考え方:**
1. まずパーツのデフォルト向き（原点、軸方向）を明確にする
2. 各軸への変換を「最終的な向き」から逆算して導出する
3. 変換の順序に注意（OpenSCAD は右から左に適用）

**よくある失敗:**
- 試行錯誤で回転角度を調整 → 理解せずに動いても後で問題になる
- 複数の回転を一度に考える → 1軸ずつ追跡する方が確実

**干渉チェック:**
複数パーツを配置すると干渉が起きやすい。プレビューで確認し、オフセットで調整する。
オフセット変数は意図が分かる名前にする（`offset` より `lateral_offset` や `edge_margin`）。

### Fillet Strategies (フィレット戦略)

角を丸める方法は複数あり、状況に応じて使い分ける。

**1. hull() + cylinder による角丸プレート**
- BOSL2 なしで角丸プレートを作成できる
- 各平面方向（XY, XZ, YZ）で cylinder の回転が異なる
- XY平面: 回転不要、XZ平面: X軸周りに-90°、YZ平面: Y軸周りに90°

**2. minkowski() による内部フィレット**
- 球体との minkowski で全エッジを丸められる
- 計算コストが高い（プレビューが遅くなる）
- 元の形状サイズを縮小しておく必要がある（minkowski で膨らむため）

**3. カウンターシンク（面取り）**
- 穴の入口を円錐で広げる
- 完全なフィレットではないが、実用的で計算が軽い
- r1（大）から r2（小）への円錐で、深さ = r1 - r2

**組み合わせ:**
複雑な形状では複数の手法を組み合わせる。例えばコーナー穴では minkowski で内部を丸め、各面の入口にカウンターシンクを追加する。

### Hexagon Pocket Design (六角ポケット設計)

ナットポケットを設計する際の考慮点。

**寸法の変換:**
- ナットの公称寸法は「対辺」（平行な2辺間の距離）
- `circle($fn=6)` は指定直径の「外接円」を持つ六角形を描く
- 対辺から外接円直径への変換: `d = 対辺 / cos(30°)`

**クリアランス:**
- 3D プリントでは収縮や精度の問題でクリアランスが必要
- PLA で 0.3〜0.5mm 程度（プリンターや条件による）
- クリアランスは対辺寸法に加算してから外接円に変換

### Iterative Positioning (イテレーティブな位置調整)

パーツ配置を調整する際のワークフロー。

**アプローチ:**
1. まず計算で理論的な位置を決める
2. プレビューで確認し、問題点を特定
3. 調整は「比率」で行うと微調整しやすい
   - 例: `(total - part_size) / 2`（中央）→ `(total - part_size) * 2/3`（やや端寄り）

**よくあるパターン:**
- 中央配置: `(外形 - パーツ幅) / 2`
- 端配置: `外形 - パーツ幅 - マージン`
- 中間: 比率で調整 `(外形 - パーツ幅) * 係数`

**教訓:**
- 最初から完璧を目指さない
- 変数名で意図を明確にする（後から調整しやすい）
- 「ちょっと行き過ぎた」時に戻しやすい設計にする

### Practical Constraints (実用上の制約)

設計は理論だけでなく実用性も考慮する。

**ネジ止めのしやすさ:**
- 穴が壁に近すぎるとドライバーが入らない
- 手が入るスペースがあるか確認
- 組み立て順序を考慮（先に固定すると後のネジにアクセスできない等）

**ハーネス・配線:**
- 配線の通り道を設計段階で確保
- 穴のサイズはコネクタが通るか確認
- 曲げ半径を考慮（急な曲がりは断線リスク）

**手触り:**
- 3D プリントは角が鋭くなりやすい
- よく触る部分にはフィレットを追加
- 完全に丸められなくても改善は価値がある

### Fixture Coordinate System for Holes (穴用器具の座標系)

穴・凹みに収まる器具の座標系は、穴の向きに合わせて設計すると配置しやすい:
- 原点: 構造と接触する面
- 穴に入る部分: 穴の掘り方向と同じ向き

**フィットチェック配置:**
```openscad
// 凹みの底に配置（表面ではなく）
translate([0, 0, structure_thickness - recess_depth])
    fixture();
```

### Multi-Layer Structure (複数面を持つ構造)

3Dプリント構造の裏に別の面（実際の壁等）がある場合、両者を区別する:
- **3Dプリント構造**: 器具を保持する凹み・穴
- **裏側の面**: 貫通穴を通じてアクセスする面（針が刺さる壁等）

貫通穴が必要な場合、構造厚は「凹み深さ + 貫通部分の長さ」以上が必要。

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

### Side-Mounted Text (垂直壁へのテキスト配置)

垂直壁（前面、側面など）にマルチカラー用のテキストラベルを配置する場合:

**rotate() による座標変換の理解:**
```
rotate([90, 0, 0]):  +Z → -Y（視聴者に向かって押し出し）
rotate([-90, 0, 0]): +Z → +Y（壁内部へ押し出し）
```

壁内部へ彫り込む凹みには `rotate([-90, 0, 0])` を使用する。

**設計手順:**
1. **押し出し方向を決定**: 壁内部へ → `rotate([-90, 0, 0])`
2. **テキスト反転を補正**: 回転で Y→-Z となるため `mirror([0, 1, 0])` を追加
3. **凹みとテキストの位置を分離**: Z-fighting 回避のため 0.01mm オフセット

**実装例（前面壁へのタイトル）:**
```openscad
// テキストモジュール（rotate([-90,0,0]) 後に正しく読めるよう補正）
module front_title_text(txt) {
    linear_extrude(height = label_depth)
        mirror([0, 1, 0])
            text(txt, size = font_size, halign = "left", valign = "top");
}

// 凹みカットアウト（壁構造の difference 内で使用）
module front_title_cutout(txt) {
    linear_extrude(height = label_depth + 0.1)
        mirror([0, 1, 0])
            offset(delta = 0.05)
                text(txt, size = font_size, halign = "left", valign = "top");
}

// 凹み（壁の difference 内）
translate([title_x, -wall_y - 0.1, title_z])
    rotate([-90, 0, 0])
        front_title_cutout("Title");

// テキスト本体（出力セクション、壁より 0.01mm 手前）
translate([title_x, -wall_y - 0.01, title_z])
    rotate([-90, 0, 0])
        front_title_text("Title");
```

**よくある失敗:**
- `rotate([90, 0, 0])` を使用 → テキストが壁から飛び出す
- mirror を忘れる → テキストが上下反転
- 凹みとテキストが同一面 → Z-fighting でちらつく

### Design for Reusability (再利用性を考慮した設計)

複数ファイルで共通の設定を使いたい場合（Customizer プリセット共有など）:

**設計アプローチ:**
1. 共有したい項目を事前に洗い出す
2. 変数名を統一する（後から変更は影響範囲が大きい）
3. include 時の変数上書き挙動を理解しておく

**トレードオフ:**
- 同じ変数名: プリセット共有可能、ただし include 時に衝突
- 異なる変数名: 衝突なし、ただしプリセット個別管理

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

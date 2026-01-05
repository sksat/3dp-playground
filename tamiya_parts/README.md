# Tamiya Parts Library

タミヤ 楽しい工作シリーズ用ライブラリ。パーツモデルの表示や互換形状の生成に使用。

## 対応パーツ

### ユニバーサルプレート

| タイプ | 製品番号 | サイズ | グリッド |
|-------|---------|--------|---------|
| standard | 70098/70157 | 160×60mm | 31×11 |
| L | 70172 | 210×160mm | 41×31 |

グリッド仕様: 穴径 3mm、ピッチ 5mm

## 主要モジュール

### プレートモデル（フィットチェック用）

```openscad
use <../tamiya_parts.scad>

universal_plate_standard();  // 160×60mm プレート表示
universal_plate_L();         // 210×160mm プレート表示
```

### 穴パターン生成（difference用）

```openscad
use <../tamiya_parts.scad>

difference() {
    cube([80, 40, 5]);
    translate([5, 5, -0.1])
        universal_plate_holes(15, 7, depth = 5.2);
}
```

- `universal_plate_holes(cols, rows, depth, pitch, hole_d, tolerance)` - 任意グリッドの穴
- `plate_holes_cutout(type, depth, tolerance)` - プレートタイプに合わせた穴パターン
- `hole_pattern_rect(width, depth, plate_thickness, tolerance)` - 矩形領域に穴を自動配置

### アクセサリ

- `angle_bracket(type, tolerance)` - L字アングル材
- `shaft_mount(type, shaft_d, tolerance)` - 軸受け（三角形ブラケット）

## サンプル

`examples/` ディレクトリ:

- `plate_demo.scad` - プレートモデルと穴パターンのデモ
- `custom_part_with_holes.scad` - 自作パーツへの穴パターン追加例

## 参考

- タミヤ 楽しい工作シリーズ: https://www.tamiya.com/japan/products/70098/index.html

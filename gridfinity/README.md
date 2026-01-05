# Gridfinity Library

Gridfinity モジュラー収納システム用ライブラリ。ベースプレートとビン（箱）を生成。

## Gridfinity 仕様

| 項目 | 値 |
|------|-----|
| グリッドユニット | 42mm × 42mm |
| 高さユニット | 7mm (1U) |
| マグネット | 6mm径 × 2mm厚 |
| ネジ | M3 |

## 主要モジュール

### ベースプレート

```openscad
use <../gridfinity.scad>

gridfinity_baseplate(3, 2, magnets = true);  // 3×2 グリッド
```

- `gridfinity_baseplate(units_x, units_y, magnets, screws)` - 標準ベースプレート
- `gridfinity_baseplate_simple(units_x, units_y, magnets)` - 軽量版（壁なし）

### ビン（箱）

```openscad
use <../gridfinity.scad>

gridfinity_bin(2, 1, 3, lip = true);  // 2×1グリッド、3U高さ
```

- `gridfinity_bin(units_x, units_y, units_z, lip, wall_thickness)` - ビン生成

パラメータ:
- `units_x`, `units_y`: グリッド数
- `units_z`: 高さユニット数（7mm単位）
- `lip`: スタッキングリップの有無
- `wall_thickness`: 壁の厚さ（デフォルト: 1.2mm）

## 内部寸法

| 変数 | 値 | 説明 |
|------|-----|------|
| `grid_unit` | 42mm | 1グリッドのサイズ |
| `height_unit` | 7mm | 高さユニット |
| `bin_clearance` | 0.5mm | ビンとベースのクリアランス |
| `magnet_d` | 6.0mm | マグネット直径 |
| `magnet_h` | 2.0mm | マグネット厚さ |

## サンプル

`examples/` ディレクトリ:

- `baseplate_demo.scad` - ベースプレートのデモ
- `bin_demo.scad` - ビンのデモ

## 参考

- Gridfinity 公式: https://gridfinity.xyz/
- Gridfinity 仕様: https://github.com/gridfinity-unofficial/specification

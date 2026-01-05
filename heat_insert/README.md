# Heat-Set Insert Library

ヒートセットインサート用穴生成ライブラリ。CNC Kitchen仕様に基づく。

## 対応サイズ

| サイズ | 外径   | 穴径   | 長さ（標準） |
|-------|--------|--------|-------------|
| M2    | 3.6mm  | 3.2mm  | 3.0mm       |
| M2.5  | 4.6mm  | 4.0mm  | 4.0mm       |
| M3    | 4.6mm  | 4.4mm  | 4.0mm       |

長さバリエーション: `"short"`, `"standard"`, `"long"` または数値で直接指定

## 主要モジュール

### インサート穴（difference用）

```openscad
use <../heat_insert.scad>

difference() {
    cylinder(h = 10, d = 8, $fn = 24);  // ボス
    translate([0, 0, 10])
        m3_insert_hole();  // 上面から穴を開ける
}
```

- `insert_hole(size, length, tolerance, extra_depth)` - 汎用
- `m2_insert_hole(length, tolerance, extra_depth)` - M2専用
- `m2p5_insert_hole(length, tolerance, extra_depth)` - M2.5専用
- `m3_insert_hole(length, tolerance, extra_depth)` - M3専用

穴は原点から -Z 方向に掘られる（ボス上面に配置して使用）。

### ヘルパー関数

- `insert_specs(size, length)` - 寸法取得 `[外径, 穴径, 長さ]`
- `insert_boss_d(size, wall)` - 推奨ボス径（インサート外径 + 肉厚×2）

## サンプル

`examples/insert_demo.scad` - 各サイズのデモ

## 参考

- CNC Kitchen: https://www.cnckitchen.com/blog/tipps-amp-tricks-fr-gewindeeinstze-im-3d-druck-3awey

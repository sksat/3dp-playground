# Screw Post Library

ネジ止め用ポスト（ナットポケット付き）ライブラリ。PCBやパーツの固定に使用。

## 対応サイズ

| サイズ | ネジ穴径 | ナット二面幅 | ナット厚 |
|-------|---------|-------------|---------|
| M2    | 2.4mm   | 4.0mm       | 1.6mm   |
| M2.5  | 2.7mm   | 5.0mm       | 2.0mm   |
| M3    | 3.4mm   | 5.5mm       | 2.4mm   |

## 主要モジュール

### ポスト生成

```openscad
use <../screw_post.scad>

difference() {
    screw_post("M2.5", h = 10);
    screw_post_hole("M2.5", h = 10, screw_length = 8, material_thickness = 1.6);
}
```

- `screw_post(size, h, d_top, d_base)` - 円錐形ポスト本体
- `screw_post_hole(size, h, nut_side, ...)` - ネジ穴＋ナットポケット（difference用）
- `screw_post_with_hole(...)` - ポスト＋穴の一体型

サイズ別ショートカット:
- `m2_screw_post()`, `m2p5_screw_post()`, `m3_screw_post()`

### パラメータ

`screw_post_hole` の主要パラメータ:

| パラメータ | 説明 | デフォルト |
|-----------|------|-----------|
| `nut_side` | ナット位置 `"bottom"` / `"top"` | `"bottom"` |
| `screw_length` | ネジ長さ（指定時は nut_depth 自動計算） | - |
| `material_thickness` | 間に挟む材料の厚さ（PCB等） | 0 |
| `nut_depth` | ナットポケット深さ（直接指定） | 自動 |
| `base_thickness` | ベース板の厚さ | 3 |
| `tolerance` | クリアランス | 0.5 |

### ヘルパー関数

- `screw_specs(size)` - 寸法取得 `[穴径, ナット幅, ナット厚]`
- `screw_post_d(size, wall)` - 推奨ポスト径
- `calc_nut_depth(h, screw_length, material_thickness)` - ナットポケット深さ計算

## サンプル

`examples/screw_post_test.scad` - 各サイズのテスト用モデル

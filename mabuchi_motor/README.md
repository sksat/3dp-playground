# Mabuchi Motor Library

マブチモーター用OpenSCADライブラリ。フィットチェック用モーターモデル、はめ込み式マウント、シャフトカップラーを提供。

## 対応モーター

| タイプ | ハウジング寸法 | シャフト径 | シャフト長 | 形状 |
|--------|---------------|-----------|-----------|------|
| FA-130 | 20×15×25mm | 2mm | 8mm | D形状 |
| RE-260 | φ24×28mm | 2mm | 10mm | 円筒 |
| RE-280 | φ24×30.5mm | 2mm | 12.3mm | 円筒 |

## 主要モジュール

### フィットチェック用モーターモデル

```openscad
use <../mabuchi_motor.scad>

mabuchi_motor("FA-130");  // FA-130 モーター
mabuchi_motor("RE-260");  // RE-260 モーター
mabuchi_motor("RE-280");  // RE-280 モーター

// 便利モジュール
fa130_motor();
re260_motor();
re280_motor();
```

原点: シャフト根元（ハウジング前面中心）、シャフトは +Z 方向

### はめ込み式モーターマウント

```openscad
use <../mabuchi_motor.scad>

// マウント本体
mabuchi_motor_mount("FA-130", wall = 2, base = 3, tolerance = 0.3);

// 便利モジュール
fa130_mount(wall = 2, base = 3, tolerance = 0.3);
re260_mount();
re280_mount();
```

パラメータ:
- `wall`: 壁厚（デフォルト: 2mm）
- `base`: 底面厚さ（デフォルト: 3mm）
- `tolerance`: 嵌合クリアランス（デフォルト: 0.3mm）

### マウント用カットアウト（difference用）

```openscad
use <../mabuchi_motor.scad>

difference() {
    cube([30, 30, 35]);
    translate([15, 15, 35])
        rotate([180, 0, 0])
            mabuchi_motor_mount_cutout("FA-130", depth = 30, tolerance = 0.3);
}
```

### シャフトカップラー

```openscad
use <../mabuchi_motor.scad>

// 汎用カップラー
shaft_coupler(shaft_d = 2, outer_d = 8, length = 10, tolerance = 0.1);

// スリット付き（締め付け用）
shaft_coupler(shaft_d = 2, outer_d = 8, length = 10, with_slit = true);

// モータータイプ指定
mabuchi_shaft_coupler("FA-130", outer_d = 8, length = 10);
```

パラメータ:
- `shaft_d`: シャフト径（デフォルト: 2mm）
- `outer_d`: 外径（デフォルト: 8mm）
- `length`: 長さ（デフォルト: 10mm）
- `tolerance`: シャフト穴クリアランス（デフォルト: 0.1mm、タイトフィット）
- `with_slit`: スリット追加（締め付け用）
- `slit_width`: スリット幅（デフォルト: 1mm）

## ヘルパー関数

```openscad
// モーター仕様取得
// 戻り値: [width, height, length, shaft_d, shaft_length, terminal_length]
specs = mabuchi_motor_specs("FA-130");

// シャフト径のみ
d = mabuchi_shaft_d("FA-130");  // => 2
```

## サンプル

`examples/` ディレクトリ:

- `motor_mount_demo.scad` - マウントとモーターの組み合わせデモ

## 参考

- [Mabuchi FA-130RA Datasheet (Pololu)](https://www.pololu.com/file/0J11/fa_130ra.pdf)
- [Hobby Engineering - Mabuchi FA-130](https://www.hobbyengineering.com/products/h2242)

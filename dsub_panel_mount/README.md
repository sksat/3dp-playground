# D-SUB Panel Mount Library

D-SUBコネクタ用パネルマウントライブラリ。3Dプリントパネルにコネクタ穴、ブラケットザグリ、ナットポケットを追加する。

## 対応コネクタ

| タイプ | ピン数 | 内部ID |
|--------|-------|--------|
| DE-9   | 9     | db9    |
| DA-15  | 15    | db15   |
| DB-25  | 25    | db25   |
| DC-37  | 37    | db37   |

## 主要モジュール

### カットアウト（difference用）

```openscad
use <../dsub_panel_mount.scad>

difference() {
    cube([50, 30, 8]);
    translate([25, 15, 0]) de9_cutout();
}
```

- `de9_cutout(tol)` - DE-9用
- `da15_cutout(tol)` - DA-15用
- `db25_cutout(tol)` - DB-25用
- `dc37_cutout(tol)` - DC-37用
- `dsub_cutout(conn_type, tol)` - 汎用版

`tol` で公差を指定可能（デフォルト: 0.3mm、垂直面では 0.4〜0.5mm 推奨）。

### パネル生成

- `dsub_panel_mount(conn_type)` - 単一コネクタ用パネル
- `multi_dsub_panel_rows(rows, h_spacing, v_spacing)` - 複数コネクタの行配置
- `custom_dsub_panel(connectors, panel_width, panel_height)` - カスタムレイアウト

### 部品モジュール

- `dsub_opening(conn, gap, depth, taper)` - D型開口部（テーパー付き）
- `dsub_flange_recess(width, height, corner_r, depth)` - ブラケットザグリ
- `dsub_nut_recesses(conn, depth)` - M3ナットポケット
- `hex_nut_recess(width, depth, rotation)` - 六角ナット凹み

## 設計パラメータ

- `plate_thickness = 8` - 板厚（M3x8ネジ対応）
- `flange_recess_depth = 1.5` - ブラケットザグリ深さ
- `default_tolerance = 0.3` - デフォルト公差

## サンプル

`examples/` ディレクトリ:

- `sample_panel.scad` - 基本的な単一コネクタパネル
- `multi_connector_panel.scad` - 複数コネクタの配置例
- `enclosure_with_panel.scad` - エンクロージャ組み立て例
- `expansion_front.scad` / `expansion_top.scad` - 拡張パネル例

## 参考

- D-Sub形状: dpeart氏のライブラリ
- ブラケット寸法: NopSCADlib

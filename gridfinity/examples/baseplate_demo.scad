// Gridfinity Baseplate Demo
// ベースプレートのサンプル
//
// 外形: 84mm x 84mm x 7.25mm (2x2)
// 依存: gridfinity.scad
//
// ビルド:
//   openscad -o baseplate_2x2.stl baseplate_demo.scad

use <../gridfinity.scad>

// ===== Customizer =====

/* [Baseplate Size] */
// グリッド数 (X)
units_x = 2;  // [1:10]
// グリッド数 (Y)
units_y = 2;  // [1:10]

/* [Options] */
// マグネット穴を追加
magnets = true;
// M3ネジ穴を追加
screws = false;
// シンプル版（壁なし）を使用
simple_version = false;

// ===== 出力 =====

if (simple_version) {
    gridfinity_baseplate_simple(units_x, units_y, magnets);
} else {
    gridfinity_baseplate(units_x, units_y, magnets, screws);
}

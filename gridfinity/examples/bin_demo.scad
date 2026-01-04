// Gridfinity Bin Demo
// ビン（箱）のサンプル
//
// 外形: 41.5mm x 41.5mm x 25.4mm (1x1x3)
// 依存: gridfinity.scad
//
// ビルド:
//   openscad -o bin_1x1x3.stl bin_demo.scad

use <../gridfinity.scad>

// ===== Customizer =====

/* [Bin Size] */
// グリッド数 (X)
units_x = 1;  // [1:6]
// グリッド数 (Y)
units_y = 1;  // [1:6]
// 高さユニット数 (7mm単位)
units_z = 3;  // [1:10]

/* [Options] */
// スタッキングリップを追加
lip = true;
// 壁の厚さ (mm)
wall_thickness = 1.2;  // [0.8:0.1:2.0]

// ===== 出力 =====

gridfinity_bin(units_x, units_y, units_z, lip, wall_thickness);

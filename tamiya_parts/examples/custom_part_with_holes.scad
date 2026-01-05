// Custom Part with Universal Plate Holes
// ユニバーサルプレート互換穴付き自作パーツ
//
// 自作パーツにユニバーサルプレート互換の穴パターンを
// 追加するサンプル
//
// 外形: 80mm x 40mm x 5mm
//
// ビルド:
//   openscad -o custom_part_with_holes.stl custom_part_with_holes.scad

use <../tamiya_parts.scad>

// ===== パラメータ =====

plate_width = 80;
plate_depth = 40;
plate_thickness = 5;

// 穴パターン設定
hole_margin = 5;  // エッジからのマージン（ユニバーサルプレートと同じ5mm）

// ===== 本体 =====

difference() {
    // プレート本体
    color("blue")
        cube([plate_width, plate_depth, plate_thickness]);

    // ユニバーサルプレート互換穴パターン
    // 15×7グリッド（75mm×35mm相当）
    translate([hole_margin, hole_margin, -0.1])
        universal_plate_holes(15, 7, plate_thickness + 0.2);
}

// ===== フィットチェック用プレート表示 =====

show_reference_plate = false;

if (show_reference_plate) {
    // 参考: 実際のユニバーサルプレートを重ねて確認
    translate([0, 0, plate_thickness + 1])
        color("gray", 0.5)
            universal_plate_standard();
}

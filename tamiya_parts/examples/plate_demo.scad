// Tamiya Universal Plate Demo
// タミヤ ユニバーサルプレート デモ
//
// 各種プレートとアクセサリの可視化サンプル
//
// ビルド:
//   openscad -o plate_demo.stl plate_demo.scad

use <../tamiya_parts.scad>

// ===== 表示フラグ =====

show_standard_plate = true;
show_L_plate = true;
show_accessories = true;

// ===== 表示 =====

// 標準プレート（160×60mm）
if (show_standard_plate) {
    color("gray")
        universal_plate_standard();
}

// Lサイズプレート（210×160mm）
if (show_L_plate) {
    translate([0, 80, 0])
        color("gray")
            universal_plate_L();
}

// アクセサリ
if (show_accessories) {
    translate([180, 0, 0]) {
        // アングル材
        color("gray")
            angle_bracket();

        // 軸受け
        translate([30, 5, 0])
            color("gray")
                shaft_mount();
    }
}

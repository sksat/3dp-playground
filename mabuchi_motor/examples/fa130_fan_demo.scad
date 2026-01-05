// FA-130 Small Fan Demo
// FA-130 小型ファンデモ
//
// プロペラ付き小型送風機の例
//
// 外形: 約 50mm x 50mm x 50mm
// 使用モーター: FA-130 x1
//
// ビルド:
//   openscad --enable=lazy-union -O export-3mf/material-type=color \
//     -o fa130_fan_demo.3mf fa130_fan_demo.scad

include <../mabuchi_motor.scad>

// ===== Customizer パラメータ =====

/* [表示設定] */
// モーターモデルを表示（フィットチェック用）
show_motor = false;

// プロペラを表示
show_propeller = true;

// スタンドを表示
show_stand = true;

// マウントを表示
show_mount = true;

/* [ファン設定] */
// プロペラ直径
propeller_d = 40; // [30:5:60]

// プロペラ羽根数
blade_count = 3; // [2:1:6]

// シャフト穴クリアランス
shaft_tolerance = 0.2; // [0.1:0.1:0.5]

/* [マウント設定] */
// 嵌合クリアランス
tolerance = 0.3; // [0.1:0.05:0.5]

// 壁厚
wall = 2; // [1.5:0.5:3]

// ベース厚
base = 3; // [2:1:5]

// ===== 定数 =====

// マウント外形（外部定数から計算）
mount_outer_d = fa130_housing_d + tolerance + wall * 2;
mount_outer_h = fa130_housing_h + tolerance + wall * 2;
mount_len = fa130_body_len + base;

// スタンド寸法
stand_w = 50;
stand_d = 50;
stand_h = 8;
leg_h = 10;

// ===== モジュール =====

// プロペラ
module propeller(d = 40, blades = 3, hub_d = 10, hub_h = 8, shaft_tolerance = 0.2) {
    blade_w = d * 0.15;
    blade_t = 1.5;

    // ハブ
    difference() {
        cylinder(h = hub_h, d = hub_d, $fn = 32);
        // シャフト穴
        translate([0, 0, -0.1])
            cylinder(h = hub_h + 0.2, d = fa130_shaft_d + shaft_tolerance, $fn = 24);
    }

    // 羽根
    for (i = [0:blades-1]) {
        rotate([0, 0, i * 360 / blades])
            translate([hub_d/2 - 2, -blade_w/2, hub_h/2])
                hull() {
                    cube([1, blade_w, blade_t]);
                    translate([d/2 - hub_d/2, blade_w * 0.2, 3])
                        cube([1, blade_w * 0.6, blade_t]);
                }
    }
}

// ファンスタンド（脚付き）
module fan_stand() {
    // ベースプレート
    difference() {
        // 角丸の台座
        hull() {
            for (x = [5, stand_w - 5], y = [5, stand_d - 5]) {
                translate([x, y, 0])
                    cylinder(h = stand_h, r = 5, $fn = 24);
            }
        }

        // 通気穴（格子状）
        hole_spacing = 8;
        hole_d = 4;
        for (x = [hole_spacing : hole_spacing : stand_w - hole_spacing],
             y = [hole_spacing : hole_spacing : stand_d - hole_spacing]) {
            // マウント領域を避ける
            if (sqrt(pow(x - stand_w/2, 2) + pow(y - stand_d/2, 2)) > mount_outer_d/2 + 3) {
                translate([x, y, -0.1])
                    cylinder(h = stand_h + 0.2, d = hole_d, $fn = 16);
            }
        }
    }

    // 脚（4隅）
    for (x = [8, stand_w - 8], y = [8, stand_d - 8]) {
        translate([x, y, -leg_h])
            cylinder(h = leg_h, d = 8, $fn = 24);
    }
}

// ===== 組み立て =====

// スタンド
if (show_stand) {
    color("white")
    translate([-stand_w/2, -stand_d/2, 0])
        fan_stand();
}

// モーターマウント（スタンド上に配置、シャフト上向き）
// rotate([0, 90, 0]) でシャフト側（X=0）が上になる
if (show_mount) {
    color("white")
    translate([0, 0, stand_h + mount_len])
        rotate([0, 90, 0])
            mabuchi_motor_fa130_mount(wall = wall, base = base, tolerance = tolerance,
                                       anchor = "motor");
}

// フィットチェック用モーター（マウントと同じ変換を適用）
if (show_motor) {
    translate([0, 0, stand_h + mount_len])
        rotate([0, 90, 0])
            mabuchi_motor_fa130_in_mount(base = base);
}

// プロペラ
if (show_propeller) {
    // show_mount=true: 組み立て位置、false: 印刷用（Z=0）
    shaft_tip_z = show_mount ? stand_h + mount_len + fa130_shaft_protrusion + fa130_bearing_holder_len : 0;

    color("lightblue")
    translate([0, 0, shaft_tip_z])
        propeller(d = propeller_d, blades = blade_count, shaft_tolerance = shaft_tolerance);
}

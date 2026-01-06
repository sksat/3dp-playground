// FA-130 3-Axis Indicator Mount
// FA-130 3軸インジケータマウント
//
// L字型コーナーブラケットの3面に、fa130_mount_demo 形式の
// 横向きマウント+ベースプレートを固定
//
// 各ベースプレート4本、計12本のM3ネジで固定
//
// 使用モーター: FA-130 x3
// 使用ネジ: M3x8 x12（タミヤユニバーサルプレート対応穴ピッチ）
//
// ビルド:
//   openscad --enable=lazy-union -O export-3mf/material-type=color \
//     -o fa130_3axis_indicator.3mf fa130_3axis_indicator.scad

// fa130_mount_demo.scad を include（モジュールと寸法を使用）
_fa130_mount_demo_included = true;
include <fa130_mount_demo.scad>

// ===== Customizer パラメータ =====

/* [表示設定] */
show_motors = false;
show_mounts = true;
show_indicators = true;
show_bracket = true;

/* [インジケータ設定] */
disc_d = 25;
disc_h = 3;
shaft_tolerance = 0.2;
spiral_w = 1.5;
spiral_depth = 0.6;
spiral_turns = 2;

/* [ブラケット設定] */
bracket_wall = 4;

// ===== 導出寸法 =====

// L字ブラケットサイズ（モーター+インジケータが内側に収まるサイズ）
shaft_protrusion_total = fa130_shaft_protrusion + fa130_bearing_holder_len;
bracket_size = base_d + shaft_protrusion_total + disc_d + 15;

// M3ナット
m3_nut_width = 5.5;
m3_nut_pocket_depth = 3;

// コーナーからの配置オフセット
offset = 5;

// ===== インジケータモジュール =====

module spiral_2d(r_inner, r_outer, width, turns, steps_per_turn = 36) {
    total_steps = turns * steps_per_turn;
    growth = (r_outer - r_inner) / turns;
    outer_points = [for (i = [0:total_steps])
        let(theta = i * 360 / steps_per_turn, r = r_inner + (i / steps_per_turn) * growth)
        [r * cos(theta), r * sin(theta)]];
    inner_points = [for (i = [total_steps:-1:0])
        let(theta = i * 360 / steps_per_turn,
            r = max(r_inner - width/2, width/2) + (i / steps_per_turn) * growth - width/2)
        [r * cos(theta), r * sin(theta)]];
    polygon(concat(outer_points, inner_points));
}

module indicator_disc() {
    r_inner = (fa130_shaft_d + shaft_tolerance) / 2 + 0.5;
    r_outer = disc_d / 2 - 1;
    difference() {
        cylinder(h = disc_h, d = disc_d, $fn = 48);
        translate([0, 0, -0.1])
            cylinder(h = disc_h + 0.2, d = fa130_shaft_d + shaft_tolerance, $fn = 24);
        translate([0, 0, disc_h - spiral_depth])
            linear_extrude(height = spiral_depth + 0.1)
                spiral_2d(r_inner, r_outer, spiral_w, spiral_turns);
    }
}

module indicator_spiral() {
    r_inner = (fa130_shaft_d + shaft_tolerance) / 2 + 0.5;
    r_outer = disc_d / 2 - 1;
    translate([0, 0, disc_h - spiral_depth])
        linear_extrude(height = spiral_depth)
            spiral_2d(r_inner, r_outer, spiral_w, spiral_turns);
}

// ===== マウント+インジケータユニット =====
// fa130_mount_unit() を使用し、インジケータを追加
// fa130_mount_demo のシャフトは -Y 方向

module mount_with_indicator() {
    // マウントユニット（fa130_mount_demo.scad から）
    fa130_mount_unit(show_base = true, show_mount = show_mounts, show_motor = show_motors);

    // インジケータ（シャフト先端、-Y 方向）
    if (show_indicators) {
        translate([mount_x, shaft_tip_y, mount_z])
            rotate([90, 0, 0]) {
                color("white") indicator_disc();
                color("black") indicator_spiral();
            }
    }
}

// ===== L字ブラケット =====

module m3_nut_2d() {
    circle(d = m3_nut_width / cos(30), $fn = 6);
}

module l_bracket() {
    // 穴位置（中央基準でピッチ配置）
    hole_positions = [
        for (dx = [-1, 1], dy = [-1, 1])
            [base_w/2 + dx * mount_hole_pitch_x/2,
             base_d/2 + dy * mount_hole_pitch_y/2]
    ];

    difference() {
        union() {
            cube([bracket_size, bracket_size, bracket_wall]);           // 底面
            cube([bracket_size, bracket_wall, bracket_size]);           // 前面
            cube([bracket_wall, bracket_size, bracket_size]);           // 側面
        }

        // 底面の穴（Y軸用）
        for (pos = hole_positions)
            translate([offset + pos[0], offset + pos[1], -0.1]) {
                cylinder(h = bracket_wall + 0.2, d = mount_hole_d, $fn = 24);
                linear_extrude(height = m3_nut_pocket_depth) m3_nut_2d();
            }

        // 前面の穴（Z軸用）
        for (pos = hole_positions)
            translate([offset + pos[0], -0.1, offset + pos[1]])
                rotate([-90, 0, 0]) {
                    cylinder(h = bracket_wall + 0.2, d = mount_hole_d, $fn = 24);
                    linear_extrude(height = m3_nut_pocket_depth) m3_nut_2d();
                }

        // 側面の穴（X軸用）
        for (pos = hole_positions)
            translate([-0.1, offset + pos[1], offset + pos[0]])
                rotate([0, 90, 0]) {
                    cylinder(h = bracket_wall + 0.2, d = mount_hole_d, $fn = 24);
                    linear_extrude(height = m3_nut_pocket_depth) m3_nut_2d();
                }
    }
}

// ===== 組み立て =====

if (show_bracket) {
    color("white") l_bracket();
}

// X軸モーター: XY平面（底面）に配置、シャフトは +X 方向
// ベースの底面が Z = bracket_wall（底面壁の上面）に接触
// rotate([0, 0, 90]) で -Y → +X、ベース範囲 X[-base_d,0] Y[0,base_w]
translate([offset + base_d, offset, bracket_wall])
    rotate([0, 0, 90])
        mount_with_indicator();

// Y軸モーター: YZ平面（側面）に配置、シャフトは +Y 方向
// rotate([0, 90, 0]) rotate([0, 0, 180]) で:
//   シャフト -Y → +Y、ベース法線 +Z → -X（ベース裏面が側面壁に接触）
//   ベース範囲: X[0,base_h], Y[-base_d,0], Z[0,base_w]
translate([bracket_wall, offset + base_d, offset])
    rotate([0, 90, 0])
        rotate([0, 0, 180])
            mount_with_indicator();

// Z軸モーター: XZ平面（前面）に配置、シャフトは +Z 方向
// ベースの底面が Y = bracket_wall（前面壁の内側面）に接触
// rotate([-90, 0, 0]) でベース範囲 X[0,base_w] Y[0,base_h] Z[-base_d,0]
translate([offset, bracket_wall, offset + base_d])
    rotate([-90, 0, 0])
        mount_with_indicator();

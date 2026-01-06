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
show_bases = true;
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
bracket_fillet = 2;  // 外側エッジのフィレット半径

// ===== 導出寸法 =====

// L字ブラケットサイズ（モーター+インジケータが内側に収まるサイズ）
shaft_protrusion_total = fa130_shaft_protrusion + fa130_bearing_holder_len;
bracket_size = base_d + shaft_protrusion_total + disc_d + 15;

// M3ナット
m3_nut_width = 5.5;      // 対辺寸法（実寸）
m3_nut_clearance = 0.4;  // PLA 3DP 用クリアランス
m3_nut_pocket_depth = 3;

// ハーネス穴（L字中心部）
harness_hole_d = 40;  // ハーネス穴直径

// コーナーからの配置オフセット（端からの余裕）
edge_margin = 1;  // インジケータ先端から端までの余裕

// インジケータを端に配置するためのオフセット
// インジケータ先端が bracket_size - edge_margin に来るように計算
indicator_offset = bracket_size - edge_margin - disc_h - shaft_protrusion_total;

// 横方向のオフセット（中央と端の中間くらい）
lateral_offset = (bracket_size - base_w) * 2 / 3;

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
    fa130_mount_unit(show_base = show_bases, show_mount = show_mounts, show_motor = show_motors);

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
    // 対辺寸法 + クリアランスから対角寸法を計算
    circle(d = (m3_nut_width + m3_nut_clearance) / cos(30), $fn = 6);
}

module l_bracket() {
    // 穴位置（ベースプレートローカル座標、中央基準でピッチ配置）
    hole_positions = [
        for (dx = [-1, 1], dy = [-1, 1])
            [base_w/2 + dx * mount_hole_pitch_x/2,
             base_d/2 + dy * mount_hole_pitch_y/2]
    ];

    // 穴とナットポケット
    module hole_with_nut() {
        cylinder(h = bracket_wall + 0.2, d = mount_hole_d, $fn = 24);
        linear_extrude(height = m3_nut_pocket_depth) m3_nut_2d();
    }

    // 角丸の板（XY平面）
    module rounded_plate_xy(size_x, size_y, thickness, r) {
        hull() {
            for (x = [r, size_x - r], y = [r, size_y - r])
                translate([x, y, 0])
                    cylinder(h = thickness, r = r, $fn = 24);
        }
    }

    // 角丸の板（XZ平面）
    module rounded_plate_xz(size_x, size_z, thickness, r) {
        hull() {
            for (x = [r, size_x - r], z = [r, size_z - r])
                translate([x, 0, z])
                    rotate([-90, 0, 0])
                        cylinder(h = thickness, r = r, $fn = 24);
        }
    }

    // 角丸の板（YZ平面）
    module rounded_plate_yz(size_y, size_z, thickness, r) {
        hull() {
            for (y = [r, size_y - r], z = [r, size_z - r])
                translate([0, y, z])
                    rotate([0, 90, 0])
                        cylinder(h = thickness, r = r, $fn = 24);
        }
    }

    difference() {
        union() {
            rounded_plate_xy(bracket_size, bracket_size, bracket_wall, bracket_fillet);  // 底面
            rounded_plate_xz(bracket_size, bracket_size, bracket_wall, bracket_fillet);  // 前面
            rounded_plate_yz(bracket_size, bracket_size, bracket_wall, bracket_fillet);  // 側面
        }

        // 底面の穴（X軸モーター用）
        // モーターと同じ transform を使用: translate + rotate([0, 0, 90])
        translate([indicator_offset, lateral_offset, -0.1])
            rotate([0, 0, 90])
                for (pos = hole_positions)
                    translate([pos[0], pos[1], 0])
                        hole_with_nut();

        // 前面の穴（Z軸モーター用）
        // モーターと同じ transform を使用: translate + rotate([-90, 0, 0])
        translate([lateral_offset, -0.1, indicator_offset])
            rotate([-90, 0, 0])
                for (pos = hole_positions)
                    translate([pos[0], pos[1], 0])
                        hole_with_nut();

        // 側面の穴（Y軸モーター用）
        // モーターと同じ transform を使用: translate + rotate([0, 90, 0]) rotate([0, 0, 180])
        // rotate([0, 90, 0]) で cylinder は +X 方向に伸びる
        translate([-0.1, indicator_offset, lateral_offset])
            rotate([0, 90, 0])
                rotate([0, 0, 180])
                    for (pos = hole_positions)
                        translate([pos[0], pos[1], 0])
                            hole_with_nut();

        // ハーネス穴（L字の角を貫通）
        // 角の内側から斜めに貫通する穴（フィレット付き）
        translate([bracket_wall, bracket_wall, bracket_wall])
            minkowski() {
                sphere(d = harness_hole_d - bracket_fillet * 2, $fn = 32);
                sphere(r = bracket_fillet, $fn = 16);
            }

        // 穴入り口のフィレット（各面）
        harness_fillet_r = 3;  // 穴入り口のフィレット半径
        // 底面（Z=0）
        translate([bracket_wall, bracket_wall, -0.1])
            cylinder(h = harness_fillet_r + 0.1, r1 = harness_hole_d/2 + harness_fillet_r, r2 = harness_hole_d/2, $fn = 48);
        // 前面（Y=0）
        translate([bracket_wall, -0.1, bracket_wall])
            rotate([-90, 0, 0])
                cylinder(h = harness_fillet_r + 0.1, r1 = harness_hole_d/2 + harness_fillet_r, r2 = harness_hole_d/2, $fn = 48);
        // 側面（X=0）
        translate([-0.1, bracket_wall, bracket_wall])
            rotate([0, 90, 0])
                cylinder(h = harness_fillet_r + 0.1, r1 = harness_hole_d/2 + harness_fillet_r, r2 = harness_hole_d/2, $fn = 48);
    }
}

// ===== 組み立て =====

if (show_bracket) {
    color("white") l_bracket();
}

// X軸モーター: XY平面（底面）に配置、シャフトは +X 方向
// インジケータが +X 端、横方向（Y）は端寄り
translate([indicator_offset, lateral_offset, bracket_wall])
    rotate([0, 0, 90])
        mount_with_indicator();

// Y軸モーター: YZ平面（側面）に配置、シャフトは +Y 方向
// インジケータが +Y 端、横方向（Z）は端寄り
translate([bracket_wall, indicator_offset, lateral_offset])
    rotate([0, 90, 0])
        rotate([0, 0, 180])
            mount_with_indicator();

// Z軸モーター: XZ平面（前面）に配置、シャフトは +Z 方向
// インジケータが +Z 端、横方向（X）は端寄り
translate([lateral_offset, bracket_wall, indicator_offset])
    rotate([-90, 0, 0])
        mount_with_indicator();

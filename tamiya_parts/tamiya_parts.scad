// Tamiya Universal Plate Library
// タミヤ ユニバーサルプレート ライブラリ
//
// 提供モジュール:
//   universal_plate(type, tolerance)         - プレートモデル
//   universal_plate_standard(), universal_plate_L()
//   universal_plate_holes(cols, rows, ...)   - 穴パターン生成
//   plate_holes_cutout(type, ...)            - プレート全体の穴
//   hole_pattern_rect(width, depth, ...)     - 矩形領域の穴
//   angle_bracket(type, tolerance)           - アングル材
//   shaft_mount(type, shaft_d, tolerance)    - 軸受け
//
// 対応製品:
//   70098/70157: ユニバーサルプレート 160×60mm
//   70172: ユニバーサルプレートL 210×160mm
//
// 参考: タミヤ 楽しい工作シリーズ
//       https://www.tamiya.com/japan/products/70098/index.html
//
// 使用例:
//   // フィットチェック用プレート表示
//   universal_plate_standard();
//
//   // 自作パーツに穴パターンを追加
//   difference() {
//       cube([80, 40, 5]);
//       translate([5, 5, -0.1])
//           universal_plate_holes(15, 7, 5.2);
//   }

// ===== 定数 =====

hole_diameter = 3;
hole_pitch = 5;
default_tolerance = 0.2;

// ===== ルックアップテーブル =====

// ユニバーサルプレート仕様
// 戻り値: [width, depth, thickness, grid_cols, grid_rows]
function universal_plate_specs(type) =
    type == "standard" ? [160, 60, 3, 31, 11] :
    type == "70098"    ? [160, 60, 3, 31, 11] :
    type == "70157"    ? [160, 60, 3, 31, 11] :
    type == "L"        ? [210, 160, 3, 41, 31] :
    type == "70172"    ? [210, 160, 3, 41, 31] :
    undef;

// アングル材仕様（推定値、実測で要調整）
// 戻り値: [leg_length, width, thickness, holes_per_leg]
function angle_bracket_specs(type) =
    type == "standard" ? [20, 10, 3, 4] :
    undef;

// 軸受け仕様（推定値、実測で要調整）
// 戻り値: [base_width, height, thickness, shaft_hole_d]
function shaft_mount_specs(type) =
    type == "standard" ? [15, 20, 3, 3] :
    undef;

// ===== 内部2Dモジュール =====

// 単一穴（2D）
module _hole_2d(d = hole_diameter, tolerance = 0) {
    circle(d = d + tolerance, $fn = 24);
}

// 穴グリッド（2D）
module _hole_grid_2d(cols, rows, pitch = hole_pitch, hole_d = hole_diameter, tolerance = 0) {
    for (x = [0:cols-1], y = [0:rows-1]) {
        translate([x * pitch, y * pitch])
            _hole_2d(hole_d, tolerance);
    }
}

// ===== プレートモデル（フィットチェック用） =====

// ユニバーサルプレート
// 原点: 角（0,0,0）、+X/+Y/+Z方向に延伸
// 穴開始位置: エッジから5mm（1ピッチ分のマージン）
module universal_plate(type = "standard", tolerance = default_tolerance, show_holes = true) {
    specs = universal_plate_specs(type);

    if (is_undef(specs)) {
        echo(str("ERROR: Unknown plate type: ", type));
        echo("Available types: standard, L, 70098, 70157, 70172");
        color("red") cube([10, 10, 10]);
    } else {
        w = specs[0];
        d = specs[1];
        t = specs[2];
        grid_x = specs[3];
        grid_y = specs[4];
        margin = hole_pitch;

        difference() {
            cube([w, d, t]);
            if (show_holes) {
                translate([margin, margin, -0.1])
                    linear_extrude(t + 0.2)
                        _hole_grid_2d(grid_x, grid_y, hole_pitch, hole_diameter, tolerance);
            }
        }
    }
}

// 標準サイズ（160×60mm）
module universal_plate_standard(tolerance = default_tolerance, show_holes = true) {
    universal_plate("standard", tolerance, show_holes);
}

// Lサイズ（210×160mm）
module universal_plate_L(tolerance = default_tolerance, show_holes = true) {
    universal_plate("L", tolerance, show_holes);
}

// ===== 穴パターン生成（自作パーツ用） =====

// 任意グリッドの穴パターン（difference用）
// 原点から+X/+Y方向にグリッド配置
module universal_plate_holes(cols, rows, depth = 3, pitch = hole_pitch,
                             hole_d = hole_diameter, tolerance = default_tolerance) {
    linear_extrude(depth + 0.1)
        _hole_grid_2d(cols, rows, pitch, hole_d, tolerance);
}

// プレートタイプに合わせた穴パターン（difference用）
// マージン込みで配置
module plate_holes_cutout(type = "standard", depth = 3, tolerance = default_tolerance) {
    specs = universal_plate_specs(type);

    if (!is_undef(specs)) {
        grid_x = specs[3];
        grid_y = specs[4];
        margin = hole_pitch;

        translate([margin, margin, -0.1])
            universal_plate_holes(grid_x, grid_y, depth, hole_pitch, hole_diameter, tolerance);
    }
}

// 矩形領域に穴パターンを生成（difference用）
// 指定した幅・奥行きに収まるグリッドを自動計算
module hole_pattern_rect(width, depth, plate_thickness = 3, tolerance = default_tolerance) {
    cols = floor(width / hole_pitch);
    rows = floor(depth / hole_pitch);

    if (cols > 0 && rows > 0) {
        universal_plate_holes(cols, rows, plate_thickness, hole_pitch, hole_diameter, tolerance);
    }
}

// ===== アクセサリモジュール =====

// L字アングル材
// 原点: 角部分の内側角
module angle_bracket(type = "standard", tolerance = default_tolerance) {
    specs = angle_bracket_specs(type);

    if (is_undef(specs)) {
        echo(str("ERROR: Unknown angle bracket type: ", type));
        color("red") cube([10, 10, 10]);
    } else {
        leg = specs[0];
        w = specs[1];
        t = specs[2];
        holes = specs[3];

        difference() {
            union() {
                // 水平脚
                cube([leg, w, t]);
                // 垂直脚
                cube([t, w, leg]);
            }
            // 水平脚の穴
            for (i = [0:holes-1]) {
                translate([hole_pitch / 2 + i * hole_pitch, w / 2, -0.1])
                    cylinder(h = t + 0.2, d = hole_diameter + tolerance, $fn = 24);
            }
            // 垂直脚の穴
            for (i = [0:holes-1]) {
                translate([-0.1, w / 2, hole_pitch / 2 + i * hole_pitch])
                    rotate([0, 90, 0])
                        cylinder(h = t + 0.2, d = hole_diameter + tolerance, $fn = 24);
            }
        }
    }
}

// 軸受け（三角形ブラケット）
// 原点: 底辺中央
module shaft_mount(type = "standard", shaft_d = 3, tolerance = default_tolerance) {
    specs = shaft_mount_specs(type);

    if (is_undef(specs)) {
        echo(str("ERROR: Unknown shaft mount type: ", type));
        color("red") cube([10, 10, 10]);
    } else {
        base_w = specs[0];
        h = specs[1];
        t = specs[2];

        difference() {
            // 三角形プロファイルを押し出し
            linear_extrude(t)
                polygon([[0, 0], [base_w, 0], [base_w / 2, h]]);

            // シャフト穴（上部）
            translate([base_w / 2, h * 0.7, -0.1])
                cylinder(h = t + 0.2, d = shaft_d + tolerance, $fn = 24);

            // 取付穴（下部両端）
            for (x = [base_w * 0.25, base_w * 0.75]) {
                translate([x, h * 0.15, -0.1])
                    cylinder(h = t + 0.2, d = hole_diameter + tolerance, $fn = 24);
            }
        }
    }
}

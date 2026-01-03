// D-SUB Panel Mount Bracket (Top Panel for Enclosure)
// D-Subコネクタ用パネルマウント天板
//
// D-Sub形状: dpeart氏のライブラリを参考 (http://forums.reprap.org/read.php?313,577003)
// ブラケット寸法: NopSCADlib を参考 (https://github.com/nophead/NopSCADlib)

// ===== パラメータ =====

// 3Dプリント公差
tolerance = 0.3;  // 開口部の余裕

// 板設定
plate_thickness = 8;          // 板の厚さ (M3x8ネジ対応)
plate_margin = 8;             // コネクタ周囲の余白

// フランジ（標準ブラケット）ザグリ設定
flange_recess_depth = 1.5;    // ザグリ深さ (ブラケット厚さ、標準1.12mm + 余裕)
flange_corner_r = 0.5;        // ブラケット角のR (ほぼ角張り)

// M3ナット設定
m3_nut_width = 5.5;           // 二面幅 (対辺)
m3_nut_depth = 2.5;           // ナットの厚さ (2.4mm) + 少し余裕

// ===== D-Sub コネクタ寸法テーブル =====
// D型開口部 (dpeart氏のライブラリより)
// [b, d, f, k] = [取付穴中心距離/2, 開口幅/2, 開口高さ/2, 角R]
function db_opening_table(idx) =
    idx == "db9"  ? [12.50, 11.10, 6.53, 2.11] :
    idx == "db15" ? [16.66, 15.27, 6.53, 2.11] :
    idx == "db25" ? [23.52, 22.15, 6.53, 2.11] :
    idx == "db37" ? [31.75, 29.54, 6.53, 2.11] :
    "Error";

// ブラケット外形 (NopSCADlibより)
// [幅, 高さ, flange_thickness]
function db_bracket_table(idx) =
    idx == "db9"  ? [30.81,  12.55, 1.12] :  // DE-9
    idx == "db15" ? [39.14,  12.55, 1.12] :  // DA-15
    idx == "db25" ? [53.04,  12.55, 1.12] :  // DB-25
    idx == "db37" ? [69.50,  12.55, 1.12] :  // DC-37
    "Error";

// ===== 使用するコネクタタイプ =====
// connector_type = "db9";  // db9, db15, db25, db37 (単体生成時に使用)

// ===== モジュール =====

// D型形状 (2D) - 開口部用
module dsub_shape_2d(conn, gap = 0) {
    sides = 32;
    cut_angle = 10;  // D型の傾斜角度

    conn_dimensions = db_opening_table(conn);

    if (conn_dimensions != "Error") {
        d = conn_dimensions[1];  // 開口幅/2
        f = conn_dimensions[2];  // 開口高さ/2
        k = conn_dimensions[3];  // 角R (直径として使用)

        g = gap;  // 公差
        o = 2 * (g + f - k) * tan(cut_angle);  // D型のオフセット量

        hull() {
            // 上側 (広い側)
            translate([-(g + d - k), (g + f - k)])
                circle(d = k, $fn = sides);  // 修正: d=k (直径=k)
            translate([(g + d - k), (g + f - k)])
                circle(d = k, $fn = sides);
            // 下側 (狭い側) - D型の特徴
            translate([-(g + d - k) + o, -(g + f - k)])
                circle(d = k, $fn = sides);
            translate([(g + d - k) - o, -(g + f - k)])
                circle(d = k, $fn = sides);
        }
    }
}

// D-Sub開口部 (貫通穴、テーパー付き)
// 表面側は公差付き、奥側は絞って固定強化
module dsub_opening(conn, gap = 0, depth = 1, taper = true) {
    mounting_hole = 3.05;
    conn_dimensions = db_opening_table(conn);

    // テーパー設定: 表面側の深さ (ナット凹み直上まで)
    taper_depth = plate_thickness - m3_nut_depth;  // 約7mm
    inner_gap = -0.2;  // 奥側は少し小さく

    if (conn_dimensions == "Error") {
        echo(str("ERROR: Connector '", conn, "' not found"));
        color("red") cube([10, 10, depth], center = true);
    } else {
        b = conn_dimensions[0];  // 取付穴中心距離/2
        g = gap;

        if (taper && depth > taper_depth) {
            // 表面側: 公差付きD型開口
            translate([0, 0, depth - taper_depth])
                linear_extrude(height = taper_depth + 0.1)
                    dsub_shape_2d(conn, gap);

            // 奥側: 絞ったD型開口
            linear_extrude(height = depth - taper_depth + 0.1)
                dsub_shape_2d(conn, inner_gap);
        } else {
            // テーパーなし（従来通り）
            linear_extrude(height = depth)
                dsub_shape_2d(conn, gap);
        }

        // 取付穴 (貫通)
        translate([-b, 0, 0])
            cylinder(h = depth, d = g * 0.6 + mounting_hole, $fn = 24);
        translate([b, 0, 0])
            cylinder(h = depth, d = g * 0.6 + mounting_hole, $fn = 24);
    }
}

// フランジ用ザグリ (ブラケットが収まる長方形の凹み)
module dsub_flange_recess(width, height, corner_r, depth) {
    // 角丸長方形 (ほぼ長方形)
    linear_extrude(height = depth) {
        offset(r = corner_r) {
            offset(r = -corner_r) {
                square([width, height], center = true);
            }
        }
    }
}

// 六角ナット用凹み
module hex_nut_recess(width, depth, rotation = 0) {
    // 六角形 (二面幅 = width)
    rotate([0, 0, rotation])
        cylinder(h = depth, d = width / cos(30), $fn = 6);
}

// M3ナット凹み (裏面用)
// D型斜辺と平行に六角ナットを配置
// cylinder($fn=6)の辺方向: 60°, 120°, 180°, 240°, 300°, 0°
// D型斜辺: 右=80°, 左=100° (cut_angle=10°のとき)
module dsub_nut_recesses(conn, depth) {
    conn_dimensions = db_opening_table(conn);
    cut_angle = 10;  // D型の傾斜角度
    // 斜辺角度: 90° ± cut_angle
    // 六角形の60°辺→80°: +20°回転、120°辺→100°: -20°回転
    nut_rotation = 90 - cut_angle - 60;  // = 20°
    if (conn_dimensions != "Error") {
        b = conn_dimensions[0];  // 取付穴中心距離/2
        // 左側: 斜辺は100°方向 → 120°の辺を-20°回転
        translate([-b, 0, 0])
            hex_nut_recess(m3_nut_width + tolerance, depth, -nut_rotation);
        // 右側: 斜辺は80°方向 → 60°の辺を+20°回転
        translate([b, 0, 0])
            hex_nut_recess(m3_nut_width + tolerance, depth, nut_rotation);
    }
}

// ===== メイン =====

module dsub_panel_mount(conn_type = "db9") {
    opening = db_opening_table(conn_type);
    bracket = db_bracket_table(conn_type);

    if (opening == "Error" || bracket == "Error") {
        echo(str("ERROR: Invalid connector type: ", conn_type));
    } else {
        b = opening[0];  // 取付穴中心距離/2
        d = opening[1];  // 開口幅/2
        f = opening[2];  // 開口高さ/2

        bracket_w = bracket[0];  // ブラケット幅
        bracket_h = bracket[1];  // ブラケット高さ

        // プレートサイズの計算 (取付穴が収まるサイズ)
        center_width = b * 2 + plate_margin * 2;
        center_height = (f + tolerance) * 2 + plate_margin * 2;

        difference() {
            // プレート
            translate([-center_width/2, -center_height/2, 0])
                cube([center_width, center_height, plate_thickness]);

            // フランジ用ザグリ (上面から掘り下げ、長方形)
            translate([0, 0, plate_thickness - flange_recess_depth])
                dsub_flange_recess(bracket_w + tolerance, bracket_h + tolerance, flange_corner_r, flange_recess_depth + 0.1);

            // D-Sub開口部 (貫通穴)
            translate([0, 0, -0.1])
                dsub_opening(conn_type, tolerance, plate_thickness + 0.2);
        }
    }
}

// ===== 複数コネクタ用パネル (行ベース) =====

// 各行は [コネクタタイプ, 個数] の形式
// 例: [["db9", 3], ["db15", 1]] = DE-9が3個横並び、その下にDA-15が1個
module multi_dsub_panel_rows(rows, h_spacing = 5, v_spacing = 5) {
    // 各行の幅と高さを計算
    row_widths = [for (row = rows)
        let(conn = row[0], count = row[1], bracket_w = db_bracket_table(conn)[0])
        count * bracket_w + (count - 1) * h_spacing + plate_margin * 2];

    row_heights = [for (row = rows)
        let(conn = row[0], bracket_h = db_bracket_table(conn)[1])
        bracket_h + plate_margin];

    // 全体サイズ
    total_width = max(row_widths);
    total_height = [for (i = [0:len(rows)-1]) row_heights[i]][0] * len(rows)
                   + (len(rows) - 1) * v_spacing + plate_margin;

    // 各行のY位置を計算
    function cumulative_height(idx) =
        idx == 0 ? row_heights[0]/2 + plate_margin/2 :
        cumulative_height(idx-1) + row_heights[idx-1]/2 + v_spacing + row_heights[idx]/2;

    difference() {
        // 1枚の板
        translate([-total_width/2, -total_height/2, 0])
            cube([total_width, total_height, plate_thickness]);

        // 各行のコネクタ
        for (r = [0:len(rows)-1]) {
            conn = rows[r][0];
            count = rows[r][1];
            bracket = db_bracket_table(conn);
            bracket_w = bracket[0];
            bracket_h = bracket[1];

            row_width = count * bracket_w + (count - 1) * h_spacing;
            y_pos = total_height/2 - cumulative_height(r);

            for (c = [0:count-1]) {
                x_pos = -row_width/2 + bracket_w/2 + c * (bracket_w + h_spacing);

                translate([x_pos, y_pos, 0]) {
                    // フランジ用ザグリ
                    translate([0, 0, plate_thickness - flange_recess_depth])
                        dsub_flange_recess(bracket_w + tolerance, bracket_h + tolerance, flange_corner_r, flange_recess_depth + 0.1);

                    // D-Sub開口部
                    translate([0, 0, -0.1])
                        dsub_opening(conn, tolerance, plate_thickness + 0.2);
                }
            }
        }
    }
}

// ===== ライブラリ用モジュール =====

// 単一コネクタの切り欠き (difference用)
// 任意の板に対して使用可能
module dsub_cutout(conn_type) {
    bracket = db_bracket_table(conn_type);
    bracket_w = bracket[0];
    bracket_h = bracket[1];

    // フランジ用ザグリ (上面)
    translate([0, 0, plate_thickness - flange_recess_depth])
        dsub_flange_recess(bracket_w + tolerance, bracket_h + tolerance, flange_corner_r, flange_recess_depth + 0.1);

    // D-Sub開口部 (貫通)
    translate([0, 0, -0.1])
        dsub_opening(conn_type, tolerance, plate_thickness + 0.2);

    // M3ナット凹み (裏面)
    translate([0, 0, -0.1])
        dsub_nut_recesses(conn_type, m3_nut_depth + 0.1);
}

// DE-9 (9pin) 専用
module de9_cutout() {
    dsub_cutout("db9");
}

// DA-15 (15pin) 専用
module da15_cutout() {
    dsub_cutout("db15");
}

// DB-25 (25pin) 専用
module db25_cutout() {
    dsub_cutout("db25");
}

// DC-37 (37pin) 専用
module dc37_cutout() {
    dsub_cutout("db37");
}

// ===== カスタムレイアウト用パネル =====

// 各コネクタを [タイプ, x位置, y位置] で指定
module custom_dsub_panel(connectors, panel_width, panel_height) {
    difference() {
        // 板
        translate([-panel_width/2, -panel_height/2, 0])
            cube([panel_width, panel_height, plate_thickness]);

        // 各コネクタの開口部とザグリ
        for (c = connectors) {
            conn_type = c[0];
            x_pos = c[1];
            y_pos = c[2];
            bracket = db_bracket_table(conn_type);
            bracket_w = bracket[0];
            bracket_h = bracket[1];

            translate([x_pos, y_pos, 0]) {
                // フランジ用ザグリ (上面)
                translate([0, 0, plate_thickness - flange_recess_depth])
                    dsub_flange_recess(bracket_w + tolerance, bracket_h + tolerance, flange_corner_r, flange_recess_depth + 0.1);

                // D-Sub開口部 (貫通)
                translate([0, 0, -0.1])
                    dsub_opening(conn_type, tolerance, plate_thickness + 0.2);

                // M3ナット凹み (裏面)
                translate([0, 0, -0.1])
                    dsub_nut_recesses(conn_type, m3_nut_depth + 0.1);
            }
        }
    }
}

// ===== レンダリング =====

// テスト用: DE-9 と DA-15 を横に並べた小さい板
db9_w = db_bracket_table("db9")[0];
db15_w = db_bracket_table("db15")[0];
bracket_h = db_bracket_table("db9")[1];
h_spacing = 5;

test_width = db9_w + db15_w + h_spacing + plate_margin * 2;
test_height = bracket_h + plate_margin * 2;

difference() {
    // 板
    translate([-test_width/2, -test_height/2, 0])
        cube([test_width, test_height, plate_thickness]);

    // DE-9
    translate([-(db15_w + h_spacing) / 2, 0, 0])
        de9_cutout();

    // DA-15
    translate([(db9_w + h_spacing) / 2, 0, 0])
        da15_cutout();
}

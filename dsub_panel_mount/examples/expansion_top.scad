// D-SUB 拡張トップ
// 既存エンクロージャーの天板（メスコネクタ）に接続する拡張ボックス
// オスコネクタで天板に嵌合し、D-SUBのネジで固定
//
// 外形: 120mm x 110mm x 54mm（ポケット6mm + パネル8mm + 内部40mm）
// 構造: コネクタ周辺が内側に盛り上がり（天板と同じパネル構造）
//   - 底面からポケット（メスコネクタ本体が入る）
//   - ポケット床から盛り上がり（パネル構造、コネクタ取付）
//   - ブラケット凹みはポケット床側（下面）
//   - ナットポケットは盛り上がり上面側（内部）
// 使用コネクタ: DE-9 x7, DA-15 x1（オス）
// 固定: D-SUBコネクタのネジ（M3）のみ
// 依存: dsub_panel_mount.scad, BOSL2, NopSCADlib
//
// ビルド:
//   openscad --enable=lazy-union -O export-3mf/material-type=color \
//     -o expansion_top.3mf expansion_top.scad

use <../dsub_panel_mount.scad>
include <BOSL2/std.scad>
include <NopSCADlib/core.scad>
include <NopSCADlib/vitamins/d_connectors.scad>

// ===== フィットチェック用 =====
// 単体で開いた時のデフォルト値
// include される場合は呼び出し側で show_plugs を定義
show_plugs = true;

// ===== ボックスパラメータ =====
exp_top_width = 120;        // 幅（天板と同じ）
exp_top_depth = 110;        // 奥行（天板と同じ）
exp_top_internal_h = 40;    // 内部高さ
exp_top_wall = 3;           // 壁厚
exp_top_corner_r = 3;       // 角丸半径

// 底板パラメータ（天板と同じ構造）
exp_top_plate = 8;          // パネル構造厚（天板と同じ plate_thickness）

// ポケット深さの計算
// 天板のメスコネクタ突出量 = d_front_height - flange_recess_depth
// DCONN9: d_front_height = 6.693mm, flange_recess_depth = 1.5mm
// 突出量 ≈ 6.693 - 1.5 = 5.2mm
// 余裕を加えて 6mm
exp_top_pocket = 6;         // ポケット深さ（メスコネクタ突出量 + 余裕）

// ===== コネクタ配置（multi_connector_panel.scad と同じ） =====
tolerance = 0.3;      // 3Dプリント公差（ライブラリと同じ）
db9_w = 30.81;        // DE-9 ブラケット幅
db15_w = 39.14;       // DA-15 ブラケット幅
bracket_h = 12.55;    // ブラケット高さ
h_spacing = 5;        // 横方向間隔
v_spacing = 5;        // 縦方向間隔
label_height = 6;     // ラベル用スペース

// レイアウト計算
row_width = db9_w * 3 + h_spacing * 2;  // DE-9 x3 の幅
row_total_height = bracket_h + label_height;

// Y座標（パネル中心基準）
top_y = row_total_height + v_spacing;
mid_y = 0;
bottom_y = -(row_total_height + v_spacing);
conn_offset_y = -label_height / 2;  // コネクタはラベル分下にオフセット

// ===== 底板構造パラメータ =====
// 天板と同じ構造だが、内側に盛り上がり
// 構造（下から上へ）:
//   Z=0: 底面（天板に接地）
//   Z=0〜6: ポケット（メスコネクタ突出部が入る）
//   Z=6〜7.5: ブラケット凹み（ポケット床から、ブラケットが座る）
//   Z=6〜14: パネル構造（D穴貫通）= 内側への盛り上がり
//   Z=11.5〜14: ナットポケット（盛り上がり上面から）
//   Z=14〜54: 側壁（内部空間）

// dsub_panel_mount.scad と同じ値
flange_recess_depth = 1.5;    // ブラケット凹み深さ（天板と同じ）
flange_corner_r = 0.5;        // ブラケット角R
m3_nut_width = 5.5;           // M3ナット二面幅
m3_nut_depth = 2.5;           // ナット厚

// 底板 + ポケット の合計高さ
exp_top_bottom_total = exp_top_plate + exp_top_pocket;

// ===== オスコネクタ用カットアウト（天板と同じ構造、ポケット床から上に盛り上がり） =====
// base_z: カットアウトのベース位置（ポケット床）
module exp_top_dsub_cutout(conn, base_z = 0) {
    // 取付穴中心距離
    b = conn == "db9" ? 12.50 : conn == "db15" ? 16.66 : 0;
    // ブラケットサイズ
    bracket_w = conn == "db9" ? db9_w : conn == "db15" ? db15_w : 0;

    // ブラケット形状のポケット（底面からポケット床まで）
    // ブラケット外側は底面まで塞がっている
    translate([0, 0, -0.1])
        linear_extrude(height = base_z + 0.1)
            offset(r = flange_corner_r) offset(r = -flange_corner_r)
                square([bracket_w + tolerance, bracket_h + tolerance], center = true);

    // ブラケット凹み（ポケット床から、深さ1.5mm）
    // 天板の flange_recess と同じ構造
    translate([0, 0, base_z - 0.1])
        linear_extrude(height = flange_recess_depth + 0.1)
            offset(r = flange_corner_r) offset(r = -flange_corner_r)
                square([bracket_w + tolerance, bracket_h + tolerance], center = true);

    // D穴（パネル構造を貫通）
    translate([0, 0, base_z - 0.1])
        linear_extrude(height = exp_top_plate + 0.2)
            dsub_shape_2d(conn, gap = tolerance);

    // M3取付穴（全体を貫通、底面からパネル上面まで）
    mounting_hole_d = 3.05;
    for (side = [-1, 1]) {
        translate([side * b, 0, -0.1])
            cylinder(h = base_z + exp_top_plate + 0.2, d = mounting_hole_d, $fn = 24);
    }

    // ナットポケット（パネル上面から下に掘る）
    // 天板のナット凹みと同じ構造
    nut_rotation = 20;  // D型斜辺に合わせた回転
    for (side = [-1, 1]) {
        translate([side * b, 0, base_z + exp_top_plate - m3_nut_depth])
            rotate([0, 0, side < 0 ? -nut_rotation : nut_rotation])
                cylinder(h = m3_nut_depth + 0.1, d = m3_nut_width / cos(30), $fn = 6);
    }
}

// ===== 底板 =====
module expansion_top_bottom() {
    inner_r = max(exp_top_corner_r - exp_top_wall, 0);

    difference() {
        // 厚い板（ポケット深さ + パネル構造）
        cuboid([exp_top_width, exp_top_depth, exp_top_bottom_total],
               rounding=exp_top_corner_r, edges="Z", anchor=BOTTOM);

        // コネクタカットアウト（ブラケット形状のポケット + パネル構造）
        // 上段: DE-9 x3
        for (i = [0:2]) {
            x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
            translate([x, top_y + conn_offset_y, 0])
                exp_top_dsub_cutout("db9", base_z = exp_top_pocket);
        }

        // 中段: DE-9 x1 (左) + DA-15 x1 (右)
        translate([-row_width/2 + db9_w/2, mid_y + conn_offset_y, 0])
            exp_top_dsub_cutout("db9", base_z = exp_top_pocket);
        translate([row_width/2 - db15_w/2, mid_y + conn_offset_y, 0])
            exp_top_dsub_cutout("db15", base_z = exp_top_pocket);

        // 下段: DE-9 x3
        for (i = [0:2]) {
            x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
            translate([x, bottom_y + conn_offset_y, 0])
                exp_top_dsub_cutout("db9", base_z = exp_top_pocket);
        }
    }
}

// ===== 側壁（オープントップ） =====
module expansion_top_walls() {
    inner_r = max(exp_top_corner_r - exp_top_wall, 0);

    difference() {
        // 外形
        cuboid([exp_top_width, exp_top_depth, exp_top_internal_h],
               rounding=exp_top_corner_r, edges="Z", anchor=BOTTOM);

        // 内側をくり抜き
        translate([0, 0, -0.1])
            cuboid([exp_top_width - exp_top_wall * 2,
                    exp_top_depth - exp_top_wall * 2,
                    exp_top_internal_h + 0.2],
                   rounding=inner_r, edges="Z", anchor=BOTTOM);
    }
}

// ===== 拡張トップ本体 =====
module expansion_top() {
    // 底板（ポケット付き）
    expansion_top_bottom();

    // 側壁（底板 + ポケット の上）
    translate([0, 0, exp_top_bottom_total])
        expansion_top_walls();
}

// ===== フィットチェック用オスプラグ =====
module expansion_top_plugs() {
    // オスプラグはブラケット座面（ポケット床 + ブラケット凹み）に配置
    // d_plug() は Z=0 がフランジ面、Z+ 方向にピンが突出
    // rotate([180,0,180]) で下向きに回転し、ピンがポケット内に突出
    plug_z = exp_top_pocket + flange_recess_depth;

    // 上段: DE-9 x3
    for (i = [0:2]) {
        x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
        translate([x, top_y + conn_offset_y, plug_z])
            rotate([180, 0, 180])
                d_plug(DCONN9);
    }

    // 中段: DE-9 (左) + DA-15 (右)
    translate([-row_width/2 + db9_w/2, mid_y + conn_offset_y, plug_z])
        rotate([180, 0, 180])
            d_plug(DCONN9);
    translate([row_width/2 - db15_w/2, mid_y + conn_offset_y, plug_z])
        rotate([180, 0, 180])
            d_plug(DCONN15);

    // 下段: DE-9 x3
    for (i = [0:2]) {
        x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
        translate([x, bottom_y + conn_offset_y, plug_z])
            rotate([180, 0, 180])
                d_plug(DCONN9);
    }
}

// ===== 出力 =====
// show_expansion_top が未定義 = 単体で開いている → 出力
// include された場合は呼び出し側で制御
if (is_undef(show_expansion_top)) {
    color("white") expansion_top();
    if (show_plugs) {
        expansion_top_plugs();
    }
}

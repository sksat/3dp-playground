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
include <NopSCADlib/vitamins/pcbs.scad>

// 天板を include（show_lid_only が定義済みなら出力抑制）
show_lid_only = true;
include <expansion_top_lid.scad>

// ===== フィットチェック用 =====
// 単体で開いた時のデフォルト値
// include される場合は呼び出し側で show_plugs を定義
show_plugs = true;
show_pico = true;          // Raspberry Pi Pico プレビュー
show_lid = true;           // 天板プレビュー

// ===== タイトル・ラベル（カスタマイズ用） =====
// multi_connector_panel.scad と同じ変数名（共通JSONプリセット用）
panel_title = "Expansion Top v0.1";

// 上段 DE-9 x3
top_label_1 = "EXT1";
top_label_2 = "EXT2";
top_label_3 = "EXT3";
top_labels = [top_label_1, top_label_2, top_label_3];

// 中段 DE-9, DA-15
mid_label_1 = "EXT4";
mid_label_2 = "EXT5";
mid_labels = [mid_label_1, mid_label_2];

// 下段 DE-9 x3
bottom_label_1 = "EXT6";
bottom_label_2 = "EXT7";
bottom_label_3 = "EXT8";
bottom_labels = [bottom_label_1, bottom_label_2, bottom_label_3];

// ===== ラベル設定 =====
label_font_size = 5;
label_depth = 1.0;
label_font = "Liberation Sans:style=Bold";

// ===== ボックスパラメータ =====
exp_top_width = 120;        // 幅（天板と同じ）
exp_top_depth = 110;        // 奥行（天板と同じ）
exp_top_internal_h = 45;    // 内部高さ
exp_top_wall = 3;           // 壁厚
exp_top_corner_r = 3;       // 角丸半径

// 梁パラメータ（基板固定用）
beam_enabled = true;        // 梁の有効/無効
beam_width = 65;            // 梁の幅（Y方向、全コネクタを覆う）
beam_thickness = 5;         // 梁の厚さ（Z方向）
beam_y = -3;                // 梁のY位置（コネクタ中心に合わせる）
beam_z_offset = 15;         // 側壁底面からのオフセット
beam_support_depth = 50;    // 三角サポートの奥行（壁からの距離、緩やかな傾斜）
beam_support_start_z = 8;   // サポート開始高さ（コネクタ構造との干渉回避）

// Pico 配置パラメータ
pico_count = 5;             // Pico の個数
pico_spacing = 23;          // Pico 間隔（X方向、21mm幅 + 2mm隙間）
pico_y = beam_y;            // Pico の Y 位置（梁と同じ）

// 天板スロットパラメータ（後方からスライドして差し込む）
lid_thickness = 3;          // 天板の厚さ（PLA強度確保）
lid_slot_depth = 2;         // 溝の深さ（壁への食い込み量）
lid_slot_clearance = 0.3;   // スライド用クリアランス
lid_slot_top_offset = 2;    // 壁上端から溝上端までの距離

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
label_offset_y = bracket_h / 2 + label_height / 2 - 1;  // コネクタ中心からラベルまで

// タイトル位置（左上、EXT3ブラケット左端に揃える）
// 底面から見た時（文字が正しく読める向き）でEXT3の上、左端揃え
// EXT3ブラケット左端 = EXT3中心 + db9_w/2（文字読み方向の左）
title_x = row_width/2;  // EXT3ブラケットの左端（読み方向）
title_y = top_y + label_offset_y + label_font_size * 2 + 5;

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

// ===== ラベル（底面、別マテリアル用） =====
// 底面から見た時に読めるようにX軸でミラー（裏から見ると左右反転するため）
module exp_top_label_text(txt) {
    linear_extrude(height = label_depth)
        mirror([1, 0, 0])
            text(txt, size = label_font_size, font = label_font, halign = "center", valign = "center");
}

// 凹み用（少し大きめ）
module exp_top_label_cutout_text(txt) {
    translate([0, 0, -0.1])
        linear_extrude(height = label_depth + 0.1)
            mirror([1, 0, 0])
                offset(delta = 0.05)
                    text(txt, size = label_font_size, font = label_font, halign = "center", valign = "center");
}

// タイトル
// halign="left" + mirror で、底面から見た時にタイトル左端がアンカー位置に来る
module exp_top_title_text(txt) {
    linear_extrude(height = label_depth)
        mirror([1, 0, 0])
            text(txt, size = label_font_size, font = label_font, halign = "left", valign = "top");
}

module exp_top_title_cutout_text(txt) {
    translate([0, 0, -0.1])
        linear_extrude(height = label_depth + 0.1)
            mirror([1, 0, 0])
                offset(delta = 0.05)
                    text(txt, size = label_font_size, font = label_font, halign = "left", valign = "top");
}

// ===== 前面タイトル（側壁、別マテリアル用） =====
// 前面から見た時に読めるように配置
// rotate([-90,0,0]) で Y→-Z になるため、mirror([0,1,0]) で補正
module exp_top_front_title_text(txt) {
    linear_extrude(height = label_depth)
        mirror([0, 1, 0])
            text(txt, size = label_font_size, font = label_font, halign = "left", valign = "top");
}

module exp_top_front_title_cutout_text(txt) {
    // テキストと同じサイズでくり抜き（Z-fighting 回避のため手前方向に余分に延ばす）
    linear_extrude(height = label_depth + 0.1)
        mirror([0, 1, 0])
            text(txt, size = label_font_size, font = label_font, halign = "left", valign = "top");
}

// 前面タイトル位置（側壁座標系、左下）
front_title_x = -exp_top_width/2 + 10;  // 左端から余白
front_title_z = 0;                       // 下端がベース上端（側壁開始位置）

// ラベル用凹み（底板から引く）
module exp_top_label_cutouts() {
    // 上段
    for (i = [0:2]) {
        x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
        translate([x, top_y + label_offset_y, 0])
            exp_top_label_cutout_text(top_labels[i]);
    }

    // 中段
    translate([-row_width/2 + db9_w/2, mid_y + label_offset_y, 0])
        exp_top_label_cutout_text(mid_labels[0]);
    translate([row_width/2 - db15_w/2, mid_y + label_offset_y, 0])
        exp_top_label_cutout_text(mid_labels[1]);

    // 下段
    for (i = [0:2]) {
        x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
        translate([x, bottom_y + label_offset_y, 0])
            exp_top_label_cutout_text(bottom_labels[i]);
    }

    // タイトル
    translate([title_x, title_y, 0])
        exp_top_title_cutout_text(panel_title);
}

// ラベル本体（凹みにはまる）
module exp_top_labels() {
    // 上段ラベル
    for (i = [0:2]) {
        x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
        translate([x, top_y + label_offset_y, 0])
            exp_top_label_text(top_labels[i]);
    }

    // 中段ラベル
    translate([-row_width/2 + db9_w/2, mid_y + label_offset_y, 0])
        exp_top_label_text(mid_labels[0]);
    translate([row_width/2 - db15_w/2, mid_y + label_offset_y, 0])
        exp_top_label_text(mid_labels[1]);

    // 下段ラベル
    for (i = [0:2]) {
        x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
        translate([x, bottom_y + label_offset_y, 0])
            exp_top_label_text(bottom_labels[i]);
    }

    // タイトル
    translate([title_x, title_y, 0])
        exp_top_title_text(panel_title);
}

// ===== 前面タイトル（側壁上のテキスト） =====
module exp_top_front_title() {
    // 側壁は exp_top_bottom_total から始まる
    // くり抜きと同じ位置に配置（壁表面より 0.1mm 手前から開始）
    // くり抜きが先に穴を開けているため、Z-fighting なし
    translate([front_title_x, -exp_top_depth/2 - 0.1, exp_top_bottom_total + front_title_z])
        rotate([-90, 0, 0])
            exp_top_front_title_text(panel_title);
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

        // ラベル凹み（底面）
        exp_top_label_cutouts();
    }
}

// ===== 側壁（オープントップ） =====
module expansion_top_walls() {
    inner_r = max(exp_top_corner_r - exp_top_wall, 0);
    beam_length = exp_top_width - exp_top_wall * 2;  // 内壁間の長さ

    // 側壁
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

        // 前面タイトル凹み（外面から彫り込む）
        // rotate([-90,0,0]) で +Y 方向（壁内部）へ彫り込む
        // テキストと同じ位置から開始、label_depth + 0.1 で壁表面より奥まで掘る
        // → 壁表面では cutout が「途中」なので Z-fighting しない
        translate([front_title_x, -exp_top_depth/2 - 0.1, front_title_z])
            rotate([-90, 0, 0])
                exp_top_front_title_cutout_text(panel_title);

        // 天板スロット（前面・左右の3辺、背面は開口）
        slot_z = exp_top_internal_h - lid_slot_top_offset - lid_thickness;
        slot_height = lid_thickness + lid_slot_clearance;

        // 前面の溝
        translate([0, -exp_top_depth/2 + exp_top_wall - lid_slot_depth/2, slot_z + slot_height/2])
            cube([exp_top_width - exp_top_wall * 2 + lid_slot_depth * 2,
                  lid_slot_depth + 0.1,
                  slot_height], center=true);

        // 左右の溝
        for (side = [-1, 1]) {
            translate([side * (exp_top_width/2 - exp_top_wall + lid_slot_depth/2), 0, slot_z + slot_height/2])
                cube([lid_slot_depth + 0.1,
                      exp_top_depth - exp_top_wall * 2,
                      slot_height], center=true);
        }

        // 背面開口（天板スライド入口）
        translate([0, exp_top_depth/2 - exp_top_wall/2, slot_z + slot_height/2])
            cube([exp_top_width - exp_top_wall * 2 + lid_slot_depth * 2,
                  exp_top_wall + 0.2,
                  slot_height], center=true);
    }

    // 梁（側壁の後に追加、内壁に接続）
    if (beam_enabled) {
        // 梁本体
        translate([0, beam_y, beam_z_offset + beam_thickness/2])
            cube([beam_length, beam_width, beam_thickness], center=true);

        // 三角サポート（壁から梁へ斜めに成長、印刷用）
        // 左右の壁から中央方向へ、コネクタ構造より上から開始
        inner_wall_x = exp_top_width/2 - exp_top_wall;  // 内壁のX位置
        for (side = [-1, 1]) {
            translate([side * inner_wall_x, beam_y, 0])
                rotate([90, 0, 0])
                    linear_extrude(height = beam_width, center = true)
                        polygon([
                            [0, beam_support_start_z],                 // 壁から少し上（干渉回避）
                            [0, beam_z_offset + beam_thickness],       // 壁の上（梁上面）
                            [-side * beam_support_depth, beam_z_offset] // 梁の底（中央方向）
                        ]);
        }
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

// ===== フィットチェック用 Raspberry Pi Pico =====
module expansion_top_pico() {
    // 梁上面の Z 位置
    beam_top_z = exp_top_bottom_total + beam_z_offset + beam_thickness;

    // Pico サイズ: 51mm x 21mm x 1.6mm
    // 変換後: 21mm(X) x 51mm(Y) x 1.6mm(Z)、USB が Y- 方向（手前）、水平配置
    pico_length = 51;  // 元の長さ、回転後は Y 方向
    pico_width = 21;   // 元の幅、回転後は X 方向
    pico_thickness = 1.6;  // 厚さ、回転後は Z 方向
    pico_row_width = (pico_count - 1) * pico_spacing;

    for (i = [0:pico_count-1]) {
        x = -pico_row_width/2 + i * pico_spacing;
        // pcb() は中心基準、回転後は厚さ(1.6mm)の半分だけ上げて梁上面に底が来るようにする
        translate([x, pico_y, beam_top_z + pico_thickness/2])
            rotate([0, 0, 90])  // USB を手前（Y-）に向ける、水平配置
                pcb(RPI_Pico);
    }
}

// ===== 出力 =====
// show_expansion_top が未定義 = 単体で開いている → 出力
// include された場合は呼び出し側で制御
if (is_undef(show_expansion_top)) {
    color("white") expansion_top();
    color("black") {
        exp_top_labels();
        exp_top_front_title();
    }
    if (show_plugs) {
        expansion_top_plugs();
    }
    if (show_pico) {
        expansion_top_pico();
    }
    if (show_lid) {
        // 天板を装着位置にプレビュー
        lid_z = exp_top_bottom_total + exp_top_internal_h - lid_slot_top_offset - lid_thickness/2;
        translate([0, 0, lid_z]) {
            color("lightgray") expansion_top_lid();
            color("black") expansion_top_lid_label();
        }
    }
}

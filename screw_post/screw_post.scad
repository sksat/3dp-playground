// Screw Post Library
// ネジ止め用ポスト（ナットポケット付き）ライブラリ
//
// 提供モジュール:
//   screw_post(size, h, d_top, d_base)     - ポスト本体（円錐形）
//   screw_post_hole(size, h, nut_side)     - ネジ穴 + ナットポケット（difference用）
//   screw_post_with_hole(...)              - ポスト + 穴の一体型
//
// 対応サイズ: M2, M2.5, M3
//
// 使用例:
//   difference() {
//       screw_post("M2.5", h = 10);
//       // ネジ長さと材料厚さから自動計算
//       screw_post_hole("M2.5", h = 10, screw_length = 8, material_thickness = 1.6);
//   }

// ===== ネジ・ナット寸法テーブル =====
// [ネジ通し穴径, ナット二面幅, ナット厚さ]

function screw_specs(size) =
    size == "M2"   ? [2.4, 4.0, 1.6] :
    size == "M2.5" ? [2.7, 5.0, 2.0] :
    size == "M3"   ? [3.4, 5.5, 2.4] :
    undef;

// トレランス付きナット寸法を取得
// tolerance: 穴径・ナット幅に追加するクリアランス
function screw_specs_with_tolerance(size, tolerance = 0.5) =
    let(specs = screw_specs(size))
    is_undef(specs) ? undef :
    [specs[0] + tolerance * 0.5,    // ネジ穴は控えめに
     specs[1] + tolerance,          // ナット幅
     specs[2] + tolerance * 0.8];   // ナット深さ

// 推奨ポスト径（ナット収容可能なサイズ）
function screw_post_d(size, wall = 2) =
    let(specs = screw_specs(size))
    is_undef(specs) ? 0 : specs[1] / cos(30) + wall * 2;

// ナットポケット深さを自動計算
// h: ポスト高さ
// screw_length: ネジの長さ
// material_thickness: 間に挟む材料の厚さ（PCB等）
// 戻り値: ナットポケットがポスト底面からどこまで伸びるか
function calc_nut_depth(h, screw_length, material_thickness = 0) =
    let(
        // ネジ先端位置（ポスト底面からの高さ）
        screw_tip = h + material_thickness - screw_length,
        // ナットが噛み合うための余裕（2mm）
        engagement = 2
    )
    screw_tip + engagement;

// ===== モジュール =====

// ポスト本体（円錐形、底部が広い）
// h: ポスト高さ
// d_top: 上部直径（省略時は推奨値の60%）
// d_base: 底部直径（省略時は推奨値）
module screw_post(size = "M2.5", h = 10, d_top = undef, d_base = undef) {
    specs = screw_specs(size);

    if (is_undef(specs)) {
        echo(str("ERROR: Invalid screw size '", size, "'"));
    } else {
        base_d = is_undef(d_base) ? screw_post_d(size) : d_base;
        top_d = is_undef(d_top) ? base_d * 0.6 : d_top;

        cylinder(h = h, d1 = base_d, d2 = top_d, $fn = 24);
    }
}

// ネジ穴 + ナットポケット（difference用）
// h: ポスト高さ（ネジ穴の長さ）
// nut_side: ナットポケットの位置 "bottom" または "top"
// screw_length: ネジの長さ（指定時は nut_depth を自動計算）
// material_thickness: 間に挟む材料の厚さ（PCB等、screw_length と併用）
// nut_depth: ナットポケットの深さ（直接指定、screw_length より優先）
// base_thickness: ベース板の厚さ（nut_side="bottom" 時に貫通させる）
// tolerance: クリアランス
module screw_post_hole(size = "M2.5", h = 10, nut_side = "bottom",
                       screw_length = undef, material_thickness = 0,
                       nut_depth = undef, base_thickness = 3, tolerance = 0.5) {
    specs = screw_specs_with_tolerance(size, tolerance);

    if (is_undef(specs)) {
        echo(str("ERROR: Invalid screw size '", size, "'"));
    } else {
        screw_d = specs[0];
        nut_w = specs[1];

        // nut_depth の決定: 直接指定 > 自動計算 > デフォルト
        nut_h = !is_undef(nut_depth) ? nut_depth :
                !is_undef(screw_length) ? calc_nut_depth(h, screw_length, material_thickness) :
                specs[2];

        hex_d = nut_w / cos(30);  // 六角形の外接円直径
        nut_t = specs[2];  // ナット厚

        // ネジ穴（ベース + ポストを貫通）
        translate([0, 0, -base_thickness - 0.1])
            cylinder(h = base_thickness + h + 0.2, d = screw_d, $fn = 24);

        // ナットポケット
        if (nut_side == "bottom") {
            // nut_h が正（ポスト内まで必要）→ ポスト内まで掘る
            // nut_h が負（ベース内で済む）→ ベース内に収める（可能なら貫通しない）
            min_floor = 0.6;  // ナットポケット上に残す最低肉厚（1層分程度）

            if (nut_h > 0) {
                // ネジが短い：ポスト内までナットポケットが必要
                nut_pocket_h = base_thickness + nut_h;
                translate([0, 0, -base_thickness - 0.1])
                    cylinder(h = nut_pocket_h + 0.1, d = hex_d, $fn = 6);
            } else if (base_thickness >= nut_t + min_floor) {
                // ベースが十分厚い：底面から凹ませて min_floor を残す
                translate([0, 0, -base_thickness - 0.1])
                    cylinder(h = base_thickness - min_floor + 0.1, d = hex_d, $fn = 6);
            } else {
                // ベースが薄い：貫通させる
                translate([0, 0, -base_thickness - 0.1])
                    cylinder(h = base_thickness + 0.1, d = hex_d, $fn = 6);
            }
        } else if (nut_side == "top") {
            // 上面から
            translate([0, 0, h - nut_h])
                cylinder(h = nut_h + 0.1, d = hex_d, $fn = 6);
        }
    }
}

// ポスト + 穴の一体型（便利モジュール）
module screw_post_with_hole(size = "M2.5", h = 10, d_top = undef, d_base = undef,
                            nut_side = "bottom",
                            screw_length = undef, material_thickness = 0,
                            nut_depth = undef,
                            base_thickness = 3, tolerance = 0.5) {
    difference() {
        screw_post(size, h, d_top, d_base);
        screw_post_hole(size, h, nut_side, screw_length, material_thickness,
                        nut_depth, base_thickness, tolerance);
    }
}

// サイズ別便利モジュール
module m2_screw_post(h = 10, d_top = undef, d_base = undef) {
    screw_post("M2", h, d_top, d_base);
}

module m2p5_screw_post(h = 10, d_top = undef, d_base = undef) {
    screw_post("M2.5", h, d_top, d_base);
}

module m3_screw_post(h = 10, d_top = undef, d_base = undef) {
    screw_post("M3", h, d_top, d_base);
}

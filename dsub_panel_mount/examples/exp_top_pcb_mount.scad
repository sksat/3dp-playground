// 拡張トップ基板マウント
// expansion_top 内部に配置し、壁外側からネジで固定する
//
// 外形: 梁 113.4mm x 65mm x 8mm（インサート穴内蔵）
// 取付: 壁内側のレッジに載せ、外側からネジで固定
// 使用ネジ: M3 x 8mm（左右各1本）
// 固定: 側面にヒートインサート埋込、壁外側からネジ
//
// ビルド:
//   openscad -o exp_top_pcb_mount.stl exp_top_pcb_mount.scad

use <../../heat_insert/heat_insert.scad>

// ===== パラメータ =====
// expansion_top.scad と同じ値を使用

// 外形寸法（expansion_top から参照）
exp_top_width = 120;
exp_top_wall = 3;

// マウントパラメータ
pcb_mount_width = 65;           // マウントの幅（Y方向）
pcb_mount_thickness = 8;        // マウントの厚さ（Z方向）- インサート穴を収容

// マウント本体の長さ（内壁間 - クリアランス）
pcb_mount_clearance = 0.3;      // クリアランス
mount_length = exp_top_width - exp_top_wall * 2 - pcb_mount_clearance * 2;

// ===== モジュール =====

// マウント本体（インサート穴内蔵）
module exp_top_pcb_mount_beam() {
    difference() {
        // マウント本体
        cube([mount_length, pcb_mount_width, pcb_mount_thickness], center=true);

        // インサート穴（X方向、側面から板内に収容）
        // insert_hole は原点から -Z 方向に掘る
        // rotate([0, ±90, 0]) で X 方向に向ける
        for (side = [-1, 1]) {
            translate([side * mount_length/2, 0, 0])
                rotate([0, side * 90, 0])
                    m3_insert_hole(length = "standard", extra_depth = 1);
        }
    }
}

// ===== 出力 =====
// 印刷しやすいよう Z=0 に配置（マウントの底面が印刷ベッド）
translate([0, 0, pcb_mount_thickness/2])
    exp_top_pcb_mount_beam();

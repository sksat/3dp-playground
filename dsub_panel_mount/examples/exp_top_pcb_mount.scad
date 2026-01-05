// 拡張トップ基板マウント
// expansion_top 内部に配置し、壁外側からネジで固定する
//
// 外形: 梁 114mm x 65mm x 5mm + ボス
// 取付: 壁内側のレッジに載せ、外側からネジで固定
// 使用ネジ: M3 x 8mm（左右各1本）
// 固定: ボス側面にヒートインサート、壁外側からネジ
//
// ビルド:
//   openscad -o exp_top_pcb_mount.stl exp_top_pcb_mount.scad

// ===== パラメータ =====
// expansion_top.scad と同じ値を使用

// 外形寸法（expansion_top から参照）
exp_top_width = 120;
exp_top_wall = 3;

// マウントパラメータ
pcb_mount_width = 65;           // マウントの幅（Y方向）
pcb_mount_thickness = 5;        // マウントの厚さ（Z方向）

// ボスパラメータ（壁側に突出、インサート穴付き）
boss_d = 8;                     // ボス直径（M3インサート + 肉厚）
boss_length = 3;                // ボス長さ（壁に接する部分）
insert_hole_d = 4.2;            // インサート穴径
insert_hole_depth = 6;          // インサート穴深さ

// マウント本体の長さ（内壁間 - ボス長さ*2 - クリアランス）
pcb_mount_clearance = 0.3;      // クリアランス
mount_length = exp_top_width - exp_top_wall * 2 - boss_length * 2 - pcb_mount_clearance * 2;

// ===== モジュール =====

// マウント本体（ボス付き）
module exp_top_pcb_mount_beam() {
    difference() {
        union() {
            // マウント本体
            cube([mount_length, pcb_mount_width, pcb_mount_thickness], center=true);

            // 左右のボス（壁側に突出、インサート用）
            for (side = [-1, 1]) {
                translate([side * (mount_length/2 + boss_length/2), 0, 0])
                    rotate([0, 90, 0])
                        cylinder(h = boss_length, d = boss_d, center=true, $fn=24);
            }
        }

        // インサート穴（X方向、外側から）
        for (side = [-1, 1]) {
            translate([side * (mount_length/2 + boss_length + 0.1), 0, 0])
                rotate([0, side * 90, 0])
                    cylinder(h = insert_hole_depth + 0.1, d = insert_hole_d, $fn=24);
        }
    }
}

// ===== 出力 =====
// 印刷しやすいよう Z=0 に配置（マウントの底面が印刷ベッド）
translate([0, 0, pcb_mount_thickness/2])
    exp_top_pcb_mount_beam();

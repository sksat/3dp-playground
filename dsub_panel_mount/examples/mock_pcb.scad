// 模擬基板モジュール（フィットチェック用）
//
// use <mock_pcb.scad> でインポートして使用
// パラメータは引数で渡す

include <BOSL2/std.scad>

// 模擬基板（パラメータ付き）
// width, depth: 基板サイズ
// thickness: 基板厚さ（デフォルト1.6mm）
// corner_r: 角丸半径
// hole_d: マウント穴径
// hole_x, hole_y: マウント穴間隔（中心間距離）
module mock_pcb(width, depth, thickness=1.6, corner_r=3,
                hole_d=3.2, hole_x, hole_y) {
    color("green")
        difference() {
            // 角丸の板（底面中心が原点）
            cuboid([width, depth, thickness],
                   rounding=corner_r, edges="Z", anchor=BOTTOM);
            // 4隅のマウント穴
            for (dx=[-1,1], dy=[-1,1])
                translate([dx*hole_x/2, dy*hole_y/2, -0.1])
                    cylinder(h=thickness+0.2, d=hole_d, $fn=24);
        }
}

// ===== 単体プレビュー用 =====
// use で読み込まれた場合は実行されない
mock_pcb(width=88, depth=81, hole_x=81, hole_y=76);

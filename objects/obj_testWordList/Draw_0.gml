/// @description Draw

var w = sprite_get_width(sprite_index) * image_xscale;
var h = sprite_get_height(sprite_index) * image_yscale;
var hover = point_in_rectangle(mouse_x, mouse_y, x, y, x + w, y + h);
var down = hover && mouse_check_button(mb_left);

var base_top = make_color_rgb(55, 72, 168);
var base_bot = make_color_rgb(36, 52, 132);
var hover_top = make_color_rgb(72, 92, 195);
var hover_bot = make_color_rgb(46, 66, 155);
var down_top = make_color_rgb(30, 44, 110);
var down_bot = make_color_rgb(22, 34, 86);

var topc = down ? down_top : (hover ? hover_top : base_top);
var botc = down ? down_bot : (hover ? hover_bot : base_bot);

// Shadow

draw_set_alpha(0.35);
draw_set_color(c_black);
draw_rectangle(x + 2, y + 3, x + w + 2, y + h + 3, false);
draw_set_alpha(1);

// Fill gradient

draw_rectangle_color(x, y, x + w, y + h, topc, topc, botc, botc, false);

// Border + top highlight

draw_set_color(make_color_rgb(215, 220, 245));
draw_rectangle(x, y, x + w, y + h, true);

draw_set_alpha(0.22);
draw_set_color(c_white);
draw_rectangle(x + 1, y + 1, x + w - 1, y + 10, false);
draw_set_alpha(1);

// Two-line label, always fits
var pad = 12;
var avail = max(10, w - (pad * 2));

var prim = "Export";
var sec = "";

var old_ha = draw_get_halign();
var old_va = draw_get_valign();
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);

var tw1 = max(1, string_width(prim));
var sc1 = clamp(avail / tw1, 0.70, 1.05);

var centerx = x + (w * 0.5);
var y1 = y + (h * 0.42);
var y2 = y + (h * 0.70);

draw_text_transformed(centerx, (sec == "") ? (y + (h * 0.55)) : y1, prim, sc1, sc1, 0);

if (sec != "") {
    draw_set_alpha(0.85);
    var tw2 = max(1, string_width(sec));
    var sc2 = clamp((avail / tw2) * 0.85, 0.60, 0.95);
    draw_text_transformed(centerx, y2, sec, sc2, sc2, 0);
    draw_set_alpha(1);
}

draw_set_halign(old_ha);
draw_set_valign(old_va);
draw_set_color(c_white);

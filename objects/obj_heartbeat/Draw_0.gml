// Draw Event for obj_heartbeat

var tiny_font = asset_get_index("fnt_tiny");
var default_font = draw_get_font();

var unresolved_long_slots = [];
if (variable_global_exists("long_entry_min_len") && grid_width >= global.long_entry_min_len) {
    unresolved_long_slots = crossword_collect_unresolved_long_slots(global.long_entry_min_len);
}

var unresolved_cells = ds_map_create();
var unresolved_starts = ds_map_create();
for (var u = 0; u < array_length(unresolved_long_slots); u++) {
    var us = unresolved_long_slots[u];
    var skey = string(us.col) + "," + string(us.row);
    if (!ds_map_exists(unresolved_starts, skey)) ds_map_add(unresolved_starts, skey, true);

    for (var k = 0; k < us.len; k++) {
        var uc = us.col + ((us.dir == "A") ? k : 0);
        var ur = us.row + ((us.dir == "D") ? k : 0);
        var ckey = string(uc) + "," + string(ur);
        if (!ds_map_exists(unresolved_cells, ckey)) ds_map_add(unresolved_cells, ckey, true);
    }
}

// Top controls
draw_rectangle(size_prev_x, size_prev_y, size_prev_x + size_prev_w, size_prev_y + size_prev_h, true);
draw_text(size_prev_x + 12, size_prev_y + 8, "<");

draw_text(size_prev_x + 48, size_prev_y + 8, "Grid: " + string(grid_width) + "x" + string(grid_height));

draw_rectangle(size_next_x, size_next_y, size_next_x + size_next_w, size_next_y + size_next_h, true);
draw_text(size_next_x + 12, size_next_y + 8, ">");

draw_rectangle(new_blank_x, new_blank_y, new_blank_x + new_blank_w, new_blank_y + new_blank_h, true);
draw_text(new_blank_x + 12, new_blank_y + 8, "New Blank Grid");

var slot_numbers = ds_map_create();
var slots = crossword_build_slots();
for (var i = 0; i < array_length(slots); i++) {
    var s = slots[i];
    var key = string(s.col) + "," + string(s.row);
    if (!ds_map_exists(slot_numbers, key)) {
        ds_map_add(slot_numbers, key, s.num);
    }
}

for (var col_i = 0; col_i < grid_width; col_i++) {
    for (var row_i = 0; row_i < grid_height; row_i++) {
        var screen_col = padding + (col_i * cell_size);
        var screen_row = padding + (row_i * cell_size);

        draw_rectangle(screen_col, screen_row, screen_col + cell_size, screen_row + cell_size, true);

        var content = grid[# col_i, row_i];
        if (content == "INVALID") {
            draw_rectangle_color(screen_col, screen_row, screen_col + cell_size, screen_row + cell_size, c_gray, c_gray, c_gray, c_gray, false);
        } else {
            var cell_key = string(col_i) + "," + string(row_i);
            if (ds_map_exists(unresolved_cells, cell_key)) {
                draw_set_alpha(0.28);
                draw_rectangle_color(screen_col, screen_row, screen_col + cell_size, screen_row + cell_size, c_orange, c_orange, c_orange, c_orange, false);
                draw_set_alpha(1);
            }

            if (ds_map_exists(unresolved_starts, cell_key)) {
                draw_set_alpha(0.7);
                draw_rectangle_color(screen_col, screen_row, screen_col + cell_size, screen_row + 4, c_aqua, c_aqua, c_aqua, c_aqua, false);
                draw_set_alpha(1);
            }

            var num_key = cell_key;
            if (ds_map_exists(slot_numbers, num_key)) {
                if (tiny_font != -1) {
                    draw_set_font(tiny_font);
                }
                draw_text(screen_col + 2, screen_row + 1, string(slot_numbers[? num_key]));
                draw_set_font(default_font);
            }

            if (content != "") {
                draw_text(screen_col + (cell_size / 2) - 4, screen_row + (cell_size / 2) - 8, content);
            }
        }
    }
}

ds_map_destroy(slot_numbers);
ds_map_destroy(unresolved_cells);
ds_map_destroy(unresolved_starts);

if (current_time < global.solver_fail_until) {
    var pulse = (sin(current_time / 70) > 0) ? c_red : c_maroon;
    for (var f = 0; f < array_length(global.solver_fail_cells); f++) {
        var cell = global.solver_fail_cells[f];
        var fx = padding + (cell.col * cell_size);
        var fy = padding + (cell.row * cell_size);
        draw_set_alpha(0.45);
        draw_rectangle_color(fx, fy, fx + cell_size, fy + cell_size, pulse, pulse, pulse, pulse, false);
        draw_set_alpha(1);
    }
}

var text_y = padding + (grid_height * cell_size) + 16;
var template_label = current_template_name;
if (template_label == "") template_label = "(unsaved)";
draw_text(padding, text_y, "Template: " + template_label);
draw_text(padding, text_y + 24, "LMB mirror-toggle blocks, RMB single-delete, Shift+LMB type char");
draw_text(padding, text_y + 48, "Target max attempts: " + string(global.fill_attempt_limit));
draw_text(padding, text_y + 72, "Attempt count: " + string(global.fill_attempt_count));
draw_text(padding, text_y + 84, "Solver heartbeat: " + string(global.solver_heartbeat));
draw_text(padding, text_y + 96, "Work units: " + string(global.solver_work_units));

draw_set_color(c_lime);
draw_text(padding, text_y + 120, status_text);
draw_set_color(c_white);

if (array_length(unresolved_long_slots) > 0) {
    var label = "Fill blockers (" + string(global.long_entry_min_len) + "+): ";
    for (var b = 0; b < min(array_length(unresolved_long_slots), 6); b++) {
        var bs = unresolved_long_slots[b];
        if (b > 0) label += ", ";
        label += string(bs.num) + bs.dir;
    }
    draw_set_color(c_aqua);
    draw_text(padding, text_y + 144, label);
    draw_set_color(c_white);
}

if (letter_entry_active) {
    draw_set_color(c_yellow);
    draw_text(padding, text_y + 168, "Cell entry: type any character, Esc cancels");
    draw_set_color(c_white);
}

var gate_y = text_y + 192;
var gate_prev_x = padding;
var gate_next_x = padding + 252;

draw_rectangle(gate_prev_x, gate_y, gate_prev_x + 24, gate_y + 24, true);
draw_text(gate_prev_x + 8, gate_y + 4, "<");
draw_text(gate_prev_x + 34, gate_y + 4, "Manual long-slot gate: " + string(global.long_entry_min_len) + "+");
draw_rectangle(gate_next_x, gate_y, gate_next_x + 24, gate_y + 24, true);
draw_text(gate_next_x + 8, gate_y + 4, ">");


var show_thinking = solver_active && !template_list_overlay_active;
if (show_thinking) {
    var cx = room_width * 0.5;
    var cy = room_height * 0.5;
    var ring_r = 62;
    var dot_r = 4;
    var seg_total = 28;
    var word = "THINKING";
    var word_len = string_length(word);

    var cycle_ms = 2700.0;
    var t_norm = frac(current_time / cycle_ms);

    var phase = 0;
    var p = 0.0;
    if (t_norm < 0.45) {
        phase = 0; // reveal/rotate letters
        p = t_norm / 0.45;
    } else if (t_norm < 0.75) {
        phase = 1; // fill ring segments
        p = (t_norm - 0.45) / 0.30;
    } else {
        phase = 2; // erase ring segments
        p = (t_norm - 0.75) / 0.25;
    }

    var spin_deg = (current_time * 0.22) mod 360;

    draw_set_alpha(0.35);
    draw_set_color(c_dkgray);
    draw_circle(cx, cy, ring_r, true);
    draw_set_alpha(1);

    if (phase == 0) {
        var reveal = max(1, floor(p * word_len));
        draw_set_color(c_white);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        for (var i = 0; i < reveal; i++) {
            var ch = string_char_at(word, i + 1);
            var a = spin_deg + (i * (360 / word_len));
            var lx = cx + lengthdir_x(ring_r, a);
            var ly = cy + lengthdir_y(ring_r, a);
            draw_text(lx, ly, ch);
        }
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
    } else {
        var keep = seg_total;
        if (phase == 1) {
            keep = floor(p * seg_total);
        } else {
            keep = seg_total - floor(p * seg_total);
        }

        draw_set_color(c_aqua);
        for (var s = 0; s < keep; s++) {
            var sa = spin_deg + (s * (360 / seg_total));
            var sx = cx + lengthdir_x(ring_r, sa);
            var sy = cy + lengthdir_y(ring_r, sa);
            draw_circle(sx, sy, dot_r, false);
        }

        draw_set_alpha(0.45);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(c_ltgray);
        draw_text(cx, cy, "thinking");
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_alpha(1);
    }
}
if (template_list_overlay_active) {
    var gui_w = display_get_gui_width();
    var gui_h = display_get_gui_height();
    if (gui_w <= 0) gui_w = room_width;
    if (gui_h <= 0) gui_h = room_height;

    draw_set_alpha(0.90);
    draw_set_color(c_black);
    draw_rectangle(0, 0, gui_w, gui_h, false);
    draw_set_alpha(1);

    var box_margin = 48;
    var box_w = min(520, gui_w - (box_margin * 2));
    if (box_w < 300) box_w = gui_w - 20;

    var max_rows = floor((gui_h - 180) / template_list_row_h);
    if (max_rows < 1) max_rows = 1;
    var total_rows = array_length(template_list_names);
    template_list_visible_count = min(total_rows, max_rows);

    var box_h = 90 + (template_list_visible_count * template_list_row_h);
    template_list_box_x = floor((gui_w - box_w) * 0.5);
    template_list_box_y = floor((gui_h - box_h) * 0.5);
    template_list_box_w = box_w;
    template_list_box_h = box_h;
    template_list_first_row_y = template_list_box_y + 48;

    draw_set_color(c_white);
    draw_rectangle(template_list_box_x, template_list_box_y, template_list_box_x + box_w, template_list_box_y + box_h, true);
    draw_text(template_list_box_x + 12, template_list_box_y + 12, "Saved Templates");

    if (total_rows <= 0) {
        draw_text(template_list_box_x + 12, template_list_first_row_y, "(none found)");
    } else {
        for (var t = 0; t < template_list_visible_count; t++) {
            var row_y = template_list_first_row_y + (t * template_list_row_h);
            var hovered = point_in_rectangle(mouse_x, mouse_y, template_list_box_x, row_y, template_list_box_x + box_w, row_y + template_list_row_h);
            if (hovered) {
                draw_set_alpha(0.25);
                draw_set_color(c_aqua);
                draw_rectangle(template_list_box_x + 2, row_y, template_list_box_x + box_w - 2, row_y + template_list_row_h, false);
                draw_set_alpha(1);
                draw_set_color(c_white);
            }
            draw_text(template_list_box_x + 12, row_y + 2, template_list_names[t]);
        }

        if (template_list_visible_count < total_rows) {
            draw_set_color(c_ltgray);
            draw_text(template_list_box_x + 12, template_list_first_row_y + (template_list_visible_count * template_list_row_h),
                "...and " + string(total_rows - template_list_visible_count) + " more");
            draw_set_color(c_white);
        }
    }

    draw_set_color(c_ltgray);
    draw_text(template_list_box_x + 12, template_list_box_y + box_h - 26, "Left click name to load. Click anywhere or Esc to close.");
    draw_set_color(c_white);
}









if (solver_active && !template_list_overlay_active) {
    var elapsed_s = 0;
    if (variable_global_exists("solver_start_time_ms") && global.solver_start_time_ms > 0) {
        elapsed_s = floor(max(0, current_time - global.solver_start_time_ms) / 1000);
    }

    var px = room_width - 230;
    var py = 10;
    draw_set_alpha(0.35);
    draw_set_color(c_dkgray);
    draw_rectangle(px, py, px + 220, py + 74, false);
    draw_set_alpha(1);
    draw_set_color(c_yellow);
    draw_text(px + 8, py + 6, "WORKING");
    draw_set_color(c_white);
    draw_text(px + 8, py + 24, "t=" + string(elapsed_s) + "s");
    draw_text(px + 70, py + 24, "hb=" + string(global.solver_heartbeat));
    draw_text(px + 8, py + 42, "wu=" + string(global.solver_work_units));
    draw_text(px + 8, py + 58, "att=" + string(global.fill_attempt_count));
}


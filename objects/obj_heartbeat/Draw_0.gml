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

// Mark any fully-filled across/down entries that are NOT in the dictionary.
var invalid_word_cells = ds_map_create();
var have_dict = variable_global_exists("wordLookup") && ds_exists(global.wordLookup, ds_type_map);
if (have_dict) {
    for (var si = 0; si < array_length(slots); si++) {
        var sd = slots[si];
        var w = crossword_slot_word(sd);
        if (string_pos("_", w) > 0) continue;
        if (w == "") continue;
        if (!ds_map_exists(global.wordLookup, w)) {
            for (var k2 = 0; k2 < sd.len; k2++) {
                var ic = sd.col + ((sd.dir == "A") ? k2 : 0);
                var ir = sd.row + ((sd.dir == "D") ? k2 : 0);
                var ikey = string(ic) + "," + string(ir);
                if (!ds_map_exists(invalid_word_cells, ikey)) ds_map_add(invalid_word_cells, ikey, true);
            }
        }
    }
}



// Hover debug: highlight the letter under the mouse (verifies grid->mouse hitboxes)
var hover_col = -1;
var hover_row = -1;
{
    var hmx = mouse_x;
    var hmy = mouse_y;
    var gx1 = padding;
    var gy1 = padding;
    var gx2 = padding + (grid_width * cell_size);
    var gy2 = padding + (grid_height * cell_size);
    if (hmx >= gx1 && hmx < gx2 && hmy >= gy1 && hmy < gy2) {
        hover_col = floor((hmx - gx1) / cell_size);
        hover_row = floor((hmy - gy1) / cell_size);
    }
}

for (var col_i = 0; col_i < grid_width; col_i++) {
    for (var row_i = 0; row_i < grid_height; row_i++) {
        var screen_col = padding + (col_i * cell_size);
        var screen_row = padding + (row_i * cell_size);

        draw_rectangle(screen_col, screen_row, screen_col + cell_size, screen_row + cell_size, true);
        if (col_i == hover_col && row_i == hover_row) {
            draw_set_alpha(0.22);
            draw_rectangle_color(screen_col, screen_row, screen_col + cell_size, screen_row + cell_size, c_yellow, c_yellow, c_yellow, c_yellow, false);
            draw_set_alpha(1);
        }
        if (word_entry_active && col_i == word_entry_col && row_i == word_entry_row) {
            draw_set_alpha(0.65);
            draw_rectangle_color(screen_col, screen_row, screen_col + cell_size, screen_row + cell_size, c_lime, c_lime, c_lime, c_lime, false);
            draw_set_alpha(1);
        }

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

            // Missing dictionary marker (only when the whole entry is filled)
            if (ds_map_exists(invalid_word_cells, cell_key)) {
                draw_set_color(c_fuchsia);
                draw_triangle(screen_col + cell_size - 2, screen_row + 2,
                    screen_col + cell_size - 10, screen_row + 2,
                    screen_col + cell_size - 2, screen_row + 10, false);
                draw_set_color(c_white);
            }

            if (is_string(content) && content != "") {
                if (col_i == hover_col && row_i == hover_row) {
                    draw_set_color(c_yellow);
                    draw_text(screen_col + (cell_size / 2) - 4, screen_row + (cell_size / 2) - 8, content);
                    draw_set_color(c_white);
                } else {
                    draw_text(screen_col + (cell_size / 2) - 4, screen_row + (cell_size / 2) - 8, content);
                }
            }
        }
    }
}

ds_map_destroy(slot_numbers);
ds_map_destroy(invalid_word_cells);
// ROI highlight (chunk fill)
if (variable_global_exists("roi_fill_enabled") && global.roi_fill_enabled) {
    var rx = clamp(global.roi_x, 0, max(0, grid_width - global.roi_w));
    var ry = clamp(global.roi_y, 0, max(0, grid_height - global.roi_h));
    draw_set_alpha(0.45);
    draw_set_color(c_yellow);
    var sx = padding + (rx * cell_size);
    var sy = padding + (ry * cell_size);
    draw_rectangle(sx, sy, sx + (global.roi_w * cell_size), sy + (global.roi_h * cell_size), true);
    draw_set_alpha(1);
    draw_set_color(c_white);
}
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
var wrap_w = max(160, room_width - (padding * 2) - max(0, layout_right_reserved));

var template_label = current_template_name;
if (template_label == "") template_label = "(unsaved)";

var ty = text_y;

draw_set_color(c_white);
draw_text(padding, ty, "Template: " + template_label);
ty += 22;

var instr = "LMB mirror-toggle blocks, RMB single-delete, Shift+LMB type char";
draw_set_color(c_ltgray);
draw_text_ext(padding, ty, instr, 20, wrap_w);
ty += string_height_ext(instr, 20, wrap_w) + 4;

draw_set_color(c_white);
draw_text(padding, ty, "Target max attempts: " + string(global.fill_attempt_limit));
ty += 22;
draw_text(padding, ty, "Attempt count: " + string(global.fill_attempt_count));
ty += 22;
draw_text(padding, ty, "Solver heartbeat: " + string(global.solver_heartbeat));
ty += 22;
draw_text(padding, ty, "Work units: " + string(global.solver_work_units));
ty += 26;

draw_set_color(c_lime);
draw_text_ext(padding, ty, status_text, 20, wrap_w);
ty += string_height_ext(status_text, 20, wrap_w) + 6;
draw_set_color(c_white);

if (array_length(unresolved_long_slots) > 0) {
    var label = "Fill blockers (" + string(global.long_entry_min_len) + "+): ";
    for (var b = 0; b < min(array_length(unresolved_long_slots), 8); b++) {
        var bs = unresolved_long_slots[b];
        if (b > 0) label += ", ";
        label += string(bs.num) + bs.dir;
    }
    draw_set_color(c_aqua);
    draw_text_ext(padding, ty, label, 20, wrap_w);
    ty += string_height_ext(label, 20, wrap_w) + 4;
    draw_set_color(c_white);
}

if (cmd_stage == 1) {
    draw_set_color(c_yellow);
    draw_text(padding, ty, "> ? (type A or D)");
    ty += 22;
    draw_set_color(c_white);
} else if (variable_global_exists("cmd_mode") && global.cmd_mode != 0) {
    draw_set_color(c_yellow);
    var cmd_lbl = (global.cmd_mode == 1) ? "> ?A (tap a cell)" : "> ?D (tap a cell)";
    draw_text(padding, ty, cmd_lbl);
    ty += 22;
    draw_set_color(c_white);
}

if (letter_entry_active) {
    draw_set_color(c_yellow);
    var entry_lbl = "Cell entry: type any character (Space clears, Backspace/Delete clears), Esc cancels";
    draw_text_ext(padding, ty, entry_lbl, 20, wrap_w);
    ty += string_height_ext(entry_lbl, 20, wrap_w) + 4;
    draw_set_color(c_white);
}

if (word_entry_active && !is_undefined(word_entry_slot)) {
    draw_set_color(c_aqua);
    var word_entry_lbl = "Word entry: " + string(word_entry_slot.num) + word_entry_slot.dir
        + "  Arrows move, Space clears, Enter commits, Esc exits";
    draw_text_ext(padding, ty, word_entry_lbl, 20, wrap_w);
    ty += string_height_ext(word_entry_lbl, 20, wrap_w) + 4;
    draw_set_color(c_white);
} else if (variable_global_exists("word_entry_mode_enabled") && global.word_entry_mode_enabled) {
    draw_set_color(c_aqua);
    var word_entry_pick_lbl = "Word entry ON: left click an Across entry or right click a Down entry";
    draw_text_ext(padding, ty, word_entry_pick_lbl, 20, wrap_w);
    ty += string_height_ext(word_entry_pick_lbl, 20, wrap_w) + 4;
    draw_set_color(c_white);
}

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
    var hovered_letter = false; // placeholder to avoid uninitialized read (UI uses a constant here)

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
        draw_set_color(hovered_letter ? c_white : c_ltgray);
        draw_text(cx, cy, "thinking");
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_alpha(1);
    }
}

if (candidate_overlay_active) {
    var gui_w = display_get_gui_width();
    var gui_h = display_get_gui_height();
    if (gui_w <= 0) gui_w = room_width;
    if (gui_h <= 0) gui_h = room_height;

    // Use GUI-space mouse coords for overlay hover/highlight
    var mx = mouse_x;
    var my = mouse_y;
    if (gui_w > 0 && gui_h > 0 && (gui_w != room_width || gui_h != room_height)) {
        mx = device_mouse_x_to_gui(0);
        my = device_mouse_y_to_gui(0);
    }

    var box_margin = 48;
    var box_w = min(520, gui_w - (box_margin * 2));
    if (box_w < 300) box_w = gui_w - 20;

    var total_all = (variable_instance_exists(id, "candidate_list_total") ? candidate_list_total : array_length(candidate_list_words));
var total_all_unfiltered = (variable_instance_exists(id, "candidate_list_total_all") ? candidate_list_total_all : total_all);
var show_footer = (total_all_unfiltered > candidate_page_size);
var paging = (total_all > candidate_page_size);
var footer_h = show_footer ? 78 : 0;

    var max_rows = floor(((gui_h - 180) - footer_h) / candidate_list_row_h);
    if (max_rows < 1) max_rows = 1;
    var total_rows = array_length(candidate_list_words);
    candidate_list_visible_count = min(total_rows, max_rows);

    var box_h = 110 + (candidate_list_visible_count * candidate_list_row_h) + footer_h;
    candidate_list_box_x = floor((gui_w - box_w) * 0.5);
    candidate_list_box_y = floor((gui_h - box_h) * 0.5);
    candidate_list_box_w = box_w;
    candidate_list_box_h = box_h;
    candidate_list_first_row_y = candidate_list_box_y + 68;

    draw_set_alpha(0.95);
    draw_set_color(c_black);
    draw_rectangle(candidate_list_box_x + 1, candidate_list_box_y + 1, candidate_list_box_x + box_w - 1, candidate_list_box_y + box_h - 1, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_rectangle(candidate_list_box_x, candidate_list_box_y, candidate_list_box_x + box_w, candidate_list_box_y + box_h, true);
    draw_text(candidate_list_box_x + 12, candidate_list_box_y + 12, "Close possibilities");

    var mode_btn_y1 = candidate_list_box_y + 34;
    var mode_btn_h = 20;
    var mode_btn_w = 56;
    var mode_gap = 8;
    var mode_fit_x1 = candidate_list_box_x + 12;
    var mode_any_x1 = mode_fit_x1 + mode_btn_w + mode_gap;
    var mode_fit_on = (candidate_mode == 0);
    var mode_any_on = (candidate_mode == 1);

    draw_set_alpha(mode_fit_on ? 0.45 : 0.18);
    draw_set_color(mode_fit_on ? c_aqua : c_white);
    draw_rectangle(mode_fit_x1, mode_btn_y1, mode_fit_x1 + mode_btn_w, mode_btn_y1 + mode_btn_h, false);
    draw_set_alpha(mode_any_on ? 0.45 : 0.18);
    draw_set_color(mode_any_on ? c_yellow : c_white);
    draw_rectangle(mode_any_x1, mode_btn_y1, mode_any_x1 + mode_btn_w, mode_btn_y1 + mode_btn_h, false);
    draw_set_alpha(1);

    var mode_ha = draw_get_halign();
    var mode_va = draw_get_valign();
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_white);
    draw_text(mode_fit_x1 + (mode_btn_w * 0.5), mode_btn_y1 + (mode_btn_h * 0.5), "Fits");
    draw_text(mode_any_x1 + (mode_btn_w * 0.5), mode_btn_y1 + (mode_btn_h * 0.5), "Any");
    draw_set_halign(mode_ha);
    draw_set_valign(mode_va);
    draw_set_color(c_white);

// Footer paging controls + alphabet jump (only when there are lots of candidates)
if (show_footer) {
    var btn_h = 20;
    var btn_w = 44;
    var btn_gap = 8;
    var close_w = 24;

    var footer_top = candidate_list_box_y + box_h - footer_h;
    var nav_y = candidate_list_box_y + box_h - btn_h - 10;
    var right = candidate_list_box_x + box_w - 10;

    var x_close = right - close_w;
    var x_new = x_close - btn_gap - btn_w;
    var x_next = x_new - btn_gap - btn_w;
    var x_prev = x_next - btn_gap - btn_w;

    // Page indicator (left side of footer)
    draw_set_color(c_ltgray);
    var flt = (variable_instance_exists(id, "candidate_filter_letter") && candidate_filter_letter != "") ? (candidate_filter_letter + ": ") : "";
    var mode_lbl = (candidate_mode == 0) ? "fits" : "any";
    var ptxt = mode_lbl + "  " + flt + "page " + string(candidate_page + 1) + "/" + string(candidate_pages) + " (" + string(total_all) + ")";
    draw_text(candidate_list_box_x + 12, nav_y + 2, ptxt);
    draw_set_color(c_white);

    // Buttons
    draw_set_alpha(0.25);
    draw_set_color(c_white);
    draw_rectangle(x_prev, nav_y, x_prev + btn_w, nav_y + btn_h, false);
    draw_rectangle(x_next, nav_y, x_next + btn_w, nav_y + btn_h, false);
    draw_rectangle(x_new, nav_y, x_new + btn_w, nav_y + btn_h, false);
    draw_rectangle(x_close, nav_y, x_close + close_w, nav_y + btn_h, false);
    draw_set_alpha(1);

    var old_ha = draw_get_halign();
    var old_va = draw_get_valign();
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_white);
    draw_text((x_prev + x_prev + btn_w) * 0.5, nav_y + (btn_h * 0.5), "<");
    draw_text((x_next + x_next + btn_w) * 0.5, nav_y + (btn_h * 0.5), ">");
    draw_text((x_new + x_new + btn_w) * 0.5, nav_y + (btn_h * 0.5), "New");
    draw_text((x_close + x_close + close_w) * 0.5, nav_y + (btn_h * 0.5), "X");
    draw_set_halign(old_ha);
    draw_set_valign(old_va);

    // Alphabet jump (A-Z in two rows)
    var alpha_cols = 13;
    var alpha_gap = 2;
    var alpha_size = floor((box_w - 24 - (alpha_gap * (alpha_cols - 1))) / alpha_cols);
    alpha_size = clamp(alpha_size, 12, 18);
    var alpha_total_w = (alpha_cols * alpha_size) + (alpha_gap * (alpha_cols - 1));
    var alpha_x0 = candidate_list_box_x + floor((box_w - alpha_total_w) * 0.5);
    var alpha_y0 = footer_top + 8;

    // Hover feedback: highlight the letter under the mouse so we can verify hitboxes
    var hover_idx = -1;
    if (point_in_rectangle(mx, my, alpha_x0, alpha_y0, alpha_x0 + alpha_total_w, alpha_y0 + (2 * (alpha_size + alpha_gap)) - alpha_gap)) {
        var relx = mx - alpha_x0;
        var rely = my - alpha_y0;
        var col = floor(relx / (alpha_size + alpha_gap));
        var row = floor(rely / (alpha_size + alpha_gap));
        if (col >= 0 && col < 13 && row >= 0 && row < 2) {
            hover_idx = (row * 13) + col;
        }
    }

    draw_set_alpha(0.18);
    draw_set_color(c_white);
    draw_rectangle(candidate_list_box_x + 2, footer_top, candidate_list_box_x + box_w - 2, candidate_list_box_y + box_h - 2, false);
    draw_set_alpha(1);

    for (var li = 0; li < 26; li++) {
        var r = floor(li / 13);
        var cc = li mod 13;
        var lx1 = alpha_x0 + (cc * (alpha_size + alpha_gap));
        var ly1 = alpha_y0 + (r * (alpha_size + alpha_gap));
        draw_set_alpha(0.22);
        draw_set_color(c_white);
        draw_rectangle(lx1, ly1, lx1 + alpha_size, ly1 + alpha_size, false);
        draw_set_alpha(1);

        var lab = chr(ord("A") + li);

        var hovered_letter = (li == hover_idx);
        if (hovered_letter) {
            draw_set_alpha(0.55);
            draw_set_color(c_aqua);
            draw_rectangle(lx1, ly1, lx1 + alpha_size, ly1 + alpha_size, false);
            draw_set_alpha(1);
        }

        var active_letter = (variable_instance_exists(id, "candidate_filter_letter") && candidate_filter_letter == lab);
        if (active_letter) {
            draw_set_alpha(0.45);
            draw_set_color(c_yellow);
            draw_rectangle(lx1, ly1, lx1 + alpha_size, ly1 + alpha_size, false);
            draw_set_alpha(1);
        }

        var ha0 = draw_get_halign();
        var va0 = draw_get_valign();
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(c_ltgray);
        draw_text(lx1 + (alpha_size * 0.5), ly1 + (alpha_size * 0.5), lab);
        draw_set_halign(ha0);
        draw_set_valign(va0);
        draw_set_color(c_white);
    }
}

if (!is_undefined(candidate_slot_data)) {
        draw_set_color(c_ltgray);
        draw_text(candidate_list_box_x + 12, candidate_list_box_y + 58, string(candidate_slot_data.num) + candidate_slot_data.dir + " pattern=" + candidate_slot_pattern);
        draw_set_color(c_white);
    }

    if (total_rows <= 0) {
        draw_text(candidate_list_box_x + 12, candidate_list_first_row_y, "(no suggestions)" );
    } else {
        for (var t = 0; t < candidate_list_visible_count; t++) {
            var row_y = candidate_list_first_row_y + (t * candidate_list_row_h);
            var hovered = point_in_rectangle(mx, my, candidate_list_box_x, row_y, candidate_list_box_x + box_w, row_y + candidate_list_row_h);
            if (hovered) {
                draw_set_color(c_dkgray);
                draw_rectangle(candidate_list_box_x + 2, row_y, candidate_list_box_x + box_w - 2, row_y + candidate_list_row_h, false);
                draw_set_color(c_white);
            }
            var w = candidate_list_words[t];
            var x0 = candidate_list_box_x + 12;
            var y0 = row_y + 2;
            var pat = candidate_slot_pattern;
            var pat_len = string_length(pat);
            var wlen = string_length(w);
            var xpos = x0;
            for (var ci = 1; ci <= wlen; ci++) {
                var ch = string_char_at(w, ci);
                var hi = false;
                if (ci <= pat_len) {
                    var pch = string_char_at(pat, ci);
                    if (pch != "_" && pch == ch) hi = true;
                }

                var cw = max(6, string_width(ch));
                if (hi) {
                    draw_set_alpha(0.22);
                    draw_set_color(c_ltgray);
                    draw_rectangle(xpos - 1, row_y + 1, xpos + cw + 1, row_y + candidate_list_row_h - 1, false);
                    draw_set_alpha(1);
                    draw_set_color(c_white);
                }

                draw_text(xpos, y0, ch);
                xpos += string_width(ch);
            }
        }
    }
}

if (template_list_overlay_active) {
    var gui_w = display_get_gui_width();
    var gui_h = display_get_gui_height();
    if (gui_w <= 0) gui_w = room_width;
    if (gui_h <= 0) gui_h = room_height;

    // Use GUI-space mouse coords for overlay hover/highlight
    var mx = mouse_x;
    var my = mouse_y;
    if (gui_w > 0 && gui_h > 0 && (gui_w != room_width || gui_h != room_height)) {
        mx = device_mouse_x_to_gui(0);
        my = device_mouse_y_to_gui(0);
    }

    draw_set_alpha(0.90);
    draw_set_color(c_black);
    draw_rectangle(0, 0, gui_w, gui_h, false);
    draw_set_alpha(1);

    var box_margin = 48;
    var box_w = min(560, gui_w - (box_margin * 2));
    if (box_w < 320) box_w = gui_w - 20;

    var title_h = 34;
    var footer_h = 34;
    var content_h = max(0, (gui_h - 220));
    var max_rows = floor((content_h - footer_h) / template_list_row_h);
    if (max_rows < 4) max_rows = 4;

    var total_rows = array_length(template_list_names);
    template_list_visible_count = min(total_rows, max_rows);
    template_list_max_scroll = max(0, total_rows - template_list_visible_count);
    template_list_scroll = clamp(template_list_scroll, 0, template_list_max_scroll);

    var box_h = title_h + 14 + (template_list_visible_count * template_list_row_h) + footer_h + 12;
    template_list_box_x = floor((gui_w - box_w) * 0.5);
    template_list_box_y = floor((gui_h - box_h) * 0.5);
    template_list_box_w = box_w;
    template_list_box_h = box_h;
    template_list_first_row_y = template_list_box_y + title_h + 14;

    // Window
    draw_set_alpha(0.95);
    draw_set_color(c_black);
    draw_rectangle(template_list_box_x, template_list_box_y, template_list_box_x + box_w, template_list_box_y + box_h, false);
    draw_set_alpha(1);

    // Title bar
    draw_set_alpha(0.55);
    draw_set_color(c_dkgray);
    draw_rectangle(template_list_box_x + 1, template_list_box_y + 1, template_list_box_x + box_w - 1, template_list_box_y + title_h, false);
    draw_set_alpha(1);

    draw_set_color(c_white);
    draw_text(template_list_box_x + 12, template_list_box_y + 8, "Saved Templates");

    // Close X
    var close_w = 26;
    var close_x1 = template_list_box_x + box_w - close_w - 8;
    var close_y1 = template_list_box_y + 6;
    draw_set_alpha(0.25);
    draw_set_color(c_white);
    draw_rectangle(close_x1, close_y1, close_x1 + close_w, close_y1 + 22, false);
    draw_set_alpha(1);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(close_x1 + (close_w * 0.5), close_y1 + 11, "X");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    // Content background
    var content_x1 = template_list_box_x + 12;
    var content_y1 = template_list_first_row_y;
    var content_x2 = template_list_box_x + box_w - 12;
    var content_y2 = template_list_box_y + box_h - footer_h - 10;

    draw_set_alpha(0.18);
    draw_set_color(c_white);
    draw_rectangle(content_x1 - 6, content_y1 - 6, content_x2 + 6, content_y2 + 6, false);
    draw_set_alpha(1);

    // Scroll arrows (right side)
    var sb_w = 22;
    var sb_x1 = template_list_box_x + box_w - sb_w - 10;
    var sb_up_y1 = content_y1;
    var sb_dn_y1 = content_y2 - sb_w;

    draw_set_alpha(0.22);
    draw_set_color(c_white);
    draw_rectangle(sb_x1, sb_up_y1, sb_x1 + sb_w, sb_up_y1 + sb_w, false);
    draw_rectangle(sb_x1, sb_dn_y1, sb_x1 + sb_w, sb_dn_y1 + sb_w, false);
    draw_set_alpha(1);

    draw_set_color(c_ltgray);
    draw_triangle(sb_x1 + (sb_w * 0.5), sb_up_y1 + 6, sb_x1 + 6, sb_up_y1 + sb_w - 6, sb_x1 + sb_w - 6, sb_up_y1 + sb_w - 6, false);
    draw_triangle(sb_x1 + 6, sb_dn_y1 + 6, sb_x1 + sb_w - 6, sb_dn_y1 + 6, sb_x1 + (sb_w * 0.5), sb_dn_y1 + sb_w - 6, false);

    // Rows
    if (total_rows <= 0) {
        draw_set_color(c_ltgray);
        draw_text(content_x1, content_y1, "(none found)");
        draw_set_color(c_white);
    } else {
        for (var t = 0; t < template_list_visible_count; t++) {
            var idx = template_list_scroll + t;
            if (idx >= total_rows) break;

            var row_y = template_list_first_row_y + (t * template_list_row_h);
            var hovered = point_in_rectangle(mx, my, template_list_box_x, row_y, template_list_box_x + box_w, row_y + template_list_row_h);
            if (hovered) {
                draw_set_alpha(0.25);
                draw_set_color(c_aqua);
                draw_rectangle(template_list_box_x + 2, row_y, template_list_box_x + box_w - 2, row_y + template_list_row_h, false);
                draw_set_alpha(1);
                draw_set_color(c_white);
            }
            draw_text(content_x1, row_y + 2, template_list_names[idx]);
        }
    }

    // Footer hint + range
    draw_set_color(c_ltgray);
    var a0 = min(total_rows, template_list_scroll + 1);
    var a1 = min(total_rows, template_list_scroll + template_list_visible_count);
    var rng = (total_rows > 0) ? ("Showing " + string(a0) + "-" + string(a1) + " of " + string(total_rows)) : "";
    draw_text(template_list_box_x + 12, template_list_box_y + box_h - footer_h + 10, "Wheel/PgUp/PgDn scroll. Click to load. ESC/X closes.");
    if (rng != "") draw_text(template_list_box_x + 12, template_list_box_y + box_h - 16, rng);
    draw_set_color(c_white);
}










if (!candidate_overlay_active) {
// Settings panel (right side)
ui_recalc_layout();

// Help icon (upper-right)
help_btn_w = 24;
help_btn_h = 24;
help_btn_x = room_width - padding - help_btn_w;
help_btn_y = 24;

// Draw help icon
{
    draw_set_alpha(0.35);
    draw_set_color(c_white);
    draw_circle(help_btn_x + (help_btn_w * 0.5), help_btn_y + (help_btn_h * 0.5), (help_btn_w * 0.5) - 1, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(help_btn_x + (help_btn_w * 0.5), help_btn_y + (help_btn_h * 0.5), "?");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    // Hover tooltip
    if (point_in_rectangle(mouse_x, mouse_y, help_btn_x, help_btn_y, help_btn_x + help_btn_w, help_btn_y + help_btn_h)) {
        var tip_w = 56;
        var tip_h = 18;
        var tip_x1 = help_btn_x - tip_w - 6;
        var tip_y1 = help_btn_y + 3;
        draw_set_alpha(0.85);
        draw_set_color(c_black);
        draw_rectangle(tip_x1, tip_y1, tip_x1 + tip_w, tip_y1 + tip_h, false);
        draw_set_alpha(1);
        draw_set_color(c_white);
        draw_text(tip_x1 + 8, tip_y1 + 2, "Help");
    }
}

// Mobile: small settings toggle button so the grid can use full width
if (global.mobile_layout) {
    var gear_x = help_btn_x - 30;
    var gear_y = help_btn_y;
    var gear_w = 24;
    var gear_h = 24;
    draw_set_alpha(0.8);
    draw_set_color(c_black);
    draw_rectangle(gear_x, gear_y, gear_x + gear_w, gear_y + gear_h, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_text(gear_x + 4, gear_y + 4, "SET");
}

if (ui_panel_visible) {
    draw_set_alpha(0.45);
    draw_set_color(c_black);
    draw_rectangle(ui_panel_x, ui_panel_y, ui_panel_x + ui_panel_w, ui_panel_y + ui_panel_h, false);
    draw_set_alpha(1);

    var mode = variable_global_exists("solver_mode") ? global.solver_mode : 0;

    for (var i = 0; i < ui_rows_count; i++) {
        var r = ui_rows[i];
        var is_header = (r.kind == "header");

        // Row background (subtle)
        if (!is_header) {
            draw_set_alpha(0.12);
            draw_set_color(c_white);
            draw_rectangle(r.x1, r.y1, r.x2, r.y2, false);
            draw_set_alpha(1);
        }

        // Labels
        draw_set_color(is_header ? c_white : c_ltgray);
        if (r.id == "hdr") {
            draw_text(r.x1, r.y1 + 2, "SETTINGS");
            continue;
        }

        if (r.id == "method") {
            draw_text(r.x1, r.y1 + 2, "Solver");

            // Segmented control on the right
            var sx1 = r.x1 + 78;
            var sx2 = r.x2;
            var seg_w = (sx2 - sx1) / 3;
            var labels = (seg_w < 64) ? ["N", "R", "B"] : ((seg_w < 84) ? ["Norm", "Relax", "Brute"] : ["Normal", "Relaxed", "Brute"]);
            var old_ha = draw_get_halign();
            var old_va = draw_get_valign();
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            for (var s = 0; s < 3; s++) {
                var bx1 = sx1 + (s * seg_w);
                var bx2 = bx1 + seg_w - 4;
                var active = (mode == s);
                draw_set_alpha(active ? 0.60 : 0.28);
                draw_set_color(active ? c_aqua : c_white);
                draw_rectangle(bx1, r.y1 + 1, bx2, r.y2 - 1, false);
                draw_set_alpha(1);
                draw_set_color(c_black);
                var lab = labels[s];
                var avail = max(8, (bx2 - bx1) - 8);
                var tw = string_width(lab);
                var sc = 1;
                if (tw > avail) sc = avail / tw;
                sc = clamp(sc, 0.6, 1);
                draw_text_transformed((bx1 + bx2) * 0.5, (r.y1 + r.y2) * 0.5, lab, sc, sc, 0);
            }
            draw_set_halign(old_ha);
            draw_set_valign(old_va);
            continue;
        }

        // Default label
        draw_text(r.x1, r.y1 + 2, r.label);

        // Values on right
        draw_set_color(c_white);
        if (r.id == "immutables") {
            var im = variable_global_exists("immutables_mode") ? global.immutables_mode : 0;
            var im_lbl = (im == 0) ? "Strict" : ((im == 1) ? "Soft" : "Off");
            draw_set_color(c_yellow);
            draw_text(r.x2 - string_width(im_lbl), r.y1 + 2, im_lbl);
        } else if (r.id == "gate") {
            var gl = string(global.long_entry_min_len) + "+";

            // Mini -/+ buttons at far right
            var btn = 22;
            var btn_gap = 4;
            var buttons_w = (btn * 2) + btn_gap;
            var bx0 = r.x2 - buttons_w;
            var bx1 = bx0 + btn + btn_gap;

            // Value right-aligned just left of the buttons
            var value_right = bx0 - 8;
            draw_set_color(c_white);
            draw_text(value_right - string_width(gl), r.y1 + 2, gl);

            draw_set_alpha(0.35);
            draw_set_color(c_white);
            draw_rectangle(bx0, r.y1 + 1, bx0 + btn, r.y2 - 1, false);
            draw_rectangle(bx1, r.y1 + 1, bx1 + btn, r.y2 - 1, false);
            draw_set_alpha(1);

            var old_ha2 = draw_get_halign();
            var old_va2 = draw_get_valign();
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_color(c_black);
            var midy2 = (r.y1 + r.y2) * 0.5;
            draw_text(bx0 + (btn * 0.5), midy2, "-");
            draw_text(bx1 + (btn * 0.5), midy2, "+");
            draw_set_halign(old_ha2);
            draw_set_valign(old_va2);
        } else if (r.id == "closeposs") {
            var cm = variable_global_exists("cmd_mode") ? global.cmd_mode : 0;
            var cm_lbl = (cm == 0) ? "OFF" : ((cm == 1) ? "?A" : "?D");
            draw_set_color(c_white);
            draw_text(r.x2 - string_width(cm_lbl), r.y1 + 2, cm_lbl);
        } else if (r.id == "wordentry") {
            var we = (variable_global_exists("word_entry_mode_enabled") && global.word_entry_mode_enabled);
            var we_lbl = we ? "ON" : "OFF";
            draw_set_color(we ? c_aqua : c_white);
            draw_text(r.x2 - string_width(we_lbl), r.y1 + 2, we_lbl);
        } else if (r.id == "check") {
            var lbl = "Run";
            draw_set_alpha(0.35);
            draw_set_color(c_white);
            draw_rectangle(r.x2 - 44, r.y1 + 1, r.x2, r.y2 - 1, false);
            draw_set_alpha(1);
            draw_set_color(c_black);
            draw_text(r.x2 - 36, r.y1 + 2, lbl);
        } else if (r.id == "advanced") {
            var adv = ui_advanced_open ? "ON" : "OFF";
            draw_text(r.x2 - string_width(adv), r.y1 + 2, adv);
        } else if (r.id == "fastmode") {
            var fm = (variable_global_exists("fill_fast_mode") && global.fill_fast_mode);
            var fmv = fm ? "ON" : "OFF";
            draw_set_color(fm ? c_lime : c_white);
            draw_text(r.x2 - string_width(fmv), r.y1 + 2, fmv);
        } else if (r.id == "ticksperframe") {
            var tpf = variable_global_exists("fill_ticks_per_frame") ? global.fill_ticks_per_frame : 1;
            var tpfv = string(tpf);
            draw_set_color(tpf > 1 ? c_lime : c_white);
            draw_text(r.x2 - string_width(tpfv), r.y1 + 2, tpfv);
        } else if (r.id == "roi") {
            var on = (variable_global_exists("roi_fill_enabled") && global.roi_fill_enabled);
            var v = on ? "ON" : "OFF";
            draw_set_color(c_yellow);
            draw_text(r.x2 - string_width(v), r.y1 + 2, v);
        } else if (r.id == "roisize") {
            var sz = variable_global_exists("roi_default_size") ? global.roi_default_size : 5;
            var v2 = string(sz) + "x" + string(sz);
            draw_text(r.x2 - string_width(v2), r.y1 + 2, v2);
        } else if (r.id == "stall") {
            var st = (variable_global_exists("stall_restart_enabled") && global.stall_restart_enabled);
            var v3 = st ? "ON" : "OFF";
            draw_text(r.x2 - string_width(v3), r.y1 + 2, v3);
        } else if (r.id == "vocab") {
            var vm = variable_global_exists("fill_vocab_mode") ? global.fill_vocab_mode : 0;
            var v4 = (vm == 0) ? "common-first" : ((vm == 1) ? "common-only" : "full");
            draw_text(r.x2 - string_width(v4), r.y1 + 2, v4);
        } else if (r.id == "commonness") {
            var cb = (variable_global_exists("commonness_bias_enabled") && global.commonness_bias_enabled);
            var v5 = cb ? "ON" : "OFF";
            draw_text(r.x2 - string_width(v5), r.y1 + 2, v5);
        } else if (r.id == "bruteburst") {
            var left = variable_global_exists("brute_burst_remaining") ? global.brute_burst_remaining : 0;
            var v6 = string(left);
            draw_text(r.x2 - string_width(v6), r.y1 + 2, v6);
        } else if (r.id == "editmode") {
            var em = variable_global_exists("edit_mode") ? global.edit_mode : 0;
            var v7 = (em == 1) ? "Letters" : "Blocks";
            draw_text(r.x2 - string_width(v7), r.y1 + 2, v7);
        }

        draw_set_color(c_white);
    }
}

if (solver_active && !template_list_overlay_active) {
    var elapsed_s = 0;
    if (variable_global_exists("solver_start_time_ms") && global.solver_start_time_ms > 0) {
        elapsed_s = floor(max(0, current_time - global.solver_start_time_ms) / 1000);
    }

    var px = ui_panel_visible ? ui_panel_x : (room_width - padding - 220);
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
}













// Help overlay window (scrollable)
if (help_overlay_active) {
    var box_margin = 40;
    var box_w = min(680, room_width - (box_margin * 2));
    if (box_w < 320) box_w = room_width - 20;
    var box_h = min(540, room_height - 120);
    if (box_h < 240) box_h = room_height - 40;

    help_box_w = box_w;
    help_box_h = box_h;
    help_box_x = floor((room_width - box_w) * 0.5);
    help_box_y = floor((room_height - box_h) * 0.5);

    var title_h = 34;
    var footer_h = 34;
    var content_x1 = help_box_x + 12;
    var content_y1 = help_box_y + title_h + 8;
    var content_x2 = help_box_x + box_w - 12;
    var content_y2 = help_box_y + box_h - footer_h - 8;
    var content_h = max(0, content_y2 - content_y1);

    help_visible_lines = max(1, floor(content_h / help_line_h));
    var total_lines = is_array(help_lines) ? array_length(help_lines) : 0;
    var max_scroll = max(0, total_lines - help_visible_lines);
    help_scroll = clamp(help_scroll, 0, max_scroll);

    // Dim background
    draw_set_alpha(0.80);
    draw_set_color(c_black);
    draw_rectangle(0, 0, room_width, room_height, false);
    draw_set_alpha(1);

    // Window
    draw_set_alpha(0.95);
    draw_set_color(c_black);
    draw_rectangle(help_box_x, help_box_y, help_box_x + box_w, help_box_y + box_h, false);
    draw_set_alpha(1);

    // Title bar
    draw_set_alpha(0.55);
    draw_set_color(c_dkgray);
    draw_rectangle(help_box_x + 1, help_box_y + 1, help_box_x + box_w - 1, help_box_y + title_h, false);
    draw_set_alpha(1);

    draw_set_color(c_white);
    draw_text(help_box_x + 12, help_box_y + 8, "Help");

    // Close X
    var close_w = 26;
    var close_x1 = help_box_x + box_w - close_w - 8;
    var close_y1 = help_box_y + 6;
    draw_set_alpha(0.25);
    draw_rectangle(close_x1, close_y1, close_x1 + close_w, close_y1 + 22, false);
    draw_set_alpha(1);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(close_x1 + (close_w * 0.5), close_y1 + 11, "X");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    // Content background
    draw_set_alpha(0.18);
    draw_set_color(c_white);
    draw_rectangle(content_x1 - 6, content_y1 - 6, content_x2 + 6, content_y2 + 6, false);
    draw_set_alpha(1);

    // Scroll bar (right side inside content box)
    var sb_w = 22;
    var sb_x1 = help_box_x + box_w - sb_w - 10;
    var sb_up_y1 = content_y1;
    var sb_dn_y1 = content_y2 - sb_w;

    draw_set_alpha(0.22);
    draw_set_color(c_white);
    draw_rectangle(sb_x1, sb_up_y1, sb_x1 + sb_w, sb_up_y1 + sb_w, false);
    draw_rectangle(sb_x1, sb_dn_y1, sb_x1 + sb_w, sb_dn_y1 + sb_w, false);
    draw_set_alpha(1);

    // Up/Down triangles
    draw_set_color(c_ltgray);
    draw_triangle(sb_x1 + (sb_w * 0.5), sb_up_y1 + 6, sb_x1 + 6, sb_up_y1 + sb_w - 6, sb_x1 + sb_w - 6, sb_up_y1 + sb_w - 6, false);
    draw_triangle(sb_x1 + 6, sb_dn_y1 + 6, sb_x1 + sb_w - 6, sb_dn_y1 + 6, sb_x1 + (sb_w * 0.5), sb_dn_y1 + sb_w - 6, false);

    // Text
    var draw_y = content_y1;
    for (var li = 0; li < help_visible_lines; li++) {
        var idx = help_scroll + li;
        if (idx >= total_lines) break;
        var line = help_lines[idx];

        // Simple heading styling
        var is_heading = (line != "") && (string_pos("- ", line) != 1) && (string_pos(":", line) <= 0) && (string_pos("/", line) <= 0) && (string_length(line) <= 20);
        if (is_heading && li != 0) {
            draw_set_color(c_yellow);
        } else {
            draw_set_color(c_white);
        }
        draw_text(content_x1, draw_y, line);
        draw_y += help_line_h;
    }

    // Footer hint
    draw_set_color(c_ltgray);
    draw_text(help_box_x + 12, help_box_y + box_h - footer_h + 10, "Wheel/PgUp/PgDn scroll. ESC or X closes.");
    draw_set_color(c_white);
}

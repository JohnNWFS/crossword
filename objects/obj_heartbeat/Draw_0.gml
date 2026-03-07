// Draw Event for obj_heartbeat

var tiny_font = asset_get_index("fnt_tiny");
var default_font = draw_get_font();

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
            var num_key = string(col_i) + "," + string(row_i);
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
draw_text(padding, text_y + 24, "Click cells to toggle mirrored blocks");
draw_text(padding, text_y + 48, "Target max attempts: " + string(global.fill_attempt_limit));
draw_text(padding, text_y + 72, "Attempt count: " + string(global.fill_attempt_count));

draw_set_color(c_lime);
draw_text(padding, text_y + 96, status_text);
draw_set_color(c_white);

if (letter_entry_active) {
    draw_set_color(c_yellow);
    draw_text(padding, text_y + 120, "Letter entry: type A-Z, Esc cancels");
    draw_set_color(c_white);
}

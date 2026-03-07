// Step Event for obj_heartbeat

if (solver_active) {
    crossword_solver_tick();
}

if (template_list_overlay_active) {
    if (keyboard_check_pressed(vk_escape)) {
        template_list_overlay_active = false;
        set_status("Template picker closed");
        exit;
    }

    var click_left = mouse_check_button_pressed(mb_left);
    var click_right = mouse_check_button_pressed(mb_right);
    var click_middle = mouse_check_button_pressed(mb_middle);
    if (click_left || click_right || click_middle) {
        if (click_left
            && point_in_rectangle(mouse_x, mouse_y, template_list_box_x, template_list_first_row_y,
                template_list_box_x + template_list_box_w, template_list_box_y + template_list_box_h)
            && array_length(template_list_names) > 0) {
            var idx = floor((mouse_y - template_list_first_row_y) / template_list_row_h);
            if (idx >= 0 && idx < template_list_visible_count) {
                var chosen = template_list_names[idx];
                template_list_overlay_active = false;
                load_template(chosen);
                exit;
            }
        }

        template_list_overlay_active = false;
        set_status("Template picker closed");
        exit;
    }

    exit;
}

if (mouse_check_button_pressed(mb_left)) {
    if (point_in_rectangle(mouse_x, mouse_y, size_prev_x, size_prev_y, size_prev_x + size_prev_w, size_prev_y + size_prev_h)) {
        if (current_size_index > 0) {
            current_size_index--;
            set_grid_size(grid_size_options[current_size_index]);
        }
        exit;
    }

    if (point_in_rectangle(mouse_x, mouse_y, size_next_x, size_next_y, size_next_x + size_next_w, size_next_y + size_next_h)) {
        if (current_size_index < array_length(grid_size_options) - 1) {
            current_size_index++;
            set_grid_size(grid_size_options[current_size_index]);
        }
        exit;
    }

    if (point_in_rectangle(mouse_x, mouse_y, new_blank_x, new_blank_y, new_blank_x + new_blank_w, new_blank_y + new_blank_h)) {
        new_blank_grid();
        exit;
    }

    var text_y = padding + (grid_height * cell_size) + 16;
    var gate_y = text_y + 168;
    var gate_prev_x = padding;
    var gate_next_x = padding + 252;

    if (point_in_rectangle(mouse_x, mouse_y, gate_prev_x, gate_y, gate_prev_x + 24, gate_y + 24)) {
        set_long_gate_index(long_gate_index - 1);
        exit;
    }

    if (point_in_rectangle(mouse_x, mouse_y, gate_next_x, gate_y, gate_next_x + 24, gate_y + 24)) {
        set_long_gate_index(long_gate_index + 1);
        exit;
    }
}

if (letter_entry_active) {
    if (keyboard_check_pressed(vk_escape)) {
        letter_entry_active = false;
        status_text = "Letter entry canceled";
    } else {
        var typed = keyboard_lastchar;
        if (typed != "") {
            var ch = string_char_at(typed, 1);
            if (ord(ch) >= 32) {
                if (letter_entry_col >= 0 && letter_entry_row >= 0
                    && letter_entry_col < grid_width && letter_entry_row < grid_height
                    && grid[# letter_entry_col, letter_entry_row] != "INVALID") {
                    grid[# letter_entry_col, letter_entry_row] = ch;
                    status_text = "Cell set at (" + string(letter_entry_col + 1) + "," + string(letter_entry_row + 1) + ")";
                }
                letter_entry_active = false;
            }
        }
    }
}

if (mouse_check_button_pressed(mb_left)
    && mouse_x >= padding && mouse_x <= padding + grid_width * cell_size
    && mouse_y >= padding && mouse_y <= padding + grid_height * cell_size) {

    var clicked_i = floor((mouse_x - padding) / cell_size);
    var clicked_j = floor((mouse_y - padding) / cell_size);

    if (clicked_i >= 0 && clicked_i < grid_width && clicked_j >= 0 && clicked_j < grid_height) {
        if (keyboard_check(vk_shift)) {
            if (grid[# clicked_i, clicked_j] != "INVALID") {
                letter_entry_active = true;
                letter_entry_col = clicked_i;
                letter_entry_row = clicked_j;
                status_text = "Type any character (Esc to cancel)";
            }
        } else {
            var new_value = "INVALID";
            if (grid[# clicked_i, clicked_j] == "INVALID") {
                new_value = "";
            }

            grid[# clicked_i, clicked_j] = new_value;

            var opposite_i = grid_width - 1 - clicked_i;
            var opposite_j = grid_height - 1 - clicked_j;
            if (clicked_i != opposite_i || clicked_j != opposite_j) {
                grid[# opposite_i, opposite_j] = new_value;
            }
        }
    }
}
if (mouse_check_button_pressed(mb_right)
    && mouse_x >= padding && mouse_x <= padding + grid_width * cell_size
    && mouse_y >= padding && mouse_y <= padding + grid_height * cell_size) {

    var r_clicked_i = floor((mouse_x - padding) / cell_size);
    var r_clicked_j = floor((mouse_y - padding) / cell_size);

    if (r_clicked_i >= 0 && r_clicked_i < grid_width && r_clicked_j >= 0 && r_clicked_j < grid_height) {
        if (grid[# r_clicked_i, r_clicked_j] == "INVALID") {
            grid[# r_clicked_i, r_clicked_j] = "";
            status_text = "Removed single block at (" + string(r_clicked_i + 1) + "," + string(r_clicked_j + 1) + ")";
        }
    }
}




// Step Event for obj_heartbeat

if (solver_active) {
    crossword_solver_tick();
}

if (letter_entry_active) {
    if (keyboard_check_pressed(vk_escape)) {
        letter_entry_active = false;
        status_text = "Letter entry canceled";
    } else {
        var typed = keyboard_lastchar;
        if (typed != "") {
            var ch = string_upper(string_char_at(typed, 1));
            if (ord(ch) >= ord("A") && ord(ch) <= ord("Z")) {
                if (letter_entry_col >= 0 && letter_entry_row >= 0
                    && letter_entry_col < grid_width && letter_entry_row < grid_height
                    && grid[# letter_entry_col, letter_entry_row] != "INVALID") {
                    grid[# letter_entry_col, letter_entry_row] = ch;
                    status_text = "Letter set at (" + string(letter_entry_col + 1) + "," + string(letter_entry_row + 1) + ")";
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
                status_text = "Type letter A-Z (Esc to cancel)";
            }
        } else {
            if (grid[# clicked_i, clicked_j] == "INVALID") {
                grid[# clicked_i, clicked_j] = "";
            } else {
                grid[# clicked_i, clicked_j] = "INVALID";
            }

            var opposite_i = grid_width - 1 - clicked_i;
            var opposite_j = grid_height - 1 - clicked_j;

            if (clicked_i != opposite_i || clicked_j != opposite_j) {
                if (grid[# opposite_i, opposite_j] == "INVALID") {
                    grid[# opposite_i, opposite_j] = "";
                } else {
                    grid[# opposite_i, opposite_j] = "INVALID";
                }
            }
        }
    }
}

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

// Detect small-screen touch layout (HTML/Android/iOS). Keeps desktop behavior unchanged.
var is_mobile_os = (os_type == os_android) || (os_type == os_ios) || (os_type == os_html5);
if (is_mobile_os) {
    var sw = display_get_width();
    var sh = display_get_height();
    global.mobile_layout = (min(sw, sh) <= 600);
} else {
    global.mobile_layout = false;
}

if (global.mobile_layout != mobile_layout_prev) {
    apply_mobile_layout(global.mobile_layout);
    mobile_layout_prev = global.mobile_layout;
}

// HTML5: keep GUI sized to the browser window (helps small screens)
if (os_type == os_html5) {
    display_set_gui_maximize();
}

// Solver options panel (top-right)
// Normal: all heuristics
// Relaxed: fewer heuristics
// Brute: ignore heuristics and randomize candidate order
var opt_x = room_width - 230;
var opt_y = 92;
var opt_w = 220;
var opt_h = 22;
var opt_panel_h = global.mobile_layout ? 256 : 230;
var opt_row0_y = opt_y + 22;

if (mouse_check_button_pressed(mb_left)) {
    // Method radios (rows are below the "Solver Method" header)
    if (point_in_rectangle(mouse_x, mouse_y, opt_x, opt_row0_y, opt_x + opt_w, opt_row0_y + opt_h)) {
        global.solver_mode = 0;
        global.brute_burst_remaining = 0;
        status_text = "Solver method: Normal";
        exit;
    }
    if (point_in_rectangle(mouse_x, mouse_y, opt_x, opt_row0_y + 26, opt_x + opt_w, opt_row0_y + 26 + opt_h)) {
        global.solver_mode = 1;
        global.brute_burst_remaining = 0;
        status_text = "Solver method: Relaxed";
        exit;
    }
    if (point_in_rectangle(mouse_x, mouse_y, opt_x, opt_row0_y + 52, opt_x + opt_w, opt_row0_y + 52 + opt_h)) {
        global.solver_mode = 2;
        global.brute_burst_remaining = 0;
        status_text = "Solver method: Brute";
        exit;
    }

    // Brute burst + ROI share the last row (matches Draw)
    if (point_in_rectangle(mouse_x, mouse_y, opt_x, opt_row0_y + 78, opt_x + 110, opt_row0_y + 78 + opt_h)) {
        global.brute_burst_remaining = 200;
        status_text = "Brute burst: 200 placements";
        exit;
    }
    if (point_in_rectangle(mouse_x, mouse_y, opt_x + 110, opt_row0_y + 78, opt_x + opt_w, opt_row0_y + 78 + opt_h)) {
        global.roi_fill_enabled = !global.roi_fill_enabled;
        status_text = global.roi_fill_enabled ? "ROI fill enabled (Alt+click grid to move ROI)" : "ROI fill disabled";
        exit;
    }
    // ROI size toggle (5x5 <-> 7x7)
    if (point_in_rectangle(mouse_x, mouse_y, opt_x, opt_row0_y + 104, opt_x + opt_w, opt_row0_y + 104 + opt_h)) {
        if (!variable_global_exists("roi_default_size")) global.roi_default_size = 5;
        global.roi_default_size = (global.roi_default_size == 7) ? 5 : 7;
        global.roi_w = global.roi_default_size;
        global.roi_h = global.roi_default_size;
        global.roi_x = clamp(global.roi_x, 0, max(0, grid_width - global.roi_w));
        global.roi_y = clamp(global.roi_y, 0, max(0, grid_height - global.roi_h));
        status_text = "ROI size set to " + string(global.roi_w) + "x" + string(global.roi_h);
        exit;
    }
    // Stall restart toggle (helps large grids escape long stalls)
    if (point_in_rectangle(mouse_x, mouse_y, opt_x, opt_row0_y + 130, opt_x + opt_w, opt_row0_y + 130 + opt_h)) {
        if (!variable_global_exists("stall_restart_enabled")) global.stall_restart_enabled = false;
        global.stall_restart_enabled = !global.stall_restart_enabled;
        status_text = global.stall_restart_enabled ? "Stall restart enabled" : "Stall restart disabled";
        exit;
    }

    // Vocab mode cycle (common-first -> common-only -> full)
    if (point_in_rectangle(mouse_x, mouse_y, opt_x, opt_row0_y + 156, opt_x + opt_w, opt_row0_y + 156 + opt_h)) {
        global.fill_vocab_mode = (global.fill_vocab_mode + 1) mod 3;
        status_text = "Vocab mode set to " + string(global.fill_vocab_mode);
        exit;
    }

    // Commonness scoring toggle (affects ranking within candidate lists)
    if (point_in_rectangle(mouse_x, mouse_y, opt_x, opt_row0_y + 182, opt_x + opt_w, opt_row0_y + 182 + opt_h)) {
        global.commonness_bias_enabled = !global.commonness_bias_enabled;
        status_text = global.commonness_bias_enabled ? "Commonness scoring enabled" : "Commonness scoring disabled";
        exit;
    }


    // Mobile-only: toggle between block editing and letter entry (Shift is not available on touch)
    if (global.mobile_layout
        && point_in_rectangle(mouse_x, mouse_y, opt_x, opt_row0_y + 208, opt_x + opt_w, opt_row0_y + 208 + opt_h)) {
        global.edit_mode = 1 - global.edit_mode;
        status_text = (global.edit_mode == 1) ? "Edit mode: Letters" : "Edit mode: Blocks";
        exit;
    }
    // Manual long-slot gate controls (moved to right column under solver panel)
    var gate_y = opt_y + opt_panel_h + 12;
    var gate_prev_x = opt_x;
    var gate_next_x = opt_x + opt_w - 24;
    if (point_in_rectangle(mouse_x, mouse_y, gate_prev_x, gate_y, gate_prev_x + 24, gate_y + 24)) {
        set_long_gate_index(long_gate_index - 1);
        exit;
    }
    if (point_in_rectangle(mouse_x, mouse_y, gate_next_x, gate_y, gate_next_x + 24, gate_y + 24)) {
        set_long_gate_index(long_gate_index + 1);
        exit;
    }
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

}

if (letter_entry_active) {
    if (keyboard_check_pressed(vk_escape)) {
        letter_entry_active = false;
        status_text = "Letter entry canceled";
    } else if (keyboard_check_pressed(vk_backspace) || keyboard_check_pressed(vk_delete)) {
        if (letter_entry_col >= 0 && letter_entry_row >= 0
            && letter_entry_col < grid_width && letter_entry_row < grid_height
            && grid[# letter_entry_col, letter_entry_row] != "INVALID") {
            grid[# letter_entry_col, letter_entry_row] = "";
            status_text = "Cell cleared at (" + string(letter_entry_col + 1) + "," + string(letter_entry_row + 1) + ")";
        }
        letter_entry_active = false;
    } else {
        var typed = keyboard_lastchar;
        if (typed != "") {
            var ch = string_char_at(typed, 1);
            if (ord(ch) >= 32) {
                if (letter_entry_col >= 0 && letter_entry_row >= 0
                    && letter_entry_col < grid_width && letter_entry_row < grid_height
                    && grid[# letter_entry_col, letter_entry_row] != "INVALID") {
                    if (ch == " ") {
                        grid[# letter_entry_col, letter_entry_row] = "";
                        status_text = "Cell cleared at (" + string(letter_entry_col + 1) + "," + string(letter_entry_row + 1) + ")";
                    } else {
                        grid[# letter_entry_col, letter_entry_row] = ch;
                        status_text = "Cell set at (" + string(letter_entry_col + 1) + "," + string(letter_entry_row + 1) + ")";
                    }
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
        if (keyboard_check(vk_alt)) {
            global.roi_fill_enabled = true;
            if (!variable_global_exists("roi_default_size")) global.roi_default_size = 5;
            global.roi_w = global.roi_default_size;
            global.roi_h = global.roi_default_size;
            global.roi_x = clamp(clicked_i, 0, max(0, grid_width - global.roi_w));
            global.roi_y = clamp(clicked_j, 0, max(0, grid_height - global.roi_h));
            status_text = "ROI set to (" + string(global.roi_x + 1) + "," + string(global.roi_y + 1) + ") size " + string(global.roi_w) + "x" + string(global.roi_h);
        } else if (keyboard_check(vk_shift) || (global.mobile_layout && global.edit_mode == 1)) {
            if (grid[# clicked_i, clicked_j] != "INVALID") {
                letter_entry_col = clicked_i;
                letter_entry_row = clicked_j;

                if (global.mobile_layout) {
                    // On mobile/HTML, use an async string prompt to reliably open the OS keyboard.
                    cell_dialog_col = clicked_i;
                    cell_dialog_row = clicked_j;
                    cell_dialog_request_id = get_string_async(
                        "Enter a character (blank clears):",
                        string(grid[# clicked_i, clicked_j])
                    );
                    status_text = "Cell entry prompt opened";
                } else {
                    letter_entry_active = true;
                    status_text = "Type any character (Space clears, Backspace/Delete clears, Esc cancels)";
                }
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
        } else if (grid[# r_clicked_i, r_clicked_j] != "") {
            grid[# r_clicked_i, r_clicked_j] = "";
            status_text = "Cleared cell at (" + string(r_clicked_i + 1) + "," + string(r_clicked_j + 1) + ")";
        }
    }
}







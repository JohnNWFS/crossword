// Step Event for obj_heartbeat

if (solver_active) {
    crossword_solver_tick();
}

// Help overlay interaction
if (help_overlay_active) {
    // Layout the help window in room-space coords (matches Draw).
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
    var content_top = help_box_y + title_h + 8;
    var content_h = max(0, (help_box_y + box_h - footer_h - 8) - content_top);
    help_visible_lines = max(1, floor(content_h / help_line_h));

    var total_lines = is_array(help_lines) ? array_length(help_lines) : 0;
    var max_scroll = max(0, total_lines - help_visible_lines);

    // Keys
    if (keyboard_check_pressed(vk_escape)) {
        help_close();
        exit;
    }
    if (keyboard_check_pressed(vk_pageup)) help_scroll -= help_visible_lines; // PgUp
    if (keyboard_check_pressed(vk_pagedown)) help_scroll += help_visible_lines;  // PgDn
    if (keyboard_check_pressed(vk_up)) help_scroll -= 1;
    if (keyboard_check_pressed(vk_down)) help_scroll += 1;

    // Mouse wheel
    if (mouse_wheel_up()) help_scroll -= 2;
    if (mouse_wheel_down()) help_scroll += 2;

    // Click controls
    if (mouse_check_button_pressed(mb_left)) {
        // Close X
        var close_w = 26;
        var close_x1 = help_box_x + box_w - close_w - 8;
        var close_y1 = help_box_y + 6;
        if (point_in_rectangle(mouse_x, mouse_y, close_x1, close_y1, close_x1 + close_w, close_y1 + 22)) {
            help_close();
            exit;
        }

        // Scroll arrows on right
        var sb_w = 22;
        var sb_x1 = help_box_x + box_w - sb_w - 10;
        var up_y1 = content_top;
        var dn_y1 = (help_box_y + box_h - footer_h - 8) - sb_w;
        if (point_in_rectangle(mouse_x, mouse_y, sb_x1, up_y1, sb_x1 + sb_w, up_y1 + sb_w)) {
            help_scroll -= 1;
        } else if (point_in_rectangle(mouse_x, mouse_y, sb_x1, dn_y1, sb_x1 + sb_w, dn_y1 + sb_w)) {
            help_scroll += 1;
        }
    }

    help_scroll = clamp(help_scroll, 0, max_scroll);
    exit;
}

if (template_list_overlay_active) {
    if (keyboard_check_pressed(vk_escape)) {
        template_list_overlay_active = false;
        set_status("Template picker closed");
        exit;
    }

    // Layout in GUI-space (matches Draw)
    var gui_w = display_get_gui_width();
    var gui_h = display_get_gui_height();
    if (gui_w <= 0) gui_w = room_width;
    if (gui_h <= 0) gui_h = room_height;

    var mx = mouse_x;
    var my = mouse_y;
    if (gui_w > 0 && gui_h > 0 && (gui_w != room_width || gui_h != room_height)) {
        mx = device_mouse_x_to_gui(0);
        my = device_mouse_y_to_gui(0);
    }

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

    // Keyboard scroll
    if (keyboard_check_pressed(vk_pageup)) template_list_scroll -= template_list_visible_count;
    if (keyboard_check_pressed(vk_pagedown)) template_list_scroll += template_list_visible_count;
    if (keyboard_check_pressed(vk_up)) template_list_scroll -= 1;
    if (keyboard_check_pressed(vk_down)) template_list_scroll += 1;

    // Mouse wheel
    if (mouse_wheel_up()) template_list_scroll -= 2;
    if (mouse_wheel_down()) template_list_scroll += 2;

    template_list_scroll = clamp(template_list_scroll, 0, template_list_max_scroll);

    var click_left = mouse_check_button_pressed(mb_left);
    var click_right = mouse_check_button_pressed(mb_right);
    var click_middle = mouse_check_button_pressed(mb_middle);
    if (click_left || click_right || click_middle) {
        // Close X
        var close_w = 26;
        var close_x1 = template_list_box_x + box_w - close_w - 8;
        var close_y1 = template_list_box_y + 6;
        if (click_left && point_in_rectangle(mx, my, close_x1, close_y1, close_x1 + close_w, close_y1 + 22)) {
            template_list_overlay_active = false;
            set_status("Template picker closed");
            exit;
        }

        // Scroll arrows (right side)
        var sb_w = 22;
        var sb_x1 = template_list_box_x + box_w - sb_w - 10;
        var up_y1 = template_list_first_row_y;
        var dn_y1 = (template_list_box_y + box_h - footer_h - 10) - sb_w;
        if (click_left && point_in_rectangle(mx, my, sb_x1, up_y1, sb_x1 + sb_w, up_y1 + sb_w)) {
            template_list_scroll = clamp(template_list_scroll - 1, 0, template_list_max_scroll);
            exit;
        }
        if (click_left && point_in_rectangle(mx, my, sb_x1, dn_y1, sb_x1 + sb_w, dn_y1 + sb_w)) {
            template_list_scroll = clamp(template_list_scroll + 1, 0, template_list_max_scroll);
            exit;
        }

        // Click a row to load
        if (click_left
            && point_in_rectangle(mx, my, template_list_box_x, template_list_first_row_y,
                template_list_box_x + box_w, template_list_first_row_y + (template_list_visible_count * template_list_row_h))
            && total_rows > 0) {
            var rel = floor((my - template_list_first_row_y) / template_list_row_h);
            var idx = template_list_scroll + rel;
            if (idx >= 0 && idx < total_rows) {
                var chosen = template_list_names[idx];
                template_list_overlay_active = false;
                load_template(chosen);
                exit;
            }
        }

        // Click outside closes
        if (!point_in_rectangle(mx, my, template_list_box_x, template_list_box_y, template_list_box_x + box_w, template_list_box_y + box_h)) {
            template_list_overlay_active = false;
            set_status("Template picker closed");
            exit;
        }
    }

    exit;
}


if (candidate_overlay_active) {
    if (keyboard_check_pressed(vk_escape)) {
        candidate_picker_close();
        set_status("Picker closed");
        exit;
    }

    var click_left = mouse_check_button_pressed(mb_left);
    var click_right = mouse_check_button_pressed(mb_right);
    var click_middle = mouse_check_button_pressed(mb_middle);

    // Use GUI-space mouse coords for this overlay (Draw uses GUI size/coords)
    var gui_w = display_get_gui_width();
    var gui_h = display_get_gui_height();
    var mx = mouse_x;
    var my = mouse_y;
    if (gui_w > 0 && gui_h > 0 && (gui_w != room_width || gui_h != room_height)) {
        mx = device_mouse_x_to_gui(0);
        my = device_mouse_y_to_gui(0);
    }

    // Footer controls (only when there are lots of candidates)
    if (click_left && candidate_list_total_all > candidate_page_size) {
        var btn_h = 20;
        var btn_w = 44;
        var btn_gap = 8;
        var close_w = 24;
        var footer_h = 78;

        var footer_top = candidate_list_box_y + candidate_list_box_h - footer_h;
        var nav_y = candidate_list_box_y + candidate_list_box_h - btn_h - 10;
        var right = candidate_list_box_x + candidate_list_box_w - 10;

        var x_close = right - close_w;
        var x_new = x_close - btn_gap - btn_w;
        var x_next = x_new - btn_gap - btn_w;
        var x_prev = x_next - btn_gap - btn_w;

        if (point_in_rectangle(mx, my, x_prev, nav_y, x_prev + btn_w, nav_y + btn_h)) {
            candidate_page -= 1;
            if (candidate_page < 0) candidate_page = candidate_pages - 1;
            candidate_picker_apply_page();
            set_status("Picker page " + string(candidate_page + 1) + "/" + string(candidate_pages));
            exit;
        }
        if (point_in_rectangle(mx, my, x_next, nav_y, x_next + btn_w, nav_y + btn_h)) {
            candidate_page += 1;
            if (candidate_page >= candidate_pages) candidate_page = 0;
            candidate_picker_apply_page();
            set_status("Picker page " + string(candidate_page + 1) + "/" + string(candidate_pages));
            exit;
        }
        if (point_in_rectangle(mx, my, x_new, nav_y, x_new + btn_w, nav_y + btn_h)) {
            candidate_page = irandom(candidate_pages - 1);
            candidate_picker_apply_page();
            set_status("Picker shuffled (page " + string(candidate_page + 1) + "/" + string(candidate_pages) + ")");
            exit;
        }
        if (point_in_rectangle(mx, my, x_close, nav_y, x_close + close_w, nav_y + btn_h)) {
            candidate_picker_close();
            set_status("Picker closed");
            exit;
        }

        // Alphabet filter (A-Z in two rows)
        var alpha_cols = 13;
        var alpha_gap = 2;
        var alpha_size = floor((candidate_list_box_w - 24 - (alpha_gap * (alpha_cols - 1))) / alpha_cols);
        alpha_size = clamp(alpha_size, 12, 18);
        var alpha_total_w = (alpha_cols * alpha_size) + (alpha_gap * (alpha_cols - 1));
        var alpha_x0 = candidate_list_box_x + floor((candidate_list_box_w - alpha_total_w) * 0.5);
        var alpha_y0 = footer_top + 8;

        if (point_in_rectangle(mx, my, alpha_x0, alpha_y0, alpha_x0 + alpha_total_w, alpha_y0 + (2 * (alpha_size + alpha_gap)) - alpha_gap)) {
            var relx = mx - alpha_x0;
            var rely = my - alpha_y0;
            var col = floor(relx / (alpha_size + alpha_gap));
            var row = floor(rely / (alpha_size + alpha_gap));
            if (col >= 0 && col < 13 && row >= 0 && row < 2) {
                var idx = (row * 13) + col;
                if (idx >= 0 && idx < 26) {
                    var ch = chr(ord("A") + idx);
                    if (candidate_picker_set_filter(ch)) {
                        set_status("Jump " + ch + " (page " + string(candidate_page + 1) + "/" + string(candidate_pages) + ")");
                    } else {
                        set_status("No words for " + ch);
                    }
                    exit;
                }
            }
        }
    }

    if (click_left || click_right || click_middle) {
        if (click_left
            && point_in_rectangle(mx, my, candidate_list_box_x, candidate_list_first_row_y,
                candidate_list_box_x + candidate_list_box_w, candidate_list_first_row_y + (candidate_list_visible_count * candidate_list_row_h))
            && array_length(candidate_list_words) > 0) {
            var idx = floor((my - candidate_list_first_row_y) / candidate_list_row_h);
            if (idx >= 0 && idx < candidate_list_visible_count) {
                var chosen = candidate_list_words[idx];
                var sd = candidate_slot_data;
                if (!is_undefined(sd) && chosen != "") {
                    for (var k = 0; k < sd.len; k++) {
                        var col_i = sd.col + ((sd.dir == "A") ? k : 0);
                        var row_i = sd.row + ((sd.dir == "D") ? k : 0);
                        if (obj_heartbeat.grid[# col_i, row_i] != "INVALID") {
                            obj_heartbeat.grid[# col_i, row_i] = string_char_at(chosen, k + 1);
                        }
                    }
                    set_status("Applied " + string(sd.num) + sd.dir + "=" + chosen);
                }
                candidate_picker_close();
                exit;
            }
        }

        candidate_picker_close();
        set_status("Picker closed");
        exit;
    }

    exit;
}

// Detect small-screen touch layout (HTML/Android/iOS). Keeps desktop behavior unchanged.
var is_mobile_os = (os_type == os_android) || (os_type == os_ios) || (os_type == os_browser);
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
if (os_type == os_browser) {
    display_set_gui_maximize();
}

// UI layout (panel visibility affects grid sizing + bottom buttons)
ui_recalc_layout();
update_cell_size();
ui_layout_bottom_buttons();


// Command: press ? then A or D, then click a cell to open the Close Possibilities picker
if (!solver_active && !letter_entry_active && !template_list_overlay_active && !candidate_overlay_active) {
    // keyboard_lastchar works reliably for punctuation like "?" across platforms
    var ch = keyboard_lastchar;
    if (ch != "" && ch != cmd_lastchar) {
        cmd_lastchar = ch;
        var up = string_upper(ch);

        if (cmd_stage == 0) {
            if (ch == "?") {
                cmd_stage = 1;
                global.cmd_mode = 0;
                set_status("Command: type A or D");
            }
        } else if (cmd_stage == 1) {
            if (up == "A") {
                cmd_stage = 2;
                global.cmd_mode = 1;
                set_status("Close possibilities armed: ?A (click a cell)");
            } else if (up == "D") {
                cmd_stage = 2;
                global.cmd_mode = 2;
                set_status("Close possibilities armed: ?D (click a cell)");
            } else if (ch == "\u001b") {
                cmd_stage = 0;
                set_status("Command cancelled");
            }
        }
    }

    if ((cmd_stage == 1 || cmd_stage == 2) && keyboard_check_pressed(vk_escape)) {
        cmd_stage = 0;
        global.cmd_mode = 0;
        set_status("Command cancelled");
    }
}


// Help button + Settings panel interaction (right side)
// Uses ui_rows hitboxes so clicks always match what is drawn.
if (mouse_check_button_pressed(mb_left) && !template_list_overlay_active && !candidate_overlay_active) {
    // Help icon (upper-right)
    help_btn_w = 24;
    help_btn_h = 24;
    help_btn_x = room_width - padding - help_btn_w;
    help_btn_y = 24;
    if (point_in_rectangle(mouse_x, mouse_y, help_btn_x, help_btn_y, help_btn_x + help_btn_w, help_btn_y + help_btn_h)) {
        // Close other overlays just in case
        candidate_picker_close();
        template_list_overlay_active = false;
        help_open();
        exit;
    }

    // Mobile: small settings toggle button so the grid can use full width
    if (global.mobile_layout) {
        var set_x = help_btn_x - 30;
        var set_y = help_btn_y;
        var set_w = 24;
        var set_h = 24;
        if (point_in_rectangle(mouse_x, mouse_y, set_x, set_y, set_x + set_w, set_y + set_h)) {
            ui_settings_open_mobile = !ui_settings_open_mobile;
            set_status(ui_settings_open_mobile ? "Settings opened" : "Settings hidden");
            exit;
        }
    }

    // Ensure row geometry is current for this frame.
    ui_recalc_layout();

    if (ui_panel_visible && point_in_rectangle(mouse_x, mouse_y, ui_panel_x, ui_panel_y, ui_panel_x + ui_panel_w, ui_panel_y + ui_panel_h)) {
        var mode = variable_global_exists("solver_mode") ? global.solver_mode : 0;

        for (var i = 0; i < ui_rows_count; i++) {
            var r = ui_rows[i];
            if (!point_in_rectangle(mouse_x, mouse_y, r.x1, r.y1, r.x2, r.y2)) continue;

            // Header row: no action
            if (r.kind == "header") exit;

            if (r.id == "method") {
                var sx1 = r.x1 + 78;
                var sx2 = r.x2;
                if (mouse_x >= sx1 && mouse_x <= sx2) {
                    var seg_w = (sx2 - sx1) / 3;
                    var s = floor((mouse_x - sx1) / max(1, seg_w));
                    s = clamp(s, 0, 2);
                    global.solver_mode = s;
                    global.brute_burst_remaining = 0;
                    set_status("Solver method: " + ((s == 0) ? "Normal" : ((s == 1) ? "Relaxed" : "Brute")));
                }
                exit;
            }

            if (r.id == "immutables") {
                if (!variable_global_exists("immutables_mode")) global.immutables_mode = 0;
                global.immutables_mode = (global.immutables_mode + 1) mod 3;
                set_status("Immutables: " + ((global.immutables_mode == 0) ? "Strict" : ((global.immutables_mode == 1) ? "Soft" : "Off")));
                exit;
            }

            if (r.id == "gate") {
                var btn = 22;
                var btn_gap = 4;
                var buttons_w = (btn * 2) + btn_gap;
                var bx0 = r.x2 - buttons_w;
                var bx1 = bx0 + btn + btn_gap;

                if (point_in_rectangle(mouse_x, mouse_y, bx0, r.y1 + 1, bx0 + btn, r.y2 - 1)) {
                    set_long_gate_index(long_gate_index - 1);
                } else if (point_in_rectangle(mouse_x, mouse_y, bx1, r.y1 + 1, bx1 + btn, r.y2 - 1)) {
                    set_long_gate_index(long_gate_index + 1);
                }
                exit;
            }

            if (r.id == "closeposs") {
                global.cmd_mode = (global.cmd_mode + 1) mod 3;
                cmd_stage = 0;
                set_status((global.cmd_mode == 0) ? "Close words: OFF" : ((global.cmd_mode == 1) ? "Close words: ?A" : "Close words: ?D"));
                exit;
            }

            if (r.id == "check") {
                crossword_check_grid_feasibility();
                exit;
            }

            if (r.id == "advanced") {
                ui_advanced_open = !ui_advanced_open;
                set_status(ui_advanced_open ? "Advanced settings opened" : "Advanced settings closed");
                exit;
            }

            // Advanced-only rows below are only present in ui_rows when Advanced is open.
            if (r.id == "roi") {
                if (!variable_global_exists("roi_fill_enabled")) global.roi_fill_enabled = false;
                global.roi_fill_enabled = !global.roi_fill_enabled;
                set_status(global.roi_fill_enabled ? "ROI chunk fill enabled (Alt+click grid to move ROI)" : "ROI chunk fill disabled");
                exit;
            }

            if (r.id == "roisize") {
                if (!variable_global_exists("roi_default_size")) global.roi_default_size = 5;
                global.roi_default_size = (global.roi_default_size == 7) ? 5 : 7;
                global.roi_w = global.roi_default_size;
                global.roi_h = global.roi_default_size;
                global.roi_x = clamp(global.roi_x, 0, max(0, grid_width - global.roi_w));
                global.roi_y = clamp(global.roi_y, 0, max(0, grid_height - global.roi_h));
                set_status("ROI size set to " + string(global.roi_w) + "x" + string(global.roi_h));
                exit;
            }

            if (r.id == "stall") {
                if (!variable_global_exists("stall_restart_enabled")) global.stall_restart_enabled = false;
                global.stall_restart_enabled = !global.stall_restart_enabled;
                set_status(global.stall_restart_enabled ? "Stall restart enabled" : "Stall restart disabled");
                exit;
            }

            if (r.id == "vocab") {
                if (!variable_global_exists("fill_vocab_mode")) global.fill_vocab_mode = 0;
                global.fill_vocab_mode = (global.fill_vocab_mode + 1) mod 3;
                set_status("Vocab: " + ((global.fill_vocab_mode == 0) ? "common-first" : ((global.fill_vocab_mode == 1) ? "common-only" : "full")));
                exit;
            }

            if (r.id == "commonness") {
                if (!variable_global_exists("commonness_bias_enabled")) global.commonness_bias_enabled = true;
                global.commonness_bias_enabled = !global.commonness_bias_enabled;
                set_status(global.commonness_bias_enabled ? "Commonness score ON" : "Commonness score OFF");
                exit;
            }

            if (r.id == "bruteburst") {
                if (!variable_global_exists("brute_burst_remaining")) global.brute_burst_remaining = 0;
                global.brute_burst_remaining = (global.brute_burst_remaining <= 0) ? 200 : 0;
                set_status("Brute burst: " + string(global.brute_burst_remaining));
                exit;
            }
        }

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

        // Close possibilities one-shot command: open picker instead of toggling blocks/letters
        if (variable_global_exists("cmd_mode") && global.cmd_mode != 0) {
            var want_dir = (global.cmd_mode == 1) ? "A" : "D";
            var slots = crossword_build_slots();
            var found = undefined;
            for (var si = 0; si < array_length(slots); si++) {
                var sd = slots[si];
                if (sd.dir != want_dir) continue;
                if (want_dir == "A") {
                    if (sd.row == clicked_j && clicked_i >= sd.col && clicked_i < sd.col + sd.len) { found = sd; break; }
                } else {
                    if (sd.col == clicked_i && clicked_j >= sd.row && clicked_j < sd.row + sd.len) { found = sd; break; }
                }
            }

            if (is_undefined(found)) {
                set_status("No slot found at that cell");
            } else {
                // Collect a larger pool so paging + A-Z filtering works (the popup still shows 10 per page).
                var res = crossword_collect_close_possibilities(found, 240);
                candidate_slot_data = found;
                candidate_slot_pattern = res.pattern;
                if (array_length(res.words) > 0) {
                    candidate_picker_open(res.words);
                } else {
                    set_status("No suggestions for " + string(found.num) + found.dir + " pattern=" + res.pattern);
                }
            }

            global.cmd_mode = 0;
            cmd_stage = 0;
            exit;
        }
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









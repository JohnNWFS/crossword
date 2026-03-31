// Create Event for obj_heartbeat

grid_size_options = [5, 7, 9, 11, 13, 15];
current_size_index = 0;
grid_width = grid_size_options[current_size_index];
grid_height = grid_size_options[current_size_index];

cell_size = 32;
padding = 64;
layout_bottom_reserved = 220;
layout_right_reserved = 0;

// Cache base layout values so we can switch to a compact touch layout on small screens (HTML/mobile)
base_padding = padding;
base_layout_bottom_reserved = layout_bottom_reserved;
base_layout_right_reserved = layout_right_reserved;
mobile_layout_prev = false;

recalc_ui_positions = function() {
    size_prev_x = padding;
    size_prev_y = 24;
    size_prev_w = 32;
    size_prev_h = 32;

    size_next_x = padding + 176;
    size_next_y = 24;
    size_next_w = 32;
    size_next_h = 32;

    new_blank_x = padding + 224;
    new_blank_y = 24;
    new_blank_w = 160;
    new_blank_h = 32;
};


// UI layout settings (right panel + bottom bar)
ui_panel_w = 240;
ui_panel_pad = 12;
ui_row_h = 24;
ui_row_gap = 6;
ui_panel_y = 92;
ui_panel_gap_left = 24; // space between grid and right panel
ui_panel_visible = true;
ui_panel_x = 0;
ui_panel_h = 0;
ui_rows = [];
ui_rows_count = 0;
ui_advanced_open = false;
ui_settings_open_mobile = false; // toggled by a small icon on mobile
apply_mobile_layout = function(_on) {
    // Keep changes minimal to avoid breaking desktop layout.
    if (_on) {
        padding = 24;
        layout_bottom_reserved = 190;
        // On mobile, default to hiding the right panel so the grid fits.
        ui_settings_open_mobile = false;
    } else {
        padding = base_padding;
        layout_bottom_reserved = base_layout_bottom_reserved;
    }
    recalc_ui_positions();
    update_cell_size();
};

// Bottom buttons layout
ui_layout_bottom_buttons = function() {
    // Keep buttons aligned and sized across resolutions/HTML/mobile.
    var btn_h = global.mobile_layout ? 60 : 64;
    var btn_gap = global.mobile_layout ? 12 : 18;
    var btn_pad = max(16, padding);

    if (global.mobile_layout) {
        // 2 rows on small screens
        var y2 = room_height - btn_h - 24;
        var y1 = y2 - btn_h - btn_gap;

        // Row 1: Load, Save, Pattern
        var row1 = 3;
        var w1 = floor((room_width - (btn_pad * 2) - (btn_gap * (row1 - 1))) / row1);
        var x1 = btn_pad;
        with (obj_loadButton) { x = x1; y = y1; image_xscale = w1 / 64; image_yscale = btn_h / 64; }
        with (obj_saveButton) { x = x1 + (w1 + btn_gap) * 1; y = y1; image_xscale = w1 / 64; image_yscale = btn_h / 64; }
        with (obj_makePattern) { x = x1 + (w1 + btn_gap) * 2; y = y1; image_xscale = w1 / 64; image_yscale = btn_h / 64; }

        // Row 2: Fill, Stop, Export
        var row2 = 3;
        var w2 = floor((room_width - (btn_pad * 2) - (btn_gap * (row2 - 1))) / row2);
        var x2 = btn_pad;
        with (obj_fillGrid) { x = x2; y = y2; image_xscale = w2 / 64; image_yscale = btn_h / 64; }
        with (obj_stopFill) { x = x2 + (w2 + btn_gap) * 1; y = y2; image_xscale = w2 / 64; image_yscale = btn_h / 64; }
        with (obj_testWordList) { x = x2 + (w2 + btn_gap) * 2; y = y2; image_xscale = w2 / 64; image_yscale = btn_h / 64; }
    } else {
        // Single row on desktop
        var btn_y = room_height - btn_h - 24;
        var count = 6;
        var btn_w = floor((room_width - (btn_pad * 2) - (btn_gap * (count - 1))) / count);
        var bx = btn_pad;

        with (obj_loadButton) { x = bx + (btn_w + btn_gap) * 0; y = btn_y; image_xscale = btn_w / 64; image_yscale = btn_h / 64; }
        with (obj_saveButton) { x = bx + (btn_w + btn_gap) * 1; y = btn_y; image_xscale = btn_w / 64; image_yscale = btn_h / 64; }
        with (obj_makePattern) { x = bx + (btn_w + btn_gap) * 2; y = btn_y; image_xscale = btn_w / 64; image_yscale = btn_h / 64; }
        with (obj_fillGrid) { x = bx + (btn_w + btn_gap) * 3; y = btn_y; image_xscale = btn_w / 64; image_yscale = btn_h / 64; }
        with (obj_stopFill) { x = bx + (btn_w + btn_gap) * 4; y = btn_y; image_xscale = btn_w / 64; image_yscale = btn_h / 64; }
        with (obj_testWordList) { x = bx + (btn_w + btn_gap) * 5; y = btn_y; image_xscale = btn_w / 64; image_yscale = btn_h / 64; }
    }
};

status_text = "Ready";
current_template_name = "";
template_dialog_request_id = -1;
template_dialog_action = "";
template_list_overlay_active = false;
template_list_names = [];
template_list_box_x = 0;
template_list_box_y = 0;
template_list_box_w = 0;
template_list_box_h = 0;
template_list_row_h = 22;
template_list_first_row_y = 0;
template_list_visible_count = 0;
template_list_scroll = 0;
template_list_max_scroll = 0;

// Help overlay (click ? in the upper-right)
help_btn_x = 0;
help_btn_y = 0;
help_btn_w = 24;
help_btn_h = 24;
help_overlay_active = false;
help_box_x = 0;
help_box_y = 0;
help_box_w = 0;
help_box_h = 0;
help_scroll = 0;
help_line_h = 18;
help_visible_lines = 0;
help_lines = [];

help_build_lines = function() {
    help_lines = [
        "Crossword Maker Help",
        "",
        "Grid",
        "- Use the < and > buttons to change grid size (odd sizes).",
        "- Click cells to toggle blocks.",
        "- LMB toggles mirrored blocks.",
        "- RMB deletes a single block without deleting its mirror.",
        "- Shift+LMB types a character into a cell.",
        "- Backspace/Delete clears a typed cell back to empty.",
        "",
        "Templates",
        "- Save Template writes the current grid (blocks + typed cells)",
        "  to a template file.",
        "- Left-click Load Template to type a template name.",
        "- Right-click Load Template to open a list of saved templates.",
        "- Make Pattern applies a mirrored, fillable block layout for the current size.",
        "",
        "Fill",
        "- Fill Grid runs the solver.",
        "- Stop Fill stops the solver so you can adjust the grid and run again.",
        "",
        "Export",
        "- Export saves the puzzle in grid format",
        "  and also writes a CSV of Across/Down words.",
        "",
        "Settings Panel",
        "Solver: Normal / Relaxed / Brute",
        "- Normal: MRV + forward-check + backtracking.",
        "- Relaxed: loosened constraints to escape local traps.",
        "- Brute: fewer heuristics; try anything that matches the slot pattern.",
        "Immutables: Strict / Soft / Off",
        "- Strict: typed letters are protected and never overwritten.",
        "- Soft: solver may override typed letters if needed.",
        "- Off: typed letters are treated like normal fill.",
        "Long-slot gate",
        "- Prevents Fill until every slot of N+ is blocked or user-filled.",
        "Close words",
        "- Type ? then A or D, then click a cell to open Close possibilities.",
        "- In the popup: click A-Z to filter suggestions by starting letter.",
        "Word entry",
        "- Toggle Word entry ON in Settings for direct answer entry.",
        "- Left click chooses an Across entry, right click chooses a Down entry.",
        "- Arrow keys move within the active entry, typing overwrites the current cell.",
        "- Space clears the current cell. Enter commits. Esc exits and keeps the letters.",
        "Check grid",
        "- Runs a feasibility check (every slot must have at least one candidate).",
        "",
        "Advanced",
        "- Toggle Advanced to show additional solver controls.",
        "- ROI chunk fill: fill a 5x5 or 7x7 region first.",
        "- Stall restart: auto-restart if progress stalls.",
        "- Vocab: common-first / common-only / full.",
        "- Commonness score: bias candidate selection toward common words.",
        "- Brute burst: temporary brute-force tries even in other modes.",
        "",
        "Controls",
        "- Mouse wheel scrolls lists/help.",
        "- PgUp/PgDn scroll help.",
        "- ESC closes popups."
    ];
};
help_build_lines();

help_open = function() {
    // Ensure Advanced is open so the help matches what users can see.
    ui_advanced_open = true;
    if (variable_global_exists("mobile_layout") && global.mobile_layout) ui_settings_open_mobile = true;
    help_overlay_active = true;
    help_scroll = 0;
    set_status("Help opened");
};

help_close = function() {
    help_overlay_active = false;
    set_status("Help closed");
};

// Command / picker helpers (for ?A / ?D style commands)
cmd_stage = 0; // 0=idle, 1=got ?, 2=armed
cmd_lastchar = ""; // last processed keyboard_lastchar for command mode
global.cmd_mode = 0; // 0=none, 1=?A (across), 2=?D (down)
candidate_overlay_active = false;
candidate_list_words = [];
candidate_list_box_x = 0;
candidate_list_box_y = 0;
candidate_list_box_w = 0;
candidate_list_box_h = 0;
candidate_list_row_h = 22;
candidate_list_first_row_y = 0;
candidate_list_visible_count = 0;
candidate_slot_data = undefined;
candidate_slot_pattern = "";

// Close-words picker paging (when there are lots of candidates)
candidate_list_all_words = [];
candidate_list_total = 0;
candidate_list_total_all = 0;
candidate_filter_letter = "";
candidate_list_filtered_words = [];
candidate_words_strict = [];
candidate_words_any = [];
candidate_mode = 0; // 0=strict fit, 1=any same-length
candidate_page_size = 10;
candidate_page = 0;
candidate_pages = 1;

candidate_picker_get_source_words = function() {
    return (candidate_mode == 0) ? candidate_words_strict : candidate_words_any;
};

candidate_picker_pick_auto_letter = function(_words) {
    if (!is_array(_words) || array_length(_words) <= 0) return "";

    if (string_length(candidate_slot_pattern) > 0) {
        var first = string_char_at(candidate_slot_pattern, 1);
        if (first != "_") return first;
    }

    for (var code = ord("A"); code <= ord("Z"); code++) {
        var ch = chr(code);
        for (var i = 0; i < array_length(_words); i++) {
            var w = _words[i];
            if (string_length(w) > 0 && string_char_at(w, 1) == ch) return ch;
        }
    }

    return "";
};

candidate_picker_apply_page = function() {
    var src_all = candidate_picker_get_source_words();
    if (!is_array(src_all)) src_all = [];
    candidate_list_total_all = array_length(src_all);

    var src = (candidate_filter_letter != "") ? candidate_list_filtered_words : src_all;
    candidate_list_total = array_length(src);
    candidate_pages = max(1, ceil(candidate_list_total / max(1, candidate_page_size)));
    candidate_page = clamp(candidate_page, 0, candidate_pages - 1);

    candidate_list_words = [];
    var start_i = candidate_page * candidate_page_size;
    var end_i = min(candidate_list_total, start_i + candidate_page_size);
    var out_i = 0;
    for (var i = start_i; i < end_i; i++) {
        candidate_list_words[out_i] = src[i];
        out_i += 1;
    }
};

candidate_picker_close = function() {
    candidate_overlay_active = false;
    candidate_list_words = [];
    candidate_list_all_words = [];
    candidate_list_total = 0;
    candidate_list_total_all = 0;
    candidate_filter_letter = "";
    candidate_list_filtered_words = [];
    candidate_words_strict = [];
    candidate_words_any = [];
    candidate_mode = 0;
    candidate_page = 0;
    candidate_pages = 1;
    candidate_slot_data = undefined;
    candidate_slot_pattern = "";
};

candidate_picker_set_mode = function(_mode) {
    candidate_mode = clamp(_mode, 0, 1);
    candidate_page = 0;
    candidate_filter_letter = "";
    candidate_list_filtered_words = [];
    candidate_picker_apply_page();
};

candidate_picker_open = function(_strict_words, _any_words) {
    candidate_words_strict = _strict_words;
    candidate_words_any = _any_words;
    candidate_list_all_words = candidate_words_strict;
    candidate_picker_set_mode(0);

    candidate_overlay_active = true;
};

candidate_picker_jump_to_letter = function(_ch) {
    return candidate_picker_set_filter(_ch);
};
candidate_picker_set_filter = function(_ch) {
    var up = string_upper(_ch);
    if (candidate_filter_letter == up) {
        // Toggle off
        candidate_filter_letter = "";
        candidate_list_filtered_words = [];
        candidate_page = 0;
        candidate_picker_apply_page();
        return true;
    }

    var source_words = candidate_picker_get_source_words();
    var tmp = [];
    var out = 0;
    for (var i = 0; i < array_length(source_words); i++) {
        var w = source_words[i];
        if (string_length(w) > 0 && string_char_at(w, 1) == up) {
            tmp[out++] = w;
        }
    }

    if (out <= 0) return false;

    candidate_filter_letter = up;
    candidate_list_filtered_words = tmp;
    candidate_page = 0;
    candidate_picker_apply_page();
    return true;
};

global.fill_attempt_limit = 250000;
global.fill_attempt_count = 0;
global.step15_min_ratio = 0.60;
global.slot_try_limit = 100;
global.long_entry_min_len = 9;
global.commonness_bias_enabled = true;

// Solver method controls (can be changed while running)
global.solver_mode = 0; // 0=Normal, 1=Relaxed, 2=Brute

global.immutables_mode = 0; // 0=Strict, 1=Soft, 2=Off

// Mobile/HTML helpers
global.mobile_layout = false;
global.edit_mode = 0; // 0=blocks, 1=letters (used on small touch screens)
global.brute_burst_remaining = 0;
global.word_entry_mode_enabled = false;

// Mobile letter-entry async prompt state (so mobile can open the OS keyboard reliably)
cell_dialog_request_id = -1;
cell_dialog_col = -1;
cell_dialog_row = -1;

// ROI (chunk fill) controls: Alt+LMB to set top-left of a 5x5 region
global.roi_fill_enabled = false;
global.roi_x = 0;
global.roi_y = 0;
global.roi_w = 5;
global.roi_h = 5;
global.roi_default_size = 5;

// Fast fill: skip the 500ms visual delay on each backtrack (default OFF so the animation is still visible)
global.fill_fast_mode = false;

// Ticks per frame: how many solver steps to run each game step (default 10 = 10x throughput vs original 1)
global.fill_ticks_per_frame = 10;
fill_ticks_options = [1, 5, 10, 20, 50];

// Optional: restart search if the solver stalls for a long time (useful on 11x11+)
global.stall_restart_enabled = false;
global.stall_restart_ms = 15000;
global.stall_restart_units = 250000;
// RNG config: set to false for normal random behavior (recommended for release).
global.use_fixed_seed = false;
global.fixed_seed = 13371;

long_gate_options = [7, 9, 11, 13, 15];
long_gate_index = 1;

letter_entry_active = false;
letter_entry_prev_active = false;
letter_entry_col = -1;
letter_entry_row = -1;
word_entry_active = false;
word_entry_slot = undefined;
word_entry_index = 0;
word_entry_col = -1;
word_entry_row = -1;
word_entry_lastchar = "";

solver_active = false;
global.visual_solver = undefined;
global.solver_fail_cells = [];
global.solver_fail_until = 0;
global.solver_heartbeat = 0;
global.solver_work_units = 0;
global.solver_start_time_ms = 0;
global.solver_last_progress_log_units = 0;

// Initialize grid
grid = ds_grid_create(grid_width, grid_height);
ds_grid_clear(grid, "");

set_status = function(_msg) {
    status_text = _msg;
};
word_entry_sync_position = function() {
    if (!word_entry_active || is_undefined(word_entry_slot)) return;

    word_entry_index = clamp(word_entry_index, 0, word_entry_slot.len - 1);
    word_entry_col = word_entry_slot.col + ((word_entry_slot.dir == "A") ? word_entry_index : 0);
    word_entry_row = word_entry_slot.row + ((word_entry_slot.dir == "D") ? word_entry_index : 0);
};
word_entry_advance = function() {
    if (!word_entry_active || is_undefined(word_entry_slot)) return;

    var next_index = word_entry_index + 1;
    if (next_index >= word_entry_slot.len) next_index = 0;

    var next_col = word_entry_slot.col + ((word_entry_slot.dir == "A") ? next_index : 0);
    var next_row = word_entry_slot.row + ((word_entry_slot.dir == "D") ? next_index : 0);

    if (next_col < 0 || next_col >= grid_width || next_row < 0 || next_row >= grid_height
        || grid[# next_col, next_row] == "INVALID") {
        next_index = 0;
    }

    word_entry_index = next_index;
    word_entry_sync_position();
};
word_entry_begin_slot = function(_slot, _col, _row) {
    if (is_undefined(_slot)) return false;

    word_entry_active = true;
    word_entry_slot = _slot;
    word_entry_index = 0;
    word_entry_lastchar = "";

    if (_slot.dir == "A") {
        word_entry_index = clamp(_col - _slot.col, 0, _slot.len - 1);
    } else {
        word_entry_index = clamp(_row - _slot.row, 0, _slot.len - 1);
    }

    word_entry_sync_position();
    set_status("Word entry: " + string(_slot.num) + _slot.dir);
    return true;
};
word_entry_stop = function(_msg) {
    word_entry_active = false;
    word_entry_slot = undefined;
    word_entry_index = 0;
    word_entry_col = -1;
    word_entry_row = -1;
    word_entry_lastchar = "";
    if (_msg != "") set_status(_msg);
};
set_long_gate_index = function(_idx) {
    if (_idx < 0 || _idx >= array_length(long_gate_options)) return;
    long_gate_index = _idx;
    global.long_entry_min_len = long_gate_options[long_gate_index];
    set_status("Manual long-slot gate set to " + string(global.long_entry_min_len) + "+");
};
apply_rng_seed = function() {
    if (global.use_fixed_seed) {
        random_set_seed(global.fixed_seed);
        show_debug_message("[RNG] Fixed seed=" + string(global.fixed_seed));
    } else {
        randomize();
        show_debug_message("[RNG] randomize()");
    }
};
update_cell_size = function() {
    // Reserve space for the right settings panel so large grids never draw under it.
    var available_w = room_width - (padding * 2) - max(0, layout_right_reserved);
    var available_h = room_height - padding - layout_bottom_reserved;
    var max_w = floor(available_w / max(1, grid_width));
    var max_h = floor(available_h / max(1, grid_height));
    var target = min(max_w, max_h);
    target = clamp(target, 18, 32);
    cell_size = target;
};

ui_recalc_layout = function() {
    // Decide if the panel is visible this frame.
    // Desktop: always on. Mobile: hidden unless the user opens it.
    ui_panel_visible = (!global.mobile_layout) || ui_settings_open_mobile;

    // Reserve right-side space for the panel (and a small gap) so the grid fits.
    layout_right_reserved = ui_panel_visible ? (ui_panel_w + ui_panel_gap_left) : 0;

    // Recompute panel geometry.
    ui_panel_x = room_width - padding - ui_panel_w;
    ui_panel_h = 0;

    // Build a compact row list used by both Step hit-testing and Draw rendering.
    ui_rows = [];
    ui_rows_count = 0;
    ui_row_cursor_y = ui_panel_y + ui_panel_pad;

    // Helper: add a single row (uniform height).
    var add_row = function(_id, _kind, _label) {
        ui_rows[ui_rows_count] = {
            id: _id,
            kind: _kind,
            label: _label,
            x1: ui_panel_x + ui_panel_pad,
            y1: ui_row_cursor_y,
            x2: ui_panel_x + ui_panel_w - ui_panel_pad,
            y2: ui_row_cursor_y + ui_row_h
        };
        ui_rows_count += 1;
        ui_row_cursor_y += ui_row_h + ui_row_gap;
    };

    add_row("hdr", "header", "Settings");
    add_row("method", "segmented", "Solver Method");
    add_row("immutables", "cycle3", "Immutables");
    add_row("gate", "gate", "Long-slot gate");
    add_row("closeposs", "cycle3", "Close words");
    add_row("wordentry", "toggle", "Word entry");
    add_row("check", "action", "Check grid");
    add_row("advanced", "toggle", "Advanced");

    if (ui_advanced_open) {
        add_row("fastmode", "toggle", "Fast fill");
        add_row("ticksperframe", "cycle", "Ticks/frame");
        add_row("roi", "toggle", "ROI chunk fill");
        add_row("roisize", "cycle", "ROI size");
        add_row("stall", "toggle", "Stall restart");
        add_row("vocab", "cycle", "Vocab");
        add_row("commonness", "toggle", "Commonness score");
        add_row("bruteburst", "action", "Brute burst");
    }

    if (global.mobile_layout) {
        add_row("editmode", "toggle", "Edit mode");
    }

    // Panel height includes bottom padding, but must not overlap the bottom button area.
    ui_panel_h = (ui_row_cursor_y - ui_panel_y) + (ui_panel_pad - ui_row_gap);
    var max_panel_h = max(0, room_height - ui_panel_y - layout_bottom_reserved);
    ui_panel_h = min(ui_panel_h, max_panel_h);
};
update_cell_size();
apply_rng_seed();
recalc_ui_positions();

sanitize_template_name = function(_name) {
    var src = string_lower(_name);
    var out = "";
    for (var i = 1; i <= string_length(src); i++) {
        var ch = string_char_at(src, i);
        var o = ord(ch);
        var is_alpha = (o >= ord("a") && o <= ord("z"));
        var is_num = (o >= ord("0") && o <= ord("9"));
        if (is_alpha || is_num) {
            out += ch;
        } else {
            out += "_";
        }
    }
    while (string_pos("__", out) > 0) {
        out = string_replace_all(out, "__", "_");
    }
    if (out == "") out = "template";
    return out;
};
refresh_template_name_list = function() {
    var collected = ds_list_create();
    var found = file_find_first("template_*.ini", fa_archive);
    while (found != "") {
        var display_name = "";
        ini_open(found);
        display_name = ini_read_string("template", "name", "");
        ini_close();

        if (display_name == "") {
            display_name = found;
            var lower = string_lower(display_name);
            if (string_copy(lower, 1, 9) == "template_") {
                display_name = string_delete(display_name, 1, 9);
            }

            var n = string_length(display_name);
            if (n >= 4) {
                var ext = string_lower(string_copy(display_name, n - 3, 4));
                if (ext == ".ini") {
                    display_name = string_delete(display_name, n - 3, 4);
                }
            }
        }

        if (display_name != "") ds_list_add(collected, display_name);
        found = file_find_next();
    }
    file_find_close();

    ds_list_sort(collected, true);
    var count = ds_list_size(collected);
    template_list_names = array_create(count, "");
    for (var i = 0; i < count; i++) {
        template_list_names[i] = collected[| i];
    }
    ds_list_destroy(collected);
};

set_grid_size = function(_size) {
    if (solver_active) {
        crossword_solver_stop(false);
    }

    if (ds_exists(grid, ds_type_grid)) {
        ds_grid_destroy(grid);
    }

    grid_width = _size;
    grid_height = _size;
    grid = ds_grid_create(grid_width, grid_height);
    ds_grid_clear(grid, "");
    update_cell_size();

    current_template_name = "";
    letter_entry_active = false;
    global.fill_attempt_count = 0;
    set_status("Grid set to " + string(grid_width) + "x" + string(grid_height));
};

new_blank_grid = function() {
    if (solver_active) {
        crossword_solver_stop(false);
    }

    for (var col_i = 0; col_i < grid_width; col_i++) {
        for (var row_i = 0; row_i < grid_height; row_i++) {
            grid[# col_i, row_i] = "";
        }
    }

    current_template_name = "";
    set_status("New blank " + string(grid_width) + "x" + string(grid_height) + " grid");
};

apply_pattern_rows = function(_rows) {
    var row_count = array_length(_rows);
    if (row_count != grid_height) return false;

    for (var row_i = 0; row_i < grid_height; row_i++) {
        var row_str = _rows[row_i];
        if (string_length(row_str) != grid_width) return false;
        for (var col_i = 0; col_i < grid_width; col_i++) {
            var ch = string_char_at(row_str, col_i + 1);
            grid[# col_i, row_i] = (ch == "#") ? "INVALID" : "";
        }
    }

    current_template_name = "";
    return true;
};

pattern_rows_transpose = function(_rows) {
    var out = array_create(array_length(_rows), "");
    for (var row_i = 0; row_i < grid_height; row_i++) {
        var row_str = "";
        for (var col_i = 0; col_i < grid_width; col_i++) {
            row_str += string_char_at(_rows[col_i], row_i + 1);
        }
        out[row_i] = row_str;
    }
    return out;
};

pattern_rows_flip_h = function(_rows) {
    var out = array_create(array_length(_rows), "");
    for (var row_i = 0; row_i < grid_height; row_i++) {
        var row_src = _rows[row_i];
        var row_out = "";
        for (var col_i = string_length(row_src); col_i >= 1; col_i--) {
            row_out += string_char_at(row_src, col_i);
        }
        out[row_i] = row_out;
    }
    return out;
};

pattern_rows_flip_v = function(_rows) {
    var out = array_create(array_length(_rows), "");
    for (var row_i = 0; row_i < grid_height; row_i++) {
        out[row_i] = _rows[grid_height - 1 - row_i];
    }
    return out;
};

build_realistic_block_pattern = function() {
    if (solver_active) crossword_solver_stop(false);
    if (letter_entry_active) {
        letter_entry_active = false;
        letter_entry_prev_active = false;
        letter_entry_col = -1;
        letter_entry_row = -1;
    }
    if (word_entry_active) word_entry_stop("");
    if (candidate_overlay_active) candidate_picker_close();
    if (template_list_overlay_active) template_list_overlay_active = false;
    if (help_overlay_active) help_overlay_active = false;

    var base_rows = [];
    switch (grid_width) {
        case 5:
            base_rows = [
                "#...#",
                ".....",
                ".....",
                ".....",
                "#...#"
            ];
            break;
        case 7:
            base_rows = [
                "#.....#",
                "#.....#",
                ".......",
                ".......",
                ".......",
                "#.....#",
                "#.....#"
            ];
            break;
        case 9:
            base_rows = [
                "...###...",
                ".....#...",
                ".....#...",
                "#........",
                "###...###",
                "........#",
                "...#.....",
                "...#.....",
                "...###..."
            ];
            break;
        case 11:
            base_rows = [
                "##....##...",
                "......#....",
                "......#....",
                "....#...###",
                "...##......",
                "...#...#...",
                "......##...",
                "###...#....",
                "....#......",
                "....#......",
                "...##....##"
            ];
            break;
        case 13:
            base_rows = [
                "#.....##.....",
                "#.....#......",
                "#............",
                ".....#...#...",
                "...#...#.....",
                "...##......##",
                "#...#...#...#",
                "##......##...",
                ".....#...#...",
                "...#...#.....",
                "............#",
                "......#.....#",
                ".....##.....#"
            ];
            break;
        case 15:
            base_rows = [
                "...#.....#...##",
                "...#.....#....#",
                "...............",
                "......#...##...",
                ".....###...#...",
                "#...##.........",
                "....#...#......",
                "...............",
                "......#...#....",
                ".........##...#",
                "...#...###.....",
                "...##...#......",
                "...............",
                "#....#.....#...",
                "##...#.....#..."
            ];
            break;
    }

    if (array_length(base_rows) <= 0) {
        set_status("No built-in pattern for " + string(grid_width) + "x" + string(grid_height));
        return false;
    }

    var rows = base_rows;
    if (irandom(1) == 1) rows = pattern_rows_transpose(rows);
    if (irandom(1) == 1) rows = pattern_rows_flip_h(rows);
    if (irandom(1) == 1) rows = pattern_rows_flip_v(rows);

    if (!apply_pattern_rows(rows)) {
        set_status("Pattern apply failed");
        return false;
    }

    global.fill_attempt_count = 0;
    set_status("Applied realistic " + string(grid_width) + "x" + string(grid_height) + " block pattern");
    return true;
};

save_template = function(_template_name) {
    var safe = sanitize_template_name(_template_name);
    var filename = "template_" + safe + ".ini";

    var rows = "";
    for (var row_i_save = 0; row_i_save < grid_height; row_i_save++) {
        var row_tokens = "";
        for (var col_i_save = 0; col_i_save < grid_width; col_i_save++) {
            var cell = grid[# col_i_save, row_i_save];
            var token = "-2"; // empty
            if (cell == "INVALID") {
                token = "-1";
            } else if (cell != "") {
                token = string(ord(string_char_at(cell, 1)));
            }

            row_tokens += token;
            if (col_i_save < grid_width - 1) row_tokens += ",";
        }

        rows += row_tokens;
        if (row_i_save < grid_height - 1) rows += "|";
    }

    ini_open(filename);
    ini_write_string("template", "name", _template_name);
    ini_write_real("template", "width", grid_width);
    ini_write_real("template", "height", grid_height);
    ini_write_real("grid", "format", 2);
    ini_write_string("grid", "rows", rows);
    ini_close();

    current_template_name = _template_name;
    set_status("Saved template '" + _template_name + "' (" + filename + ")");
    show_debug_message("[Crossword] Saved template '" + _template_name + "' -> " + filename);
};

load_template = function(_template_name) {
    var safe = sanitize_template_name(_template_name);
    var filename = "template_" + safe + ".ini";

    if (!file_exists(filename)) {
        set_status("Template not found: " + filename);
        show_debug_message("[Crossword] Template not found: " + filename);
        return;
    }

    ini_open(filename);
    var w = floor(ini_read_real("template", "width", 5));
    var h = floor(ini_read_real("template", "height", 5));
    var fmt = floor(ini_read_real("grid", "format", 1));
    var rows = ini_read_string("grid", "rows", "");
    ini_close();

    if (w < 5 || h < 5 || w != h) {
        set_status("Invalid template dimensions in " + filename);
        return;
    }

    var found_index = -1;
    for (var i = 0; i < array_length(grid_size_options); i++) {
        if (grid_size_options[i] == w) {
            found_index = i;
            break;
        }
    }
    if (found_index == -1) {
        set_status("Unsupported template size " + string(w));
        return;
    }

    current_size_index = found_index;
    set_grid_size(w);

    var row_parts = string_split(rows, "|");
    for (var row_i_load = 0; row_i_load < min(array_length(row_parts), grid_height); row_i_load++) {
        var row = row_parts[row_i_load];

        // Format 2: numeric tokens (-1 invalid, -2 empty, else ord value).
        if (fmt >= 2 || string_pos(",", row) > 0) {
            var col_tokens = string_split(row, ",");
            for (var col_i_load = 0; col_i_load < min(array_length(col_tokens), grid_width); col_i_load++) {
                var token_value = floor(real(col_tokens[col_i_load]));
                if (token_value == -1) {
                    grid[# col_i_load, row_i_load] = "INVALID";
                } else if (token_value == -2) {
                    grid[# col_i_load, row_i_load] = "";
                } else {
                    grid[# col_i_load, row_i_load] = chr(token_value);
                }
            }
        } else {
            // Legacy format: '#' for block, '.' for open/empty.
            for (var col_i_load = 0; col_i_load < min(string_length(row), grid_width); col_i_load++) {
                var ch = string_char_at(row, col_i_load + 1);
                grid[# col_i_load, row_i_load] = (ch == "#") ? "INVALID" : "";
            }
        }
    }

    current_template_name = _template_name;
    set_status("Loaded template '" + _template_name + "' (" + filename + ")");
    show_debug_message("[Crossword] Loaded template '" + _template_name + "' <- " + filename);
};

// Create dictionary data structures
global.wordList = ds_list_create();
global.wordLookup = ds_map_create();
global.wordsByLength = ds_map_create();
global.prefix2ByLength = ds_map_create();
global.prefixSetByLength = ds_map_create(); // prefixSetByLength[len][prefix] = true; O(1) prefix lookup
global.posIndexByLength = ds_map_create();  // posIndexByLength["len:pos:letter"] -> ds_list of words
global.wordFreqScore = ds_map_create();     // wordFreqScore[word] -> 0-2000 log-normalized frequency

global.fill_vocab_mode = 0; // 0=common-first, 1=common-only, 2=full
global.allow_phrases = true; // If false, skip long phrase-like entries during dictionary load.
global.phrase_min_len = 10; // Treat entries >= this length as phrases when allow_phrases is false.
global.commonWordLookup = ds_map_create();
global.commonWordRank = ds_map_create();
global.discouragedFillLookup = ds_map_create();

var discouraged_fill_words = [
    "AAL","ADO","AERO","AIN","AIRTED","ALIENER","ALUM","AORISTS","ATCO","ATT","AVE",
    "DOAT","ENATE","ENATES","ENON","ERATH","ERE","EREAT","ERR","ETWEE","GYRES","HE",
    "HEREAT","ITHER","IHLEN","IN","INC","LAH","ME","NAEVI","NAKEDER","NANA","NENES",
    "NERAL","NONET","NOTI","OTHO","PERITI","PYXIE","RERAN","RET","REEDER","RENTIER",
    "RISCO","ROOSE","ROTOS","SE","SERENER","SIEVA","SIS","SNORE","SNOTS","SRI","ST",
    "STAPHS","TAENIA","TAFIA","TERRIT","TET","THE","TI","TIT","TODAYS","TORA","TORAHS",
    "TOTHER","TUT","USEE","YIN"
];
for (var dfi = 0; dfi < array_length(discouraged_fill_words); dfi++) {
    var dfw = discouraged_fill_words[dfi];
    if (!ds_map_exists(global.discouragedFillLookup, dfw)) ds_map_add(global.discouragedFillLookup, dfw, true);
}

var candidate_files = [
    "datafiles/wordgamedictionary.com_twl06_download_twl06.txt",
    "wordgamedictionary.com_twl06_download_twl06.txt"
];

var word_file = "";
for (var f = 0; f < array_length(candidate_files); f++) {
    if (file_exists(candidate_files[f])) {
        word_file = candidate_files[f];
        break;
    }
}

if (word_file == "") {
    show_debug_message("[Crossword] Missing dictionary file: wordgamedictionary.com_twl06_download_twl06.txt");
} else {
    var file = file_text_open_read(word_file);

    var skipped_phrases = 0;
    var skipped_short = 0;
    while (!file_text_eof(file)) {
        var raw_word = string_upper(file_text_read_string(file));
        file_text_readln(file);

        var word = "";
        for (var i = 1; i <= string_length(raw_word); i++) {
            var ch = string_char_at(raw_word, i);
            if (ord(ch) >= ord("A") && ord(ch) <= ord("Z")) {
                word += ch;
            }
        }

        if (word == "") continue;

        var wlen = string_length(word);
        if (wlen < 2) {
            skipped_short++;
            continue;
        }
        if (!global.allow_phrases && wlen >= global.phrase_min_len) {
            skipped_phrases++;
            continue;
        }
        if (!ds_map_exists(global.wordLookup, word)) {
            ds_list_add(global.wordList, word);
            ds_map_add(global.wordLookup, word, true);

            var lengthKey = string(string_length(word));
            var lengthList;
            if (!ds_map_exists(global.wordsByLength, lengthKey)) {
                lengthList = ds_list_create();
                ds_map_add(global.wordsByLength, lengthKey, lengthList);
            } else {
                lengthList = global.wordsByLength[? lengthKey];
            }
            ds_list_add(lengthList, word);

            if (string_length(word) >= 2) {
                var p2key = string(string_length(word));
                var p2map;
                if (!ds_map_exists(global.prefix2ByLength, p2key)) {
                    p2map = ds_map_create();
                    ds_map_add(global.prefix2ByLength, p2key, p2map);
                } else {
                    p2map = global.prefix2ByLength[? p2key];
                }

                var p2 = string_char_at(word, 1) + string_char_at(word, 2);
                if (!ds_map_exists(p2map, p2)) {
                    ds_map_add(p2map, p2, true);
                }

                // Build prefixSetByLength: store all prefixes of length 2..wlen-1
                // so crossword_prefix_exists_for_length becomes an O(1) lookup.
                var pskey = p2key;
                var psmap;
                if (!ds_map_exists(global.prefixSetByLength, pskey)) {
                    psmap = ds_map_create();
                    ds_map_add(global.prefixSetByLength, pskey, psmap);
                } else {
                    psmap = global.prefixSetByLength[? pskey];
                }
                var ps_max = wlen - 1;
                var pfx_len = 2;
                repeat (ps_max - 1) {
                    var pfx = string_copy(word, 1, pfx_len);
                    if (!ds_map_exists(psmap, pfx)) {
                        ds_map_add(psmap, pfx, true);
                    }
                    pfx_len++;
                }

                // Build posIndexByLength: "len:pos:letter" -> ds_list of matching words
                var pos_key_base = string(wlen) + ":";
                var pos_idx = 1;
                repeat (wlen) {
                    var pos_ch = string_char_at(word, pos_idx);
                    var pos_key = pos_key_base + string(pos_idx) + ":" + pos_ch;
                    var pos_list;
                    if (!ds_map_exists(global.posIndexByLength, pos_key)) {
                        pos_list = ds_list_create();
                        ds_map_add(global.posIndexByLength, pos_key, pos_list);
                    } else {
                        pos_list = global.posIndexByLength[? pos_key];
                    }
                    ds_list_add(pos_list, word);
                    pos_idx++;
                }
            }
        }
    }

    file_text_close(file);
    ds_list_shuffle(global.wordList);
    show_debug_message("[Crossword] Loaded words: " + string(ds_list_size(global.wordList)) + " from " + word_file
        + " (skipped short=" + string(skipped_short)
        + " skipped phrases=" + string(skipped_phrases)
        + " allow_phrases=" + string(global.allow_phrases)
        + " phrase_min_len=" + string(global.phrase_min_len) + ")");
}


var common_files = [
    "datafiles/common_words.txt",
    "common_words.txt"
];

var common_file = "";
for (var cf = 0; cf < array_length(common_files); cf++) {
    if (file_exists(common_files[cf])) {
        common_file = common_files[cf];
        break;
    }
}

if (common_file != "") {
    var cfile = file_text_open_read(common_file);
    var rank = 1;
    while (!file_text_eof(cfile)) {
        var cword = string_upper(file_text_read_string(cfile));
        file_text_readln(cfile);

        var cleaned = "";
        for (var ci = 1; ci <= string_length(cword); ci++) {
            var cch = string_char_at(cword, ci);
            if (ord(cch) >= ord("A") && ord(cch) <= ord("Z")) cleaned += cch;
        }

        if (cleaned == "") continue;
        if (!ds_map_exists(global.wordLookup, cleaned)) continue;

        if (!ds_map_exists(global.commonWordLookup, cleaned)) {
            ds_map_add(global.commonWordLookup, cleaned, true);
            ds_map_add(global.commonWordRank, cleaned, rank);
            rank++;
        }
    }
    file_text_close(cfile);
    show_debug_message("[Crossword] Loaded common words: " + string(ds_map_size(global.commonWordLookup)) + " from " + common_file);
} else {
    show_debug_message("[Crossword] common_words.txt not found; using heuristic-only ranking.");
}

// Load count_1w.txt: tab-separated "word<TAB>frequency", sorted by frequency descending.
// Store a log10-normalized 0-2000 score for each word that exists in our crossword dictionary.
// Cap at 100,000 lines to bound startup time; the file is frequency-sorted so top words come first.
var freq1w_candidates = [
    "datafiles/count_1w.txt",
    "count_1w.txt"
];
var freq1w_file = "";
for (var fw = 0; fw < array_length(freq1w_candidates); fw++) {
    if (file_exists(freq1w_candidates[fw])) {
        freq1w_file = freq1w_candidates[fw];
        break;
    }
}

if (freq1w_file == "") {
    show_debug_message("[Crossword] count_1w.txt not found; frequency scoring uses common_words.txt ranking.");
} else {
    var freq1w_fh = file_text_open_read(freq1w_file);
    var freq1w_loaded = 0;
    var freq1w_lines = 0;
    var freq1w_dict_size = ds_map_size(global.wordLookup);
    while (!file_text_eof(freq1w_fh) && freq1w_lines < 100000) {
        var freq1w_line = file_text_read_string(freq1w_fh);
        file_text_readln(freq1w_fh);
        freq1w_lines++;

        var freq1w_tab = string_pos("\t", freq1w_line);
        if (freq1w_tab < 2) continue;

        var freq1w_word = string_upper(string_copy(freq1w_line, 1, freq1w_tab - 1));
        if (!ds_map_exists(global.wordLookup, freq1w_word)) continue;
        if (ds_map_exists(global.wordFreqScore, freq1w_word)) continue;

        var freq1w_str = string_copy(freq1w_line, freq1w_tab + 1, string_length(freq1w_line) - freq1w_tab);
        var freq1w_val = real(freq1w_str);

        var freq1w_score = 0.0;
        if (freq1w_val >= 1) {
            freq1w_score = clamp((log10(freq1w_val) / 11.0) * 2000.0, 0, 2000);
        }

        ds_map_add(global.wordFreqScore, freq1w_word, freq1w_score);
        freq1w_loaded++;
        if (freq1w_loaded >= freq1w_dict_size) break;
    }
    file_text_close(freq1w_fh);
    show_debug_message("[Crossword] Frequency scores loaded: " + string(freq1w_loaded) + "/"
        + string(freq1w_dict_size) + " dict words from " + freq1w_file
        + " (scanned " + string(freq1w_lines) + " lines)");
}

















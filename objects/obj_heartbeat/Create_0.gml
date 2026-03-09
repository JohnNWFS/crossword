// Create Event for obj_heartbeat

grid_size_options = [5, 7, 9, 11, 13, 15];
current_size_index = 0;
grid_width = grid_size_options[current_size_index];
grid_height = grid_size_options[current_size_index];

cell_size = 32;
padding = 64;
layout_bottom_reserved = 220;

// Cache base layout values so we can switch to a compact touch layout on small screens (HTML/mobile)
base_padding = padding;
base_layout_bottom_reserved = layout_bottom_reserved;
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

apply_mobile_layout = function(_on) {
    // Keep changes minimal to avoid breaking desktop layout.
    if (_on) {
        padding = 24;
        layout_bottom_reserved = 190;
    } else {
        padding = base_padding;
        layout_bottom_reserved = base_layout_bottom_reserved;
    }
    recalc_ui_positions();
    update_cell_size();
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
    var available_w = room_width - (padding * 2);
    var available_h = room_height - padding - layout_bottom_reserved;
    var max_w = floor(available_w / max(1, grid_width));
    var max_h = floor(available_h / max(1, grid_height));
    var target = min(max_w, max_h);
    target = clamp(target, 18, 32);
    cell_size = target;
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

global.fill_vocab_mode = 0; // 0=common-first, 1=common-only, 2=full
global.allow_phrases = true; // If false, skip long phrase-like entries during dictionary load.
global.phrase_min_len = 10; // Treat entries >= this length as phrases when allow_phrases is false.
global.commonWordLookup = ds_map_create();
global.commonWordRank = ds_map_create();

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












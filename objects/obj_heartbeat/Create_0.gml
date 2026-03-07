// Create Event for obj_heartbeat

grid_size_options = [5, 7, 9, 11, 13, 15];
current_size_index = 0;
grid_width = grid_size_options[current_size_index];
grid_height = grid_size_options[current_size_index];

cell_size = 32;
padding = 64;

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

status_text = "Ready";
current_template_name = "";
template_dialog_request_id = -1;
template_dialog_action = "";

global.fill_attempt_limit = 250000;
global.fill_attempt_count = 0;
global.step15_min_ratio = 0.60;
global.slot_try_limit = 100;

letter_entry_active = false;
letter_entry_col = -1;
letter_entry_row = -1;

solver_active = false;
global.visual_solver = undefined;
global.solver_fail_cells = [];
global.solver_fail_until = 0;

// Initialize grid
grid = ds_grid_create(grid_width, grid_height);
ds_grid_clear(grid, "");

set_status = function(_msg) {
    status_text = _msg;
};

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
        var row = "";
        for (var col_i_save = 0; col_i_save < grid_width; col_i_save++) {
            row += (grid[# col_i_save, row_i_save] == "INVALID") ? "#" : ".";
        }
        rows += row;
        if (row_i_save < grid_height - 1) rows += "|";
    }

    ini_open(filename);
    ini_write_string("template", "name", _template_name);
    ini_write_real("template", "width", grid_width);
    ini_write_real("template", "height", grid_height);
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
        for (var col_i_load = 0; col_i_load < min(string_length(row), grid_width); col_i_load++) {
            var ch = string_char_at(row, col_i_load + 1);
            grid[# col_i_load, row_i_load] = (ch == "#") ? "INVALID" : "";
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
    show_debug_message("[Crossword] Loaded words: " + string(ds_list_size(global.wordList)) + " from " + word_file);
}





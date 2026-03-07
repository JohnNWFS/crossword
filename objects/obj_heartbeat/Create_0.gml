// Create Event for obj_heartbeat

grid_width = 15;
grid_height = 15;
cell_size = 32;
padding = 64;

status_text = "Ready";
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

// Initialize an empty grid
grid = ds_grid_create(grid_width, grid_height);
ds_grid_clear(grid, "");

// Create dictionary data structures
global.wordList = ds_list_create();
global.wordLookup = ds_map_create();
global.wordsByLength = ds_map_create();

var candidate_files = [
    "en_US-large-clean.txt",
    "datafiles/en_US-large-clean.txt",
    "wordgamedictionary.com_twl06_download_twl06.txt",
    "datafiles/wordgamedictionary.com_twl06_download_twl06.txt"
];

var word_file = "";
for (var f = 0; f < array_length(candidate_files); f++) {
    if (file_exists(candidate_files[f])) {
        word_file = candidate_files[f];
        break;
    }
}

if (word_file == "") {
    show_debug_message("[Crossword] Missing dictionary file. Checked en_US and TWL paths.");
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

        if (word == "") {
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
        }
    }

    file_text_close(file);
    ds_list_shuffle(global.wordList);
    show_debug_message("[Crossword] Loaded words: " + string(ds_list_size(global.wordList)) + " from " + word_file);
}

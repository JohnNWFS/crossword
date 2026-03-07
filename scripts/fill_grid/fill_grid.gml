function crossword_build_slots() {
    var slots = [];
    var slot_count = 0;
    var clue_num = 1;

    for (var row_i = 0; row_i < obj_heartbeat.grid_height; row_i++) {
        for (var col_i = 0; col_i < obj_heartbeat.grid_width; col_i++) {
            if (obj_heartbeat.grid[# col_i, row_i] == "INVALID") {
                continue;
            }

            var starts_across = (col_i == 0 || obj_heartbeat.grid[# col_i - 1, row_i] == "INVALID")
                && (col_i + 1 < obj_heartbeat.grid_width && obj_heartbeat.grid[# col_i + 1, row_i] != "INVALID");
            var starts_down = (row_i == 0 || obj_heartbeat.grid[# col_i, row_i - 1] == "INVALID")
                && (row_i + 1 < obj_heartbeat.grid_height && obj_heartbeat.grid[# col_i, row_i + 1] != "INVALID");

            if (!starts_across && !starts_down) {
                continue;
            }

            if (starts_across) {
                var across_len = 0;
                var across_col = col_i;
                while (across_col < obj_heartbeat.grid_width && obj_heartbeat.grid[# across_col, row_i] != "INVALID") {
                    across_len++;
                    across_col++;
                }
                slots[slot_count++] = { num: clue_num, dir: "A", col: col_i, row: row_i, len: across_len };
            }

            if (starts_down) {
                var down_len = 0;
                var down_row = row_i;
                while (down_row < obj_heartbeat.grid_height && obj_heartbeat.grid[# col_i, down_row] != "INVALID") {
                    down_len++;
                    down_row++;
                }
                slots[slot_count++] = { num: clue_num, dir: "D", col: col_i, row: row_i, len: down_len };
            }

            clue_num++;
        }
    }

    return slots;
}

function crossword_slot_pattern(slot_data) {
    var pattern = "";
    for (var k = 0; k < slot_data.len; k++) {
        var cell_col = slot_data.col + ((slot_data.dir == "A") ? k : 0);
        var cell_row = slot_data.row + ((slot_data.dir == "D") ? k : 0);
        var value = obj_heartbeat.grid[# cell_col, cell_row];
        pattern += (value == "" || value == "INVALID") ? "_" : value;
    }
    return pattern;
}

function crossword_slot_word(slot_data) {
    var word = "";
    for (var k = 0; k < slot_data.len; k++) {
        var cell_col = slot_data.col + ((slot_data.dir == "A") ? k : 0);
        var cell_row = slot_data.row + ((slot_data.dir == "D") ? k : 0);
        var value = obj_heartbeat.grid[# cell_col, cell_row];
        word += (value == "" || value == "INVALID") ? "_" : value;
    }
    return word;
}

function crossword_pattern_has_blank(pattern) {
    return string_pos("_", pattern) > 0;
}

function crossword_pattern_has_fixed_letter(pattern) {
    for (var i = 1; i <= string_length(pattern); i++) {
        if (string_char_at(pattern, i) != "_") {
            return true;
        }
    }
    return false;
}

function crossword_word_matches_pattern(word, pattern) {
    var len_word = string_length(word);
    if (len_word != string_length(pattern)) {
        return false;
    }

    for (var i = 1; i <= len_word; i++) {
        var pattern_char = string_char_at(pattern, i);
        if (pattern_char != "_" && pattern_char != string_char_at(word, i)) {
            return false;
        }
    }

    return true;
}

function crossword_slot_blank_count(pattern) {
    var n = 0;
    for (var i = 1; i <= string_length(pattern); i++) {
        if (string_char_at(pattern, i) == "_") n++;
    }
    return n;
}

function crossword_first_candidate_for_slot(slot_data, used_words) {
    var key_len = string(slot_data.len);
    if (!ds_map_exists(global.wordsByLength, key_len)) {
        return "";
    }

    var pattern = crossword_slot_pattern(slot_data);
    var slot_dir = (slot_data.dir == "A") ? "horizontal" : "vertical";
    var list_words = global.wordsByLength[? key_len];
    var count_words = ds_list_size(list_words);

    for (var i = 0; i < count_words; i++) {
        var candidate = list_words[| i];
        if (is_undefined(used_words) == false && ds_exists(used_words, ds_type_map) && ds_map_exists(used_words, candidate)) continue;
        if (!crossword_word_matches_pattern(candidate, pattern)) continue;
        if (!can_place_word(candidate, slot_data.col, slot_data.row, slot_dir)) continue;
        return candidate;
    }

    return "";
}

function crossword_count_candidates_for_slot(slot_data, used_words) {
    var key_len = string(slot_data.len);
    if (!ds_map_exists(global.wordsByLength, key_len)) {
        return 0;
    }

    var pattern = crossword_slot_pattern(slot_data);
    var slot_dir = (slot_data.dir == "A") ? "horizontal" : "vertical";
    var list_words = global.wordsByLength[? key_len];
    var count_words = ds_list_size(list_words);
    var count_ok = 0;

    for (var i = 0; i < count_words; i++) {
        var candidate = list_words[| i];
        if (is_undefined(used_words) == false && ds_exists(used_words, ds_type_map) && ds_map_exists(used_words, candidate)) continue;
        if (!crossword_word_matches_pattern(candidate, pattern)) continue;
        if (!can_place_word(candidate, slot_data.col, slot_data.row, slot_dir)) continue;

        count_ok++;
        if (count_ok >= 4) return count_ok;
    }

    return count_ok;
}

function crossword_has_candidate_for_slot(slot_data, used_words) {
    return crossword_count_candidates_for_slot(slot_data, used_words) > 0;
}

function crossword_remaining_across_viability(used_words) {
    var slots = crossword_build_slots();
    var viable = 0;
    var total = 0;
    var failed_slot = "";
    var failed_slot_data = undefined;
    var failed_candidate_count = -1;
    var forced_slot_data = undefined;
    var forced_word = "";

    for (var i = 0; i < array_length(slots); i++) {
        var slot_data = slots[i];

        var pattern = crossword_slot_pattern(slot_data);
        if (!crossword_pattern_has_blank(pattern)) continue;
        if (!crossword_pattern_has_fixed_letter(pattern)) continue;

        total++;
        var candidate_count = crossword_count_candidates_for_slot(slot_data, used_words);
        var fixed_prefix_len = crossword_slot_start_prefix_len(pattern);
        var min_needed = 1;
        if (fixed_prefix_len >= 4) min_needed = 3;
        else if (fixed_prefix_len >= 3) min_needed = 2;

        var slot_viable = (candidate_count >= min_needed);

        if (slot_viable) {
            viable++;
            if (crossword_slot_blank_count(pattern) == 1 && candidate_count == 1 && is_undefined(forced_slot_data)) {
                forced_slot_data = slot_data;
                forced_word = crossword_first_candidate_for_slot(slot_data, used_words);
            }
        } else if (failed_slot == "") {
            failed_slot = string(slot_data.num) + slot_data.dir + " pattern=" + pattern + " candidates=" + string(candidate_count);
            failed_slot_data = slot_data;
            failed_candidate_count = candidate_count;
        }
    }

    var ratio = (total == 0) ? 1.0 : (viable / total);
    return {
        viable: viable,
        total: total,
        ratio: ratio,
        failed_slot: failed_slot,
        failed_slot_data: failed_slot_data,
        failed_candidate_count: failed_candidate_count,
        forced_slot_data: forced_slot_data,
        forced_word: forced_word
    };
}

function crossword_apply_forced_singletons(used_words) {
    var placed_any = false;

    while (true) {
        var scan = crossword_remaining_across_viability(used_words);
        if (scan.total > 0 && scan.viable < scan.total) {
            return { ok: false, placed_any: placed_any, failed_slot: scan.failed_slot, failed_slot_data: scan.failed_slot_data };
        }

        if (is_undefined(scan.forced_slot_data) || scan.forced_word == "") {
            return { ok: true, placed_any: placed_any, failed_slot: "", failed_slot_data: undefined };
        }

        var fs = scan.forced_slot_data;
        var fword = scan.forced_word;
        var current_word = crossword_slot_word(fs);
        if (string_pos("_", current_word) == 0) {
            return { ok: true, placed_any: placed_any, failed_slot: "", failed_slot_data: undefined };
        }

        var fdir = (fs.dir == "A") ? "horizontal" : "vertical";
        if (!can_place_word(fword, fs.col, fs.row, fdir)) {
            return { ok: false, placed_any: placed_any, failed_slot: "Forced slot cannot place " + string(fs.num) + fs.dir, failed_slot_data: fs };
        }

        place_word(fword, fs.col, fs.row, fdir);
        if (!ds_map_exists(used_words, fword)) {
            ds_map_add(used_words, fword, true);
        }
        placed_any = true;
        show_debug_message("[Visual] Forced " + string(fs.num) + fs.dir + "=" + fword);
    }
}
function crossword_try_pick_word(slot_data, used_words, first_char, trace_label) {
    var key_len = string(slot_data.len);
    if (!ds_map_exists(global.wordsByLength, key_len)) {
        if (trace_label != "") show_debug_message("[FillTrace] " + trace_label + " no length bucket " + key_len);
        return "";
    }

    var pattern = crossword_slot_pattern(slot_data);
    var slot_dir = (slot_data.dir == "A") ? "horizontal" : "vertical";
    var list_words = global.wordsByLength[? key_len];
    var count_words = ds_list_size(list_words);
    if (count_words <= 0) {
        if (trace_label != "") show_debug_message("[FillTrace] " + trace_label + " empty length bucket " + key_len);
        return "";
    }

    var start_index = irandom(count_words - 1);
    var best_word = "";
    var best_score = -1;

    for (var i = 0; i < count_words; i++) {
        var idx = (start_index + i) mod count_words;
        var candidate = list_words[| idx];
        global.fill_attempt_count++;

        if (ds_map_exists(used_words, candidate)) {
            continue;
        }
        if (first_char != "" && string_char_at(candidate, 1) != first_char) {
            continue;
        }
        if (!crossword_word_matches_pattern(candidate, pattern)) {
            continue;
        }
        if (!can_place_word(candidate, slot_data.col, slot_data.row, slot_dir)) {
            continue;
        }

        place_word(candidate, slot_data.col, slot_data.row, slot_dir);
        var viability = crossword_remaining_across_viability(used_words);
        remove_word(candidate, slot_data.col, slot_data.row, slot_dir);

        var candidate_score = viability.viable * 1000 + floor(viability.ratio * 100);
        if (candidate_score > best_score) {
            best_score = candidate_score;
            best_word = candidate;
        }

        var is_good = (viability.ratio >= global.step15_min_ratio) || (viability.total <= 1);
        if (is_good) {
            if (trace_label != "") {
                show_debug_message("[FillTrace] " + trace_label + " pick=" + candidate
                    + " viability=" + string(viability.viable) + "/" + string(viability.total));
            }
            return candidate;
        }

        if (global.fill_attempt_count >= global.fill_attempt_limit) {
            break;
        }
    }

    if (best_word != "") {
        if (trace_label != "") {
            show_debug_message("[FillTrace] " + trace_label + " fallback best=" + best_word);
        }
        return best_word;
    }

    if (trace_label != "") {
        show_debug_message("[FillTrace] " + trace_label + " no candidate for pattern=" + pattern);
    }
    return "";
}

function crossword_export_word_lists() {
    var slots = crossword_build_slots();

    show_debug_message("=== ACROSS ===");
    for (var i = 0; i < array_length(slots); i++) {
        var slot_data = slots[i];
        if (slot_data.dir != "A") continue;
        show_debug_message(string(slot_data.num) + ". " + crossword_slot_word(slot_data));
    }

    show_debug_message("=== DOWN ===");
    for (var j = 0; j < array_length(slots); j++) {
        var slot_down = slots[j];
        if (slot_down.dir != "D") continue;
        show_debug_message(string(slot_down.num) + ". " + crossword_slot_word(slot_down));
    }
}

function crossword_check_remaining_across_feasibility() {
    var slots = crossword_build_slots();
    var viable = 0;
    var total = 0;
    var used_map = undefined;
    if (variable_global_exists("usedWords")) {
        used_map = global.usedWords;
    }

    show_debug_message("[Feasibility] === Remaining Across Check ===");
    for (var i = 0; i < array_length(slots); i++) {
        var slot_data = slots[i];
        if (slot_data.dir != "A") continue;

        var pattern = crossword_slot_pattern(slot_data);
        if (!crossword_pattern_has_blank(pattern)) continue;
        if (!crossword_pattern_has_fixed_letter(pattern)) continue;

        total++;
        var slot_ok = crossword_has_candidate_for_slot(slot_data, used_map);
        if (slot_ok) viable++;

        show_debug_message("[Feasibility] " + string(slot_data.num) + "A pattern=" + pattern
            + " candidates=" + string(slot_ok ? 1 : 0));
    }

    obj_heartbeat.status_text = "Step 2: viable across slots " + string(viable) + "/" + string(total);
    show_debug_message("[Crossword] Step 2: viable across slots " + string(viable) + "/" + string(total));
    return (total == 0) ? true : (viable == total);
}

function fill_grid(posX, posY) {
    if (variable_global_exists("usedWords") && ds_exists(global.usedWords, ds_type_map)) {
        ds_map_destroy(global.usedWords);
    }
    global.usedWords = ds_map_create();

    global.fill_attempt_count = 0;

    for (var col_i = 0; col_i < obj_heartbeat.grid_width; col_i++) {
        for (var row_i = 0; row_i < obj_heartbeat.grid_height; row_i++) {
            if (obj_heartbeat.grid[# col_i, row_i] != "INVALID") {
                obj_heartbeat.grid[# col_i, row_i] = "";
            }
        }
    }

    show_debug_message("[Crossword] Attempting fill...");
    show_debug_message("[FillTrace] Experiment mode: no backtracking + viability gate");

    var slots = crossword_build_slots();
    var slot_1a = undefined;
    var slot_1d = undefined;
    var attached_downs = [];
    var attached_count = 0;

    for (var i = 0; i < array_length(slots); i++) {
        var s = slots[i];
        if (s.num == 1 && s.dir == "A") slot_1a = s;
        if (s.num == 1 && s.dir == "D") slot_1d = s;
    }

    if (is_undefined(slot_1a) || is_undefined(slot_1d)) {
        obj_heartbeat.status_text = "Missing #1 Across or #1 Down";
        show_debug_message("[FillTrace] Missing #1 Across or #1 Down slot.");
        return false;
    }

    show_debug_message("[FillTrace] #1 Across len=" + string(slot_1a.len)
        + " at (" + string(slot_1a.col) + "," + string(slot_1a.row) + ")");
    show_debug_message("[FillTrace] #1 Down len=" + string(slot_1d.len)
        + " at (" + string(slot_1d.col) + "," + string(slot_1d.row) + ")");

    var word_1a = crossword_try_pick_word(slot_1a, global.usedWords, "", "Select #1A");
    if (word_1a == "") {
        obj_heartbeat.status_text = "Failed #1 Across";
        return false;
    }

    place_word(word_1a, slot_1a.col, slot_1a.row, "horizontal");
    ds_map_add(global.usedWords, word_1a, true);
    show_debug_message("[FillTrace] Placed #1A=" + word_1a);

    var first_letter = string_char_at(word_1a, 1);
    var word_1d = crossword_try_pick_word(slot_1d, global.usedWords, first_letter, "Select #1D");
    if (word_1d == "") {
        obj_heartbeat.status_text = "Failed #1 Down";
        return false;
    }

    place_word(word_1d, slot_1d.col, slot_1d.row, "vertical");
    ds_map_add(global.usedWords, word_1d, true);
    show_debug_message("[FillTrace] Placed #1D=" + word_1d);

    for (var j = 0; j < array_length(slots); j++) {
        var down_slot = slots[j];
        if (down_slot.dir != "D") continue;
        if (down_slot.num == 1) continue;
        if (down_slot.row != slot_1a.row) continue;
        if (down_slot.col < slot_1a.col || down_slot.col >= slot_1a.col + slot_1a.len) continue;

        attached_downs[attached_count++] = down_slot;
    }

    for (var a = 0; a < attached_count; a++) {
        var target_down = attached_downs[a];
        var across_idx = (target_down.col - slot_1a.col) + 1;
        var needed_start = string_char_at(word_1a, across_idx);

        var trace = "Attach " + string(target_down.num) + "D from #1A[" + string(across_idx) + "]=" + needed_start;
        var down_word = crossword_try_pick_word(target_down, global.usedWords, needed_start, trace);

        if (down_word == "") {
            obj_heartbeat.status_text = "Failed attached down " + string(target_down.num) + "D";
            show_debug_message("[FillTrace] Failed attached down " + string(target_down.num) + "D");
            return false;
        }

        place_word(down_word, target_down.col, target_down.row, "vertical");
        ds_map_add(global.usedWords, down_word, true);
        show_debug_message("[FillTrace] Placed " + string(target_down.num) + "D=" + down_word);
    }

    obj_heartbeat.status_text = "Experiment fill complete: 1A/1D + " + string(attached_count) + " attached downs";
    show_debug_message("[Crossword] " + obj_heartbeat.status_text);
    return true;
}



function crossword_cell_in_failed_across(cell_col, cell_row, failed_across_slots) {
    for (var i = 0; i < array_length(failed_across_slots); i++) {
        var a = failed_across_slots[i];
        if (cell_row == a.row && cell_col >= a.col && cell_col < a.col + a.len) {
            return true;
        }
    }
    return false;
}

function crossword_collect_failed_across_slots(used_map) {
    var result = [];
    var count = 0;
    var slots = crossword_build_slots();

    for (var i = 0; i < array_length(slots); i++) {
        var slot_data = slots[i];
        if (slot_data.dir != "A") continue;

        var pattern = crossword_slot_pattern(slot_data);
        if (!crossword_pattern_has_blank(pattern)) continue;
        if (!crossword_pattern_has_fixed_letter(pattern)) continue;

        if (!crossword_has_candidate_for_slot(slot_data, used_map)) {
            result[count++] = slot_data;
        }
    }

    return result;
}

function crossword_collect_constraining_down_slots(failed_across_slots, all_slots) {
    var result = [];
    var count = 0;
    var seen = ds_map_create();

    for (var i = 0; i < array_length(failed_across_slots); i++) {
        var a = failed_across_slots[i];
        for (var k = 0; k < a.len; k++) {
            var cell_col = a.col + k;
            var cell_row = a.row;

            for (var s = 0; s < array_length(all_slots); s++) {
                var d = all_slots[s];
                if (d.dir != "D") continue;
                if (d.col != cell_col) continue;
                if (cell_row < d.row || cell_row >= d.row + d.len) continue;

                var key = string(d.num) + "D";
                if (!ds_map_exists(seen, key)) {
                    ds_map_add(seen, key, true);
                    result[count++] = d;
                }
            }
        }
    }

    ds_map_destroy(seen);
    return result;
}

function crossword_step3_repair_failed_across() {
    if (!variable_global_exists("usedWords") || !ds_exists(global.usedWords, ds_type_map)) {
        global.usedWords = ds_map_create();
    }

    var baseline = crossword_remaining_across_viability(global.usedWords);
    var failed = crossword_collect_failed_across_slots(global.usedWords);

    if (array_length(failed) == 0) {
        obj_heartbeat.status_text = "Step 3: no failed across slots";
        show_debug_message("[Repair] No failed across slots.");
        return true;
    }

    var all_slots = crossword_build_slots();
    var down_targets = crossword_collect_constraining_down_slots(failed, all_slots);
    if (array_length(down_targets) == 0) {
        obj_heartbeat.status_text = "Step 3: no down targets";
        show_debug_message("[Repair] No down slots constrain failed across.");
        return false;
    }

    show_debug_message("[Repair] Failed across count=" + string(array_length(failed))
        + " down targets=" + string(array_length(down_targets)));

    var improved_any = false;

    for (var t = 0; t < array_length(down_targets); t++) {
        var target = down_targets[t];
        var current_word = crossword_slot_word(target);

        if (string_pos("_", current_word) > 0) {
            continue;
        }

        var relaxed_pattern = "";
        var relax_count = 0;
        for (var k = 0; k < target.len; k++) {
            var cell_col = target.col;
            var cell_row = target.row + k;
            var letter = string_char_at(current_word, k + 1);

            if (crossword_cell_in_failed_across(cell_col, cell_row, failed)) {
                relaxed_pattern += "_";
                relax_count++;
            } else {
                relaxed_pattern += letter;
            }
        }

        if (relax_count <= 0) {
            continue;
        }

        var key_len = string(target.len);
        if (!ds_map_exists(global.wordsByLength, key_len)) {
            continue;
        }

        var bucket = global.wordsByLength[? key_len];
        var bucket_count = ds_list_size(bucket);
        if (bucket_count <= 0) {
            continue;
        }

        var before = crossword_remaining_across_viability(global.usedWords);
        var best_word = "";
        var best_viable = before.viable;
        var best_ratio = before.ratio;

        var start_index = irandom(bucket_count - 1);
        for (var i = 0; i < bucket_count; i++) {
            var idx = (start_index + i) mod bucket_count;
            var candidate = bucket[| idx];
            global.fill_attempt_count++;

            if (candidate == current_word) continue;
            if (ds_map_exists(global.usedWords, candidate)) continue;
            if (!crossword_word_matches_pattern(candidate, relaxed_pattern)) continue;
            if (!can_place_word(candidate, target.col, target.row, "vertical")) continue;

            place_word(candidate, target.col, target.row, "vertical");
            var viability = crossword_remaining_across_viability(global.usedWords);
            place_word(current_word, target.col, target.row, "vertical");

            if (viability.viable > best_viable || (viability.viable == best_viable && viability.ratio > best_ratio)) {
                best_viable = viability.viable;
                best_ratio = viability.ratio;
                best_word = candidate;
            }

            if (global.fill_attempt_count >= global.fill_attempt_limit) {
                break;
            }
        }

        if (best_word != "") {
            if (ds_map_exists(global.usedWords, current_word)) {
                ds_map_delete(global.usedWords, current_word);
            }

            place_word(best_word, target.col, target.row, "vertical");
            ds_map_add(global.usedWords, best_word, true);
            improved_any = true;

            show_debug_message("[Repair] Replaced " + string(target.num) + "D " + current_word + " -> " + best_word
                + " pattern=" + relaxed_pattern + " viable=" + string(best_viable) + "/" + string(before.total));
        } else {
            show_debug_message("[Repair] No improving replacement for " + string(target.num) + "D pattern=" + relaxed_pattern);
        }
    }

    var after = crossword_remaining_across_viability(global.usedWords);
    obj_heartbeat.status_text = "Step 3: viable across " + string(after.viable) + "/" + string(after.total)
        + " (was " + string(baseline.viable) + "/" + string(baseline.total) + ")";

    show_debug_message("[Crossword] " + obj_heartbeat.status_text);
    return improved_any;
}

function crossword_validate_long_entry_gate(min_len) {
    var slots = crossword_build_slots();
    var protected_cells = ds_map_create();
    var missing_labels = [];
    var missing_count = 0;

    for (var i = 0; i < array_length(slots); i++) {
        var slot_data = slots[i];
        if (slot_data.len < min_len) continue;

        var complete = true;
        var pattern = crossword_slot_word(slot_data);

        for (var k = 0; k < slot_data.len; k++) {
            var col_i = slot_data.col + ((slot_data.dir == "A") ? k : 0);
            var row_i = slot_data.row + ((slot_data.dir == "D") ? k : 0);
            var key = string(col_i) + "," + string(row_i);
            if (!ds_map_exists(protected_cells, key)) ds_map_add(protected_cells, key, true);

            var cell = obj_heartbeat.grid[# col_i, row_i];
            if (cell == "" || cell == "INVALID") complete = false;
        }

        if (!complete) {
            missing_labels[missing_count++] = string(slot_data.num) + slot_data.dir + "(" + string(slot_data.len) + ")=" + pattern;
        }
    }

    var ok = (missing_count == 0);
    var msg = "";
    if (!ok) {
        msg = "Fill blocked: complete all " + string(min_len) + "+ slots first (" + string(missing_count) + " open).";
        show_debug_message("[Crossword] " + msg);
        for (var m = 0; m < min(missing_count, 6); m++) {
            show_debug_message("[Crossword] unresolved " + missing_labels[m]);
        }
    }

    return {
        ok: ok,
        message: msg,
        protected_cells: protected_cells
    };
}

function crossword_collect_unresolved_long_slots(min_len) {
    var slots = crossword_build_slots();
    var unresolved = [];
    var count = 0;

    for (var i = 0; i < array_length(slots); i++) {
        var slot_data = slots[i];
        if (slot_data.len < min_len) continue;

        var pattern = crossword_slot_word(slot_data);
        if (string_pos("_", pattern) > 0) {
            unresolved[count++] = slot_data;
        }
    }

    return unresolved;
}

function crossword_solver_clear_tried_maps(vs) {
    if (is_undefined(vs)) return;

    if (variable_struct_exists(vs, "tried_maps")) {
        var tried_maps = variable_struct_get(vs, "tried_maps");
        if (!is_undefined(tried_maps) && is_array(tried_maps)) {
            for (var i = 0; i < array_length(tried_maps); i++) {
                var m = tried_maps[i];
                if (!is_undefined(m) && ds_exists(m, ds_type_map)) ds_map_destroy(m);
            }
        }
    }

    if (variable_struct_exists(vs, "fail_signature_counts")) {
        var fail_map = variable_struct_get(vs, "fail_signature_counts");
        if (!is_undefined(fail_map) && ds_exists(fail_map, ds_type_map)) ds_map_destroy(fail_map);
    }

    if (variable_struct_exists(vs, "blacklist_map")) {
        var blk_map = variable_struct_get(vs, "blacklist_map");
        if (!is_undefined(blk_map) && ds_exists(blk_map, ds_type_map)) ds_map_destroy(blk_map);
    }

    if (variable_struct_exists(vs, "tries_by_slot")) {
        var tries_map = variable_struct_get(vs, "tries_by_slot");
        if (!is_undefined(tries_map) && ds_exists(tries_map, ds_type_map)) ds_map_destroy(tries_map);
    }

    if (variable_struct_exists(vs, "protected_cells")) {
        var protected_map = variable_struct_get(vs, "protected_cells");
        if (!is_undefined(protected_map) && ds_exists(protected_map, ds_type_map)) ds_map_destroy(protected_map);
    }
}

function crossword_solver_clear_visuals() {
    global.solver_fail_cells = [];
    global.solver_fail_until = 0;
}

function crossword_solver_slot_label(slot_data) {
    return string(slot_data.num) + slot_data.dir;
}

function crossword_solver_blacklist_key(slot_data, pattern, word) {
    return crossword_solver_slot_label(slot_data) + "|" + pattern + "|" + word;
}

function crossword_solver_blacklist_has(vs, slot_data, pattern, word) {
    if (is_undefined(vs.blacklist_map) || !ds_exists(vs.blacklist_map, ds_type_map)) {
        return false;
    }

    var key = crossword_solver_blacklist_key(slot_data, pattern, word);
    return ds_map_exists(vs.blacklist_map, key);
}

function crossword_solver_blacklist_add(vs, slot_data, pattern, word) {
    if (is_undefined(vs.blacklist_map) || !ds_exists(vs.blacklist_map, ds_type_map)) {
        vs.blacklist_map = ds_map_create();
    }

    var key = crossword_solver_blacklist_key(slot_data, pattern, word);
    if (!ds_map_exists(vs.blacklist_map, key)) {
        ds_map_add(vs.blacklist_map, key, true);
    }
}

function crossword_solver_place_word_with_changes(slot_data, word) {
    var changes = [];
    var c = 0;

    for (var k = 0; k < slot_data.len; k++) {
        var col_i = slot_data.col + ((slot_data.dir == "A") ? k : 0);
        var row_i = slot_data.row + ((slot_data.dir == "D") ? k : 0);
        var old_ch = obj_heartbeat.grid[# col_i, row_i];
        var new_ch = string_char_at(word, k + 1);

        if (old_ch != new_ch) {
            changes[c++] = { col: col_i, row: row_i, old: old_ch };
            obj_heartbeat.grid[# col_i, row_i] = new_ch;
        }
    }

    return changes;
}

function crossword_solver_undo_changes(changes) {
    for (var i = array_length(changes) - 1; i >= 0; i--) {
        var ch = changes[i];
        obj_heartbeat.grid[# ch.col, ch.row] = ch.old;
    }
}

function crossword_solver_collect_candidates(vs, slot_idx, pattern) {
    var slot_data = vs.slots[slot_idx];
    var key_len = string(slot_data.len);
    var out = [];

    if (!ds_map_exists(global.wordsByLength, key_len)) {
        return out;
    }

    var bucket = global.wordsByLength[? key_len];
    var bucket_count = ds_list_size(bucket);
    var slot_dir = (slot_data.dir == "A") ? "horizontal" : "vertical";

    var start_idx = irandom(max(0, bucket_count - 1));
    var out_count = 0;

    for (var i = 0; i < bucket_count; i++) {
        var bucket_idx = (start_idx + i) mod bucket_count;
        var w = bucket[| bucket_idx];

        if (ds_map_exists(global.usedWords, w)) continue;
        if (!crossword_word_matches_pattern(w, pattern)) continue;
        if (crossword_solver_blacklist_has(vs, slot_data, pattern, w)) continue;
        if (!can_place_word(w, slot_data.col, slot_data.row, slot_dir)) continue;
        if (!crossword_candidate_passes_letter_rules(w, slot_data)) continue;
        if (!crossword_candidate_passes_prefix_deadend_rules(w, slot_data)) continue;

        out[out_count++] = w;
    }

    return out;
}

function crossword_solver_choose_mrv_slot(vs) {
    var best_slot_idx = -1;
    var best_candidates = [];
    var best_pattern = "";
    var best_count = 1000000000;
    var failed_slot = undefined;
    var failed_pattern = "";

    for (var i = 0; i < array_length(vs.slots); i++) {
        var slot_data = vs.slots[i];
        var pattern = crossword_slot_pattern(slot_data);

        if (!crossword_pattern_has_blank(pattern)) {
            if (slot_data.len >= global.long_entry_min_len) continue;
            var full_word = crossword_slot_word(slot_data);
            if (!ds_map_exists(global.wordLookup, full_word)) {
                return {
                    state: "dead",
                    slot_idx: -1,
                    candidates: [],
                    pattern: "",
                    failed_slot: slot_data,
                    failed_pattern: full_word
                };
            }
            continue;
        }

        if (slot_data.len >= global.long_entry_min_len) {
            failed_slot = slot_data;
            failed_pattern = pattern;
            return {
                state: "dead",
                slot_idx: -1,
                candidates: [],
                pattern: "",
                failed_slot: failed_slot,
                failed_pattern: failed_pattern
            };
        }

        var candidates = crossword_solver_collect_candidates(vs, i, pattern);
        var c = array_length(candidates);

        if (c <= 0) {
            failed_slot = slot_data;
            failed_pattern = pattern;
            return {
                state: "dead",
                slot_idx: -1,
                candidates: [],
                pattern: "",
                failed_slot: failed_slot,
                failed_pattern: failed_pattern
            };
        }

        if (c < best_count) {
            best_count = c;
            best_slot_idx = i;
            best_candidates = candidates;
            best_pattern = pattern;
        }
    }

    if (best_slot_idx < 0) {
        return {
            state: "solved",
            slot_idx: -1,
            candidates: [],
            pattern: "",
            failed_slot: undefined,
            failed_pattern: ""
        };
    }

    return {
        state: "ok",
        slot_idx: best_slot_idx,
        candidates: best_candidates,
        pattern: best_pattern,
        failed_slot: undefined,
        failed_pattern: ""
    };
}

function crossword_solver_push_frame(vs, choice) {
    var frame = {
        slot_idx: choice.slot_idx,
        pattern: choice.pattern,
        candidates: choice.candidates,
        next_candidate: 0,
        placed_word: "",
        changes: []
    };

    var frame_depth = array_length(vs.stack);
    vs.stack[frame_depth] = frame;

    var slot_data = vs.slots[choice.slot_idx];
    show_debug_message("[Visual] Select " + crossword_solver_slot_label(slot_data)
        + " pattern=" + choice.pattern
        + " candidates=" + string(array_length(choice.candidates)));
}

function crossword_solver_schedule_reject(vs, frame_idx, failed_slot_data, reason_text) {
    var frame = vs.stack[frame_idx];
    var slot_data = vs.slots[frame.slot_idx];

    var failed_pattern = "";
    if (!is_undefined(failed_slot_data)) {
        failed_pattern = crossword_slot_pattern(failed_slot_data);
    }

    crossword_solver_blacklist_add(vs, slot_data, frame.pattern, frame.placed_word);
    crossword_solver_mark_fail_combo(failed_slot_data, slot_data);

    obj_heartbeat.status_text = "Fail " + crossword_solver_slot_label(slot_data) + "=" + frame.placed_word;

    show_debug_message("[Visual] Reject " + crossword_solver_slot_label(slot_data) + "=" + frame.placed_word
        + " slot_pattern=" + frame.pattern
        + " failed_slot=" + (is_undefined(failed_slot_data) ? "-" : crossword_solver_slot_label(failed_slot_data))
        + " failed_pattern=" + failed_pattern
        + " reason=" + reason_text);

    vs.pending_remove = true;
    vs.pending_frame_idx = frame_idx;
    vs.wait_until = current_time + 500;
}

function crossword_solver_handle_pending_remove(vs) {
    if (!vs.pending_remove || current_time < vs.wait_until) {
        return false;
    }

    var fi = vs.pending_frame_idx;
    if (fi < 0 || fi >= array_length(vs.stack)) {
        vs.pending_remove = false;
        vs.pending_frame_idx = -1;
        return false;
    }

    var frame = vs.stack[fi];
    if (frame.placed_word != "") {
        crossword_solver_undo_changes(frame.changes);
        if (ds_map_exists(global.usedWords, frame.placed_word)) {
            ds_map_delete(global.usedWords, frame.placed_word);
        }
    }

    frame.placed_word = "";
    frame.changes = [];
    frame.next_candidate++;
    vs.stack[fi] = frame;

    for (var d = array_length(vs.stack) - 1; d > fi; d--) {
        array_resize(vs.stack, d);
    }

    vs.pending_remove = false;
    vs.pending_frame_idx = -1;
    return true;
}


function crossword_solver_unwind_to_depth(vs, keep_max_idx) {
    var last_idx = array_length(vs.stack) - 1;
    for (var i = last_idx; i > keep_max_idx; i--) {
        var frame = vs.stack[i];
        if (frame.placed_word != "") {
            crossword_solver_undo_changes(frame.changes);
            if (ds_map_exists(global.usedWords, frame.placed_word)) {
                ds_map_delete(global.usedWords, frame.placed_word);
            }
        }
    }

    while (array_length(vs.stack) > keep_max_idx + 1) {
        array_resize(vs.stack, array_length(vs.stack) - 1);
    }
}

function crossword_solver_check_root_timeout(vs) {
    if (!variable_global_exists("root_word_attempt_window")) {
        global.root_word_attempt_window = 100;
    }

    if (array_length(vs.stack) <= 0) return false;

    var root = vs.stack[0];
    if (root.placed_word == "") return false;

    var span = global.fill_attempt_count - vs.root_attempt_start;
    if (span < global.root_word_attempt_window) return false;

    show_debug_message("[Visual] Root timeout " + crossword_solver_slot_label(vs.slots[root.slot_idx])
        + "=" + root.placed_word + " after " + string(span) + " attempts; forcing new starter.");

    crossword_solver_unwind_to_depth(vs, 0);
    crossword_solver_schedule_reject(vs, 0, undefined, "root-timeout");
    return true;
}

function crossword_solver_tick() {
    if (!obj_heartbeat.solver_active) {
        return;
    }

    var vs = global.visual_solver;
    if (is_undefined(vs)) {
        obj_heartbeat.solver_active = false;
        return;
    }

    if (crossword_solver_handle_pending_remove(vs)) {
        global.visual_solver = vs;
        return;
    }

    if (vs.pending_remove || current_time < vs.wait_until) {
        global.visual_solver = vs;
        return;
    }


    if (crossword_solver_check_root_timeout(vs)) {
        global.visual_solver = vs;
        return;
    }
    if (array_length(vs.stack) <= 0) {
        var first_choice = crossword_solver_choose_mrv_slot(vs);

        if (first_choice.state == "solved") {
            obj_heartbeat.status_text = "Visual solver complete";
            show_debug_message("[Visual] Fill complete.");
            crossword_export_word_lists();
            crossword_solver_stop(true);
            return;
        }

        if (first_choice.state == "dead") {
            obj_heartbeat.status_text = "Visual solver failed at root";
            if (!is_undefined(first_choice.failed_slot)) {
                crossword_solver_mark_fail(first_choice.failed_slot);
            }
            show_debug_message("[Visual] Root dead-end pattern=" + first_choice.failed_pattern);
            crossword_solver_stop(false);
            return;
        }

        crossword_solver_push_frame(vs, first_choice);
        global.visual_solver = vs;
        return;
    }

    var top_idx = array_length(vs.stack) - 1;
    var top = vs.stack[top_idx];

    if (top.placed_word != "") {
        var next_choice = crossword_solver_choose_mrv_slot(vs);

        if (next_choice.state == "solved") {
            obj_heartbeat.status_text = "Visual solver complete";
            show_debug_message("[Visual] Fill complete.");
            crossword_export_word_lists();
            crossword_solver_stop(true);
            return;
        }

        if (next_choice.state == "dead") {
            show_debug_message("[Visual] Dead-end after " + crossword_solver_slot_label(vs.slots[top.slot_idx])
                + "=" + top.placed_word
                + " at " + (is_undefined(next_choice.failed_slot) ? "-" : crossword_solver_slot_label(next_choice.failed_slot))
                + " pattern=" + next_choice.failed_pattern);
            crossword_solver_schedule_reject(vs, top_idx, next_choice.failed_slot, "forward-check-dead");
            global.visual_solver = vs;
            return;
        }

        crossword_solver_push_frame(vs, next_choice);
        global.visual_solver = vs;
        return;
    }

    var tries_so_far = 0;
    var tries_key = string(top.slot_idx);
    if (ds_map_exists(vs.tries_by_slot, tries_key)) tries_so_far = vs.tries_by_slot[? tries_key];

    if (top.next_candidate >= array_length(top.candidates) || tries_so_far >= global.slot_try_limit) {
        var exhausted_slot = vs.slots[top.slot_idx];
        show_debug_message("[Visual] Exhausted " + crossword_solver_slot_label(exhausted_slot)
            + " pattern=" + top.pattern
            + " tried=" + string(top.next_candidate)
            + "; backtracking.");

        array_resize(vs.stack, top_idx);

        if (array_length(vs.stack) <= 0) {
            obj_heartbeat.status_text = "Visual solver failed: exhausted root slot";
            show_debug_message("[Visual] Exhausted root slot; no fill found.");
            crossword_solver_stop(false);
            return;
        }

        var parent_idx = array_length(vs.stack) - 1;
        crossword_solver_schedule_reject(vs, parent_idx, exhausted_slot, "child-exhausted");
        global.visual_solver = vs;
        return;
    }

    var word = top.candidates[top.next_candidate];
    var slot_data = vs.slots[top.slot_idx];

    var changes = crossword_solver_place_word_with_changes(slot_data, word);
    ds_map_add(global.usedWords, word, true);
    global.fill_attempt_count++;

    var slot_key = string(top.slot_idx);
    var slot_tries = 0;
    if (ds_map_exists(vs.tries_by_slot, slot_key)) {
        slot_tries = vs.tries_by_slot[? slot_key];
    }
    slot_tries++;
    if (ds_map_exists(vs.tries_by_slot, slot_key)) {
        ds_map_replace(vs.tries_by_slot, slot_key, slot_tries);
    } else {
        ds_map_add(vs.tries_by_slot, slot_key, slot_tries);
    }

    show_debug_message("[Visual] Try " + crossword_solver_slot_label(slot_data)
        + "=" + word
        + " pattern=" + top.pattern
        + " candidate " + string(top.next_candidate + 1) + "/" + string(array_length(top.candidates)));

    var fc = crossword_solver_choose_mrv_slot(vs);

    if (fc.state == "dead") {
        top.placed_word = word;
        top.changes = changes;
        vs.stack[top_idx] = top;
        crossword_solver_schedule_reject(vs, top_idx, fc.failed_slot, "forward-check-dead");
        global.visual_solver = vs;
        return;
    }

    top.placed_word = word;
    top.changes = changes;
    vs.stack[top_idx] = top;

    obj_heartbeat.status_text = "Placed " + crossword_solver_slot_label(slot_data) + "=" + word;
    if (top_idx == 0) vs.root_attempt_start = global.fill_attempt_count;
    global.visual_solver = vs;
}

function crossword_solver_stop(solved) {
    if (variable_global_exists("visual_solver") && !is_undefined(global.visual_solver)) {
        crossword_solver_clear_tried_maps(global.visual_solver);
    }

    obj_heartbeat.solver_active = false;
    global.visual_solver = undefined;
    crossword_solver_clear_visuals();

    if (!solved && obj_heartbeat.status_text == "") {
        obj_heartbeat.status_text = "Visual solver stopped";
    }
}

function crossword_start_visual_solver() {
    if (obj_heartbeat.solver_active) {
        crossword_solver_stop(false);
    }

    var long_gate = crossword_validate_long_entry_gate(global.long_entry_min_len);
    if (!long_gate.ok) {
        obj_heartbeat.status_text = long_gate.message;
        if (ds_exists(long_gate.protected_cells, ds_type_map)) ds_map_destroy(long_gate.protected_cells);
        return false;
    }

    if (variable_global_exists("usedWords") && ds_exists(global.usedWords, ds_type_map)) {
        ds_map_destroy(global.usedWords);
    }
    global.usedWords = ds_map_create();

    global.fill_attempt_count = 0;

    for (var col_i = 0; col_i < obj_heartbeat.grid_width; col_i++) {
        for (var row_i = 0; row_i < obj_heartbeat.grid_height; row_i++) {
            if (obj_heartbeat.grid[# col_i, row_i] != "INVALID") {
                var pkey = string(col_i) + "," + string(row_i);
                if (!ds_map_exists(long_gate.protected_cells, pkey)) obj_heartbeat.grid[# col_i, row_i] = "";
            }
        }
    }

    var slots = crossword_build_slots();
    if (array_length(slots) <= 0) {
        obj_heartbeat.status_text = "Visual solver: no slots";
        show_debug_message("[Visual] Missing fillable slots.");
        return false;
    }

    global.visual_solver = {
        slots: slots,
        stack: [],
        pending_remove: false,
        pending_frame_idx: -1,
        wait_until: 0,
        fail_signature_counts: ds_map_create(),
        blacklist_map: ds_map_create(),
        tries_by_slot: ds_map_create(),
        root_attempt_start: 0,
        protected_cells: long_gate.protected_cells
    };

    obj_heartbeat.solver_active = true;
    crossword_solver_clear_visuals();

    obj_heartbeat.status_text = "Visual solver running (MRV CSP)...";
    show_debug_message("[Visual] Start: MRV + forward-check + backtracking + fail flash.");
    return true;
}





function crossword_is_vowel(ch) {
    return ch == "A" || ch == "E" || ch == "I" || ch == "O" || ch == "U" || ch == "Y";
}

function crossword_prefix2_exists(word_len, first_char, second_char) {
    if (word_len < 2) return true;
    if (!variable_global_exists("prefix2ByLength") || !ds_exists(global.prefix2ByLength, ds_type_map)) {
        return true;
    }

    var key = string(word_len);
    if (!ds_map_exists(global.prefix2ByLength, key)) {
        return false;
    }

    var pmap = global.prefix2ByLength[? key];
    var p2 = first_char + second_char;
    return ds_map_exists(pmap, p2);
}

function crossword_candidate_passes_letter_rules(word, slot_data) {
    var slot_dir = slot_data.dir;

    for (var k = 0; k < slot_data.len; k++) {
        var cell_col = slot_data.col + ((slot_dir == "A") ? k : 0);
        var cell_row = slot_data.row + ((slot_dir == "D") ? k : 0);
        var letter = string_char_at(word, k + 1);

        if (slot_dir == "D") {
            if (obj_heartbeat.grid[# cell_col, cell_row] == "INVALID") continue;

            var start_col = cell_col;
            while (start_col > 0 && obj_heartbeat.grid[# start_col - 1, cell_row] != "INVALID") {
                start_col--;
            }

            var across_len = 0;
            var c = start_col;
            while (c < obj_heartbeat.grid_width && obj_heartbeat.grid[# c, cell_row] != "INVALID") {
                across_len++;
                c++;
            }

            if (across_len > 1) {
                var pos_in_across = cell_col - start_col + 1;
                if (pos_in_across == 2) {
                    var first_char = obj_heartbeat.grid[# start_col, cell_row];
                    if (first_char != "") {
                        if (!crossword_prefix2_exists(across_len, first_char, letter)) {
                            return false;
                        }
                        if (!crossword_is_vowel(first_char) && !crossword_is_vowel(letter)) {
                            return false;
                        }
                    }
                }
            }
        } else {
            if (obj_heartbeat.grid[# cell_col, cell_row] == "INVALID") continue;

            var start_row = cell_row;
            while (start_row > 0 && obj_heartbeat.grid[# cell_col, start_row - 1] != "INVALID") {
                start_row--;
            }

            var down_len = 0;
            var r = start_row;
            while (r < obj_heartbeat.grid_height && obj_heartbeat.grid[# cell_col, r] != "INVALID") {
                down_len++;
                r++;
            }

            if (down_len > 1) {
                var pos_in_down = cell_row - start_row + 1;
                if (pos_in_down == 2) {
                    var first_d = obj_heartbeat.grid[# cell_col, start_row];
                    if (first_d != "") {
                        if (!crossword_prefix2_exists(down_len, first_d, letter)) {
                            return false;
                        }
                        if (!crossword_is_vowel(first_d) && !crossword_is_vowel(letter)) {
                            return false;
                        }
                    }
                }
            }
        }
    }

    return true;
}


function crossword_slot_start_prefix_len(pattern) {
    var max_len = string_length(pattern);
    var n = 0;
    for (var i = 1; i <= max_len; i++) {
        var ch = string_char_at(pattern, i);
        if (ch == "_") break;
        n++;
    }
    return n;
}

function crossword_prefix_exists_for_length(word_len, prefix) {
    if (prefix == "") return true;

    var key_len = string(word_len);
    if (!ds_map_exists(global.wordsByLength, key_len)) {
        return false;
    }

    var bucket = global.wordsByLength[? key_len];
    var bucket_count = ds_list_size(bucket);
    var p_len = string_length(prefix);

    for (var i = 0; i < bucket_count; i++) {
        var w = bucket[| i];
        if (string_copy(w, 1, p_len) == prefix) {
            return true;
        }
    }

    return false;
}

function crossword_candidate_passes_prefix_deadend_rules(word, slot_data) {
    var slot_dir = slot_data.dir;

    for (var k = 0; k < slot_data.len; k++) {
        var cell_col = slot_data.col + ((slot_dir == "A") ? k : 0);
        var cell_row = slot_data.row + ((slot_dir == "D") ? k : 0);
        var letter = string_char_at(word, k + 1);

        var cross_dir = (slot_dir == "A") ? "D" : "A";

        var start_col = cell_col;
        var start_row = cell_row;

        if (cross_dir == "A") {
            while (start_col > 0 && obj_heartbeat.grid[# start_col - 1, cell_row] != "INVALID") {
                start_col--;
            }
        } else {
            while (start_row > 0 && obj_heartbeat.grid[# cell_col, start_row - 1] != "INVALID") {
                start_row--;
            }
        }

        var cross_len = 0;
        var pattern = "";
        var step = 0;

        while (true) {
            var ccol = start_col + ((cross_dir == "A") ? step : 0);
            var crow = start_row + ((cross_dir == "D") ? step : 0);
            if (ccol < 0 || ccol >= obj_heartbeat.grid_width || crow < 0 || crow >= obj_heartbeat.grid_height) break;
            if (obj_heartbeat.grid[# ccol, crow] == "INVALID") break;

            var ch = obj_heartbeat.grid[# ccol, crow];
            if (ccol == cell_col && crow == cell_row) {
                ch = letter;
            }

            pattern += (ch == "") ? "_" : ch;
            cross_len++;
            step++;
        }

        if (cross_len <= 1) continue;

        var fixed_prefix_len = crossword_slot_start_prefix_len(pattern);
        if (fixed_prefix_len >= 3 && fixed_prefix_len < cross_len) {
            var prefix = string_copy(pattern, 1, fixed_prefix_len);
            if (!crossword_prefix_exists_for_length(cross_len, prefix)) {
                return false;
            }
        }
    }

    return true;
}
















function crossword_solver_mark_fail_combo(slot_a, slot_b) {
    var cells = [];
    var c = 0;

    var slots = [slot_a, slot_b];
    for (var s = 0; s < array_length(slots); s++) {
        var _s = slots[s];
        if (is_undefined(_s)) continue;

        for (var k = 0; k < _s.len; k++) {
            var col_i = _s.col + ((_s.dir == "A") ? k : 0);
            var row_i = _s.row + ((_s.dir == "D") ? k : 0);

            var exists = false;
            for (var z = 0; z < c; z++) {
                if (cells[z].col == col_i && cells[z].row == row_i) {
                    exists = true;
                    break;
                }
            }

            if (!exists) {
                cells[c++] = { col: col_i, row: row_i };
            }
        }
    }

    global.solver_fail_cells = cells;
    global.solver_fail_until = current_time + 500;
}






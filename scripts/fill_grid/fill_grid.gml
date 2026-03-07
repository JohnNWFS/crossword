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

function crossword_has_candidate_for_slot(slot_data, used_words) {
    var key_len = string(slot_data.len);
    if (!ds_map_exists(global.wordsByLength, key_len)) {
        return false;
    }

    var pattern = crossword_slot_pattern(slot_data);
    var direction = (slot_data.dir == "A") ? "horizontal" : "vertical";
    var list_words = global.wordsByLength[? key_len];
    var count_words = ds_list_size(list_words);

    for (var i = 0; i < count_words; i++) {
        var candidate = list_words[| i];

        if (is_undefined(used_words) == false && ds_exists(used_words, ds_type_map) && ds_map_exists(used_words, candidate)) {
            continue;
        }

        if (!crossword_word_matches_pattern(candidate, pattern)) {
            continue;
        }

        if (can_place_word(candidate, slot_data.col, slot_data.row, direction)) {
            return true;
        }
    }

    return false;
}

function crossword_remaining_across_viability(used_words) {
    var slots = crossword_build_slots();
    var viable = 0;
    var total = 0;
    var failed_slot = "";

    for (var i = 0; i < array_length(slots); i++) {
        var slot_data = slots[i];
        if (slot_data.dir != "A") {
            continue;
        }

        var pattern = crossword_slot_pattern(slot_data);
        if (!crossword_pattern_has_blank(pattern)) {
            continue;
        }
        if (!crossword_pattern_has_fixed_letter(pattern)) {
            continue;
        }

        total++;
        if (crossword_has_candidate_for_slot(slot_data, used_words)) {
            viable++;
        } else if (failed_slot == "") {
            failed_slot = string(slot_data.num) + "A pattern=" + pattern;
        }
    }

    var ratio = (total == 0) ? 1.0 : (viable / total);
    return { viable: viable, total: total, ratio: ratio, failed_slot: failed_slot };
}

function crossword_try_pick_word(slot_data, used_words, first_char, trace_label) {
    var key_len = string(slot_data.len);
    if (!ds_map_exists(global.wordsByLength, key_len)) {
        if (trace_label != "") show_debug_message("[FillTrace] " + trace_label + " no length bucket " + key_len);
        return "";
    }

    var pattern = crossword_slot_pattern(slot_data);
    var direction = (slot_data.dir == "A") ? "horizontal" : "vertical";
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
        if (!can_place_word(candidate, slot_data.col, slot_data.row, direction)) {
            continue;
        }

        place_word(candidate, slot_data.col, slot_data.row, direction);
        var viability = crossword_remaining_across_viability(used_words);
        remove_word(candidate, slot_data.col, slot_data.row, direction);

        var score = viability.viable * 1000 + floor(viability.ratio * 100);
        if (score > best_score) {
            best_score = score;
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

function crossword_solver_clear_tried_maps(vs) {
    for (var i = 0; i < array_length(vs.tried_maps); i++) {
        var m = vs.tried_maps[i];
        if (!is_undefined(m) && ds_exists(m, ds_type_map)) {
            ds_map_destroy(m);
        }
    }
}

function crossword_solver_clear_visuals() {
    global.solver_fail_cells = [];
    global.solver_fail_until = 0;
}

function crossword_get_slot_for_num_dir(slots, num, dir) {
    for (var i = 0; i < array_length(slots); i++) {
        if (slots[i].num == num && slots[i].dir == dir) {
            return slots[i];
        }
    }
    return undefined;
}

function crossword_build_visual_plan() {
    var slots = crossword_build_slots();
    var plan = [];
    var count = 0;

    var slot_1a = crossword_get_slot_for_num_dir(slots, 1, "A");
    var slot_1d = crossword_get_slot_for_num_dir(slots, 1, "D");

    if (is_undefined(slot_1a) || is_undefined(slot_1d)) {
        return plan;
    }

    plan[count++] = { slot: slot_1a, forced_mode: "none", source_idx: 0, label: "1A" };
    plan[count++] = { slot: slot_1d, forced_mode: "from_1a", source_idx: 1, label: "1D" };

    for (var i = 0; i < array_length(slots); i++) {
        var d = slots[i];
        if (d.dir != "D") continue;
        if (d.num == 1) continue;
        if (d.row != slot_1a.row) continue;
        if (d.col < slot_1a.col || d.col >= slot_1a.col + slot_1a.len) continue;

        var idx_from_1a = (d.col - slot_1a.col) + 1;
        plan[count++] = {
            slot: d,
            forced_mode: "from_1a",
            source_idx: idx_from_1a,
            label: string(d.num) + "D"
        };
    }

    return plan;
}

function crossword_solver_get_forced_letter(vs, idx) {
    var p = vs.plan[idx];
    if (p.forced_mode != "from_1a") {
        return "";
    }

    var first_word = vs.placed_words[0];
    if (first_word == "" || string_length(first_word) < p.source_idx) {
        return "";
    }

    return string_char_at(first_word, p.source_idx);
}

function crossword_solver_mark_fail(slot_data) {
    var cells = [];
    var c = 0;
    for (var k = 0; k < slot_data.len; k++) {
        cells[c++] = {
            col: slot_data.col + ((slot_data.dir == "A") ? k : 0),
            row: slot_data.row + ((slot_data.dir == "D") ? k : 0)
        };
    }
    global.solver_fail_cells = cells;
    global.solver_fail_until = current_time + 500;
}

function crossword_solver_reset_downstream(vs, from_idx) {
    for (var i = from_idx; i < array_length(vs.plan); i++) {
        if (i < array_length(vs.placed_words)) {
            vs.placed_words[i] = "";
        }
        vs.tries[i] = 0;

        var tm = vs.tried_maps[i];
        if (!is_undefined(tm) && ds_exists(tm, ds_type_map)) {
            ds_map_destroy(tm);
        }
        vs.tried_maps[i] = ds_map_create();
    }
}

function crossword_solver_backtrack(vs) {
    if (vs.slot_index <= 0) {
        obj_heartbeat.status_text = "Visual solver failed: exhausted root slot";
        show_debug_message("[Visual] Exhausted root slot; no fill found.");
        crossword_solver_stop(false);
        return false;
    }

    var prev_idx = vs.slot_index - 1;
    var prev_word = vs.placed_words[prev_idx];
    var prev_slot = vs.plan[prev_idx].slot;
    var prev_dir = (prev_slot.dir == "A") ? "horizontal" : "vertical";

    if (prev_word != "") {
        remove_word(prev_word, prev_slot.col, prev_slot.row, prev_dir);
        if (ds_map_exists(global.usedWords, prev_word)) {
            ds_map_delete(global.usedWords, prev_word);
        }
        show_debug_message("[Visual] Backtrack remove " + vs.plan[prev_idx].label + "=" + prev_word);
    }

    vs.placed_words[prev_idx] = "";
    vs.slot_index = prev_idx;
    crossword_solver_reset_downstream(vs, prev_idx + 1);
    return true;
}

function crossword_solver_pick_candidate(vs, idx, forced_letter) {
    var p = vs.plan[idx];
    var slot_data = p.slot;
    var key_len = string(slot_data.len);

    if (!ds_map_exists(global.wordsByLength, key_len)) {
        return "";
    }

    var tried_map = vs.tried_maps[idx];
    var pattern = crossword_slot_pattern(slot_data);
    var direction = (slot_data.dir == "A") ? "horizontal" : "vertical";
    var bucket = global.wordsByLength[? key_len];
    var bucket_count = ds_list_size(bucket);
    if (bucket_count <= 0) {
        return "";
    }

    var start_idx = irandom(bucket_count - 1);
    for (var i = 0; i < bucket_count; i++) {
        var id = (start_idx + i) mod bucket_count;
        var w = bucket[| id];

        if (ds_map_exists(tried_map, w)) continue;
        if (ds_map_exists(global.usedWords, w)) continue;
        if (forced_letter != "" && string_char_at(w, 1) != forced_letter) continue;
        if (!crossword_word_matches_pattern(w, pattern)) continue;
        if (!can_place_word(w, slot_data.col, slot_data.row, direction)) continue;

        return w;
    }

    return "";
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

    if (vs.pending_remove && current_time >= vs.wait_until) {
        var ps = vs.plan[vs.slot_index].slot;
        var pdir = (ps.dir == "A") ? "horizontal" : "vertical";

        remove_word(vs.pending_word, ps.col, ps.row, pdir);
        if (ds_map_exists(global.usedWords, vs.pending_word)) {
            ds_map_delete(global.usedWords, vs.pending_word);
        }

        vs.pending_remove = false;
        vs.pending_word = "";
    }

    if (vs.pending_remove || current_time < vs.wait_until) {
        global.visual_solver = vs;
        return;
    }

    if (vs.slot_index >= array_length(vs.plan)) {
        obj_heartbeat.status_text = "Visual solver complete";
        show_debug_message("[Visual] Fill complete.");
        crossword_export_word_lists();
        crossword_solver_stop(true);
        return;
    }

    var idx = vs.slot_index;
    var p = vs.plan[idx];
    var slot_data = p.slot;

    if (is_undefined(vs.tried_maps[idx]) || !ds_exists(vs.tried_maps[idx], ds_type_map)) {
        vs.tried_maps[idx] = ds_map_create();
    }

    if (vs.tries[idx] >= global.slot_try_limit) {
        show_debug_message("[Visual] Exhausted " + p.label + " after " + string(global.slot_try_limit) + " tries; backtracking.");
        if (!crossword_solver_backtrack(vs)) {
            return;
        }
        global.visual_solver = vs;
        return;
    }

    var forced = crossword_solver_get_forced_letter(vs, idx);
    var candidate = crossword_solver_pick_candidate(vs, idx, forced);

    if (candidate == "") {
        show_debug_message("[Visual] No candidate for " + p.label + "; backtracking.");
        if (!crossword_solver_backtrack(vs)) {
            return;
        }
        global.visual_solver = vs;
        return;
    }

    ds_map_add(vs.tried_maps[idx], candidate, true);
    vs.tries[idx]++;
    global.fill_attempt_count++;

    var dir = (slot_data.dir == "A") ? "horizontal" : "vertical";
    place_word(candidate, slot_data.col, slot_data.row, dir);
    ds_map_add(global.usedWords, candidate, true);

    var viability = crossword_remaining_across_viability(global.usedWords);
    var ok = (viability.viable == viability.total);

    show_debug_message("[Visual] Try " + p.label + "=" + candidate + " -> viability "
        + string(viability.viable) + "/" + string(viability.total));

    if (ok) {
        vs.placed_words[idx] = candidate;
        obj_heartbeat.status_text = "Placed " + p.label + "=" + candidate;
        vs.slot_index++;
        crossword_solver_reset_downstream(vs, vs.slot_index);
        global.visual_solver = vs;
        return;
    }

    obj_heartbeat.status_text = "Fail " + p.label + "=" + candidate + " -> " + viability.failed_slot;
    crossword_solver_mark_fail(slot_data);
    vs.pending_remove = true;
    vs.pending_word = candidate;
    vs.wait_until = current_time + 500;

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

    var plan = crossword_build_visual_plan();
    if (array_length(plan) <= 0) {
        obj_heartbeat.status_text = "Visual solver: missing #1A/#1D";
        show_debug_message("[Visual] Missing #1A or #1D.");
        return false;
    }

    var tries = [];
    var tried_maps = [];
    var placed_words = [];
    for (var i = 0; i < array_length(plan); i++) {
        tries[i] = 0;
        tried_maps[i] = ds_map_create();
        placed_words[i] = "";
    }

    global.visual_solver = {
        plan: plan,
        slot_index: 0,
        tries: tries,
        tried_maps: tried_maps,
        placed_words: placed_words,
        pending_remove: false,
        pending_word: "",
        wait_until: 0
    };

    obj_heartbeat.solver_active = true;
    crossword_solver_clear_visuals();

    obj_heartbeat.status_text = "Visual solver running...";
    show_debug_message("[Visual] Start: one-word-at-a-time with backtracking and fail flash.");
    return true;
}



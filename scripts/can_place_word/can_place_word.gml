// Check if a word can be placed at a specific position without any conflicts
function can_place_word(word, posX, posY, direction) {
    var wordLength = string_length(word);

    // Immutables mode: 0=Strict, 1=Soft, 2=Off (Soft/Off may overwrite ONLY user-seeded cells)
    var imm_mode = variable_global_exists("immutables_mode") ? global.immutables_mode : 0;
    var allow_seed_overwrite = (imm_mode != 0);
    var seed_map = undefined;
    if (allow_seed_overwrite && variable_global_exists("visual_solver") && !is_undefined(global.visual_solver)
        && variable_struct_exists(global.visual_solver, "immutable_cells") && ds_exists(global.visual_solver.immutable_cells, ds_type_map)) {
        seed_map = global.visual_solver.immutable_cells;
    }

    // Check bounds and existing letters for horizontal placement
    if (direction == "horizontal") {
        if (posX + wordLength > obj_heartbeat.grid_width) {
            return false;
        }
        for (var i = 0; i < wordLength; i++) {
            var gx = posX + i;
            var gy = posY;
            var existing = obj_heartbeat.grid[# gx, gy];
            var ch = string_char_at(word, i + 1);
            if (existing == "INVALID") return false;
            if (existing != "" && existing != ch) {
                if (!allow_seed_overwrite || is_undefined(seed_map)) return false;
                var key = string(gx) + "," + string(gy);
                if (!ds_map_exists(seed_map, key)) return false;
            }
        }
    }

    // Check bounds and existing letters for vertical placement
    if (direction == "vertical") {
        if (posY + wordLength > obj_heartbeat.grid_height) {
            return false;
        }
        for (var i = 0; i < wordLength; i++) {
            var gx = posX;
            var gy = posY + i;
            var existing = obj_heartbeat.grid[# gx, gy];
            var ch = string_char_at(word, i + 1);
            if (existing == "INVALID") return false;
            if (existing != "" && existing != ch) {
                if (!allow_seed_overwrite || is_undefined(seed_map)) return false;
                var key = string(gx) + "," + string(gy);
                if (!ds_map_exists(seed_map, key)) return false;
            }
        }
    }

    return true;
}


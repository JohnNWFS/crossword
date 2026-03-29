/// @description Clean DS List
// Clean Up Event for obj_heartbeat

if (variable_global_exists("visual_solver") && !is_undefined(global.visual_solver)) {
    crossword_solver_clear_tried_maps(global.visual_solver);
    global.visual_solver = undefined;
}

if (ds_exists(grid, ds_type_grid)) {
    ds_grid_destroy(grid);
}

if (variable_global_exists("wordList") && ds_exists(global.wordList, ds_type_list)) {
    ds_list_destroy(global.wordList);
}

if (variable_global_exists("wordLookup") && ds_exists(global.wordLookup, ds_type_map)) {
    ds_map_destroy(global.wordLookup);
}

if (variable_global_exists("wordsByLength") && ds_exists(global.wordsByLength, ds_type_map)) {
    var key = ds_map_find_first(global.wordsByLength);
    while (!is_undefined(key)) {
        var listForLength = global.wordsByLength[? key];
        if (ds_exists(listForLength, ds_type_list)) {
            ds_list_destroy(listForLength);
        }
        key = ds_map_find_next(global.wordsByLength, key);
    }

    ds_map_destroy(global.wordsByLength);
}

if (variable_global_exists("fillRefCount") && ds_exists(global.fillRefCount, ds_type_grid)) {
    ds_grid_destroy(global.fillRefCount);
}

if (variable_global_exists("fillLocked") && ds_exists(global.fillLocked, ds_type_grid)) {
    ds_grid_destroy(global.fillLocked);
}

if (variable_global_exists("usedWords") && ds_exists(global.usedWords, ds_type_map)) {
    ds_map_destroy(global.usedWords);
}

if (variable_global_exists("prefix2ByLength") && ds_exists(global.prefix2ByLength, ds_type_map)) {
    var pkey = ds_map_find_first(global.prefix2ByLength);
    while (!is_undefined(pkey)) {
        var pmap = global.prefix2ByLength[? pkey];
        if (ds_exists(pmap, ds_type_map)) {
            ds_map_destroy(pmap);
        }
        pkey = ds_map_find_next(global.prefix2ByLength, pkey);
    }
    ds_map_destroy(global.prefix2ByLength);
}

if (variable_global_exists("prefixSetByLength") && ds_exists(global.prefixSetByLength, ds_type_map)) {
    var pskey = ds_map_find_first(global.prefixSetByLength);
    while (!is_undefined(pskey)) {
        var psmap = global.prefixSetByLength[? pskey];
        if (ds_exists(psmap, ds_type_map)) {
            ds_map_destroy(psmap);
        }
        pskey = ds_map_find_next(global.prefixSetByLength, pskey);
    }
    ds_map_destroy(global.prefixSetByLength);
}

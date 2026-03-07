// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @function validate_grid()
/// @desc Validates the grid by checking every word horizontally and vertically.
function validate_grid() {
    // Check horizontal words
    for (var j = 0; j < obj_heartbeat.grid_height; j++) {
        var word = "";
        for (var i = 0; i < obj_heartbeat.grid_width; i++) {
            if (obj_heartbeat.grid[# i, j] != "" && obj_heartbeat.grid[# i, j] != "INVALID") {
                word += obj_heartbeat.grid[# i, j];
            } else {
                if (string_length(word) > 1 && !word_is_valid(word)) {
                    return false;  // Invalid word found
                }
                word = "";  // Reset the word
            }
        }
        if (string_length(word) > 1 && !word_is_valid(word)) {
            return false;  // Check the last word in the row
        }
    }

    // Check vertical words
    for (var i = 0; i < obj_heartbeat.grid_width; i++) {
        var word = "";
        for (var j = 0; j < obj_heartbeat.grid_height; j++) {
            if (obj_heartbeat.grid[# i, j] != "" && obj_heartbeat.grid[# i, j] != "INVALID") {
                word += obj_heartbeat.grid[# i, j];
            } else {
                if (string_length(word) > 1 && !word_is_valid(word)) {
                    return false;  // Invalid word found
                }
                word = "";  // Reset the word
            }
        }
        if (string_length(word) > 1 && !word_is_valid(word)) {
            return false;  // Check the last word in the column
        }
    }

    return true;  // All words are valid
}

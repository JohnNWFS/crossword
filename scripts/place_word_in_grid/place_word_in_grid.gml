// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @function place_word_in_grid(word, i, j)
/// @param word The word to place in the grid.
/// @param i The x-coordinate of the starting grid cell.
/// @param j The y-coordinate of the starting grid cell.
/// @desc Places the given word at the specified position in the grid.
function place_word_in_grid(word, i, j) {
    var orientation;
    
    // Determine orientation based on adjacent cells
    if (i > 0 && obj_heartbeat.grid[# i-1, j] != "" && i < obj_heartbeat.grid_width - 1 && obj_heartbeat.grid[# i+1, j] == "") {
        orientation = "horizontal";
    } else if (j > 0 && obj_heartbeat.grid[# i, j-1] != "" && j < obj_heartbeat.grid_height - 1 && obj_heartbeat.grid[# i, j+1] == "") {
        orientation = "vertical";
    } else {
        return;  // Cannot determine orientation, so exit the function
    }

    // Place the word in the grid based on the determined orientation
    for (var k = 0; k < string_length(word); k++) {
        var letter = string_char_at(word, k + 1);  // Get the k-th letter of the word
        
        if (orientation == "horizontal") {
            obj_heartbeat.grid[# i + k, j] = letter;
        } else if (orientation == "vertical") {
            obj_heartbeat.grid[# i, j + k] = letter;
        }
    }
}

function find_word_for_position(i, j) {
    var orientation;
    var maxLength;
    var currentLetter = obj_heartbeat.grid[# i, j];

    // Determine orientation based on available space
    if (i < obj_heartbeat.grid_width - 1 && obj_heartbeat.grid[# i+1, j] == "") {
        orientation = "horizontal";
        maxLength = obj_heartbeat.grid_width - i;  // Remaining space to the right
    } else if (j < obj_heartbeat.grid_height - 1 && obj_heartbeat.grid[# i, j+1] == "") {
        orientation = "vertical";
        maxLength = obj_heartbeat.grid_height - j;  // Remaining space below
    } else {
        return "";  // Cannot determine orientation, return empty string
    }

    // Search the word list for a suitable word
    for (var w = 0; w < ds_list_size(global.wordList); w++) {
        var word = global.wordList[| w];
        
        // Check word length
        if (string_length(word) <= maxLength) {
            return word;  // Return the first word that fits
        }
    }

    return "";  // No suitable word found
}

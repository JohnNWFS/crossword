// Check if a word can be placed at a specific position without any conflicts
function can_place_word(word, posX, posY, direction) {
    var wordLength = string_length(word);

    // Check bounds and existing letters for horizontal placement
    if (direction == "horizontal") {
        if (posX + wordLength > obj_heartbeat.grid_width) {
            return false;
        }
        for (var i = 0; i < wordLength; i++) {
            if (obj_heartbeat.grid[# posX + i, posY] != "" && obj_heartbeat.grid[# posX + i, posY] != string_char_at(word, i + 1)) {
                return false;
            }
        }
    }

    // Check bounds and existing letters for vertical placement
    if (direction == "vertical") {
        if (posY + wordLength > obj_heartbeat.grid_height) {
            return false;
        }
        for (var i = 0; i < wordLength; i++) {
            if (obj_heartbeat.grid[# posX, posY + i] != "" && obj_heartbeat.grid[# posX, posY + i] != string_char_at(word, i + 1)) {
                return false;
            }
        }
    }

    return true;
}
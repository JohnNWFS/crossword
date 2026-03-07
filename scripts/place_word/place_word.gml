// Place a word at a specific position in the grid
function place_word(word, posX, posY, direction) {
    var wordLength = string_length(word);

    if (direction == "horizontal") {
        for (var i = 0; i < wordLength; i++) {
            obj_heartbeat.grid[# posX + i, posY] = string_char_at(word, i + 1);
        }
    }

    if (direction == "vertical") {
        for (var i = 0; i < wordLength; i++) {
            obj_heartbeat.grid[# posX, posY + i] = string_char_at(word, i + 1);
        }
    }
}
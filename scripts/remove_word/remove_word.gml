// Remove a word from a specific position in the grid
function remove_word(word, posX, posY, direction) {
    var wordLength = string_length(word);

    if (direction == "horizontal") {
        for (var i = 0; i < wordLength; i++) {
            obj_heartbeat.grid[# posX + i, posY] = "";
        }
    }

    if (direction == "vertical") {
        for (var i = 0; i < wordLength; i++) {
            obj_heartbeat.grid[# posX, posY + i] = "";
        }
    }
}
// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @function word_is_valid(word)
/// @param word The word to check.
/// @desc Returns true if the word is in the word list, false otherwise.
function word_is_valid(word) {
    var _target = string_upper(word);
    for (var _i = 0; _i < ds_list_size(global.wordList); _i++) {
        if (string_upper(global.wordList[| _i]) == _target) {
            return true;
        }
    }
    return false;
}

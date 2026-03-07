// Mouse Left Button Pressed Event for obj_step3_repair
var changed = crossword_step3_repair_failed_across();
if (changed) {
    show_debug_message("[Repair] Step 3 applied replacements.");
} else {
    show_debug_message("[Repair] Step 3 found no improving replacements.");
}
crossword_export_word_lists();

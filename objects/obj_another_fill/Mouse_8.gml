// Mouse Right Button Pressed Event for obj_another_fill
var changed = crossword_step3_repair_failed_across();
if (changed) {
    show_debug_message("[Repair] Step 3 applied replacements (from Step 2 button RMB).");
} else {
    show_debug_message("[Repair] Step 3 found no improving replacements (from Step 2 button RMB).");
}
crossword_export_word_lists();

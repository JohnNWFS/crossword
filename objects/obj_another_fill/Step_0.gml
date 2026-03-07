// Step Event for obj_another_fill
if (mouse_check_button_pressed(mb_right)) {
    if (point_in_rectangle(mouse_x, mouse_y, bbox_left, bbox_top, bbox_right, bbox_bottom)) {
        var changed = crossword_step3_repair_failed_across();
        if (changed) {
            show_debug_message("[Repair] Step 3 applied replacements (RMB on Step 2).");
        } else {
            show_debug_message("[Repair] Step 3 found no improving replacements (RMB on Step 2).");
        }
        crossword_export_word_lists();
    }
}

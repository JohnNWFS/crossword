// Mouse Left Button Pressed Event for obj_saveButton

var hb = instance_find(obj_heartbeat, 0);
if (hb == noone) {
    show_debug_message("[Crossword] Cannot save: heartbeat instance missing");
    exit;
}

var default_name = "template_" + string(hb.grid_width);
if (hb.current_template_name != "") {
    default_name = hb.current_template_name;
}

hb.template_dialog_action = "save";
hb.template_dialog_request_id = get_string_async("Template name to save:", default_name);

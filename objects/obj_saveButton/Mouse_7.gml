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

var template_name = get_string("Template name to save:", default_name);
if (template_name == "") {
    hb.set_status("Save cancelled");
    exit;
}

hb.save_template(template_name);

// Mouse Left Button Pressed Event for obj_loadButton

var hb = instance_find(obj_heartbeat, 0);
if (hb == noone) {
    show_debug_message("[Crossword] Cannot load: heartbeat instance missing");
    exit;
}

var default_name = hb.current_template_name;
if (default_name == "") {
    default_name = "template_" + string(hb.grid_width);
}

hb.template_dialog_action = "load";
hb.template_dialog_request_id = get_string_async("Template name to load:", default_name);

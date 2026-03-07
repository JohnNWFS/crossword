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

var template_name = get_string("Template name to load:", default_name);
if (template_name == "") {
    hb.set_status("Load cancelled");
    exit;
}

hb.load_template(template_name);

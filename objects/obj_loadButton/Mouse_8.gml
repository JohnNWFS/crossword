// Mouse Right Button Pressed Event for obj_loadButton

var hb = instance_find(obj_heartbeat, 0);
if (hb == noone) {
    show_debug_message("[Crossword] Cannot open template list: heartbeat instance missing");
    exit;
}

hb.refresh_template_name_list();
hb.template_list_overlay_active = true;
hb.set_status("Template picker open (right-click Load Template)");

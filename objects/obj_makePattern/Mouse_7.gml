// Mouse Left Button Pressed Event for obj_makePattern
var hb = instance_find(obj_heartbeat, 0);
if (hb == noone) {
    show_debug_message("[Crossword] Cannot build pattern: heartbeat instance missing");
    exit;
}

hb.build_realistic_block_pattern();

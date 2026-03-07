// Mouse Left Button Pressed Event for obj_stopFill
if (obj_heartbeat.solver_active) {
    crossword_solver_stop(false);
    obj_heartbeat.status_text = "Solver stopped";
    show_debug_message("[Visual] Solver stopped by user.");
} else {
    obj_heartbeat.status_text = "Solver is not running";
}

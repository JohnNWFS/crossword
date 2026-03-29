// Async - Dialog Event for obj_heartbeat
if (!ds_exists(async_load, ds_type_map)) exit;

var req_id = -1;
if (ds_map_exists(async_load, "id")) req_id = async_load[? "id"];

// Template save/load prompts
if (req_id == template_dialog_request_id) {
    template_dialog_request_id = -1;

    var status_ok = true;
    if (ds_map_exists(async_load, "status")) {
        status_ok = async_load[? "status"];
    }

    if (!status_ok) {
        if (template_dialog_action == "save") set_status("Save cancelled");
        else if (template_dialog_action == "load") set_status("Load cancelled");
        template_dialog_action = "";
        exit;
    }

    var value = "";
    if (ds_map_exists(async_load, "result")) value = string(async_load[? "result"]);
    if (value == "") {
        if (template_dialog_action == "save") set_status("Save cancelled");
        else if (template_dialog_action == "load") set_status("Load cancelled");
        template_dialog_action = "";
        exit;
    }

    if (template_dialog_action == "save") {
        save_template(value);
    } else if (template_dialog_action == "load") {
        load_template(value);
    }

    template_dialog_action = "";
    exit;
}

// Mobile cell-entry prompt
if (req_id == cell_dialog_request_id) {
    cell_dialog_request_id = -1;

    var ok = true;
    if (ds_map_exists(async_load, "status")) {
        ok = async_load[? "status"];
    }

    if (!ok) {
        set_status("Cell entry cancelled");
        exit;
    }

    var s = "";
    if (ds_map_exists(async_load, "result")) s = string(async_load[? "result"]);

    if (cell_dialog_col < 0 || cell_dialog_row < 0 || cell_dialog_col >= grid_width || cell_dialog_row >= grid_height) {
        set_status("Cell entry ignored (out of range)");
        exit;
    }

    if (grid[# cell_dialog_col, cell_dialog_row] == "INVALID") {
        set_status("Cell entry ignored (block)");
        exit;
    }

    if (s == "" || string_char_at(s, 1) == " ") {
        grid[# cell_dialog_col, cell_dialog_row] = "";
        set_status("Cell cleared at (" + string(cell_dialog_col + 1) + "," + string(cell_dialog_row + 1) + ")");
        exit;
    }

    var ch = string_char_at(s, 1);
    grid[# cell_dialog_col, cell_dialog_row] = ch;
    set_status("Cell set at (" + string(cell_dialog_col + 1) + "," + string(cell_dialog_row + 1) + ")");
    exit;
}

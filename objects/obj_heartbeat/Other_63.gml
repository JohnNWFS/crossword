// Async - Dialog Event for obj_heartbeat
if (!ds_exists(async_load, ds_type_map)) exit;

var req_id = -1;
if (ds_map_exists(async_load, "id")) req_id = async_load[? "id"];
if (req_id != template_dialog_request_id) exit;

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

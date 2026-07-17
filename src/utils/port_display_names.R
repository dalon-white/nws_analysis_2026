 add_port_display_names <- function(data, port_col, port_ref = port_reference_path) {
    source("src/utils/parameters.R")
    port_reference <- readxl::read_excel(port_reference_path)
    data |> left_join(port_reference |> dplyr::select(port, name), by = "port") |>
    rename(port_display = name)
 }

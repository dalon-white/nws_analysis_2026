normalize_state_name <- function(x) {
    x |>
        stringi::stri_trans_general("Latin-ASCII") |>
        stringr::str_to_lower() |>
        stringr::str_replace_all("[^a-z0-9]+", " ") |>
        stringr::str_squish()
}

# Canonicalize frequent long-form INEGI and alternate labels to a single state key.
canonicalize_mexico_state <- function(x) {
    x_norm <- normalize_state_name(x)

    dplyr::case_when(
        x_norm == "coahuila de zaragoza" ~ "coahuila",
        x_norm == "michoacan de ocampo" ~ "michoacan",
        x_norm == "veracruz de ignacio de la llave" ~ "veracruz",
        x_norm == "mexico" ~ "estado de mexico",
        x_norm == "distrito federal" ~ "ciudad de mexico",
        TRUE ~ x_norm
    )
}
match_georeference <- function(
    data,
    georeference,
    data_state_col = "State",
    data_municipality_col = "Municipality",
    geo_state_col = "NOMGEO",
    geo_municipality_col = "NOMMUN",
    geo_id_col = "CVEGEO",
    verbose = TRUE
) {
    data_cols <- colnames(data)
    .geo_id <- .state_geo <- .municipality_geo <- NULL
    use_state <- !is.null(data_state_col) && !is.null(geo_state_col)
    use_municipality <- !is.null(data_municipality_col) && !is.null(geo_municipality_col)

    if (!use_state && !use_municipality) {
        stop("Provide state columns, municipality columns, or both for matching.")
    }

    data_state_sym <- if (use_state) rlang::sym(data_state_col) else NULL
    data_municipality_sym <- if (use_municipality) rlang::sym(data_municipality_col) else NULL
    geo_state_sym <- if (use_state) rlang::sym(geo_state_col) else NULL
    geo_municipality_sym <- if (use_municipality) rlang::sym(geo_municipality_col) else NULL
    geo_id_sym <- rlang::sym(geo_id_col)
    join_cols <- c()
    if (use_state) {
        join_cols <- c(join_cols, ".state_input" = ".state_geo")
    }
    if (use_municipality) {
        join_cols <- c(join_cols, ".municipality_input" = ".municipality_geo")
    }

    required_data_cols <- c(
        if (use_state) data_state_col,
        if (use_municipality) data_municipality_col
    )
    required_geo_cols <- c(
        if (use_state) geo_state_col,
        if (use_municipality) geo_municipality_col,
        geo_id_col
    )

    missing_data_cols <- setdiff(required_data_cols, colnames(data))
    missing_geo_cols <- setdiff(required_geo_cols, colnames(georeference))

    if (length(missing_data_cols) > 0) {
        stop("Missing required data columns: ", paste(missing_data_cols, collapse = ", "))
    }

    if (length(missing_geo_cols) > 0) {
        stop("Missing required georeference columns: ", paste(missing_geo_cols, collapse = ", "))
    }

    data_prepped <- data
    if (use_state) {
        data_prepped <- data_prepped |>
            dplyr::mutate(.state_input = !!data_state_sym)
    }
    if (use_municipality) {
        data_prepped <- data_prepped |>
            dplyr::mutate(.municipality_input = !!data_municipality_sym)
    }

    georeference_prepped <- georeference |>
        dplyr::mutate(.geo_id = !!geo_id_sym)
    if (use_state) {
        georeference_prepped <- georeference_prepped |>
            dplyr::mutate(.state_geo = !!geo_state_sym)
    }
    if (use_municipality) {
        georeference_prepped <- georeference_prepped |>
            dplyr::mutate(.municipality_geo = !!geo_municipality_sym)
    }

    georeference_prepped <- georeference_prepped |>
        dplyr::distinct(!!!rlang::syms(unname(join_cols)), .keep_all = TRUE)

    data_geo <- data_prepped |>
        dplyr::left_join(
            georeference_prepped,
            by = join_cols
        )

    unknown_locations <- data_geo |>
        dplyr::filter(is.na(.geo_id)) |>
        dplyr::select(dplyr::all_of(data_cols))

    georeference_plain <- georeference_prepped
    plain_join_cols <- c()

    if (use_state) {
        unknown_locations <- unknown_locations |>
            dplyr::mutate(
                State_plain = stringi::stri_trans_general(!!data_state_sym, "Latin-ASCII")
            )
        georeference_plain <- georeference_plain |>
            dplyr::mutate(
                NOMGEO_plain = stringi::stri_trans_general(.state_geo, "Latin-ASCII")
            )
        plain_join_cols <- c(plain_join_cols, "State_plain" = "NOMGEO_plain")
    }
    if (use_municipality) {
        unknown_locations <- unknown_locations |>
            dplyr::mutate(
                Municipality_plain = stringi::stri_trans_general(!!data_municipality_sym, "Latin-ASCII")
            )
        georeference_plain <- georeference_plain |>
            dplyr::mutate(
                NOMMUN_plain = stringi::stri_trans_general(.municipality_geo, "Latin-ASCII")
            )
        plain_join_cols <- c(plain_join_cols, "Municipality_plain" = "NOMMUN_plain")
    }

    data_geo_plain <- unknown_locations |>
        dplyr::left_join(
            georeference_plain,
            by = plain_join_cols
        )

    if (isTRUE(verbose)) {
        cat("Unmatched locations after plain text join:\n")
        count_cols <- c(
            if (use_state) data_state_col,
            if (use_municipality) data_municipality_col
        )
        print(
            data_geo_plain |>
                dplyr::filter(is.na(.geo_id)) |>
                dplyr::count(
                    dplyr::across(dplyr::all_of(count_cols)),
                    sort = TRUE,
                    name = "n"
                )
        )
    }

    data_geo_plain <- data_geo_plain |>
        dplyr::filter(!is.na(.geo_id)) |>
        dplyr::select(-dplyr::any_of(c("Municipality_plain", "State_plain")))

    dplyr::bind_rows(
        data_geo |> dplyr::filter(!is.na(.geo_id)),
        data_geo_plain
    ) |>
        dplyr::select(-dplyr::any_of(c(".state_input", ".municipality_input", ".state_geo", ".municipality_geo", ".geo_id")))
}

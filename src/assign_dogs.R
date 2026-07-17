# Assign dogs as risk chunks to ports based on risk values


#identify the number of chunks, ie dogs to be distributed
source("src/utils/parameters.R")
risk_chunks <- n_dogs

#provide a function to assign risk chunks to ports based on risk values
assign_risk_chunks <- function(data, risk_columns, total_chunks, year = "year", by_year = TRUE) {
    missing_cols <- setdiff(risk_columns, colnames(data))
    if (length(missing_cols) > 0) {
        stop(paste("Columns not found in the data frame:", paste(missing_cols, collapse = ", ")))
    }

    results <- vector("list", length(risk_columns))
    names(results) <- risk_columns

    # determine if user wants results for each year, or to otherwise sum across years/years are not included.
    if(!by_year){
        data <- data |> dplyr::group_by(port) |> dplyr::summarise(across(all_of(risk_columns), ~sum(.x, na.rm = TRUE)), .groups = "drop")
    } else if (!is.character(year) || length(year) != 1 || !year %in% colnames(data)) {
        stop("by_year indicates you want to group by year, but the provide column name of year is not in the data frame. The 'year' argument must be a column name in the data frame. Turn off by_year (by_year = FALSE) or provide a valid column name for year.")
    }

    for (risk_col in risk_columns) {
        risk_data <- if (by_year) {
            data |> dplyr::group_by(.data[[year]])
        } else {
            data
        }

        results[[risk_col]] <- risk_data |>
            mutate(
                risk_share = (.data[[risk_col]]) / sum((.data[[risk_col]]), na.rm = TRUE),
                raw_chunks = risk_share * total_chunks,
                chunks_floor = floor(raw_chunks),
                remainder = raw_chunks - chunks_floor
            ) |>
            arrange(desc(remainder), desc(.data[[risk_col]])) |>
            mutate(
                remainder_rank = row_number(),
                extra_chunks_needed = total_chunks - sum(chunks_floor),
                extra_chunk = as.integer(remainder_rank <= extra_chunks_needed),
                chunks_assigned = chunks_floor + extra_chunk
            ) |>
            dplyr::ungroup()

        if (by_year) {
            results[[risk_col]] <- results[[risk_col]] |>
                dplyr::select(port, all_of(year), risk_value = all_of(risk_col), risk_share, chunks_assigned) |>
                arrange(.data[[year]], desc(chunks_assigned), desc(risk_value))
        } else {
            results[[risk_col]] <- results[[risk_col]] |>
                dplyr::select(port, risk_value = all_of(risk_col), risk_share, chunks_assigned) |>
                arrange(desc(chunks_assigned), desc(risk_value))
        }
    }

    results
}

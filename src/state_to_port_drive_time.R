#!/usr/bin/env Rscript

suppressPackageStartupMessages({
	library(here)
	library(dplyr)
	library(tidyr)
	library(purrr)
	library(readr)
	library(readxl)
	library(stringr)
	library(sf)
})

source(here("src", "normalize_state_names.R"))

normalize_port_key <- function(x) {
	x |>
		stringr::str_to_lower() |>
		stringr::str_replace_all("[^a-z0-9]+", "_") |>
		stringr::str_replace_all("^_+|_+$", "")
}

copy_file_windows <- function(src, dst) {
	if (.Platform$OS.type != "windows") {
		return(FALSE)
	}

	escape_single_quote <- function(x) {
		gsub("'", "''", x, fixed = TRUE)
	}

	cmd <- paste0(
		"Copy-Item -LiteralPath '",
		escape_single_quote(src),
		"' -Destination '",
		escape_single_quote(dst),
		"' -Force"
	)

	status <- suppressWarnings(
		system2(
			"powershell",
			c("-NoProfile", "-Command", cmd),
			stdout = FALSE,
			stderr = FALSE
		)
	)

	isTRUE(status == 0) &&
		file.exists(dst) &&
		!is.na(file.info(dst)$size) &&
		file.info(dst)$size > 0
}

safe_read_excel <- function(path) {
	tryCatch(
		readxl::read_excel(path),
		error = function(e) {
			tmp_path <- tempfile(pattern = "port_reference_", fileext = ".xlsx")
			ok <- suppressWarnings(file.copy(path, tmp_path, overwrite = TRUE))

			if (!isTRUE(ok) || !file.exists(tmp_path) || is.na(file.info(tmp_path)$size) || file.info(tmp_path)$size == 0) {
				ok <- copy_file_windows(path, tmp_path)
			}

			if (!ok) {
				stop("Could not read workbook and failed to copy to temp path: ", path)
			}
			readxl::read_excel(tmp_path)
		}
	)
}

build_state_centroids <- function(states_geo_path) {
	readRDS(states_geo_path) |>
		st_as_sf() |>
		st_transform(4326) |>
		mutate(state_join = canonicalize_mexico_state(NOMGEO)) |>
		group_by(state_join) |>
		summarise(geometry = st_union(geometry), .groups = "drop") |>
		st_point_on_surface() |>
		mutate(
			state_lon = st_coordinates(geometry)[, 1],
			state_lat = st_coordinates(geometry)[, 2]
		) |>
		st_drop_geometry() |>
		select(state_join, state_lon, state_lat)
}

port_coordinate_fallback <- function() {
	tibble::tribble(
		~port, ~fallback_lon, ~fallback_lat,
		"colombia", -99.50, 27.58,
		"columbus", -107.64, 31.83,
		"del_rio", -100.90, 29.37,
		"douglas", -109.55, 31.34,
		"eagle_pass", -100.50, 28.71,
		"laredo", -99.49, 27.53,
		"nogales", -110.94, 31.34,
		"pharr", -98.18, 26.19,
		"presidio", -104.37, 29.56,
		"santa_teresa", -106.68, 31.85
	)
}

resolve_port_coordinates <- function(port_reference) {
	ports <- port_reference |>
		transmute(
			port = normalize_port_key(port),
			port_name = as.character(name),
			port_lon = suppressWarnings(as.numeric(lon)),
			port_lat = suppressWarnings(as.numeric(lat))
		) |>
		distinct(port, .keep_all = TRUE) |>
		left_join(port_coordinate_fallback(), by = "port") |>
		mutate(
			port_lon = coalesce(port_lon, fallback_lon),
			port_lat = coalesce(port_lat, fallback_lat)
		) |>
		select(port, port_name, port_lon, port_lat)

	if (requireNamespace("tidygeocoder", quietly = TRUE)) {
		missing_idx <- which(is.na(ports$port_lon) | is.na(ports$port_lat))
		if (length(missing_idx) > 0) {
			to_geocode <- ports[missing_idx, ] |>
				mutate(
					query = if_else(
						!is.na(port_name) & nzchar(port_name),
						port_name,
						port
					)
				)

			geocoded <- tryCatch(
				tidygeocoder::geo(
					to_geocode,
					address = query,
					method = "osm",
					lat = geo_lat,
					long = geo_lon,
					full_results = FALSE,
					quiet = TRUE
				),
				error = function(e) NULL
			)

			if (!is.null(geocoded)) {
				ports <- ports |>
					left_join(
						geocoded |>
							select(port, geo_lon, geo_lat),
						by = "port"
					) |>
					mutate(
						port_lon = coalesce(port_lon, geo_lon),
						port_lat = coalesce(port_lat, geo_lat)
					) |>
					select(port, port_name, port_lon, port_lat)
			}
		}
	}

	unresolved <- ports |>
		filter(is.na(port_lon) | is.na(port_lat))

	if (nrow(unresolved) > 0) {
		stop(
			"Missing coordinates for ports: ",
			paste(unresolved$port, collapse = ", "),
			". Add coordinates in data/raw/port of entry reference table.xlsx or fallback lookup."
		)
	}

	ports
}

extract_route_metrics <- function(route_obj) {
	if (is.numeric(route_obj) && !is.null(names(route_obj))) {
		dist_name <- intersect(c("distance", "dist", "distance_km"), names(route_obj))
		dur_name <- intersect(c("duration", "time", "duration_min"), names(route_obj))
		if (length(dist_name) == 0 || length(dur_name) == 0) {
			return(tibble(distance_km = NA_real_, drive_time_min = NA_real_))
		}
		return(tibble(
			distance_km = suppressWarnings(as.numeric(route_obj[[dist_name[1]]])),
			drive_time_min = suppressWarnings(as.numeric(route_obj[[dur_name[1]]]))
		))
	}

	if (inherits(route_obj, "sf")) {
		dist_val <- suppressWarnings(as.numeric(route_obj$distance[1]))
		dur_val <- suppressWarnings(as.numeric(route_obj$duration[1]))
		return(tibble(distance_km = dist_val, drive_time_min = dur_val))
	}

	if (is.data.frame(route_obj)) {
		dist_col <- intersect(c("distance", "dist", "distance_km"), names(route_obj))
		dur_col <- intersect(c("duration", "time", "duration_min"), names(route_obj))
		if (length(dist_col) == 0 || length(dur_col) == 0) {
			return(tibble(distance_km = NA_real_, drive_time_min = NA_real_))
		}
		return(tibble(
			distance_km = suppressWarnings(as.numeric(route_obj[[dist_col[1]]][1])),
			drive_time_min = suppressWarnings(as.numeric(route_obj[[dur_col[1]]][1]))
		))
	}

	tibble(distance_km = NA_real_, drive_time_min = NA_real_)
}

safe_osrm_route <- function(src_lon, src_lat, dst_lon, dst_lat, retries = 3) {
	for (attempt in seq_len(retries)) {
		route_obj <- tryCatch(
			osrm::osrmRoute(
				src = c(src_lon, src_lat),
				dst = c(dst_lon, dst_lat),
				overview = FALSE
			),
			error = function(e) e
		)

		if (!inherits(route_obj, "error")) {
			metrics <- extract_route_metrics(route_obj)
			if (!is.na(metrics$distance_km[1]) && !is.na(metrics$drive_time_min[1])) {
				return(metrics |>
					mutate(route_status = "ok"))
			}
		}

		Sys.sleep(0.25 * attempt)
	}

	tibble(
		distance_km = NA_real_,
		drive_time_min = NA_real_,
		route_status = "failed"
	)
}

haversine_km <- function(lon1, lat1, lon2, lat2) {
	to_rad <- pi / 180
	dlon <- (lon2 - lon1) * to_rad
	dlat <- (lat2 - lat1) * to_rad
	a <- sin(dlat / 2)^2 +
		cos(lat1 * to_rad) * cos(lat2 * to_rad) * sin(dlon / 2)^2
	c <- 2 * atan2(sqrt(a), sqrt(1 - a))
	6371 * c
}

load_expected_pairs <- function() {
	rds_path <- here("data", "processed", "state_to_port_final.rds")
	csv_path <- here("data", "processed", "state_to_port_final.csv")

	if (file.exists(rds_path)) {
		stp <- readRDS(rds_path)
	} else {
		stp <- readr::read_csv(csv_path, show_col_types = FALSE)
	}

	stp |>
		transmute(
			state_join = canonicalize_mexico_state(state_join),
			port = normalize_port_key(port)
		) |>
		distinct()
}

write_outputs <- function(route_tbl) {
	readr::write_csv(
		route_tbl,
		here("data", "processed", "state_port_drive_time.csv")
	)
	saveRDS(
		route_tbl,
		here("data", "processed", "state_port_drive_time.rds")
	)
	readr::write_csv(
		route_tbl,
		here("outputs", "tables", "state_port_drive_time.csv")
	)

	# Compatibility output used by 20260715_limited_port_openings.Rmd.
	legacy_tbl <- route_tbl |>
		select(state_join, port, distance_guess_km)

	readr::write_csv(
		legacy_tbl,
		here("data", "processed", "state_port_distance_placeholder.csv")
	)
	readr::write_csv(
		legacy_tbl,
		here("outputs", "tables", "state_port_distance_placeholder.csv")
	)
}

main <- function() {
	if (!requireNamespace("osrm", quietly = TRUE)) {
		stop("Package 'osrm' is required. Install with install.packages('osrm').")
	}

	states_geo_path <- here("data", "processed", "mexico_states_geo.rds")
	port_reference_path <- here("data", "raw", "port of entry reference table.xlsx")

	expected_pairs <- load_expected_pairs()
	state_centroids <- build_state_centroids(states_geo_path)
	port_reference <- safe_read_excel(port_reference_path)
	ports <- resolve_port_coordinates(port_reference)

	route_inputs <- expected_pairs |>
		left_join(state_centroids, by = "state_join") |>
		left_join(ports, by = "port")

	missing_inputs <- route_inputs |>
		filter(
			is.na(state_lon) |
				is.na(state_lat) |
				is.na(port_lon) |
				is.na(port_lat)
		)

	if (nrow(missing_inputs) > 0) {
		stop(
			"Missing route coordinates after joins for one or more state/port pairs. ",
			"First few missing rows: ",
			paste(utils::capture.output(print(head(missing_inputs, 5))), collapse = " ")
		)
	}

	drive_tbl <- pmap_dfr(
		route_inputs,
		function(state_join, port, state_lon, state_lat, port_name, port_lon, port_lat) {
			metrics <- safe_osrm_route(
				src_lon = state_lon,
				src_lat = state_lat,
				dst_lon = port_lon,
				dst_lat = port_lat
			)

			tibble(
				state_join = state_join,
				port = port,
				port_name = port_name,
				state_lon = state_lon,
				state_lat = state_lat,
				port_lon = port_lon,
				port_lat = port_lat,
				distance_km = metrics$distance_km,
				drive_time_min = metrics$drive_time_min,
				route_status = metrics$route_status
			)
		}
	) |>
			mutate(
				gc_km = haversine_km(state_lon, state_lat, port_lon, port_lat),
				fallback_distance_km = round(pmax(25, (gc_km * 1.30) + 35), 2),
				fallback_drive_time_min = round((fallback_distance_km / 70) * 60, 2),
				distance_km = if_else(is.na(distance_km), fallback_distance_km, distance_km),
				drive_time_min = if_else(is.na(drive_time_min), fallback_drive_time_min, drive_time_min),
				route_status = if_else(route_status == "ok", "ok", "fallback_gc"),
				distance_guess_km = distance_km
			) |>
		select(
			state_join,
			port,
			distance_guess_km,
			drive_time_min,
			distance_km,
			route_status,
			state_lon,
			state_lat,
			port_lon,
			port_lat,
			port_name,
			gc_km
		)

	fallback_routes <- drive_tbl |>
		filter(route_status == "fallback_gc")

	missing_routes <- drive_tbl |>
		filter(is.na(distance_guess_km) | is.na(drive_time_min))

	if (nrow(fallback_routes) > 0) {
		message(
			"Used geodesic fallback for ", nrow(fallback_routes),
			" state/port pairs where OSRM did not return a route."
		)
	}

	if (nrow(missing_routes) > 0) {
		warning(
			"Some routes still have missing values after fallback. Missing rows: ",
			nrow(missing_routes)
		)
	}

	write_outputs(drive_tbl)

	message(
		"Wrote state-to-port drive-time tables. Rows: ", nrow(drive_tbl),
		"; osrm_ok: ", sum(drive_tbl$route_status == "ok"),
		"; fallback: ", sum(drive_tbl$route_status == "fallback_gc"),
		"; missing: ", nrow(missing_routes)
	)
}

if (!interactive()) {
	main()
}

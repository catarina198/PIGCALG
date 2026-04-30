## Funcoes extraidas de main_script_original_v2.R

## # - CRIAR DONNUTS ####
criar_donuts_valor_chave <- function(
  tipo_valor_chave,
  shp_aglomerados_base,
  shp_valor_natural_base,
  shp_valor_economico_base,
  shp_aglomerados_0_100,
  shp_aglomerados_100_500,
  shp_aglomerados_500_1000,
  shp_valor_natural_0_100,
  shp_valor_natural_100_500,
  shp_valor_natural_500_1000,
  shp_valor_economico_0_100,
  shp_valor_economico_100_500,
  shp_valor_economico_500_1000
) {
  print("funcao criar_donuts_valor_chave iniciou")
  on.exit(print("funcao criar_donuts_valor_chave terminou"), add = TRUE)

  if (tipo_valor_chave == "aglomerados") {
    shp_valor_chave_base <- shp_aglomerados_base
    shp_valor_chave_0_100 <- shp_aglomerados_0_100
    shp_valor_chave_100_500 <- shp_aglomerados_100_500
    shp_valor_chave_500_1000 <- shp_aglomerados_500_1000
  } else if (tipo_valor_chave == "valor_natural") {
    shp_valor_chave_base <- shp_valor_natural_base
    shp_valor_chave_0_100 <- shp_valor_natural_0_100
    shp_valor_chave_100_500 <- shp_valor_natural_100_500
    shp_valor_chave_500_1000 <- shp_valor_natural_500_1000
  } else if (tipo_valor_chave == "valor_economico") {
    shp_valor_chave_base <- shp_valor_economico_base
    shp_valor_chave_0_100 <- shp_valor_economico_0_100
    shp_valor_chave_100_500 <- shp_valor_economico_100_500
    shp_valor_chave_500_1000 <- shp_valor_economico_500_1000
  } else {
    stop("tipo_valor_chave invalido.")
  }

  pairwise_difference <- function(x, y) {
    if (length(x) != length(y)) {
      stop("x e y tem comprimentos diferentes.")
    }

    geoms <- lapply(seq_along(x), function(i) {
      st_difference(x[i], y[i])[[1]]
    })

    st_sfc(geoms, crs = st_crs(x))
  }

  dir.create(dirname(shp_valor_chave_0_100), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(shp_valor_chave_100_500), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(shp_valor_chave_500_1000), recursive = TRUE, showWarnings = FALSE)

  valor_chave <- st_read(shp_valor_chave_base, quiet = TRUE)
  if (tipo_valor_chave == "aglomerados") {
    if (!"TIPO_p" %in% names(valor_chave)) {
      stop("Falta coluna obrigatoria TIPO_p em shp_aglomerados_base.", call. = FALSE)
    }

    tipo_p_raw <- valor_chave$TIPO_p
    tipo_p_num <- suppressWarnings(as.integer(as.character(tipo_p_raw)))
    idx_invalid <- is.na(tipo_p_num) | !(tipo_p_num %in% c(1L, 2L, 3L))

    if (any(idx_invalid)) {
      invalid_values <- unique(as.character(tipo_p_raw[idx_invalid]))
      invalid_values <- invalid_values[!is.na(invalid_values) & nzchar(invalid_values)]
      invalid_txt <- if (length(invalid_values) > 0) {
        paste(invalid_values, collapse = ", ")
      } else {
        "<NA>"
      }
      stop(
        paste0(
          "TIPO_p invalido em shp_aglomerados_base. Valores permitidos: 1, 2, 3. ",
          "Valores encontrados: ",
          invalid_txt
        ),
        call. = FALSE
      )
    }

    valor_chave$.__d1 <- ifelse(tipo_p_num == 2L, 50, 100)
  } else {
    valor_chave$.__d1 <- 100
  }

  valor_chave$fid_u <- seq_len(nrow(valor_chave))
  valor_chave <- valor_chave[order(valor_chave$fid_u), ]
  d1_dist <- as.numeric(valor_chave$.__d1)
  valor_chave <- valor_chave[, "fid_u", drop = FALSE]

  geom_valor_chave <- st_geometry(valor_chave)
  gc()

  buffer_d1 <- st_sfc(
    lapply(seq_along(geom_valor_chave), function(i) {
      st_buffer(geom_valor_chave[i], dist = d1_dist[i], nQuadSegs = 5)[[1]]
    }),
    crs = st_crs(geom_valor_chave)
  )
  buffer_500m <- st_buffer(geom_valor_chave, dist = 500, nQuadSegs = 5)
  buffer_1000m <- st_buffer(geom_valor_chave, dist = 1000, nQuadSegs = 5)

  valor_chave_0_100 <- pairwise_difference(buffer_d1, geom_valor_chave)
  valor_chave_100_500 <- pairwise_difference(buffer_500m, buffer_d1)
  valor_chave_500_1000 <- pairwise_difference(buffer_1000m, buffer_500m)

  resultado_valor_chave_0_100 <- st_sf(fid_u = valor_chave$fid_u, geometry = valor_chave_0_100)
  resultado_valor_chave_100_500 <- st_sf(fid_u = valor_chave$fid_u, geometry = valor_chave_100_500)
  resultado_valor_chave_500_1000 <- st_sf(fid_u = valor_chave$fid_u, geometry = valor_chave_500_1000)

  st_write(resultado_valor_chave_0_100, shp_valor_chave_0_100, delete_layer = TRUE, quiet = TRUE)
  print(paste0("st_write shp_valor_chave_0_100: ", normalizePath(shp_valor_chave_0_100, winslash = "/", mustWork = FALSE)))
  st_write(resultado_valor_chave_100_500, shp_valor_chave_100_500, delete_layer = TRUE, quiet = TRUE)
  print(paste0("st_write shp_valor_chave_100_500: ", normalizePath(shp_valor_chave_100_500, winslash = "/", mustWork = FALSE)))
  st_write(resultado_valor_chave_500_1000, shp_valor_chave_500_1000, delete_layer = TRUE, quiet = TRUE)
  print(paste0("st_write shp_valor_chave_500_1000: ", normalizePath(shp_valor_chave_500_1000, winslash = "/", mustWork = FALSE)))

  rm(
    buffer_d1, buffer_500m, buffer_1000m,
    valor_chave_0_100, valor_chave_100_500, valor_chave_500_1000,
    resultado_valor_chave_0_100, resultado_valor_chave_100_500, resultado_valor_chave_500_1000,
    geom_valor_chave, d1_dist
  )
  gc()

  list(
    `0_100` = shp_valor_chave_0_100,
    `100_500` = shp_valor_chave_100_500,
    `500_1000` = shp_valor_chave_500_1000
  )
}

## # - UNIDADES DE TRATAMENTO ####
normalizar_poligonos <- function(x) {
  extrair_apenas_poligonos <- function(obj) {
    if (inherits(obj, "sf") && nrow(obj) == 0) return(obj)

    tipos <- unique(as.character(st_geometry_type(obj, by_geometry = TRUE)))
    tipos <- tipos[!is.na(tipos)]
    if (length(tipos) == 0) return(obj)

    if (all(tipos %in% c("POLYGON", "MULTIPOLYGON"))) {
      return(obj)
    }

    st_collection_extract(obj, "POLYGON", warn = FALSE)
  }

  # Evita que st_make_valid use snap de precisao herdado do objeto.
  x <- tryCatch(st_set_precision(x, 0), error = function(e) x)

  x <- tryCatch(
    st_make_valid(
      x,
      geos_method = "valid_structure",
      geos_keep_collapsed = FALSE
    ),
    error = function(e) st_make_valid(x)
  )
  x <- extrair_apenas_poligonos(x)
  x <- x[!st_is_empty(x), ]
  if (inherits(x, "sf") && nrow(x) == 0) return(x)
  x <- st_cast(x, "MULTIPOLYGON", warn = FALSE)

  # Nao aplicar snapping/quantizacao aqui: preserva a geometria original.
  x <- tryCatch(
    st_make_valid(
      x,
      geos_method = "valid_structure",
      geos_keep_collapsed = FALSE
    ),
    error = function(e) st_make_valid(x)
  )
  x <- extrair_apenas_poligonos(x)
  x <- x[!st_is_empty(x), ]
  x <- st_cast(x, "MULTIPOLYGON", warn = FALSE)
  x
}

layer_shp_interface_dissolve <- "shp_interface_dissolve"
layer_stands_interface_int <- "stands_interface_int"
layer_stands_interface_diss <- "stands_interface_diss"
layer_stands_interface_final <- "stands_interface_final"
layer_stands_erase_single <- "stands_erase_single"
layer_interface_diss_completa <- "interface_diss_completa"
layer_shp_aglomerados_base_sel <- "shp_aglomerados_base_sel"
layer_stands_aglom_int <- "stands_aglom_int"
layer_stands_aglom_int_diss <- "stands_aglom_int_diss"
layer_stands_sem_aglomerado <- "stands_sem_aglomerado"
layer_shp_stands_interface_edf <- "shp_stands_interface_edf"
layer_shp_stands_interface_final <- "stands_alg_interface_final"

vector_path_is_gdb <- function(path) {
  is.character(path) && length(path) == 1 && grepl("\\.gdb$", path, ignore.case = TRUE)
}

vector_layer_or_null <- function(path, layer_name) {
  if (vector_path_is_gdb(path)) layer_name else NULL
}

sanitize_sf_attributes_for_write <- function(sf_obj) {
  if (!inherits(sf_obj, "sf")) return(sf_obj)

  geom_col <- attr(sf_obj, "sf_column")
  if (!is.character(geom_col) || length(geom_col) != 1 || is.na(geom_col) || !nzchar(geom_col) || !(geom_col %in% names(sf_obj))) {
    geom_col <- tryCatch(st_geometry_name(sf_obj), error = function(e) NULL)
  }
  if (!is.character(geom_col) || length(geom_col) != 1 || is.na(geom_col) || !nzchar(geom_col) || !(geom_col %in% names(sf_obj))) {
    geom_candidates <- names(sf_obj)[vapply(sf_obj, function(x) inherits(x, "sfc"), logical(1))]
    if (length(geom_candidates) > 0) {
      geom_col <- geom_candidates[1]
    } else {
      geom_col <- character(0)
    }
  }

  attr_cols <- setdiff(names(sf_obj), geom_col)
  if (length(attr_cols) == 0) return(sf_obj)

  list_cols <- attr_cols[vapply(
    sf_obj[attr_cols],
    function(x) is.list(x) && !inherits(x, "sfc"),
    logical(1)
  )]
  if (length(list_cols) == 0) return(sf_obj)

  to_scalar_character <- function(x) {
    if (is.null(x) || length(x) == 0) return(NA_character_)
    if (is.list(x)) x <- unlist(x, recursive = TRUE, use.names = FALSE)
    if (length(x) == 0) return(NA_character_)
    paste(as.character(x), collapse = "|")
  }

  for (col in list_cols) {
    sf_obj[[col]] <- vapply(sf_obj[[col]], to_scalar_character, character(1))
  }

  sf_obj
}

read_vector <- function(path, layer = NULL, quiet = TRUE) {
  if (vector_path_is_gdb(path)) {
    if (is.null(layer) || !nzchar(layer)) {
      stop("read_vector: para .gdb, o argumento layer e obrigatorio.")
    }
    return(st_read(path, layer = layer, quiet = quiet))
  }
  st_read(path, quiet = quiet)
}

write_vector <- function(sf_obj, path, layer = NULL, quiet = TRUE) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  sf_obj <- sanitize_sf_attributes_for_write(sf_obj)
  if (vector_path_is_gdb(path)) {
    if (is.null(layer) || !nzchar(layer)) {
      stop("write_vector: para .gdb, o argumento layer e obrigatorio.")
    }
    sf_out <- sf_obj
    sf_out <- tryCatch({
      tmp <- st_make_valid(sf_out)
      tmp <- st_zm(tmp, drop = TRUE, what = "ZM")
      tmp_poly <- suppressWarnings(st_collection_extract(tmp, "POLYGON", warn = FALSE))
      tmp_poly <- tmp_poly[!st_is_empty(tmp_poly), , drop = FALSE]
      if (nrow(tmp_poly) > 0) {
        tmp_poly <- st_cast(tmp_poly, "MULTIPOLYGON", warn = FALSE)
        tmp_poly
      } else {
        tmp
      }
    }, error = function(e) sf_out)
    ensure_openfilegdb_write_support()
    write_result <- st_write(
      sf_out,
      dsn = path,
      layer = layer,
      driver = "OpenFileGDB",
      delete_layer = TRUE,
      quiet = quiet
    )
    label_write <- if (!is.null(layer) && is.character(layer) && nzchar(layer)) layer else tools::file_path_sans_ext(basename(path))
    print(paste0("st_write ", label_write, ": ", normalizePath(path, winslash = "/", mustWork = FALSE)))
    return(write_result)
  }
  write_result <- st_write(sf_obj, path, delete_layer = TRUE, quiet = quiet)
  label_write <- tools::file_path_sans_ext(basename(path))
  print(paste0("st_write ", label_write, ": ", normalizePath(path, winslash = "/", mustWork = FALSE)))
  write_result
}

stands_interface <- function(
  shp_aglomerados_0_100 = shp_aglomerados_0_100,
  shp_stands_base = shp_stands_base,
  shp_interface_dissolve = shp_interface_dissolve,
  stands_interface_int = stands_interface_int,
  stands_interface_diss = stands_interface_diss,
  stands_interface_final = stands_interface_final,
  stands_erase_single = stands_erase_single,
  interface_diss_completa = interface_diss_completa,
  verbose = FALSE
) {
  print("funcao stands_interface iniciou")
  on.exit(print("funcao stands_interface terminou"), add = TRUE)

  quiet_mode <- !isTRUE(verbose)

  log_checkpoint <- function(msg) {
    print(paste0("[stands_interface] ", msg))
  }

  log_sf_diag <- function(label, sf_obj) {
    if (!inherits(sf_obj, "sf")) {
      log_checkpoint(
        paste0(
          label,
          " | tipo_objeto=",
          paste(class(sf_obj), collapse = ",")
        )
      )
      return(invisible(NULL))
    }

    n_feat <- tryCatch(nrow(sf_obj), error = function(e) NA_integer_)

    geom_types <- tryCatch(
      unique(as.character(st_geometry_type(sf_obj, by_geometry = TRUE))),
      error = function(e) character(0)
    )
    geom_types <- geom_types[!is.na(geom_types)]
    geom_txt <- if (length(geom_types) == 0) "<vazio>" else paste(sort(geom_types), collapse = ",")

    invalid_n <- tryCatch({
      valid_vec <- st_is_valid(sf_obj)
      sum(is.na(valid_vec) | !valid_vec)
    }, error = function(e) NA_integer_)

    log_checkpoint(
      paste0(
        label,
        " | nrow=",
        ifelse(is.na(n_feat), "NA", as.character(n_feat)),
        " | geom=",
        geom_txt,
        " | invalid=",
        ifelse(is.na(invalid_n), "NA", as.character(invalid_n))
      )
    )
  }

  run_checkpoint <- function(label, expr) {
    log_checkpoint(paste0(label, " iniciou"))
    res <- tryCatch(
      eval.parent(substitute(expr)),
      error = function(e) {
        stop(
          paste0("[stands_interface] ", label, " falhou: ", conditionMessage(e)),
          call. = FALSE
        )
      }
    )
    log_checkpoint(paste0(label, " terminou"))
    res
  }

  dir.create(dirname(shp_interface_dissolve), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(stands_interface_int), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(stands_interface_diss), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(stands_interface_final), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(stands_erase_single), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(interface_diss_completa), recursive = TRUE, showWarnings = FALSE)

  ## =========================================================
  ## 1) APLICAR MASCARA DE INTERFACE COM Local = 1
  ## =========================================================

  run_checkpoint("Bloco 1 - Mascara/interface dissolve", {
    shp_aglomerados_0_100_sf <- st_read(shp_aglomerados_0_100, quiet = quiet_mode)
    shp_aglomerados_0_100_sf <- tryCatch(st_set_precision(shp_aglomerados_0_100_sf, 0), error = function(e) shp_aglomerados_0_100_sf)
    shp_aglomerados_0_100_sf <- normalizar_poligonos(shp_aglomerados_0_100_sf)
    log_sf_diag("Bloco 1 - shp_aglomerados_0_100_sf", shp_aglomerados_0_100_sf)

    interface_diss <- st_union(shp_aglomerados_0_100_sf)
    shp_interface_dissolve_sf <- st_cast(interface_diss, "POLYGON")

    shp_interface_dissolve_sf <- st_as_sf(
      data.frame(Inter_ID = seq_along(shp_interface_dissolve_sf)),
      geometry = shp_interface_dissolve_sf
    )

    shp_interface_dissolve_sf$Interf_ha <- as.numeric(
      st_area(shp_interface_dissolve_sf)
    ) / 10000
    log_sf_diag("Bloco 1 - shp_interface_dissolve_sf", shp_interface_dissolve_sf)

    run_checkpoint("Bloco 1 - write_vector shp_interface_dissolve", {
      write_vector(
        shp_interface_dissolve_sf,
        shp_interface_dissolve,
        layer = layer_shp_interface_dissolve,
        quiet = quiet_mode
      )
    })
  })

  ## =========================================================
  ## 2) FRAGMENTAR STANDS PELA INTERFACE
  ## =========================================================

  run_checkpoint("Bloco 2 - Preparacao inputs", {
    shp_stands_base_sf <- st_read(shp_stands_base, quiet = quiet_mode)
    shp_stands_base_sf <- tryCatch(st_set_precision(shp_stands_base_sf, 0), error = function(e) shp_stands_base_sf)
    shp_interface_dissolve_sf <- read_vector(
      shp_interface_dissolve,
      layer = layer_shp_interface_dissolve,
      quiet = quiet_mode
    )

    shp_stands_base_sf <- normalizar_poligonos(shp_stands_base_sf)
    log_sf_diag("Bloco 2 - shp_stands_base_sf", shp_stands_base_sf)
    log_sf_diag("Bloco 2 - shp_interface_dissolve_sf (lido)", shp_interface_dissolve_sf)

    shp_interface_dissolve_sf <- st_transform(
      shp_interface_dissolve_sf,
      st_crs(shp_stands_base_sf)
    )
    log_sf_diag("Bloco 2 - shp_interface_dissolve_sf (transformado)", shp_interface_dissolve_sf)
  })

  ## =========================================================
  ## A) INTERSECT
  ## =========================================================

  run_checkpoint("Bloco 2A - st_intersection", {
    stands_interface_int_sf <- tryCatch(
      st_intersection(
        shp_stands_base_sf,
        shp_interface_dissolve_sf
      ),
      error = function(e) {
        stop(
          paste0("st_intersection falhou: ", conditionMessage(e)),
          call. = FALSE
        )
      }
    )

    stands_interface_int_sf <- normalizar_poligonos(stands_interface_int_sf)
    stands_interface_int_sf <- st_cast(
      stands_interface_int_sf,
      "POLYGON",
      warn = FALSE
    )

    stands_interface_int_sf$Origem <- "interface"

    if (!"Inter_ID" %in% names(stands_interface_int_sf)) {
      stands_interface_int_sf$Inter_ID <- -1L
    }

    if (!"Interf_ha" %in% names(stands_interface_int_sf)) {
      stands_interface_int_sf$Interf_ha <- -1
    }

    stands_interface_int_sf$AREA_ha <- as.numeric(
      st_area(stands_interface_int_sf)
    ) / 10000
    log_sf_diag("Bloco 2A - stands_interface_int_sf", stands_interface_int_sf)

    run_checkpoint("Bloco 2A - write_vector stands_interface_int", {
      write_vector(
        stands_interface_int_sf,
        stands_interface_int,
        layer = layer_stands_interface_int,
        quiet = quiet_mode
      )
    })
  })

  ## =========================================================
  ## B) DISSOLVE IMEDIATO DA INTERFACE
  ## =========================================================

  run_checkpoint("Bloco 2B - summarise/dissolve", {
    stands_interface_dissolver_sf <- stands_interface_int_sf %>%
      filter(Interf_ha < 3)

    stands_interface_nao_diss_sf <- stands_interface_int_sf %>%
      filter(Interf_ha >= 3)

    stands_interface_dissolver_sf$area_temp <- as.numeric(
      st_area(stands_interface_dissolver_sf)
    )

    stands_interface_diss_sf <- tryCatch(
      stands_interface_dissolver_sf %>%
        group_by(Inter_ID, COS23_n4_L) %>%
        summarise(
          ID = ID[which.max(area_temp)],
          COS23_n4_C = COS23_n4_C[which.max(area_temp)],
          Class = Class[which.max(area_temp)],
          treatable = treatable[which.max(area_temp)],
          dec_p90 = dec_p90[which.max(area_temp)],
          dec_p90_wg = dec_p90_wg[which.max(area_temp)],
          gerivel = gerivel[which.max(area_temp)],
          exclude = exclude[which.max(area_temp)],
          exposicao = exposicao[which.max(area_temp)],
          Stand_ID = Stand_ID[which.max(area_temp)],
          Origem = Origem[which.max(area_temp)],
          Interf_ha = Interf_ha[which.max(area_temp)],
          do_union = FALSE,
          .groups = "drop"
        ),
      error = function(e) {
        stop(
          paste0("summarise (dissolve) falhou: ", conditionMessage(e)),
          call. = FALSE
        )
      }
    )

    stands_interface_diss_sf <- normalizar_poligonos(stands_interface_diss_sf)
    log_sf_diag("Bloco 2B - stands_interface_diss_sf", stands_interface_diss_sf)
    log_sf_diag("Bloco 2B - stands_interface_nao_diss_sf", stands_interface_nao_diss_sf)
  })

  ## =========================================================
  ## C) SEPARAR PARTES NAO CONTIGUAS SEM PERDER POLIGONOS
  ## =========================================================

  run_checkpoint("Bloco 2C - separacao de partes", {
    geom_types_diss <- unique(as.character(st_geometry_type(
      stands_interface_diss_sf,
      by_geometry = TRUE
    )))
    geom_types_diss <- geom_types_diss[!is.na(geom_types_diss)]
    if (!all(geom_types_diss %in% c("POLYGON", "MULTIPOLYGON"))) {
      stands_interface_diss_sf <- st_collection_extract(
        stands_interface_diss_sf,
        "POLYGON",
        warn = FALSE
      )
    }

    atribs <- st_drop_geometry(stands_interface_diss_sf)

    geom_multi <- st_cast(
      st_geometry(stands_interface_diss_sf),
      "MULTIPOLYGON",
      warn = FALSE
    )

    n_partes <- lengths(geom_multi)

    geom_poly <- st_cast(
      geom_multi,
      "POLYGON",
      warn = FALSE
    )

    atribs_rep <- atribs[
      rep(seq_len(nrow(atribs)), n_partes),
      ,
      drop = FALSE
    ]

    stands_interface_diss_sf <- st_sf(
      atribs_rep,
      geometry = geom_poly
    )

    stands_interface_diss_sf <- stands_interface_diss_sf[
      !st_is_empty(stands_interface_diss_sf),
    ]

    stands_interface_diss_sf$AREA_ha <- as.numeric(
      st_area(stands_interface_diss_sf)
    ) / 10000

    stands_interface_diss_sf$Local <- 1L
    log_sf_diag("Bloco 2C - stands_interface_diss_sf", stands_interface_diss_sf)

    run_checkpoint("Bloco 2C - write_vector stands_interface_diss", {
      write_vector(
        stands_interface_diss_sf,
        stands_interface_diss,
        layer = layer_stands_interface_diss,
        quiet = quiet_mode
      )
    })
  })

  ## =========================================================
  ## D) JUNTAR INTERFACE DISSOLVIDA + INTERFACE NAO DISSOLVIDA
  ## =========================================================

  run_checkpoint("Bloco 2D - rbind interface final", {
    cols_comuns_int <- intersect(
      names(stands_interface_nao_diss_sf),
      names(stands_interface_diss_sf)
    )

    stands_interface_nao_diss_bind <- stands_interface_nao_diss_sf[, cols_comuns_int]
    stands_interface_diss_bind <- stands_interface_diss_sf[, cols_comuns_int]

    stands_interface_final_sf <- rbind(
      stands_interface_nao_diss_bind,
      stands_interface_diss_bind
    )

    stands_interface_final_sf$AREA_ha <- as.numeric(
      st_area(stands_interface_final_sf)
    ) / 10000

    stands_interface_final_sf$Local <- 1L
    stands_interface_final_sf$Origem <- "interface"
    log_sf_diag("Bloco 2D - stands_interface_final_sf", stands_interface_final_sf)

    run_checkpoint("Bloco 2D - write_vector stands_interface_final", {
      write_vector(
        stands_interface_final_sf,
        stands_interface_final,
        layer = layer_stands_interface_final,
        quiet = quiet_mode
      )
    })
  })

  ## =========================================================
  ## E) ERASE
  ## =========================================================

  run_checkpoint("Bloco 2E - st_difference erase", {
    stands_erase_sf <- tryCatch(
      st_difference(
        shp_stands_base_sf,
        st_union(shp_interface_dissolve_sf)
      ),
      error = function(e) {
        stop(
          paste0("st_difference falhou: ", conditionMessage(e)),
          call. = FALSE
        )
      }
    )

    stands_erase_sf <- normalizar_poligonos(stands_erase_sf)

    stands_erase_sf <- st_cast(
      stands_erase_sf,
      "MULTIPOLYGON",
      warn = FALSE
    )

    stands_erase_single_sf <- st_cast(
      stands_erase_sf,
      "POLYGON",
      warn = FALSE
    )

    stands_erase_single_sf <- stands_erase_single_sf[
      !st_is_empty(stands_erase_single_sf),
    ]

    stands_erase_single_sf$Origem <- "paisagem"
    stands_erase_single_sf$Inter_ID <- -1L

    if (!"Interf_ha" %in% names(stands_erase_single_sf)) {
      stands_erase_single_sf$Interf_ha <- -1
    }

    stands_erase_single_sf$AREA_ha <- as.numeric(
      st_area(stands_erase_single_sf)
    ) / 10000

    stands_erase_single_sf$Local <- 2L
    log_sf_diag("Bloco 2E - stands_erase_single_sf", stands_erase_single_sf)

    run_checkpoint("Bloco 2E - write_vector stands_erase_single", {
      write_vector(
        stands_erase_single_sf,
        stands_erase_single,
        layer = layer_stands_erase_single,
        quiet = quiet_mode
      )
    })
  })

  ## =========================================================
  ## F) MERGE FINAL
  ## =========================================================

  run_checkpoint("Bloco 2F - merge final", {
    cols_comuns_final <- intersect(
      names(stands_erase_single_sf),
      names(stands_interface_final_sf)
    )

    stands_erase_bind <- stands_erase_single_sf[, cols_comuns_final]
    stands_interface_bind <- stands_interface_final_sf[, cols_comuns_final]

    interface_diss_completa_sf <- rbind(
      stands_erase_bind,
      stands_interface_bind
    )

    interface_diss_completa_sf$Stand_IDv2 <- seq_len(nrow(interface_diss_completa_sf))

    interface_diss_completa_sf$AREA_ha <- as.numeric(
      st_area(interface_diss_completa_sf)
    ) / 10000

    interface_diss_completa_sf$Local <- -1L
    interface_diss_completa_sf$Local[interface_diss_completa_sf$Origem == "interface"] <- 1L
    interface_diss_completa_sf$Local[interface_diss_completa_sf$Origem == "paisagem"] <- 2L

    log_sf_diag("Bloco 2F - interface_diss_completa_sf", interface_diss_completa_sf)

    if (isTRUE(verbose)) {
      print(table(interface_diss_completa_sf$Origem, useNA = "ifany"))
      print(table(interface_diss_completa_sf$Local, useNA = "ifany"))
      print(table(st_geometry_type(interface_diss_completa_sf)))
    }

    run_checkpoint("Bloco 2F - write_vector interface_diss_completa", {
      write_vector(
        interface_diss_completa_sf,
        interface_diss_completa,
        layer = layer_interface_diss_completa,
        quiet = quiet_mode
      )
    })
  })

  invisible(interface_diss_completa_sf)
}

stands_edificado <- function(
  shp_aglomerados_base = shp_aglomerados_base,
  interface_diss_completa = interface_diss_completa,
  stands_aglom_int = stands_aglom_int,
  stands_aglom_int_diss = stands_aglom_int_diss,
  stands_sem_aglomerado = stands_sem_aglomerado,
  shp_stands_interface_edf = shp_stands_interface_edf,
  shp_municipios_path = shp_municipios,
  verbose = FALSE
) {
  print("funcao stands_edificado iniciou")
  on.exit(print("funcao stands_edificado terminou"), add = TRUE)

  quiet_mode <- !isTRUE(verbose)

  # Garantir que as pastas de output existem
  dir.create(dirname(stands_aglom_int), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(stands_aglom_int_diss), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(stands_sem_aglomerado), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(shp_stands_interface_edf), recursive = TRUE, showWarnings = FALSE)

  ## =========================================================
  ## INPUTS
  ## =========================================================

  shp_aglomerados_base_sf <- st_read(shp_aglomerados_base, quiet = quiet_mode)
  interface_diss_completa_sf <- read_vector(
    interface_diss_completa,
    layer = layer_interface_diss_completa,
    quiet = quiet_mode
  )

  ## =========================================================
  ## PREPARACAO
  ## =========================================================

  shp_aglomerados_base_sf <- st_make_valid(shp_aglomerados_base_sf)
  interface_diss_completa_sf <- st_make_valid(interface_diss_completa_sf)

  shp_aglomerados_base_sf <- st_transform(
    shp_aglomerados_base_sf,
    st_crs(interface_diss_completa_sf)
  )

  shp_aglomerados_base_sel <- shp_aglomerados_base_sf[, c(
    "fid_u",
    "TIPO_p",
    attr(shp_aglomerados_base_sf, "sf_column")
  )]

  ## =========================================================
  ## A) INTERSECT
  ## =========================================================

  stands_aglom_int_sf <- st_intersection(
    interface_diss_completa_sf,
    shp_aglomerados_base_sel
  )

  stands_aglom_int_sf <- st_make_valid(stands_aglom_int_sf)
  stands_aglom_int_sf <- st_collection_extract(stands_aglom_int_sf, "POLYGON")
  stands_aglom_int_sf <- stands_aglom_int_sf[!st_is_empty(stands_aglom_int_sf), ]

  stands_aglom_int_sf$area_temp <- as.numeric(
    st_area(stands_aglom_int_sf)
  )

  write_vector(
    stands_aglom_int_sf,
    stands_aglom_int,
    layer = layer_stands_aglom_int,
    quiet = quiet_mode
  )

  ## =========================================================
  ## A.1) DISSOLVE
  ## =========================================================

  stands_aglom_int_diss_sf <- stands_aglom_int_sf %>%
    group_by(fid_u, TIPO_p) |>
    summarise(
      ID = ID[which.max(area_temp)],
      COS23_n4_C = COS23_n4_C[which.max(area_temp)],
      COS23_n4_L = COS23_n4_L[which.max(area_temp)],
      Class = Class[which.max(area_temp)],
      treatable = treatable[which.max(area_temp)],
      dec_p90 = dec_p90[which.max(area_temp)],
      dec_p90_wg = dec_p90_wg[which.max(area_temp)],
      gerivel = 0,
      exclude = 0,
      exposicao = 0,
      Stand_ID = Stand_ID[which.max(area_temp)],
      Origem = "edificado",
      Inter_ID = Inter_ID[which.max(area_temp)],
      Interf_ha = Interf_ha[which.max(area_temp)],
      Stand_IDv2 = Stand_IDv2[which.max(area_temp)],
      Local = 3L,
      do_union = TRUE,
      .groups = "drop"
    )

  stands_aglom_int_diss_sf <- normalizar_poligonos(stands_aglom_int_diss_sf)

  stands_aglom_int_diss_sf$AREA_ha <- as.numeric(
    st_area(stands_aglom_int_diss_sf)
  ) / 10000

  stands_aglom_int_diss_sf <- normalizar_poligonos(stands_aglom_int_diss_sf)

  write_vector(
    stands_aglom_int_diss_sf,
    stands_aglom_int_diss,
    layer = layer_stands_aglom_int_diss,
    quiet = quiet_mode
  )

  ## =========================================================
  ## B) ERASE
  ## =========================================================

  aglo_union <- st_union(shp_aglomerados_base_sel)

  stands_sem_aglomerado_sf <- st_difference(
    interface_diss_completa_sf,
    aglo_union
  )

  stands_sem_aglomerado_sf <- st_make_valid(stands_sem_aglomerado_sf)
  stands_sem_aglomerado_sf <- st_collection_extract(stands_sem_aglomerado_sf, "POLYGON")
  stands_sem_aglomerado_sf <- stands_sem_aglomerado_sf[!st_is_empty(stands_sem_aglomerado_sf), ]

  stands_sem_aglomerado_sf$fid_u <- -1
  stands_sem_aglomerado_sf$TIPO_p <- -1

  stands_sem_aglomerado_sf$AREA_ha <- as.numeric(
    st_area(stands_sem_aglomerado_sf)
  ) / 10000

  write_vector(
    stands_sem_aglomerado_sf,
    stands_sem_aglomerado,
    layer = layer_stands_sem_aglomerado,
    quiet = quiet_mode
  )

  ## =========================================================
  ## C) MERGE
  ## =========================================================

  cols_comuns <- intersect(
    names(stands_sem_aglomerado_sf),
    names(stands_aglom_int_diss_sf)
  )

  stands_sem_edificado_bind <- stands_sem_aglomerado_sf[, cols_comuns]
  aglo_stands_int_diss_bind <- stands_aglom_int_diss_sf[, cols_comuns]

  shp_stands_interface_edf_sf <- rbind(
    stands_sem_edificado_bind,
    aglo_stands_int_diss_bind
  )

  shp_stands_interface_edf_sf <- st_make_valid(shp_stands_interface_edf_sf)

  ## =========================================================
  ## D) GARANTIR CAMPOS
  ## =========================================================

  shp_stands_interface_edf_sf$Local <- -1L
  shp_stands_interface_edf_sf$Local[shp_stands_interface_edf_sf$Origem == "interface"] <- 1L
  shp_stands_interface_edf_sf$Local[shp_stands_interface_edf_sf$Origem == "paisagem"] <- 2L
  shp_stands_interface_edf_sf$Local[shp_stands_interface_edf_sf$Origem == "edificado"] <- 3L

  idx_local3 <- shp_stands_interface_edf_sf$Local == 3
  shp_stands_interface_edf_sf$gerivel[idx_local3] <- 0
  shp_stands_interface_edf_sf$exclude[idx_local3] <- 0
  shp_stands_interface_edf_sf$exposicao[idx_local3] <- 0

  ## =========================================================
  ## E) USO DO SOLO
  ## =========================================================

  shp_stands_interface_edf_sf$Uso_solo <- shp_stands_interface_edf_sf$COS23_n4_L

  shp_stands_interface_edf_sf$Uso_solo[idx_local3] <- ifelse(
    is.na(shp_stands_interface_edf_sf$TIPO_p[idx_local3]) | shp_stands_interface_edf_sf$TIPO_p[idx_local3] == -1,
    "Área edificada",
    paste0("Área edificada tipo_p ", shp_stands_interface_edf_sf$TIPO_p[idx_local3])
  )

  ## =========================================================
  ## F) AREA FINAL + ID
  ## =========================================================

  shp_stands_interface_edf_sf$AREA_ha <- as.numeric(
    st_area(shp_stands_interface_edf_sf)
  ) / 10000

  shp_stands_interface_edf_sf$Stand_IDv2 <- seq_len(nrow(shp_stands_interface_edf_sf))

  ## =========================================================
  ## G) ATRIBUIR MUNICIPIO (MAIOR AREA DE SOBREPOSICAO)
  ## =========================================================

  municipios_sf <- st_read(shp_municipios_path, quiet = quiet_mode)
  if (!"Municipio" %in% names(municipios_sf)) {
    stop("Falta coluna Municipio em shp_municipios.")
  }

  shp_stands_interface_edf_sf <- st_make_valid(shp_stands_interface_edf_sf)
  municipios_sf <- st_make_valid(municipios_sf)
  municipios_sf <- st_transform(municipios_sf, st_crs(shp_stands_interface_edf_sf))

  shp_stands_interface_edf_sf$.row_id <- seq_len(nrow(shp_stands_interface_edf_sf))
  shp_stands_interface_edf_sf$municipio <- NA_character_
  area_total_stand <- as.numeric(st_area(shp_stands_interface_edf_sf))

  inter_sf <- st_intersection(
    shp_stands_interface_edf_sf[, ".row_id", drop = FALSE],
    municipios_sf[, "Municipio", drop = FALSE]
  )

  if (nrow(inter_sf) > 0) {
    inter_sf$area_intersecao <- as.numeric(st_area(inter_sf))
    inter_sf$area_total <- area_total_stand[inter_sf$.row_id]
    inter_sf$pct_cover <- ifelse(
      is.na(inter_sf$area_total) | inter_sf$area_total <= 0,
      NA_real_,
      inter_sf$area_intersecao / inter_sf$area_total
    )

    inter_df <- st_drop_geometry(inter_sf)[, c(".row_id", "Municipio", "pct_cover"), drop = FALSE]
    inter_df <- inter_df[order(inter_df$.row_id, -inter_df$pct_cover, inter_df$Municipio), ]
    inter_df <- inter_df[!duplicated(inter_df$.row_id), , drop = FALSE]

    shp_stands_interface_edf_sf$municipio[inter_df$.row_id] <- as.character(inter_df$Municipio)
  }

  shp_stands_interface_edf_sf$.row_id <- NULL

  ## =========================================================
  ## H) CHECKS
  ## =========================================================

  if (isTRUE(verbose)) {
    print(table(st_geometry_type(shp_stands_interface_edf_sf)))
    print(table(shp_stands_interface_edf_sf$Origem, useNA = "ifany"))
    print(table(shp_stands_interface_edf_sf$Local, useNA = "ifany"))
    print(table(is.na(shp_stands_interface_edf_sf$municipio) | !nzchar(trimws(as.character(shp_stands_interface_edf_sf$municipio)))))
  }

  write_vector(
    shp_stands_interface_edf_sf,
    shp_stands_interface_edf,
    layer = layer_shp_stands_interface_edf,
    quiet = quiet_mode
  )

  invisible(shp_stands_interface_edf_sf)
}

correcao_stands_final <- function(
  shp_stands_interface_edf = shp_stands_interface_edf,
  shp_stands_interface_final = shp_stands_interface_final,
  threshold_eliminate_ha,
  max_small_iter = 10,
  tolerancia_gap_m = 0.5,
  n_cores_correcao = 1,
  progress_por_core = TRUE,
  verbose = FALSE
) {
  print("funcao correcao_stands_final iniciou")
  on.exit(print("funcao correcao_stands_final terminou"), add = TRUE)

  if (missing(threshold_eliminate_ha) || is.null(threshold_eliminate_ha)) {
    stop("O parametro threshold_eliminate_ha e obrigatorio.")
  }

  threshold_eliminate_ha <- suppressWarnings(as.numeric(threshold_eliminate_ha))
  if (is.na(threshold_eliminate_ha) || threshold_eliminate_ha <= 0) {
    stop("threshold_eliminate_ha deve ser numerico e > 0.")
  }
  max_small_iter <- suppressWarnings(as.integer(max_small_iter))
  if (is.na(max_small_iter) || max_small_iter < 1) {
    stop("max_small_iter deve ser um inteiro >= 1.")
  }
  tolerancia_gap_m <- suppressWarnings(as.numeric(tolerancia_gap_m))
  if (is.na(tolerancia_gap_m) || tolerancia_gap_m < 0) {
    stop("tolerancia_gap_m deve ser numerico e >= 0.")
  }
  n_cores_correcao <- suppressWarnings(as.integer(n_cores_correcao))
  if (is.na(n_cores_correcao) || n_cores_correcao < 1) {
    stop("n_cores_correcao deve ser um inteiro >= 1.")
  }
  progress_por_core <- isTRUE(progress_por_core)

  quiet_mode <- !isTRUE(verbose)
  threshold_ha <- threshold_eliminate_ha
  max_iter <- max_small_iter

  worker_state_path <- function(progress_dir, worker_id) {
    file.path(progress_dir, sprintf("worker_%02d.rds", as.integer(worker_id)))
  }

  write_worker_state <- function(progress_dir, worker_id, state) {
    if (is.null(progress_dir) || !nzchar(progress_dir)) return(invisible(NULL))
    dir.create(progress_dir, recursive = TRUE, showWarnings = FALSE)
    state$worker <- as.integer(worker_id)
    state$updated_at <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    try(saveRDS(state, worker_state_path(progress_dir, worker_id)), silent = TRUE)
    invisible(NULL)
  }

  read_worker_states <- function(progress_dir, n_workers) {
    states <- vector("list", n_workers)
    for (w in seq_len(n_workers)) {
      p <- worker_state_path(progress_dir, w)
      if (file.exists(p)) {
        states[[w]] <- tryCatch(readRDS(p), error = function(e) NULL)
      }
      if (is.null(states[[w]])) {
        states[[w]] <- list(
          worker = w,
          status = "idle",
          stage = "-",
          processados = 0L,
          total = 0L,
          agregados = 0L,
          ignorados = 0L,
          municipio = "-",
          updated_at = "-"
        )
      }
    }
    states
  }

  print_worker_progress_table <- function(progress_dir, n_workers, title = "Progresso por worker") {
    states <- read_worker_states(progress_dir, n_workers)
    header <- sprintf(
      "%-6s | %-10s | %-22s | %-13s | %-11s | %-10s | %-10s | %-16s",
      "worker", "status", "stage", "processados", "agregados", "ignorados", "municipio", "atualizado"
    )
    sep <- paste(rep("-", nchar(header)), collapse = "")
    cat("\n")
    cat(title, "\n", sep, "\n", header, "\n", sep, "\n", sep = "")
    for (s in states) {
      proc_txt <- sprintf("%d/%d", as.integer(s$processados), as.integer(s$total))
      cat(sprintf(
        "%-6d | %-10s | %-22s | %-13s | %-11d | %-10d | %-10s | %-16s\n",
        as.integer(s$worker),
        as.character(s$status),
        as.character(s$stage),
        proc_txt,
        as.integer(s$agregados),
        as.integer(s$ignorados),
        as.character(s$municipio),
        as.character(s$updated_at)
      ))
    }
    cat(sep, "\n")
    flush.console()
    invisible(NULL)
  }

  build_progress_callback <- function(progress_dir, worker_id, municipio_label = NA_character_) {
    function(evt = list()) {
      if (!is.list(evt)) evt <- list()
      state <- list(
        status = if (!is.null(evt$status)) as.character(evt$status) else "running",
        stage = if (!is.null(evt$stage)) as.character(evt$stage) else "-",
        processados = if (!is.null(evt$processados)) as.integer(evt$processados) else 0L,
        total = if (!is.null(evt$total)) as.integer(evt$total) else 0L,
        agregados = if (!is.null(evt$agregados)) as.integer(evt$agregados) else 0L,
        ignorados = if (!is.null(evt$ignorados)) as.integer(evt$ignorados) else 0L,
        municipio = if (!is.null(evt$municipio)) as.character(evt$municipio) else as.character(municipio_label)
      )
      write_worker_state(progress_dir, worker_id, state)

      # Em alguns ambientes (Rterm/outfile = ""), esta linha aparece em tempo real.
      cat(sprintf(
        "[worker %d] %-10s | %-22s | %d/%d | agg=%d | ign=%d | %s\n",
        as.integer(worker_id),
        state$status,
        state$stage,
        state$processados,
        state$total,
        state$agregados,
        state$ignorados,
        state$municipio
      ))
      flush.console()
      invisible(NULL)
    }
  }

  dir.create(dirname(shp_stands_interface_final), recursive = TRUE, showWarnings = FALSE)

  shp_stands_interface_edf_sf <- read_vector(
    shp_stands_interface_edf,
    layer = layer_shp_stands_interface_edf,
    quiet = quiet_mode
  )

  required_stands <- c("Local", "municipio")
  missing_stands <- setdiff(required_stands, names(shp_stands_interface_edf_sf))
  if (length(missing_stands) > 0) {
    stop(
      paste(
        "Faltam colunas obrigatorias em shp_stands_interface_edf:",
        paste(missing_stands, collapse = ", ")
      )
    )
  }

  ## A) AGREGAR POLIGONOS PEQUENOS A VIZINHANCA COM sf
  shp_stands_interface_final_sf <- st_make_valid(shp_stands_interface_edf_sf)

  shp_stands_interface_final_sf <- st_collection_extract(
    shp_stands_interface_final_sf,
    "POLYGON"
  )
  shp_stands_interface_final_sf <- shp_stands_interface_final_sf[
    !st_is_empty(shp_stands_interface_final_sf),
  ]

  shp_stands_interface_final_sf$AREA_ha <- as.numeric(
    st_area(shp_stands_interface_final_sf)
  ) / 10000

  shp_stands_interface_final_sf <- shp_stands_interface_final_sf[
    !is.na(shp_stands_interface_final_sf$AREA_ha) &
      shp_stands_interface_final_sf$AREA_ha > 0,
  ]

  agregar_pequenos_sf <- function(
    sf_obj,
    threshold_ha = 0.1,
    max_iter = 10,
    verbose_mode = FALSE,
    tolerancia_gap = 0.5,
    progress_cb = NULL,
    progress_stage = "agregar"
  ) {
    if (nrow(sf_obj) == 0) return(sf_obj)

    sf_obj <- st_make_valid(sf_obj)
    sf_obj <- st_collection_extract(sf_obj, "POLYGON")
    sf_obj <- sf_obj[!st_is_empty(sf_obj), ]

    normalizar_merge_geom <- function(geom_obj, crs_ref) {
      extrair_geom <- function(x) {
        if (is.null(x)) return(NULL)
        if (inherits(x, "sf")) x <- st_geometry(x)
        if (inherits(x, "sfc")) {
          if (length(x) == 0) return(NULL)
          return(x[[1]])
        }
        if (inherits(x, "sfg")) return(x)
        NULL
      }

      g <- extrair_geom(geom_obj)
      if (is.null(g)) return(NULL)

      sf_tmp <- tryCatch(
        st_as_sf(data.frame(.id = 1L), geometry = st_sfc(g, crs = crs_ref)),
        error = function(e) NULL
      )
      if (is.null(sf_tmp)) return(NULL)

      sf_tmp <- tryCatch(st_make_valid(sf_tmp), error = function(e) NULL)
      if (is.null(sf_tmp)) return(NULL)

      sf_tmp <- tryCatch(st_collection_extract(sf_tmp, "POLYGON"), error = function(e) NULL)
      if (is.null(sf_tmp) || nrow(sf_tmp) == 0) return(NULL)

      sf_tmp <- sf_tmp[!st_is_empty(sf_tmp), ]
      if (nrow(sf_tmp) == 0) return(NULL)

      sf_tmp <- tryCatch(st_cast(sf_tmp, "MULTIPOLYGON", warn = FALSE), error = function(e) NULL)
      if (is.null(sf_tmp) || nrow(sf_tmp) == 0) return(NULL)

      g_out <- st_geometry(sf_tmp)
      if (length(g_out) == 0) return(NULL)
      g_out[[1]]
    }

    iter <- 0L
    skipped_invalid_total <- 0L
    repeat {
      iter <- iter + 1L

      sf_obj$AREA_ha <- as.numeric(st_area(sf_obj)) / 10000
      sf_obj$tmp_id <- seq_len(nrow(sf_obj))

      ids_pequenos <- sf_obj$tmp_id[sf_obj$AREA_ha < threshold_ha]
      n_small_now <- length(ids_pequenos)
      removed_iter <- 0L
      skipped_invalid_iter <- 0L
      processed_iter <- 0L

      if (isTRUE(verbose_mode)) {
        cat(sprintf("Iteracao %d - poligonos pequenos: %d\n", iter, n_small_now))
      }

      if (n_small_now == 0) {
        if (isTRUE(verbose_mode)) cat("Paragem: nao existem mais poligonos abaixo do limiar.\n")
        break
      }

      if (iter > max_iter) {
        if (isTRUE(verbose_mode)) cat("Paragem: atingido numero maximo de iteracoes.\n")
        break
      }

      report_progress <- function() {
        if (isTRUE(verbose_mode) && (processed_iter %% 250L == 0L || processed_iter == n_small_now)) {
          cat(sprintf(
            "Iteracao %d - processados: %d/%d | agregados: %d | ignorados: %d\n",
            iter, processed_iter, n_small_now, removed_iter, skipped_invalid_iter
          ))
        }
        if (is.function(progress_cb) && (processed_iter %% 250L == 0L || processed_iter == n_small_now)) {
          progress_cb(list(
            status = "running",
            stage = sprintf("%s | iter %d", progress_stage, iter),
            processados = processed_iter,
            total = n_small_now,
            agregados = removed_iter,
            ignorados = skipped_invalid_iter
          ))
        }
      }

      for (id_small in ids_pequenos) {
        processed_iter <- processed_iter + 1L
        idx_small <- match(id_small, sf_obj$tmp_id)
        if (is.na(idx_small)) {
          report_progress()
          next
        }

        feat_small <- sf_obj[idx_small, ]

        idx_touch <- st_touches(feat_small, sf_obj)[[1]]
        if (length(idx_touch) > 0) {
          idx_candidatos <- idx_touch
        } else {
          idx_int <- st_intersects(feat_small, sf_obj)[[1]]
          idx_int <- setdiff(idx_int, idx_small)
          idx_candidatos <- idx_int
        }

        # Fallback final: vizinho mais proximo dentro da tolerancia para fechar micro-gaps
        if (length(idx_candidatos) == 0 && tolerancia_gap > 0 && nrow(sf_obj) > 1) {
          idx_all <- setdiff(seq_len(nrow(sf_obj)), idx_small)
          d_all <- tryCatch(
            suppressWarnings(as.numeric(st_distance(feat_small, sf_obj[idx_all, ], by_element = FALSE))),
            error = function(e) rep(NA_real_, length(idx_all))
          )
          if (length(d_all) == length(idx_all)) {
            ok <- which(!is.na(d_all) & d_all <= tolerancia_gap)
            if (length(ok) > 0) {
              idx_candidatos <- idx_all[ok]
            }
          }
        }

        if (length(idx_candidatos) == 0) {
          report_progress()
          next
        }

        vizinhos <- sf_obj[idx_candidatos, ]
        vizinhos <- vizinhos[vizinhos$tmp_id != id_small, ]
        if (nrow(vizinhos) == 0) {
          report_progress()
          next
        }

        vizinhos$AREA_ha_tmp <- as.numeric(st_area(vizinhos)) / 10000
        vizinhos_grandes <- vizinhos[vizinhos$AREA_ha_tmp >= threshold_ha, ]
        vizinhos_candidatos <- if (nrow(vizinhos_grandes) > 0) vizinhos_grandes else vizinhos

        if (nrow(vizinhos_candidatos) == 1) {
          id_best <- vizinhos_candidatos$tmp_id[1]
          feat_best <- sf_obj[sf_obj$tmp_id == id_best, ]
          geom_new <- tryCatch(st_union(feat_best, feat_small), error = function(e) NULL)
        } else {
          boundary_small <- tryCatch(st_boundary(feat_small), error = function(e) NULL)
          border_len <- numeric(nrow(vizinhos_candidatos))
          if (!is.null(boundary_small)) {
            for (k in seq_len(nrow(vizinhos_candidatos))) {
              border_len[k] <- tryCatch(
                {
                  inter_b <- suppressWarnings(
                    st_intersection(
                      boundary_small,
                      st_boundary(vizinhos_candidatos[k, ])
                    )
                  )
                  len_b <- suppressWarnings(st_length(inter_b))
                  if (length(len_b) == 0) 0 else as.numeric(sum(len_b, na.rm = TRUE))
                },
                error = function(e) NA_real_
              )
            }
          } else {
            border_len[] <- NA_real_
          }

          vizinhos_candidatos$border_len <- border_len
          vizinhos_com_aresta <- vizinhos_candidatos[
            !is.na(vizinhos_candidatos$border_len) & vizinhos_candidatos$border_len > 0,
          ]

          if (nrow(vizinhos_com_aresta) > 0) {
            idx_best <- which.max(vizinhos_com_aresta$border_len)
            id_best <- vizinhos_com_aresta$tmp_id[idx_best]
            feat_best <- sf_obj[sf_obj$tmp_id == id_best, ]
            geom_new <- tryCatch(st_union(feat_best, feat_small), error = function(e) NULL)
          } else {
            if (tolerancia_gap <= 0) {
              report_progress()
              next
            }
            d_viz <- tryCatch(
              suppressWarnings(as.numeric(st_distance(feat_small, vizinhos_candidatos, by_element = FALSE))),
              error = function(e) rep(NA_real_, nrow(vizinhos_candidatos))
            )
            if (length(d_viz) != nrow(vizinhos_candidatos)) {
              report_progress()
              next
            }
            ok_d <- which(!is.na(d_viz) & d_viz <= tolerancia_gap)
            if (length(ok_d) == 0) {
              report_progress()
              next
            }

            idx_best <- ok_d[which.min(d_viz[ok_d])]
            id_best <- vizinhos_candidatos$tmp_id[idx_best]
            feat_best <- sf_obj[sf_obj$tmp_id == id_best, ]

            # Ponte geometrica minima para unir casos de contacto por ponto/micro-gap
            bridge_tol <- max(tolerancia_gap / 2, 0.001)
            geom_new <- tryCatch(
              suppressWarnings(
                st_union(
                  st_buffer(feat_best, bridge_tol),
                  st_buffer(feat_small, bridge_tol)
                )
              ),
              error = function(e) NULL
            )
            geom_new <- tryCatch(
              suppressWarnings(st_buffer(geom_new, -bridge_tol)),
              error = function(e) NULL
            )
          }
        }

        geom_new_norm <- normalizar_merge_geom(geom_new, st_crs(sf_obj))
        if (is.null(geom_new_norm)) {
          skipped_invalid_iter <- skipped_invalid_iter + 1L
          skipped_invalid_total <- skipped_invalid_total + 1L
          report_progress()
          next
        }

        sf_obj$geometry[sf_obj$tmp_id == id_best] <- st_sfc(
          geom_new_norm,
          crs = st_crs(sf_obj)
        )
        sf_obj <- sf_obj[sf_obj$tmp_id != id_small, ]
        removed_iter <- removed_iter + 1L
        report_progress()
      }

      sf_obj <- st_make_valid(sf_obj)
      sf_obj <- sf_obj[!st_is_empty(sf_obj), ]
      sf_obj <- st_collection_extract(sf_obj, "POLYGON")

      if (isTRUE(verbose_mode) && skipped_invalid_iter > 0) {
        cat(sprintf("Iteracao %d - agregacoes ignoradas por geometria invalida: %d\n", iter, skipped_invalid_iter))
      }

      if (removed_iter == 0) {
        if (isTRUE(verbose_mode)) cat("Paragem: nenhuma agregacao na iteracao.\n")
        break
      }
    }

    if (isTRUE(verbose_mode) && skipped_invalid_total > 0) {
      cat(sprintf("Total de agregacoes ignoradas por geometria invalida: %d\n", skipped_invalid_total))
    }

    if ("tmp_id" %in% names(sf_obj)) sf_obj$tmp_id <- NULL
    if ("AREA_ha_tmp" %in% names(sf_obj)) sf_obj$AREA_ha_tmp <- NULL
    if ("border_len" %in% names(sf_obj)) sf_obj$border_len <- NULL

    sf_obj
  }

  rbind_sf_align <- function(sf_list, template_sf = NULL) {
    sf_list <- Filter(function(x) !is.null(x) && inherits(x, "sf"), sf_list)
    if (length(sf_list) == 0) {
      if (!is.null(template_sf) && inherits(template_sf, "sf")) {
        return(template_sf[0, , drop = FALSE])
      }
      return(NULL)
    }

    all_cols <- unique(unlist(lapply(sf_list, names), use.names = FALSE))
    fill_missing_col <- function(col_name, n_rows) {
      exemplar <- NULL
      for (obj in sf_list) {
        if (col_name %in% names(obj)) {
          exemplar <- obj[[col_name]]
          break
        }
      }
      if (!is.null(exemplar) && (is.integer(exemplar) || is.numeric(exemplar))) {
        return(rep(-1, n_rows))
      }
      rep(NA, n_rows)
    }
    sf_list <- lapply(sf_list, function(x) {
      miss <- setdiff(all_cols, names(x))
      if (length(miss) > 0) {
        for (col in miss) x[[col]] <- fill_missing_col(col, nrow(x))
      }
      x[, all_cols, drop = FALSE]
    })

    do.call(rbind, sf_list)
  }

  agregar_local2_rodeado_local1 <- function(
    local1_sf,
    local2_sf,
    local3_sf,
    outros_sf,
    threshold_ha,
    verbose_mode = FALSE,
    progress_cb = NULL,
    progress_stage = "local2_rod_local1"
  ) {
    if (nrow(local1_sf) == 0 || nrow(local2_sf) == 0) {
      return(list(
        local1 = local1_sf,
        local2 = local2_sf,
        n_candidatos = 0L,
        n_transferidos = 0L,
        n_ignorados = 0L
      ))
    }

    normalizar_merge_geom_local <- function(geom_obj, crs_ref) {
      extrair_geom <- function(x) {
        if (is.null(x)) return(NULL)
        if (inherits(x, "sf")) x <- st_geometry(x)
        if (inherits(x, "sfc")) {
          if (length(x) == 0) return(NULL)
          return(x[[1]])
        }
        if (inherits(x, "sfg")) return(x)
        NULL
      }

      g <- extrair_geom(geom_obj)
      if (is.null(g)) return(NULL)

      sf_tmp <- tryCatch(
        st_as_sf(data.frame(.id = 1L), geometry = st_sfc(g, crs = crs_ref)),
        error = function(e) NULL
      )
      if (is.null(sf_tmp)) return(NULL)

      sf_tmp <- tryCatch(st_make_valid(sf_tmp), error = function(e) NULL)
      if (is.null(sf_tmp)) return(NULL)

      sf_tmp <- tryCatch(st_collection_extract(sf_tmp, "POLYGON"), error = function(e) NULL)
      if (is.null(sf_tmp) || nrow(sf_tmp) == 0) return(NULL)

      sf_tmp <- sf_tmp[!st_is_empty(sf_tmp), ]
      if (nrow(sf_tmp) == 0) return(NULL)

      sf_tmp <- tryCatch(st_cast(sf_tmp, "MULTIPOLYGON", warn = FALSE), error = function(e) NULL)
      if (is.null(sf_tmp) || nrow(sf_tmp) == 0) return(NULL)

      g_out <- st_geometry(sf_tmp)
      if (length(g_out) == 0) return(NULL)
      g_out[[1]]
    }

    local1_sf$.__l1_id <- seq_len(nrow(local1_sf))
    local2_sf$.__l2_id <- seq_len(nrow(local2_sf))
    local2_sf$AREA_ha <- as.numeric(st_area(local2_sf)) / 10000

    ids_candidatos <- local2_sf$.__l2_id[
      !is.na(local2_sf$AREA_ha) &
        local2_sf$AREA_ha < threshold_ha
    ]

    n_candidatos <- length(ids_candidatos)
    n_transferidos <- 0L
    n_ignorados <- 0L
    processed_iter <- 0L

    if (isTRUE(verbose_mode)) {
      cat(sprintf("Local 2 rodeado por Local 1 - candidatos: %d\n", n_candidatos))
    }

    for (cid in ids_candidatos) {
      processed_iter <- processed_iter + 1L
      if (isTRUE(verbose_mode) && (processed_iter %% 250L == 0L || processed_iter == n_candidatos)) {
        cat(sprintf(
          "Local 2 rodeado por Local 1 - processados: %d/%d | agregados: %d | ignorados: %d\n",
          processed_iter, n_candidatos, n_transferidos, n_ignorados
        ))
      }
      if (is.function(progress_cb) && (processed_iter %% 250L == 0L || processed_iter == n_candidatos)) {
        progress_cb(list(
          status = "running",
          stage = progress_stage,
          processados = processed_iter,
          total = n_candidatos,
          agregados = n_transferidos,
          ignorados = n_ignorados
        ))
      }

      idx_small <- match(cid, local2_sf$.__l2_id)
      if (is.na(idx_small)) next

      feat_small <- local2_sf[idx_small, ]

      l1_ctx <- local1_sf
      l2_ctx <- local2_sf
      l3_ctx <- local3_sf
      out_ctx <- outros_sf

      l1_ctx$.__ctx_local <- rep(1L, nrow(l1_ctx))
      l2_ctx$.__ctx_local <- rep(2L, nrow(l2_ctx))
      l3_ctx$.__ctx_local <- rep(3L, nrow(l3_ctx))
      out_ctx$.__ctx_local <- rep(99L, nrow(out_ctx))

      if (!".__l1_id" %in% names(l2_ctx)) l2_ctx$.__l1_id <- rep(NA_integer_, nrow(l2_ctx))
      if (!".__l1_id" %in% names(l3_ctx)) l3_ctx$.__l1_id <- rep(NA_integer_, nrow(l3_ctx))
      if (!".__l1_id" %in% names(out_ctx)) out_ctx$.__l1_id <- rep(NA_integer_, nrow(out_ctx))

      if (!".__l2_id" %in% names(l1_ctx)) l1_ctx$.__l2_id <- rep(NA_integer_, nrow(l1_ctx))
      if (!".__l2_id" %in% names(l3_ctx)) l3_ctx$.__l2_id <- rep(NA_integer_, nrow(l3_ctx))
      if (!".__l2_id" %in% names(out_ctx)) out_ctx$.__l2_id <- rep(NA_integer_, nrow(out_ctx))

      contexto <- rbind_sf_align(
        list(l1_ctx, l2_ctx, l3_ctx, out_ctx),
        template_sf = l1_ctx
      )
      if (is.null(contexto)) next

      idx_ctx_small <- which(contexto$.__ctx_local == 2L & contexto$.__l2_id == cid)
      if (length(idx_ctx_small) != 1) next
      idx_ctx_small <- idx_ctx_small[1]

      idx_viz <- tryCatch(st_touches(contexto[idx_ctx_small, ], contexto)[[1]], error = function(e) integer(0))
      idx_viz <- setdiff(idx_viz, idx_ctx_small)
      if (length(idx_viz) == 0) {
        idx_viz <- tryCatch(st_intersects(contexto[idx_ctx_small, ], contexto)[[1]], error = function(e) integer(0))
        idx_viz <- setdiff(idx_viz, idx_ctx_small)
      }
      if (length(idx_viz) == 0) next

      if (!all(contexto$.__ctx_local[idx_viz] == 1L, na.rm = TRUE)) next

      idx_viz_l1 <- idx_viz[contexto$.__ctx_local[idx_viz] == 1L]
      if (length(idx_viz_l1) == 0) next

      boundary_small <- tryCatch(st_boundary(feat_small), error = function(e) NULL)
      if (is.null(boundary_small)) {
        n_ignorados <- n_ignorados + 1L
        next
      }

      border_len <- rep(NA_real_, length(idx_viz_l1))
      for (k in seq_along(idx_viz_l1)) {
        border_len[k] <- tryCatch(
          {
            inter_b <- suppressWarnings(
              st_intersection(
                boundary_small,
                st_boundary(contexto[idx_viz_l1[k], ])
              )
            )
            len_b <- suppressWarnings(st_length(inter_b))
            if (length(len_b) == 0) 0 else as.numeric(sum(len_b, na.rm = TRUE))
          },
          error = function(e) NA_real_
        )
      }

      if (all(is.na(border_len)) || all(border_len <= 0, na.rm = TRUE)) {
        n_ignorados <- n_ignorados + 1L
        next
      }

      idx_best_ctx <- idx_viz_l1[which.max(ifelse(is.na(border_len), -Inf, border_len))]
      id_dest_l1 <- contexto$.__l1_id[idx_best_ctx]
      idx_dest <- match(id_dest_l1, local1_sf$.__l1_id)
      if (is.na(idx_dest)) {
        n_ignorados <- n_ignorados + 1L
        next
      }

      feat_dest <- local1_sf[idx_dest, ]
      geom_new <- tryCatch(st_union(feat_dest, feat_small), error = function(e) NULL)
      geom_new_norm <- normalizar_merge_geom_local(geom_new, st_crs(local1_sf))
      if (is.null(geom_new_norm)) {
        n_ignorados <- n_ignorados + 1L
        next
      }

      local1_sf$geometry[idx_dest] <- st_sfc(geom_new_norm, crs = st_crs(local1_sf))
      local2_sf <- local2_sf[local2_sf$.__l2_id != cid, ]
      n_transferidos <- n_transferidos + 1L
    }

    local1_sf$.__l1_id <- NULL
    if (".__l2_id" %in% names(local1_sf)) local1_sf$.__l2_id <- NULL
    if (".__ctx_local" %in% names(local1_sf)) local1_sf$.__ctx_local <- NULL

    if (".__l2_id" %in% names(local2_sf)) local2_sf$.__l2_id <- NULL
    if (".__l1_id" %in% names(local2_sf)) local2_sf$.__l1_id <- NULL
    if (".__ctx_local" %in% names(local2_sf)) local2_sf$.__ctx_local <- NULL

    if (isTRUE(verbose_mode)) {
      cat(sprintf(
        "Local 2 rodeado por Local 1 - agregados: %d | ignorados: %d\n",
        n_transferidos,
        n_ignorados
      ))
    }

    list(
      local1 = local1_sf,
      local2 = local2_sf,
      n_candidatos = as.integer(n_candidatos),
      n_transferidos = as.integer(n_transferidos),
      n_ignorados = as.integer(n_ignorados)
    )
  }

  processar_subset_correcao <- function(sf_subset, verbose_mode = FALSE, progress_cb = NULL) {
    if (nrow(sf_subset) == 0) return(sf_subset)

    local1 <- sf_subset[
      !is.na(sf_subset$Local) &
        sf_subset$Local == 1,
    ]
    local2 <- sf_subset[
      !is.na(sf_subset$Local) &
        sf_subset$Local == 2,
    ]
    local3 <- sf_subset[
      !is.na(sf_subset$Local) &
        sf_subset$Local == 3,
    ]
    outros <- sf_subset[
      is.na(sf_subset$Local) |
        !(sf_subset$Local %in% c(1, 2, 3)),
    ]

    local3_corr <- local3
    if (is.function(progress_cb)) {
      progress_cb(list(status = "running", stage = "inicio", processados = 0L, total = nrow(sf_subset), agregados = 0L, ignorados = 0L))
    }
    for (iter_global in seq_len(max_small_iter)) {
      if (isTRUE(verbose_mode)) {
        cat(sprintf("Iteracao global %d/%d\n", iter_global, max_small_iter))
      }

      local1_before_n <- nrow(local1)
      local2_before_n <- nrow(local2)
      if (nrow(local1) > 0) {
        if (isTRUE(verbose_mode)) cat("Processar Local 1\n")
        local1_corr <- agregar_pequenos_sf(
          local1,
          threshold_ha = threshold_ha,
          max_iter = max_small_iter,
          verbose_mode = verbose_mode,
          tolerancia_gap = tolerancia_gap_m,
          progress_cb = progress_cb,
          progress_stage = sprintf("local1 | iter_global %d", iter_global)
        )
      } else {
        local1_corr <- local1
      }

      transf_local2_l1 <- agregar_local2_rodeado_local1(
        local1_sf = local1_corr,
        local2_sf = local2,
        local3_sf = local3,
        outros_sf = outros,
        threshold_ha = threshold_ha,
        verbose_mode = verbose_mode,
        progress_cb = progress_cb,
        progress_stage = sprintf("local2_rod_local1 | iter_global %d", iter_global)
      )

      local1_corr <- transf_local2_l1$local1
      local2_after_transfer <- transf_local2_l1$local2
      n_transferidos <- as.integer(transf_local2_l1$n_transferidos)

      if (nrow(local2_after_transfer) > 0) {
        if (isTRUE(verbose_mode)) cat("Processar Local 2\n")
        local2_corr <- agregar_pequenos_sf(
          local2_after_transfer,
          threshold_ha = threshold_ha,
          max_iter = max_small_iter,
          verbose_mode = verbose_mode,
          tolerancia_gap = tolerancia_gap_m,
          progress_cb = progress_cb,
          progress_stage = sprintf("local2 | iter_global %d", iter_global)
        )
      } else {
        local2_corr <- local2_after_transfer
      }

      delta_local1 <- as.integer(local1_before_n - nrow(local1_corr))
      delta_local2 <- as.integer(local2_before_n - nrow(local2_corr))

      if (isTRUE(verbose_mode)) {
        cat(sprintf(
          "Iteracao global %d - delta_local1: %d | delta_local2: %d | transferidos_l2_l1: %d\n",
          iter_global, delta_local1, delta_local2, n_transferidos
        ))
      }
      if (is.function(progress_cb)) {
        progress_cb(list(
          status = "running",
          stage = sprintf("iter_global %d/%d", iter_global, max_small_iter),
          processados = iter_global,
          total = max_small_iter,
          agregados = delta_local1 + delta_local2 + n_transferidos,
          ignorados = 0L
        ))
      }

      local1 <- local1_corr
      local2 <- local2_corr

      if (delta_local1 == 0L && delta_local2 == 0L && n_transferidos == 0L) {
        if (isTRUE(verbose_mode)) {
          cat("Paragem global: estabilizacao (sem alteracoes).\n")
        }
        break
      }

      if (iter_global >= max_small_iter && isTRUE(verbose_mode)) {
        cat(sprintf("Paragem global: atingido limite maximo (%d).\n", max_small_iter))
      }
    }

    sf_out <- rbind_sf_align(
      list(local1, local2, local3_corr, outros),
      template_sf = sf_subset
    )
    if (is.null(sf_out)) sf_out <- sf_subset[0, , drop = FALSE]
    if (is.function(progress_cb)) {
      progress_cb(list(status = "concluido", stage = "fim", processados = max_small_iter, total = max_small_iter, agregados = 0L, ignorados = 0L))
    }
    sf_out
  }

  municipio_norm <- trimws(as.character(shp_stands_interface_final_sf$municipio))
  municipio_norm[is.na(municipio_norm) | !nzchar(municipio_norm)] <- "__SEM_MUNICIPIO__"
  municipios <- sort(unique(municipio_norm))
  idx_por_municipio <- lapply(municipios, function(m) which(municipio_norm == m))
  names(idx_por_municipio) <- municipios

  if (isTRUE(verbose)) {
    cat(sprintf(
      "Correcao por municipio - grupos: %d | n_cores_correcao: %d\n",
      length(municipios),
      n_cores_correcao
    ))
  }

  resultados_subsets <- list()
  progress_dir <- NULL
  if (length(municipios) > 0) {
    if (n_cores_correcao == 1L || length(municipios) == 1L) {
      resultados_subsets <- vector("list", length(municipios))
      for (i in seq_along(municipios)) {
        if (isTRUE(verbose)) {
          cat(sprintf(
            "Processar municipio: %s (%d/%d)\n",
            municipios[i],
            i,
            length(municipios)
          ))
        }
        idx_i <- idx_por_municipio[[i]]
        sf_i <- shp_stands_interface_final_sf[idx_i, , drop = FALSE]
        resultados_subsets[[i]] <- processar_subset_correcao(
          sf_subset = sf_i,
          verbose_mode = verbose
        )
      }
    } else {
      n_workers <- min(n_cores_correcao, length(municipios))
      if (isTRUE(verbose)) {
        cat(sprintf("Correcao por municipio em paralelo com %d workers.\n", n_workers))
      }

      progress_enabled <- isTRUE(verbose) && isTRUE(progress_por_core)
      if (progress_enabled) {
        progress_dir <- file.path(
          tempdir(),
          paste0("correcao_progress_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_", Sys.getpid())
        )
        dir.create(progress_dir, recursive = TRUE, showWarnings = FALSE)
        for (w in seq_len(n_workers)) {
          write_worker_state(progress_dir, w, list(
            status = "idle",
            stage = "aguardar",
            processados = 0L,
            total = 0L,
            agregados = 0L,
            ignorados = 0L,
            municipio = "-"
          ))
        }
        print_worker_progress_table(progress_dir, n_workers, title = "Progresso por worker (inicio)")
      }

      cl <- if (progress_enabled) {
        makeCluster(n_workers, type = "SOCK", outfile = "")
      } else {
        makeCluster(n_workers, type = "SOCK")
      }
      on.exit(stopCluster(cl), add = TRUE)
      registerDoSNOW(cl)
      on.exit(registerDoSEQ(), add = TRUE)

      progress <- function(n) NULL
      if (isTRUE(verbose)) {
        pb <- txtProgressBar(min = 0, max = length(municipios), style = 3)
        on.exit(try(close(pb), silent = TRUE), add = TRUE)
        progress <- function(n) {
          setTxtProgressBar(pb, n)
          if (n >= length(municipios)) cat("\n")
          flush.console()
        }
      }
      opts_snow <- list(progress = function(n) {
        progress(n)
        if (progress_enabled) {
          print_worker_progress_table(progress_dir, n_workers, title = sprintf("Progresso por worker (tarefas concluidas: %d/%d)", n, length(municipios)))
        }
      })

      resultados_subsets <- foreach(
        i = seq_along(municipios),
        .packages = c("sf"),
        .options.snow = opts_snow,
        .export = c(
          "processar_subset_correcao",
          "agregar_pequenos_sf",
          "agregar_local2_rodeado_local1",
          "rbind_sf_align",
          "build_progress_callback",
          "write_worker_state",
          "threshold_ha",
          "max_small_iter",
          "tolerancia_gap_m",
          "max_iter",
          "idx_por_municipio",
          "shp_stands_interface_final_sf",
          "progress_dir",
          "n_workers",
          "municipios"
        )
      ) %dopar% {
        idx_i <- idx_por_municipio[[i]]
        sf_i <- shp_stands_interface_final_sf[idx_i, , drop = FALSE]
        worker_id <- ((i - 1L) %% n_workers) + 1L
        cb <- NULL
        if (!is.null(progress_dir) && nzchar(progress_dir)) {
          cb <- build_progress_callback(
            progress_dir = progress_dir,
            worker_id = worker_id,
            municipio_label = municipios[i]
          )
          cb(list(status = "running", stage = "arranque", processados = 0L, total = nrow(sf_i), agregados = 0L, ignorados = 0L))
        }
        processar_subset_correcao(
          sf_subset = sf_i,
          verbose_mode = FALSE,
          progress_cb = cb
        )
      }

      if (progress_enabled) {
        print_worker_progress_table(progress_dir, n_workers, title = "Progresso por worker (fim)")
      }
    }
  }

  shp_stands_interface_final_sf <- rbind_sf_align(
    resultados_subsets,
    template_sf = shp_stands_interface_edf_sf
  )
  if (is.null(shp_stands_interface_final_sf)) {
    shp_stands_interface_final_sf <- shp_stands_interface_edf_sf[0, ]
  }

  shp_stands_interface_final_sf <- st_make_valid(shp_stands_interface_final_sf)
  shp_stands_interface_final_sf <- shp_stands_interface_final_sf[
    !st_is_empty(shp_stands_interface_final_sf),
  ]
  shp_stands_interface_final_sf <- st_collection_extract(
    shp_stands_interface_final_sf,
    "POLYGON"
  )
  shp_stands_interface_final_sf <- st_cast(
    shp_stands_interface_final_sf,
    "POLYGON",
    warn = FALSE
  )

  ## G) RECALCULAR AREA_ha E NOVO ID
  shp_stands_interface_final_sf$AREA_ha <- as.numeric(
    st_area(shp_stands_interface_final_sf)
  ) / 10000

  shp_stands_interface_final_sf <- shp_stands_interface_final_sf[
    !is.na(shp_stands_interface_final_sf$AREA_ha) &
      shp_stands_interface_final_sf$AREA_ha > 0,
  ]

  shp_stands_interface_final_sf$Stand_IDv2 <- seq_len(nrow(shp_stands_interface_final_sf))

  ## H) CONFERIR
  table(shp_stands_interface_final_sf$Local, useNA = "ifany")
  table(st_geometry_type(shp_stands_interface_final_sf))
  summary(shp_stands_interface_final_sf$AREA_ha)
  n_abaixo_limite <- sum(shp_stands_interface_final_sf$AREA_ha < threshold_ha, na.rm = TRUE)
  cat(
    sprintf(
      "Poligonos abaixo do limite (< %.6f ha): %d\n",
      threshold_ha,
      as.integer(n_abaixo_limite)
    )
  )

  ## I) GUARDAR
  write_vector(
    shp_stands_interface_final_sf,
    shp_stands_interface_final,
    layer = layer_shp_stands_interface_final,
    quiet = quiet_mode
  )

  invisible(shp_stands_interface_final_sf)
}

## # - CALCULO DA EXPOSICAO ####
run_exposure_interface <- function(
  shp_donut_path,
  stands_sf,
  raster_path,
  out_rds,
  out_csv,
  metric_col,
  n_cores = 8
) {
  print("funcao run_exposure_interface iniciou")
  on.exit(print("funcao run_exposure_interface terminou"), add = TRUE)

  donut <- st_read(shp_donut_path, quiet = TRUE)
  donut <- st_make_valid(donut)
  stands_sf <- st_make_valid(stands_sf)
  donut <- st_transform(donut, st_crs(stands_sf))

  if (!"fid_u" %in% names(donut)) stop(paste("Falta fid_u em:", shp_donut_path))

  stands_filtrados <- stands_sf[stands_sf$Local == 1, ]

  if (nrow(stands_filtrados) == 0 || nrow(donut) == 0) {
    saveRDS(data.frame(), out_rds)
    df_empty <- data.frame(Stand_IDv2 = integer(), value_tmp = numeric())
    names(df_empty)[2] <- metric_col
    write.csv(df_empty, out_csv, row.names = FALSE)
    return(df_empty)
  }

  raster_obj <- raster(raster_path)

  cl <- makeCluster(min(n_cores, nrow(donut)), type = "SOCK")
  on.exit(stopCluster(cl), add = TRUE)
  registerDoSNOW(cl)
  on.exit(registerDoSEQ(), add = TRUE)

  pb <- txtProgressBar(max = nrow(donut), style = 3)
  on.exit(close(pb), add = TRUE)

  progress <- function(n) {
    setTxtProgressBar(pb, n)
    flush.console()
  }
  opts <- list(progress = progress)

  df_final <- foreach(
    i = seq_len(nrow(donut)),
    .combine = rbind,
    .packages = c("sf", "exactextractr", "raster"),
    .options.snow = opts,
    .export = c("stands_filtrados", "donut", "raster_obj")
  ) %dopar% {
    donut_loop <- donut[i, ]

    stands_loop <- st_intersection(stands_filtrados, donut_loop)
    if (nrow(stands_loop) == 0) return(NULL)

    stands_loop <- st_collection_extract(stands_loop, "POLYGON")
    if (nrow(stands_loop) == 0) return(NULL)

    df_loop_list <- exactextractr::exact_extract(raster_obj, stands_loop)
    if (length(df_loop_list) == 0) return(NULL)

    for (j in seq_along(df_loop_list)) {
      if (is.null(df_loop_list[[j]]) || nrow(df_loop_list[[j]]) == 0) next
      df_loop_list[[j]]$Stand_IDv2 <- stands_loop$Stand_IDv2[j]
      df_loop_list[[j]]$comunidade_id <- donut$fid_u[i]
    }

    df_loop_list <- Filter(function(x) !is.null(x) && nrow(x) > 0, df_loop_list)
    if (length(df_loop_list) == 0) return(NULL)

    df_loop <- do.call(rbind, df_loop_list)
    df_loop$rast_weighted <- df_loop$value * df_loop$coverage_fraction
    df_loop
  }

  if (is.null(df_final) || nrow(df_final) == 0) {
    df_sum <- data.frame(Stand_IDv2 = integer(), value_tmp = numeric())
    names(df_sum)[2] <- metric_col
  } else {
    df_sum <- as.data.frame(
      df_final %>%
        group_by(Stand_IDv2) %>%
        summarise(value_tmp = sum(rast_weighted, na.rm = TRUE), .groups = "drop")
    )
    names(df_sum)[names(df_sum) == "value_tmp"] <- metric_col
  }

  saveRDS(if (is.null(df_final)) data.frame() else df_final, out_rds)
  write.csv(df_sum, out_csv, row.names = FALSE)

  df_sum
}

run_exposure_lcp <- function(
  shp_donut_path,
  stands_sf,
  raster_path,
  out_rds,
  out_csv,
  metric_col,
  n_cores = 8
) {
  print("funcao run_exposure_lcp iniciou")
  on.exit(print("funcao run_exposure_lcp terminou"), add = TRUE)

  donut <- st_read(shp_donut_path, quiet = TRUE)
  donut <- st_make_valid(donut)
  stands_sf <- st_make_valid(stands_sf)
  donut <- st_transform(donut, st_crs(stands_sf))

  if (!"fid_u" %in% names(donut)) stop(paste("Falta fid_u em:", shp_donut_path))

  stands_filtrados <- stands_sf[stands_sf$Local == 2, ]

  if (nrow(stands_filtrados) == 0 || nrow(donut) == 0) {
    saveRDS(data.frame(), out_rds)
    df_empty <- data.frame(Stand_IDv2 = integer(), value_tmp = numeric())
    names(df_empty)[2] <- metric_col
    write.csv(df_empty, out_csv, row.names = FALSE)
    return(df_empty)
  }

  raster_obj <- raster(raster_path)

  cl <- makeCluster(min(n_cores, nrow(donut)), type = "SOCK")
  on.exit(stopCluster(cl), add = TRUE)
  registerDoSNOW(cl)
  on.exit(registerDoSEQ(), add = TRUE)

  pb <- txtProgressBar(max = nrow(donut), style = 3)
  on.exit(close(pb), add = TRUE)

  progress <- function(n) {
    setTxtProgressBar(pb, n)
    flush.console()
  }
  opts <- list(progress = progress)

  df_final <- foreach(
    i = seq_len(nrow(donut)),
    .combine = rbind,
    .packages = c("sf", "exactextractr", "raster"),
    .options.snow = opts,
    .export = c("stands_filtrados", "donut", "raster_obj")
  ) %dopar% {
    donut_loop <- donut[i, ]

    stands_loop <- st_intersection(stands_filtrados, donut_loop)
    if (nrow(stands_loop) == 0) return(NULL)

    stands_loop <- st_collection_extract(stands_loop, "POLYGON")
    if (nrow(stands_loop) == 0) return(NULL)

    df_loop_list <- exactextractr::exact_extract(raster_obj, stands_loop)
    if (length(df_loop_list) == 0) return(NULL)

    for (j in seq_along(df_loop_list)) {
      if (is.null(df_loop_list[[j]]) || nrow(df_loop_list[[j]]) == 0) next
      df_loop_list[[j]]$Stand_IDv2 <- stands_loop$Stand_IDv2[j]
      df_loop_list[[j]]$comunidade_id <- donut$fid_u[i]
    }

    df_loop_list <- Filter(function(x) !is.null(x) && nrow(x) > 0, df_loop_list)
    if (length(df_loop_list) == 0) return(NULL)

    df_loop <- do.call(rbind, df_loop_list)
    df_loop$rast_weighted <- df_loop$value * df_loop$coverage_fraction
    df_loop
  }

  if (is.null(df_final) || nrow(df_final) == 0) {
    df_sum <- data.frame(Stand_IDv2 = integer(), value_tmp = numeric())
    names(df_sum)[2] <- metric_col
  } else {
    df_sum <- as.data.frame(
      df_final %>%
        group_by(Stand_IDv2) %>%
        summarise(value_tmp = sum(rast_weighted, na.rm = TRUE), .groups = "drop")
    )
    names(df_sum)[names(df_sum) == "value_tmp"] <- metric_col
  }

  saveRDS(if (is.null(df_final)) data.frame() else df_final, out_rds)
  write.csv(df_sum, out_csv, row.names = FALSE)

  df_sum
}

ensure_openfilegdb_write_support <- function() {
  drivers <- sf::st_drivers(what = "vector")
  has_openfilegdb <- any(drivers$name == "OpenFileGDB" & drivers$write)
  if (!has_openfilegdb) {
    stop(
      paste(
        "Sem suporte GDAL para escrita OpenFileGDB.",
        "Instala/usa um ambiente com driver OpenFileGDB (write = TRUE)."
      ),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

export_arcgis_copy <- function(sf_obj, gdb_path, layer_name) {
  print("funcao export_arcgis_copy iniciou")
  on.exit(print("funcao export_arcgis_copy terminou"), add = TRUE)

  if (!inherits(sf_obj, "sf")) {
    stop("export_arcgis_copy: sf_obj tem de ser um objeto sf.", call. = FALSE)
  }
  if (!is.character(gdb_path) || length(gdb_path) != 1 || !nzchar(gdb_path)) {
    stop("export_arcgis_copy: gdb_path invalido.", call. = FALSE)
  }
  if (!is.character(layer_name) || length(layer_name) != 1 || !nzchar(layer_name)) {
    stop("export_arcgis_copy: layer_name invalido.", call. = FALSE)
  }

  ensure_openfilegdb_write_support()

  dir.create(dirname(gdb_path), recursive = TRUE, showWarnings = FALSE)

  sf_arcgis <- sf_obj
  sf_arcgis <- st_make_valid(sf_arcgis)
  sf_arcgis <- st_zm(sf_arcgis, drop = TRUE, what = "ZM")
  sf_arcgis <- st_collection_extract(sf_arcgis, "POLYGON", warn = FALSE)
  sf_arcgis <- sf_arcgis[!st_is_empty(sf_arcgis), , drop = FALSE]
  sf_arcgis <- st_cast(sf_arcgis, "MULTIPOLYGON", warn = FALSE)
  sf_arcgis <- sf_arcgis[!st_is_empty(sf_arcgis), , drop = FALSE]

  if (nrow(sf_arcgis) == 0) {
    warning(
      paste0(
        "export_arcgis_copy: sem feicoes apos normalizacao para a layer '",
        layer_name,
        "'."
      ),
      call. = FALSE
    )
    return(invisible(NULL))
  }

  st_write(
    sf_arcgis,
    dsn = gdb_path,
    layer = layer_name,
    driver = "OpenFileGDB",
    delete_layer = TRUE,
    quiet = TRUE
  )
  print(paste0("st_write ", layer_name, ": ", normalizePath(gdb_path, winslash = "/", mustWork = FALSE)))

  invisible(sf_arcgis)
}

update_stands_exposicao <- function(
  stands_base,
  stands_exposicao_path,
  update_tables = list(),
  recalc_scope = c("interface", "lcp", "all")
) {
  print("funcao update_stands_exposicao iniciou")
  on.exit(print("funcao update_stands_exposicao terminou"), add = TRUE)

  recalc_scope <- match.arg(recalc_scope)
  stands_exposicao_layer <- vector_layer_or_null(stands_exposicao_path, "stands_alg_expo")

  stands_out <- tryCatch(
    read_vector(stands_exposicao_path, layer = stands_exposicao_layer, quiet = TRUE),
    error = function(e) NULL
  )
  if (is.null(stands_out)) stands_out <- stands_base

  if (!"Stand_IDv2" %in% names(stands_out)) stop("Falta Stand_IDv2 em stands_exposicao.")

  metric_cols <- c(
    "d100_Ed", "d100_Vn", "d100_Ve",
    "d500_Ed", "d500_Vn", "d500_Ve",
    "d1000_Ed", "d1000_Vn", "d1000_Ve"
  )
  derived_cols <- c("PFl_Ed", "PFl_Vn", "PFl_Ve", "PBr_Ed", "PBr_Vn", "PBr_Ve")
  interface_metric_cols <- c("d100_Ed")
  interface_cols <- c(interface_metric_cols, "PFl_Ed")
  lcp_metric_cols <- c(
    "d500_Ed", "d1000_Ed",
    "d100_Vn", "d500_Vn", "d1000_Vn",
    "d100_Ve", "d500_Ve", "d1000_Ve"
  )
  lcp_cols <- c(lcp_metric_cols, "PFl_Vn", "PFl_Ve", "PBr_Ed", "PBr_Vn", "PBr_Ve")

  for (col in c(metric_cols, derived_cols)) {
    if (!col %in% names(stands_out)) stands_out[[col]] <- rep(-1, nrow(stands_out))
    stands_out[[col]] <- as.numeric(stands_out[[col]])
  }

  keep_cols <- unique(c(names(stands_base), metric_cols, derived_cols))
  drop_cols <- setdiff(names(stands_out), keep_cols)
  if (length(drop_cols) > 0) stands_out <- stands_out[, setdiff(names(stands_out), drop_cols)]

  for (tbl in update_tables) {
    if (is.null(tbl) || nrow(tbl) == 0) next
    if (!"Stand_IDv2" %in% names(tbl)) stop("Tabela de update sem Stand_IDv2.")

    metric_col <- setdiff(names(tbl), "Stand_IDv2")
    if (length(metric_col) != 1) stop("Cada tabela de update deve ter apenas 1 coluna de metrica alem de Stand_IDv2.")
    metric_col <- metric_col[1]
    if (!metric_col %in% metric_cols) stop(paste("Coluna de metrica inesperada:", metric_col))

    idx <- match(stands_out$Stand_IDv2, tbl$Stand_IDv2)
    matched <- !is.na(idx)
    if (any(matched)) {
      new_values <- as.numeric(tbl[[metric_col]][idx[matched]])
      new_values[is.na(new_values)] <- -1
      stands_out[[metric_col]][matched] <- new_values
    }
  }

  if (!"Local" %in% names(stands_out)) {
    stop("Falta Local em stands_exposicao.")
  }
  local_num <- suppressWarnings(as.integer(as.character(stands_out$Local)))
  idx_local1 <- !is.na(local_num) & local_num == 1
  idx_local2 <- !is.na(local_num) & local_num == 2

  stands_out[!idx_local1, interface_cols] <- -1
  stands_out[!idx_local2, lcp_cols] <- -1

  if (recalc_scope %in% c("interface", "all")) {
    stands_out$d100_Ed[idx_local1 & (is.na(stands_out$d100_Ed) | stands_out$d100_Ed == -1)] <- 0
    stands_out$PFl_Ed[idx_local1] <- stands_out$d100_Ed[idx_local1]
  }

  if (recalc_scope %in% c("lcp", "all")) {
    for (col in lcp_metric_cols) {
      stands_out[[col]][idx_local2 & (is.na(stands_out[[col]]) | stands_out[[col]] == -1)] <- 0
    }
    stands_out$PFl_Vn[idx_local2] <- stands_out$d100_Vn[idx_local2]
    stands_out$PFl_Ve[idx_local2] <- stands_out$d100_Ve[idx_local2]
    stands_out$PBr_Ed[idx_local2] <- stands_out$d500_Ed[idx_local2] + stands_out$d1000_Ed[idx_local2]
    stands_out$PBr_Vn[idx_local2] <- stands_out$d500_Vn[idx_local2] + stands_out$d1000_Vn[idx_local2]
    stands_out$PBr_Ve[idx_local2] <- stands_out$d500_Ve[idx_local2] + stands_out$d1000_Ve[idx_local2]
  }

  for (col in c(metric_cols, derived_cols)) {
    stands_out[[col]][is.na(stands_out[[col]])] <- -1
  }

  # Evita geometrias problematicas em outputs lidos no ArcGIS Pro.
  stands_out <- st_make_valid(stands_out)

  write_vector(
    stands_out,
    stands_exposicao_path,
    layer = stands_exposicao_layer,
    quiet = TRUE
  )

  invisible(stands_out)
}

expo_values_correction <- function(stands_exposicao_path) {
  print("funcao expo_values_correction iniciou")
  on.exit(print("funcao expo_values_correction terminou"), add = TRUE)

  stands_exposicao_layer <- vector_layer_or_null(stands_exposicao_path, "stands_alg_expo")

  shape <- read_vector(stands_exposicao_path, layer = stands_exposicao_layer, quiet = TRUE)

  interface_cols <- c("d100_Ed", "PFl_Ed")
  lcp_cols <- c(
    "d500_Ed", "d1000_Ed",
    "d100_Vn", "d500_Vn", "d1000_Vn",
    "d100_Ve", "d500_Ve", "d1000_Ve",
    "PFl_Vn", "PFl_Ve",
    "PBr_Ed", "PBr_Vn", "PBr_Ve"
  )
  cols <- unique(c(interface_cols, lcp_cols))

  if (!"exposicao" %in% names(shape)) {
    stop("Nao foi encontrado o campo obrigatorio 'exposicao' em stands_exposicao.")
  }
  expo_col <- "exposicao"
  cols_existentes <- intersect(cols, names(shape))
  if (length(cols_existentes) == 0) {
    write_vector(
      shape,
      stands_exposicao_path,
      layer = stands_exposicao_layer,
      quiet = TRUE
    )

    return(invisible(shape))
  }
  if (!"Local" %in% names(shape)) {
    stop("Falta coluna Local em stands_exposicao.")
  }

  to_numeric_safe <- function(x) suppressWarnings(as.numeric(as.character(x)))

  expo_vals <- to_numeric_safe(shape[[expo_col]])
  local_num <- suppressWarnings(as.integer(as.character(shape$Local)))
  idx_local1 <- !is.na(local_num) & local_num == 1
  idx_local2 <- !is.na(local_num) & local_num == 2
  mask_zero <- !is.na(expo_vals) & expo_vals == 0

  interface_existentes <- intersect(interface_cols, cols_existentes)
  for (col in interface_existentes) {
    vals <- to_numeric_safe(shape[[col]])
    vals[!idx_local1] <- -1
    vals[mask_zero & idx_local1 & !is.na(vals) & vals != -1] <- 0
    shape[[col]] <- vals
  }

  lcp_existentes <- intersect(lcp_cols, cols_existentes)
  for (col in lcp_existentes) {
    vals <- to_numeric_safe(shape[[col]])
    vals[!idx_local2] <- -1
    vals[mask_zero & idx_local2 & !is.na(vals) & vals != -1] <- 0
    shape[[col]] <- vals
  }

  for (col in cols_existentes) {
    vals <- to_numeric_safe(shape[[col]])
    vals[is.na(vals)] <- -1
    shape[[col]] <- vals
  }

  # Revalida geometrias antes de escrever para reduzir erros de integridade no ArcGIS.
  shape <- st_make_valid(shape)

  write_vector(
    shape,
    stands_exposicao_path,
    layer = stands_exposicao_layer,
    quiet = TRUE
  )

  invisible(shape)
}

gerar_stands_exposicao_limpa <- function(
  stands_exposicao_path = stands_exposicao,
  stands_exposicao_layer = NULL,
  stands_exposicao_limpa_path = stands_exposicao_limpa,
  stands_exposicao_limpa_layer = NULL,
  verbose = FALSE
) {
  quiet_mode <- !isTRUE(verbose)
  stands_exposicao_layer_use <- vector_layer_or_null(stands_exposicao_path, stands_exposicao_layer)
  stands_exposicao_limpa_layer_use <- vector_layer_or_null(stands_exposicao_limpa_path, stands_exposicao_limpa_layer)

  stands_sf <- read_vector(
    stands_exposicao_path,
    layer = stands_exposicao_layer_use,
    quiet = quiet_mode
  )

  geom_type_chr <- as.character(st_geometry_type(stands_sf, by_geometry = TRUE))
  idx_descartar <- geom_type_chr %in% c("POINT", "MULTIPOINT", "LINESTRING", "MULTILINESTRING")

  n_total <- nrow(stands_sf)
  n_descartar <- sum(idx_descartar, na.rm = TRUE)

  stands_limpa <- stands_sf[!idx_descartar, , drop = FALSE]
  stands_limpa <- st_make_valid(stands_limpa)
  stands_limpa <- st_collection_extract(stands_limpa, "POLYGON", warn = FALSE)
  stands_limpa <- stands_limpa[!st_is_empty(stands_limpa), , drop = FALSE]
  if (nrow(stands_limpa) > 0) {
    stands_limpa <- st_cast(stands_limpa, "MULTIPOLYGON", warn = FALSE)
  }

  dir.create(dirname(stands_exposicao_limpa_path), recursive = TRUE, showWarnings = FALSE)
  write_vector(
    stands_limpa,
    stands_exposicao_limpa_path,
    layer = stands_exposicao_limpa_layer_use,
    quiet = quiet_mode
  )

  if (isTRUE(verbose)) {
    cat(sprintf(
      "stands_exposicao_limpa criado: total=%d | removidos (linha/ponto)=%d | restantes=%d\n",
      n_total,
      n_descartar,
      nrow(stands_limpa)
    ))
  }

  invisible(stands_limpa)
}

## # - IDENTIFICAR AREAS PRIORITARIAS - INTERFACE ####
informacao_UTs <- function(
  stands_exposicao_path,
  stands_gestao_interface_path = stands_gestao_interface
) {
  print("funcao informacao_UTs iniciou")
  on.exit(print("funcao informacao_UTs terminou"), add = TRUE)

  stands_exposicao_layer <- vector_layer_or_null(stands_exposicao_path, "stands_alg_expo")
  stands_gestao_layer <- vector_layer_or_null(stands_gestao_interface_path, "stands_alg_interface")

  stands_exposicao_sf <- read_vector(stands_exposicao_path, layer = stands_exposicao_layer, quiet = TRUE)
  stands_exposicao_sf <- st_make_valid(stands_exposicao_sf)

  required_cols <- c("PFl_Ed", "AREA_ha", "Local", "gerivel", "municipio")
  missing_cols <- setdiff(required_cols, names(stands_exposicao_sf))
  if (length(missing_cols) > 0) {
    stop(
      paste(
        "Faltam colunas obrigatorias em stands_exposicao (municipio deve vir de stands_edificado):",
        paste(missing_cols, collapse = ", ")
      )
    )
  }

  stands_exposicao_sf$PFl_Ed <- as.numeric(stands_exposicao_sf$PFl_Ed)
  stands_exposicao_sf$AREA_ha <- as.numeric(stands_exposicao_sf$AREA_ha)

  stands_exposicao_sf$PFl_EdNorm <- ifelse(
    is.na(stands_exposicao_sf$AREA_ha) | stands_exposicao_sf$AREA_ha <= 0,
    0,
    stands_exposicao_sf$PFl_Ed / stands_exposicao_sf$AREA_ha
  )

  local_num <- suppressWarnings(as.integer(as.character(stands_exposicao_sf$Local)))
  gerivel_num <- suppressWarnings(as.integer(as.character(stands_exposicao_sf$gerivel)))
  stands_exposicao_sf$geriv_Ed <- ifelse(
    !is.na(local_num) & !is.na(gerivel_num) & local_num == 1 & gerivel_num == 1,
    1,
    0
  )

  # Revalida geometrias antes de gravar output consumido no ArcGIS.
  stands_exposicao_sf <- st_make_valid(stands_exposicao_sf)

  dir.create(dirname(stands_gestao_interface_path), recursive = TRUE, showWarnings = FALSE)
  write_vector(
    stands_exposicao_sf,
    stands_gestao_interface_path,
    layer = stands_gestao_layer,
    quiet = TRUE
  )

  stands_exposicao_sf
}

prioridade_absoluta <- function(
  stands_gestao_interface_path = stands_gestao_interface
) {
  print("funcao prioridade_absoluta iniciou")
  on.exit(print("funcao prioridade_absoluta terminou"), add = TRUE)

  stands_gestao_layer <- vector_layer_or_null(stands_gestao_interface_path, "stands_alg_interface")

  stands_gestao_sf <- read_vector(stands_gestao_interface_path, layer = stands_gestao_layer, quiet = TRUE)

  required_cols <- c("PFl_EdNorm", "geriv_Ed")
  missing_cols <- setdiff(required_cols, names(stands_gestao_sf))
  if (length(missing_cols) > 0) {
    stop(
      paste(
        "Faltam colunas obrigatorias em stands_gestao_interface:",
        paste(missing_cols, collapse = ", ")
      )
    )
  }

  stands_gestao_sf$PFl_EdNorm <- as.numeric(stands_gestao_sf$PFl_EdNorm)
  geriv_num <- suppressWarnings(as.numeric(as.character(stands_gestao_sf$geriv_Ed)))

  stands_gestao_sf$PAbs_pct <- -1L
  idx_class <- !is.na(geriv_num) & geriv_num == 1 & !is.na(stands_gestao_sf$PFl_EdNorm) & stands_gestao_sf$PFl_EdNorm >= 0

  if (any(idx_class)) {
    values <- stands_gestao_sf$PFl_EdNorm[idx_class]
    idx_values <- which(idx_class)

    ord <- order(values, seq_along(values))
    idx_sorted <- idx_values[ord]
    n_sel <- length(idx_sorted)

    pct_class <- as.integer(floor(((seq_len(n_sel) - 1) * 10) / n_sel) + 1)
    pct_class[n_sel] <- 10

    stands_gestao_sf$PAbs_pct[idx_sorted] <- pct_class

    max_val <- max(values, na.rm = TRUE)
    idx_max <- idx_class & stands_gestao_sf$PFl_EdNorm == max_val
    stands_gestao_sf$PAbs_pct[idx_max] <- 10
  }

  # Revalida geometrias antes de gravar output final.
  stands_gestao_sf <- st_make_valid(stands_gestao_sf)

  dir.create(dirname(stands_gestao_interface_path), recursive = TRUE, showWarnings = FALSE)
  write_vector(
    stands_gestao_sf,
    stands_gestao_interface_path,
    layer = stands_gestao_layer,
    quiet = TRUE
  )

  stands_gestao_sf
}

prioridade_relativa <- function(
  stands_gestao_interface_path = stands_gestao_interface
) {
  print("funcao prioridade_relativa iniciou")
  on.exit(print("funcao prioridade_relativa terminou"), add = TRUE)

  stands_gestao_layer <- vector_layer_or_null(stands_gestao_interface_path, "stands_alg_interface")

  stands_gestao_sf <- read_vector(stands_gestao_interface_path, layer = stands_gestao_layer, quiet = TRUE)

  required_cols <- c("PFl_EdNorm", "geriv_Ed", "municipio")
  missing_cols <- setdiff(required_cols, names(stands_gestao_sf))
  if (length(missing_cols) > 0) {
    stop(
      paste(
        "Faltam colunas obrigatorias em stands_gestao_interface:",
        paste(missing_cols, collapse = ", ")
      )
    )
  }

  stands_gestao_sf$PFl_EdNorm <- as.numeric(stands_gestao_sf$PFl_EdNorm)
  geriv_num <- suppressWarnings(as.numeric(as.character(stands_gestao_sf$geriv_Ed)))
  municipio_chr <- trimws(as.character(stands_gestao_sf$municipio))

  stands_gestao_sf$PRel_pct <- -1L
  idx_base <- !is.na(geriv_num) &
    geriv_num == 1 &
    !is.na(stands_gestao_sf$PFl_EdNorm) &
    stands_gestao_sf$PFl_EdNorm >= 0 &
    !is.na(municipio_chr) &
    nzchar(municipio_chr)

  if (any(idx_base)) {
    municipios <- sort(unique(municipio_chr[idx_base]))

    for (mun in municipios) {
      idx_class <- idx_base & municipio_chr == mun
      if (!any(idx_class)) next

      values <- stands_gestao_sf$PFl_EdNorm[idx_class]
      idx_values <- which(idx_class)

      ord <- order(values, seq_along(values))
      idx_sorted <- idx_values[ord]
      n_sel <- length(idx_sorted)
      if (n_sel == 0) next

      pct_class <- as.integer(floor(((seq_len(n_sel) - 1) * 10) / n_sel) + 1)
      pct_class[n_sel] <- 10

      stands_gestao_sf$PRel_pct[idx_sorted] <- pct_class

      max_val <- max(values, na.rm = TRUE)
      idx_max <- idx_class & stands_gestao_sf$PFl_EdNorm == max_val
      stands_gestao_sf$PRel_pct[idx_max] <- 10
    }
  }

  # Revalida geometrias antes de gravar output final.
  stands_gestao_sf <- st_make_valid(stands_gestao_sf)

  dir.create(dirname(stands_gestao_interface_path), recursive = TRUE, showWarnings = FALSE)
  write_vector(
    stands_gestao_sf,
    stands_gestao_interface_path,
    layer = stands_gestao_layer,
    quiet = TRUE
  )

  stands_gestao_sf
}

readme_manifesto_blocos <- function() {
  list(
    bloco_donuts = list(
      inputs = c(
        shp_aglomerados_base,
        shp_valor_natural_base,
        shp_valor_economico_base
      ),
      outputs = c(
        shp_aglomerados_0_100,
        shp_aglomerados_100_500,
        shp_aglomerados_500_1000,
        shp_valor_natural_0_100,
        shp_valor_natural_100_500,
        shp_valor_natural_500_1000,
        shp_valor_economico_0_100,
        shp_valor_economico_100_500,
        shp_valor_economico_500_1000
      )
    ),
    bloco_unidades_tratamento = list(
      inputs = c(
        shp_stands_base,
        shp_aglomerados_0_100,
        shp_aglomerados_base,
        shp_municipios
      ),
      outputs = c(
        shp_interface_dissolve,
        stands_interface_int,
        stands_interface_diss,
        stands_interface_final,
        stands_erase_single,
        interface_diss_completa,
        stands_aglom_int,
        stands_aglom_int_diss,
        stands_sem_aglomerado,
        shp_stands_interface_edf,
        shp_stands_interface_final
      )
    ),
    bloco_exposicao = list(
      inputs = c(
        shp_stands_interface_final,
        p_arder2virg5,
        p_arder3virg5,
        shp_aglomerados_0_100,
        shp_aglomerados_100_500,
        shp_aglomerados_500_1000,
        shp_valor_natural_0_100,
        shp_valor_natural_100_500,
        shp_valor_natural_500_1000,
        shp_valor_economico_0_100,
        shp_valor_economico_100_500,
        shp_valor_economico_500_1000
      ),
      outputs = c(
        df_final0a100_aglomerados,
        df_final0a100_valor_natural,
        df_final0a100_valor_economico,
        df_final0a100_weighted_sum_aglomerados,
        df_final0a100_weighted_sum_valor_natural,
        df_final0a100_weighted_sum_valor_economico,
        df_final100a500_aglomerados,
        df_final100a500_valor_natural,
        df_final100a500_valor_economico,
        df_final100a500_weighted_sum_aglomerados,
        df_final100a500_weighted_sum_valor_natural,
        df_final100a500_weighted_sum_valor_economico,
        df_final500a1000_aglomerados,
        df_final500a1000_valor_natural,
        df_final500a1000_valor_economico,
        df_final500a1000_weighted_sum_aglomerados,
        df_final500a1000_weighted_sum_valor_natural,
        df_final500a1000_weighted_sum_valor_economico,
        stands_exposicao,
        stands_exposicao_limpa
      )
    ),
    bloco_prioridades_interface = list(
      inputs = c(
        stands_exposicao,
        stands_gestao_interface
      ),
      outputs = c(
        stands_gestao_interface
      )
    )
  )
}

atualizar_readme_bloco <- function(
  bloco_nome,
  readme_path = README,
  comentarios_txt = comentarios
) {
  manifesto <- readme_manifesto_blocos()
  if (!bloco_nome %in% names(manifesto)) {
    stop(paste("Bloco invalido para README:", bloco_nome), call. = FALSE)
  }

  normalize_paths <- function(x) {
    x <- as.character(x)
    x <- x[!is.na(x) & nzchar(x)]
    unique(x)
  }

  remove_section_marked <- function(lines, begin_marker, end_marker) {
    if (length(lines) == 0) return(lines)
    i_begin <- which(lines == begin_marker)
    i_end <- which(lines == end_marker)
    if (length(i_begin) == 0 || length(i_end) == 0) return(lines)
    start <- i_begin[1]
    end_candidates <- i_end[i_end >= start]
    if (length(end_candidates) == 0) return(lines)
    end <- end_candidates[1]
    lines[-seq.int(start, end)]
  }

  format_path_list <- function(paths) {
    if (length(paths) == 0) return("  - (nenhum)")
    paste0("  - ", paths)
  }

  dir.create(dirname(readme_path), recursive = TRUE, showWarnings = FALSE)

  existing <- if (file.exists(readme_path)) {
    readLines(readme_path, warn = FALSE, encoding = "UTF-8")
  } else {
    character(0)
  }

  header_begin <- "### README_HEADER_BEGIN"
  header_end <- "### README_HEADER_END"
  existing <- remove_section_marked(existing, header_begin, header_end)

  block_begin <- paste0("### BLOCO_BEGIN: ", bloco_nome)
  block_end <- paste0("### BLOCO_END: ", bloco_nome)
  existing <- remove_section_marked(existing, block_begin, block_end)

  bloco <- manifesto[[bloco_nome]]
  inputs <- normalize_paths(bloco$inputs)
  outputs <- normalize_paths(bloco$outputs)

  ts <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cabecalho <- c(
    header_begin,
    paste0("Analise: ", nome_analise),
    paste0("Diretorio output: ", dir_output_analise),
    paste0("README: ", readme_path),
    paste0("Comentario: ", as.character(comentarios_txt)),
    paste0("Ultima atualizacao: ", ts),
    header_end
  )

  bloco_lines <- c(
    block_begin,
    paste0("Bloco: ", bloco_nome),
    paste0("Concluido em: ", ts),
    "Inputs:",
    format_path_list(inputs),
    "Outputs:",
    format_path_list(outputs),
    block_end
  )

  body <- existing
  while (length(body) > 0 && !nzchar(body[1])) body <- body[-1]
  while (length(body) > 0 && !nzchar(body[length(body)])) body <- body[-length(body)]

  novo <- c(
    cabecalho,
    "",
    if (length(body) > 0) body else character(0),
    if (length(body) > 0) "" else character(0),
    bloco_lines,
    ""
  )

  writeLines(novo, readme_path, useBytes = TRUE)
  invisible(readme_path)
}

## # - RUNNERS DE BLOCO ####
executar_bloco_donuts <- function() {
  print("bloco CRIAR DONNUTS iniciou")
  on.exit(print("bloco CRIAR DONNUTS terminou"), add = TRUE)

  print("[executar_bloco_donuts] criar_donuts_valor_chave iniciou")
  criar_donuts_valor_chave(
    tipo_valor_chave = tipo_valor_chave,
    shp_aglomerados_base = shp_aglomerados_base,
    shp_valor_natural_base = shp_valor_natural_base,
    shp_valor_economico_base = shp_valor_economico_base,
    shp_aglomerados_0_100 = shp_aglomerados_0_100,
    shp_aglomerados_100_500 = shp_aglomerados_100_500,
    shp_aglomerados_500_1000 = shp_aglomerados_500_1000,
    shp_valor_natural_0_100 = shp_valor_natural_0_100,
    shp_valor_natural_100_500 = shp_valor_natural_100_500,
    shp_valor_natural_500_1000 = shp_valor_natural_500_1000,
    shp_valor_economico_0_100 = shp_valor_economico_0_100,
    shp_valor_economico_100_500 = shp_valor_economico_100_500,
    shp_valor_economico_500_1000 = shp_valor_economico_500_1000
  )
  print("[executar_bloco_donuts] criar_donuts_valor_chave terminou")
  print("[executar_bloco_donuts] atualizar_readme_bloco iniciou")
  atualizar_readme_bloco("bloco_donuts")
  print("[executar_bloco_donuts] atualizar_readme_bloco terminou")
}

executar_bloco_unidades_tratamento <- function(
  n_cores_correcao = 1,
  progress_por_core = TRUE
) {
  print("bloco UNIDADES DE TRATAMENTO iniciou")
  on.exit(print("bloco UNIDADES DE TRATAMENTO terminou"), add = TRUE)

  print("[executar_bloco_unidades_tratamento] stands_interface iniciou")
  stands_interface(
    shp_aglomerados_0_100 = shp_aglomerados_0_100,
    shp_stands_base = shp_stands_base,
    shp_interface_dissolve = shp_interface_dissolve,
    stands_interface_int = stands_interface_int,
    stands_interface_diss = stands_interface_diss,
    stands_interface_final = stands_interface_final,
    stands_erase_single = stands_erase_single,
    interface_diss_completa = interface_diss_completa
  )
  print("[executar_bloco_unidades_tratamento] stands_interface terminou")

  print("[executar_bloco_unidades_tratamento] stands_edificado iniciou")
  stands_edificado(
    shp_aglomerados_base = shp_aglomerados_base,
    interface_diss_completa = interface_diss_completa,
    stands_aglom_int = stands_aglom_int,
    stands_aglom_int_diss = stands_aglom_int_diss,
    stands_sem_aglomerado = stands_sem_aglomerado,
    shp_stands_interface_edf = shp_stands_interface_edf
  )
  print("[executar_bloco_unidades_tratamento] stands_edificado terminou")

  print("[executar_bloco_unidades_tratamento] correcao_stands_final iniciou")
  correcao_stands_final(
    shp_stands_interface_edf = shp_stands_interface_edf,
    shp_stands_interface_final = shp_stands_interface_final,
    threshold_eliminate_ha = threshold_eliminate_ha_correcao,
    n_cores_correcao = n_cores_correcao,
    progress_por_core = progress_por_core,
    verbose = verbose_correcao_stands_final
  )
  print("[executar_bloco_unidades_tratamento] correcao_stands_final terminou")

  print("[executar_bloco_unidades_tratamento] atualizar_readme_bloco iniciou")
  atualizar_readme_bloco("bloco_unidades_tratamento")
  print("[executar_bloco_unidades_tratamento] atualizar_readme_bloco terminou")

  invisible(NULL)
}

executar_bloco_exposicao <- function(n_cores = n_cores) {
  print("bloco EXPOSICAO iniciou")
  on.exit(print("bloco EXPOSICAO terminou"), add = TRUE)

  dirs_out <- unique(c(
    dirname(df_final0a100_aglomerados),
    dirname(df_final100a500_aglomerados),
    dirname(df_final500a1000_aglomerados),
    dirname(stands_exposicao),
    dirname(stands_exposicao_limpa)
  ))
  for (d in dirs_out) dir.create(d, recursive = TRUE, showWarnings = FALSE)

  print("[executar_bloco_exposicao] read_vector stands iniciou")
  stands <- read_vector(
    shp_stands_interface_final,
    layer = layer_shp_stands_interface_final,
    quiet = TRUE
  )
  print("[executar_bloco_exposicao] read_vector stands terminou")
  if (!"Stand_IDv2" %in% names(stands)) stop("Falta Stand_IDv2 em shp_stands_interface_final.")
  if (!"Local" %in% names(stands)) stop("Falta Local em shp_stands_interface_final.")

  print("[executar_bloco_exposicao] run_exposure_interface 0_100 aglomerados iniciou")
  sum_agl_0_100 <- run_exposure_interface(
    shp_aglomerados_0_100, stands, p_arder2virg5,
    df_final0a100_aglomerados, df_final0a100_weighted_sum_aglomerados,
    metric_col = "d100_Ed",
    n_cores = n_cores
  )
  print("[executar_bloco_exposicao] run_exposure_interface 0_100 aglomerados terminou")

  print("[executar_bloco_exposicao] update_stands_exposicao interface iniciou")
  update_stands_exposicao(
    stands_base = stands,
    stands_exposicao_path = stands_exposicao,
    update_tables = list(sum_agl_0_100),
    recalc_scope = "interface"
  )
  print("[executar_bloco_exposicao] update_stands_exposicao interface terminou")

  print("[executar_bloco_exposicao] expo_values_correction (1) iniciou")
  expo_values_correction(stands_exposicao)
  print("[executar_bloco_exposicao] expo_values_correction (1) terminou")

  print("[executar_bloco_exposicao] run_exposure_lcp 100_500 aglomerados iniciou")
  sum_agl_100_500 <- run_exposure_lcp(
    shp_aglomerados_100_500, stands, p_arder2virg5,
    df_final100a500_aglomerados, df_final100a500_weighted_sum_aglomerados,
    metric_col = "d500_Ed",
    n_cores = n_cores
  )
  print("[executar_bloco_exposicao] run_exposure_lcp 100_500 aglomerados terminou")
  print("[executar_bloco_exposicao] run_exposure_lcp 500_1000 aglomerados iniciou")
  sum_agl_500_1000 <- run_exposure_lcp(
    shp_aglomerados_500_1000, stands, p_arder3virg5,
    df_final500a1000_aglomerados, df_final500a1000_weighted_sum_aglomerados,
    metric_col = "d1000_Ed",
    n_cores = n_cores
  )
  print("[executar_bloco_exposicao] run_exposure_lcp 500_1000 aglomerados terminou")

  print("[executar_bloco_exposicao] run_exposure_lcp 0_100 valor_natural iniciou")
  sum_vn_0_100 <- run_exposure_lcp(
    shp_valor_natural_0_100, stands, p_arder2virg5,
    df_final0a100_valor_natural, df_final0a100_weighted_sum_valor_natural,
    metric_col = "d100_Vn",
    n_cores = n_cores
  )
  print("[executar_bloco_exposicao] run_exposure_lcp 0_100 valor_natural terminou")
  print("[executar_bloco_exposicao] run_exposure_lcp 100_500 valor_natural iniciou")
  sum_vn_100_500 <- run_exposure_lcp(
    shp_valor_natural_100_500, stands, p_arder2virg5,
    df_final100a500_valor_natural, df_final100a500_weighted_sum_valor_natural,
    metric_col = "d500_Vn",
    n_cores = n_cores
  )
  print("[executar_bloco_exposicao] run_exposure_lcp 100_500 valor_natural terminou")
  print("[executar_bloco_exposicao] run_exposure_lcp 500_1000 valor_natural iniciou")
  sum_vn_500_1000 <- run_exposure_lcp(
    shp_valor_natural_500_1000, stands, p_arder3virg5,
    df_final500a1000_valor_natural, df_final500a1000_weighted_sum_valor_natural,
    metric_col = "d1000_Vn",
    n_cores = n_cores
  )
  print("[executar_bloco_exposicao] run_exposure_lcp 500_1000 valor_natural terminou")

  print("[executar_bloco_exposicao] run_exposure_lcp 0_100 valor_economico iniciou")
  sum_ve_0_100 <- run_exposure_lcp(
    shp_valor_economico_0_100, stands, p_arder2virg5,
    df_final0a100_valor_economico, df_final0a100_weighted_sum_valor_economico,
    metric_col = "d100_Ve",
    n_cores = n_cores
  )
  print("[executar_bloco_exposicao] run_exposure_lcp 0_100 valor_economico terminou")
  print("[executar_bloco_exposicao] run_exposure_lcp 100_500 valor_economico iniciou")
  sum_ve_100_500 <- run_exposure_lcp(
    shp_valor_economico_100_500, stands, p_arder2virg5,
    df_final100a500_valor_economico, df_final100a500_weighted_sum_valor_economico,
    metric_col = "d500_Ve",
    n_cores = n_cores
  )
  print("[executar_bloco_exposicao] run_exposure_lcp 100_500 valor_economico terminou")
  print("[executar_bloco_exposicao] run_exposure_lcp 500_1000 valor_economico iniciou")
  sum_ve_500_1000 <- run_exposure_lcp(
    shp_valor_economico_500_1000, stands, p_arder3virg5,
    df_final500a1000_valor_economico, df_final500a1000_weighted_sum_valor_economico,
    metric_col = "d1000_Ve",
    n_cores = n_cores
  )
  print("[executar_bloco_exposicao] run_exposure_lcp 500_1000 valor_economico terminou")

  print("[executar_bloco_exposicao] update_stands_exposicao lcp iniciou")
  update_stands_exposicao(
    stands_base = stands,
    stands_exposicao_path = stands_exposicao,
    update_tables = list(
      sum_agl_100_500,
      sum_agl_500_1000,
      sum_vn_0_100,
      sum_vn_100_500,
      sum_vn_500_1000,
      sum_ve_0_100,
      sum_ve_100_500,
      sum_ve_500_1000
    ),
    recalc_scope = "lcp"
  )
  print("[executar_bloco_exposicao] update_stands_exposicao lcp terminou")

  print("[executar_bloco_exposicao] expo_values_correction (2) iniciou")
  expo_values_correction(stands_exposicao)
  print("[executar_bloco_exposicao] expo_values_correction (2) terminou")
  print("[executar_bloco_exposicao] gerar_stands_exposicao_limpa iniciou")
  gerar_stands_exposicao_limpa(
    stands_exposicao_path = stands_exposicao,
    stands_exposicao_limpa_path = stands_exposicao_limpa
  )
  print("[executar_bloco_exposicao] gerar_stands_exposicao_limpa terminou")

  print("[executar_bloco_exposicao] atualizar_readme_bloco iniciou")
  atualizar_readme_bloco("bloco_exposicao")
  print("[executar_bloco_exposicao] atualizar_readme_bloco terminou")

  invisible(NULL)
}

executar_bloco_prioridades_interface <- function() {
  print("bloco PRIORIDADES INTERFACE iniciou")
  on.exit(print("bloco PRIORIDADES INTERFACE terminou"), add = TRUE)

  print("[executar_bloco_prioridades_interface] informacao_UTs iniciou")
  stands_gestao_sf <- informacao_UTs(stands_exposicao, stands_gestao_interface)
  print("[executar_bloco_prioridades_interface] informacao_UTs terminou")
  print("[executar_bloco_prioridades_interface] prioridade_absoluta iniciou")
  stands_gestao_sf <- prioridade_absoluta(stands_gestao_interface)
  print("[executar_bloco_prioridades_interface] prioridade_absoluta terminou")
  print("[executar_bloco_prioridades_interface] prioridade_relativa iniciou")
  stands_gestao_sf <- prioridade_relativa(stands_gestao_interface)
  print("[executar_bloco_prioridades_interface] prioridade_relativa terminou")
  print("[executar_bloco_prioridades_interface] atualizar_readme_bloco iniciou")
  atualizar_readme_bloco("bloco_prioridades_interface")
  print("[executar_bloco_prioridades_interface] atualizar_readme_bloco terminou")
  invisible(stands_gestao_sf)
}

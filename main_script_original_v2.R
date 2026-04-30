
## SCRIPT COMPLETO ## ## CENARIO_BAU_FUEL_ACUM_UT2023##

## BIBLIOTECAS ##
library(sf)
library(qgisprocess)
library(raster)
library(dplyr)
library(exactextractr)
library(tidyr)
library(snow)
library(doSNOW)
library(foreach)

## CAMINHOS ####

dir_inputs <- "C:/projetos/PIGCALG/09_resultados_2026_v2/Inputs"
dir_outputs <- "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise"

##INPUTS PRINCIPAIS ##

# Unidades de tratamento
shp_stands_base <- file.path(dir_inputs, "UTratamento/stands_alg_COS23_base.shp")

# Valores chave - bases
shp_aglomerados_base <- file.path(dir_inputs, "Valores_Chave/V2_2026/aglomerados/aglomerados.shp")
shp_valor_natural_base <- file.path(dir_inputs, "Valores_Chave/V2_2026/valor_natural/valor_natural.shp")
shp_valor_economico_base <- file.path(dir_inputs, "Valores_Chave/V2_2026/valor_economico/valor_economico.shp")

# Probabilidade de arder com comprimento de chama
p_arder2virg5 <- file.path(dir_inputs, "Simulacoes/Prob_condicionada/Prob_cond_sup2virg5.tif")
p_arder3virg5 <- file.path(dir_inputs, "Simulacoes/Prob_condicionada/Prob_cond_sup3virg5.tif")

# Municipios Algarve
shp_municipios <- file.path(dir_inputs, "Municipios/algarve_mun.shp")

##INPUTS DONNUTS DOS VALORES CHAVE##

# Aglomerados
shp_aglomerados_0_100 <- file.path(dir_inputs, "Valores_Chave/V2_2026/aglomerados/aglomerados_0a100m.shp")
shp_aglomerados_100_500 <- file.path(dir_inputs, "Valores_Chave/V2_2026/aglomerados/aglomerados_100a500m.shp")
shp_aglomerados_500_1000 <- file.path(dir_inputs, "Valores_Chave/V2_2026/aglomerados/aglomerados_500a1000m.shp")

# Valor natural
shp_valor_natural_0_100 <- file.path(dir_inputs, "Valores_Chave/V2_2026/valor_natural/valor_natural_0a100m.shp")
shp_valor_natural_100_500 <- file.path(dir_inputs, "Valores_Chave/V2_2026/valor_natural/valor_natural_100a500m.shp")
shp_valor_natural_500_1000 <- file.path(dir_inputs, "Valores_Chave/V2_2026/valor_natural/valor_natural_500a1000m.shp")

# Valor economico
shp_valor_economico_0_100 <- file.path(dir_inputs, "Valores_Chave/V2_2026/valor_economico/valor_economico_0a100m.shp")
shp_valor_economico_100_500 <- file.path(dir_inputs, "Valores_Chave/V2_2026/valor_economico/valor_economico_100_500.shp")
shp_valor_economico_500_1000 <- file.path(dir_inputs, "Valores_Chave/V2_2026/valor_economico/valor_economico_500_1000.shp")


##OUTPUTS PRINCIPAIS ##
nome_analise <- "V4_20260423"

dir_output_analise <- file.path(dir_outputs, nome_analise)

#interface dissolvida
dir_interface <- file.path(dir_output_analise, "Interface")

shp_interface_dissolve <- file.path(dir_interface, "shp_interface_dissolve.shp")
stands_interface_int <- file.path(dir_interface, "stands_interface_int.shp")
stands_interface_diss <- file.path(dir_interface, "stands_interface_diss.shp")
stands_interface_final <- file.path(dir_interface, "stands_interface_final.shp")
stands_erase_single <- file.path(dir_interface, "stands_erase_single.shp")
interface_diss_completa <- file.path(dir_interface, "interface_diss_completa.shp")

#aglomerados na interface
dir_aglomerados <- file.path(dir_output_analise, "Aglomerados")

shp_aglomerados_base_sel <- file.path(dir_aglomerados, "shp_aglomerados_base_sel.shp")
stands_aglom_int <- file.path(dir_aglomerados, "stands_aglom_int.shp")
stands_aglom_int_diss <- file.path(dir_aglomerados, "stands_aglom_int_diss.shp")
stands_sem_aglomerado <- file.path(dir_aglomerados, "stands_sem_aglomerado.shp")
shp_stands_interface_edf <- file.path(dir_aglomerados, "shp_stands_interface_edf.shp")


# Unidades Tratamento
dir_unidades_tratamento <- file.path(dir_output_analise, "UTratamento")
shp_stands_interface_final <- file.path(dir_unidades_tratamento, "stands_alg_interface_final.shp")

# Exposicao
dir_exposicao <- file.path(dir_output_analise, "Exposicao")

#dataframes
dir_dataFrames <- file.path(dir_exposicao, "DataFrames")

# df0a100m
df_final0a100_aglomerados <- file.path(dir_dataFrames, "df_0a100/intermed0a100_Ed.rds")
df_final0a100_valor_natural <- file.path(dir_dataFrames, "df_0a100/intermed0a100_Vn.rds")
df_final0a100_valor_economico <- file.path(dir_dataFrames, "df_0a100/intermed0a100_Ve.rds")
df_final0a100_weighted_sum_aglomerados <- file.path(dir_dataFrames, "df_0a100/final0a100_Ed.csv")
df_final0a100_weighted_sum_valor_natural <- file.path(dir_dataFrames, "df_0a100/final0a100_Vn.csv")
df_final0a100_weighted_sum_valor_economico <- file.path(dir_dataFrames, "df_0a100/final0a100_Ve.csv")

#df100a500m
df_final100a500_aglomerados <- file.path(dir_dataFrames, "df_100a500/intermed100a500_Ed.rds")
df_final100a500_valor_natural <- file.path(dir_dataFrames, "df_100a500/intermed100a500_Vn.rds")
df_final100a500_valor_economico <- file.path(dir_dataFrames, "df_100a500/intermed100a500_Ve.rds")
df_final100a500_weighted_sum_aglomerados <- file.path(dir_dataFrames, "df_100a500/final100a500_Ed.csv")
df_final100a500_weighted_sum_valor_natural <- file.path(dir_dataFrames, "df_100a500/final100a500_Vn.csv")
df_final100a500_weighted_sum_valor_economico <- file.path(dir_dataFrames, "df_100a500/final100a500_Ve.csv")

#df50500a10000m
df_final500a1000_aglomerados <- file.path(dir_dataFrames, "df_500a1000/intermed500a1000_Ed.rds")
df_final500a1000_valor_natural <- file.path(dir_dataFrames, "df_500a1000/intermed500a1000_Vn.rds")
df_final500a1000_valor_economico <- file.path(dir_dataFrames, "df_500a1000/intermed500a1000_Ve.rds")
df_final500a1000_weighted_sum_aglomerados <- file.path(dir_dataFrames, "df_500a1000/final500a1000_Ed.csv")
df_final500a1000_weighted_sum_valor_natural <- file.path(dir_dataFrames, "df_500a1000/final500a1000_Vn.csv")
df_final500a1000_weighted_sum_valor_economico <- file.path(dir_dataFrames, "df_500a1000/final500a1000_Ve.csv")

#shapefile
stands_exposicao <- file.path(dir_exposicao, "GPKG/stands_alg_expo.gpkg")

# Gestao interface
dir_gestao_interface <- file.path(dir_output_analise, "Gestao_Interface")
stands_gestao_interface <- file.path(dir_gestao_interface, "GPKG/stands_alg_interface.gpkg")

# Copias ArcGIS (FileGDB) para compatibilidade de visualizacao/atributos
dir_arcgis <- file.path(dir_output_analise, "ArcGIS")
arcgis_gdb_path <- file.path(dir_arcgis, "stands_arcgis.gdb")
arcgis_layer_stands_expo <- "stands_alg_expo"
arcgis_layer_stands_interface <- "stands_alg_interface"

# Gestao paisagem
dir_gestao_paisagem <- file.path(dir_output_analise, "Gestao_Paisagem")
stands_gestao_lcp <- file.path(dir_gestao_paisagem, "Shapefile/stands_alg_lcp.shp")


## # - CRIAR SHAPEFILE DE VALORES CHAVE####

##AGLOMERADOS##

##VALOR NATURAL##


##VALOR ECONOMICO##

## # - CRIAR DONNUTS ####

## Definir qual o valor-chave a utilizar
  # "aglomerados", "valor_natural" ou "valor_economico"

tipo_valor_chave <- "valor_economico"

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
  st_write(resultado_valor_chave_100_500, shp_valor_chave_100_500, delete_layer = TRUE, quiet = TRUE)
  st_write(resultado_valor_chave_500_1000, shp_valor_chave_500_1000, delete_layer = TRUE, quiet = TRUE)

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

donuts_outputs <- criar_donuts_valor_chave(
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


## # - UNIDADES DE TRATAMENTO ####

normalizar_poligonos <- function(x) {
  x <- st_make_valid(x)
  x <- st_collection_extract(x, "POLYGON")
  x <- x[!st_is_empty(x), ]
  x <- st_cast(x, "MULTIPOLYGON", warn = FALSE)
  x <- suppressWarnings(st_buffer(x, 0))
  x <- st_make_valid(x)
  x <- st_collection_extract(x, "POLYGON")
  x <- x[!st_is_empty(x), ]
  x <- st_cast(x, "MULTIPOLYGON", warn = FALSE)
  x
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
  quiet_mode <- !isTRUE(verbose)

  dir.create(dirname(shp_interface_dissolve), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(stands_interface_int), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(stands_interface_diss), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(stands_interface_final), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(stands_erase_single), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(interface_diss_completa), recursive = TRUE, showWarnings = FALSE)

  ## =========================================================
  ## 1) APLICAR MASCARA DE INTERFACE COM Local = 1
  ## =========================================================

  shp_aglomerados_0_100_sf <- st_read(shp_aglomerados_0_100, quiet = quiet_mode)
  shp_aglomerados_0_100_sf <- normalizar_poligonos(shp_aglomerados_0_100_sf)

  interface_diss <- st_union(shp_aglomerados_0_100_sf)
  shp_interface_dissolve_sf <- st_cast(interface_diss, "POLYGON")

  shp_interface_dissolve_sf <- st_as_sf(
    data.frame(Inter_ID = seq_along(shp_interface_dissolve_sf)),
    geometry = shp_interface_dissolve_sf
  )

  shp_interface_dissolve_sf$Interf_ha <- as.numeric(
    st_area(shp_interface_dissolve_sf)
  ) / 10000

  st_write(
    shp_interface_dissolve_sf,
    shp_interface_dissolve,
    delete_layer = TRUE,
    quiet = quiet_mode
  )

  ## =========================================================
  ## 2) FRAGMENTAR STANDS PELA INTERFACE
  ## =========================================================

  shp_stands_base_sf <- st_read(shp_stands_base, quiet = quiet_mode)
  shp_interface_dissolve_sf <- st_read(shp_interface_dissolve, quiet = quiet_mode)

  shp_stands_base_sf <- normalizar_poligonos(shp_stands_base_sf)

  shp_interface_dissolve_sf <- st_transform(
    shp_interface_dissolve_sf,
    st_crs(shp_stands_base_sf)
  )

  ## =========================================================
  ## A) INTERSECT
  ## =========================================================

  stands_interface_int_sf <- st_intersection(
    shp_stands_base_sf,
    shp_interface_dissolve_sf
  )

  stands_interface_int_sf <- normalizar_poligonos(stands_interface_int_sf)
  stands_interface_int_sf <- st_cast(
    stands_interface_int_sf,
    "POLYGON",
    warn = FALSE
  )

  stands_interface_int_sf$Origem <- "interface"

  if (!"Inter_ID" %in% names(stands_interface_int_sf)) {
    stands_interface_int_sf$Inter_ID <- NA_integer_
  }

  if (!"Interf_ha" %in% names(stands_interface_int_sf)) {
    stands_interface_int_sf$Interf_ha <- NA_real_
  }

  stands_interface_int_sf$AREA_ha <- as.numeric(
    st_area(stands_interface_int_sf)
  ) / 10000

  st_write(
    stands_interface_int_sf,
    stands_interface_int,
    delete_layer = TRUE,
    quiet = quiet_mode
  )

  ## =========================================================
  ## B) DISSOLVE IMEDIATO DA INTERFACE
  ## =========================================================

  stands_interface_dissolver_sf <- stands_interface_int_sf %>%
    filter(Interf_ha < 3)

  stands_interface_nao_diss_sf <- stands_interface_int_sf %>%
    filter(Interf_ha >= 3)

  stands_interface_dissolver_sf$area_temp <- as.numeric(
    st_area(stands_interface_dissolver_sf)
  )

  stands_interface_diss_sf <- stands_interface_dissolver_sf %>%
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
      do_union = TRUE,
      .groups = "drop"
    )

  stands_interface_diss_sf <- normalizar_poligonos(stands_interface_diss_sf)

  ## =========================================================
  ## C) SEPARAR PARTES NAO CONTIGUAS SEM PERDER POLIGONOS
  ## =========================================================

  stands_interface_diss_sf <- st_collection_extract(
    stands_interface_diss_sf,
    "POLYGON"
  )

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

  st_write(
    stands_interface_diss_sf,
    stands_interface_diss,
    delete_layer = TRUE,
    quiet = quiet_mode
  )

  ## =========================================================
  ## D) JUNTAR INTERFACE DISSOLVIDA + INTERFACE NAO DISSOLVIDA
  ## =========================================================

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

  st_write(
    stands_interface_final_sf,
    stands_interface_final,
    delete_layer = TRUE,
    quiet = quiet_mode
  )

  ## =========================================================
  ## E) ERASE
  ## =========================================================

  stands_erase_sf <- st_difference(
    shp_stands_base_sf,
    st_union(shp_interface_dissolve_sf)
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
  stands_erase_single_sf$Inter_ID <- NA_integer_

  if (!"Interf_ha" %in% names(stands_erase_single_sf)) {
    stands_erase_single_sf$Interf_ha <- NA_real_
  }

  stands_erase_single_sf$AREA_ha <- as.numeric(
    st_area(stands_erase_single_sf)
  ) / 10000

  stands_erase_single_sf$Local <- 2L

  st_write(
    stands_erase_single_sf,
    stands_erase_single,
    delete_layer = TRUE,
    quiet = quiet_mode
  )

  ## =========================================================
  ## F) MERGE FINAL
  ## =========================================================

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

  interface_diss_completa_sf$Local <- NA_integer_
  interface_diss_completa_sf$Local[interface_diss_completa_sf$Origem == "interface"] <- 1L
  interface_diss_completa_sf$Local[interface_diss_completa_sf$Origem == "paisagem"] <- 2L

  if (isTRUE(verbose)) {
    print(table(interface_diss_completa_sf$Origem, useNA = "ifany"))
    print(table(interface_diss_completa_sf$Local, useNA = "ifany"))
    print(table(st_geometry_type(interface_diss_completa_sf)))
  }

  st_write(
    interface_diss_completa_sf,
    interface_diss_completa,
    delete_layer = TRUE,
    quiet = quiet_mode
  )

  invisible(interface_diss_completa_sf)
}

stands_edificado <- function(
  shp_aglomerados_base = shp_aglomerados_base,
  interface_diss_completa = interface_diss_completa,
  stands_aglom_int = stands_aglom_int,
  stands_aglom_int_diss = stands_aglom_int_diss,
  stands_sem_aglomerado = stands_sem_aglomerado,
  shp_stands_interface_edf = shp_stands_interface_edf,
  verbose = FALSE
) {
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
  interface_diss_completa_sf <- st_read(interface_diss_completa, quiet = quiet_mode)

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

  st_write(
    stands_aglom_int_sf,
    stands_aglom_int,
    delete_layer = TRUE,
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

  st_write(
    stands_aglom_int_diss_sf,
    stands_aglom_int_diss,
    delete_layer = TRUE,
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

  stands_sem_aglomerado_sf$fid_u <- NA
  stands_sem_aglomerado_sf$TIPO_p <- NA

  stands_sem_aglomerado_sf$AREA_ha <- as.numeric(
    st_area(stands_sem_aglomerado_sf)
  ) / 10000

  st_write(
    stands_sem_aglomerado_sf,
    stands_sem_aglomerado,
    delete_layer = TRUE,
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

  shp_stands_interface_edf_sf$Local <- NA_integer_
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
    is.na(shp_stands_interface_edf_sf$TIPO_p[idx_local3]),
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
  ## CHECKS
  ## =========================================================

  if (isTRUE(verbose)) {
    print(table(st_geometry_type(shp_stands_interface_edf_sf)))
    print(table(shp_stands_interface_edf_sf$Origem, useNA = "ifany"))
    print(table(shp_stands_interface_edf_sf$Local, useNA = "ifany"))
  }

  st_write(
    shp_stands_interface_edf_sf,
    shp_stands_interface_edf,
    delete_layer = TRUE,
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
  verbose = FALSE
) {
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

  quiet_mode <- !isTRUE(verbose)
  threshold_ha <- threshold_eliminate_ha
  max_iter <- max_small_iter

  dir.create(dirname(shp_stands_interface_final), recursive = TRUE, showWarnings = FALSE)

  shp_stands_interface_edf_sf <- st_read(shp_stands_interface_edf, quiet = quiet_mode)

  required_stands <- c("Local", "Inter_ID")
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

  agregar_pequenos_sf <- function(sf_obj, threshold_ha = 0.1, max_iter = 10, verbose_mode = FALSE, tolerancia_gap = 0.5) {
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

      for (id_small in ids_pequenos) {
        processed_iter <- processed_iter + 1L
        if (isTRUE(verbose_mode) && (processed_iter %% 250L == 0L || processed_iter == n_small_now)) {
          cat(sprintf(
            "Iteracao %d - processados: %d/%d | fusoes: %d | ignorados: %d\n",
            iter, processed_iter, n_small_now, removed_iter, skipped_invalid_iter
          ))
        }
        idx_small <- match(id_small, sf_obj$tmp_id)
        if (is.na(idx_small)) {
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

        if (length(idx_candidatos) == 0) next

        vizinhos <- sf_obj[idx_candidatos, ]
        vizinhos <- vizinhos[vizinhos$tmp_id != id_small, ]
        if (nrow(vizinhos) == 0) next

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
            if (tolerancia_gap <= 0) next
            d_viz <- tryCatch(
              suppressWarnings(as.numeric(st_distance(feat_small, vizinhos_candidatos, by_element = FALSE))),
              error = function(e) rep(NA_real_, nrow(vizinhos_candidatos))
            )
            if (length(d_viz) != nrow(vizinhos_candidatos)) next
            ok_d <- which(!is.na(d_viz) & d_viz <= tolerancia_gap)
            if (length(ok_d) == 0) next

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
          next
        }

        sf_obj$geometry[sf_obj$tmp_id == id_best] <- st_sfc(
          geom_new_norm,
          crs = st_crs(sf_obj)
        )
        sf_obj <- sf_obj[sf_obj$tmp_id != id_small, ]
        removed_iter <- removed_iter + 1L
      }

      sf_obj <- st_make_valid(sf_obj)
      sf_obj <- sf_obj[!st_is_empty(sf_obj), ]
      sf_obj <- st_collection_extract(sf_obj, "POLYGON")

      if (isTRUE(verbose_mode) && skipped_invalid_iter > 0) {
        cat(sprintf("Iteracao %d - merges ignorados por geometria invalida: %d\n", iter, skipped_invalid_iter))
      }

      if (removed_iter == 0) {
        if (isTRUE(verbose_mode)) cat("Paragem: nenhuma fusao na iteracao.\n")
        break
      }
    }

    if (isTRUE(verbose_mode) && skipped_invalid_total > 0) {
      cat(sprintf("Total de merges ignorados por geometria invalida: %d\n", skipped_invalid_total))
    }

    if ("tmp_id" %in% names(sf_obj)) sf_obj$tmp_id <- NULL
    if ("AREA_ha_tmp" %in% names(sf_obj)) sf_obj$AREA_ha_tmp <- NULL
    if ("border_len" %in% names(sf_obj)) sf_obj$border_len <- NULL

    sf_obj
  }

  local1 <- shp_stands_interface_final_sf[
    !is.na(shp_stands_interface_final_sf$Local) &
      shp_stands_interface_final_sf$Local == 1,
  ]
  local2 <- shp_stands_interface_final_sf[
    !is.na(shp_stands_interface_final_sf$Local) &
      shp_stands_interface_final_sf$Local == 2,
  ]
  local3 <- shp_stands_interface_final_sf[
    !is.na(shp_stands_interface_final_sf$Local) &
      shp_stands_interface_final_sf$Local == 3,
  ]
  outros <- shp_stands_interface_final_sf[
    is.na(shp_stands_interface_final_sf$Local) |
      !(shp_stands_interface_final_sf$Local %in% c(1, 2, 3)),
  ]

  local1_corr_list <- list()
  if (nrow(local1) > 0) {
    inter_ids_local1 <- sort(unique(local1$Inter_ID[!is.na(local1$Inter_ID)]))
    for (iid in inter_ids_local1) {
      if (isTRUE(verbose)) cat(sprintf("Processar Local 1 - Inter_ID: %s\n", as.character(iid)))
      local1_sub <- local1[local1$Inter_ID == iid, ]
      local1_corr_list[[as.character(iid)]] <- agregar_pequenos_sf(
        local1_sub,
        threshold_ha = threshold_ha,
        max_iter = max_iter,
        verbose_mode = verbose,
        tolerancia_gap = tolerancia_gap_m
      )
    }

    local1_sem_inter <- local1[is.na(local1$Inter_ID), ]
    if (nrow(local1_sem_inter) > 0) {
      local1_corr_list[["sem_inter"]] <- agregar_pequenos_sf(
        local1_sem_inter,
        threshold_ha = threshold_ha,
        max_iter = max_iter,
        verbose_mode = verbose,
        tolerancia_gap = tolerancia_gap_m
      )
    }

    if (length(local1_corr_list) > 0) {
      local1_corr <- do.call(rbind, local1_corr_list)
    } else {
      local1_corr <- local1[0, ]
    }
  } else {
    local1_corr <- local1
  }

  agregar_local2_rodeado_local1 <- function(local1_sf, local2_sf, local3_sf, outros_sf, threshold_ha, verbose_mode = FALSE) {
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
          "Local 2 rodeado por Local 1 - processados: %d/%d | transferidos: %d | ignorados: %d\n",
          processed_iter, n_candidatos, n_transferidos, n_ignorados
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

      contexto <- rbind(l1_ctx, l2_ctx, l3_ctx, out_ctx)

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
        "Local 2 rodeado por Local 1 - transferidos: %d | ignorados: %d\n",
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

  transf_local2_l1 <- agregar_local2_rodeado_local1(
    local1_sf = local1_corr,
    local2_sf = local2,
    local3_sf = local3,
    outros_sf = outros,
    threshold_ha = threshold_ha,
    verbose_mode = verbose
  )

  local1_corr <- transf_local2_l1$local1
  local2 <- transf_local2_l1$local2

  if (nrow(local2) > 0) {
    if (isTRUE(verbose)) cat("Processar Local 2\n")
    local2_corr <- agregar_pequenos_sf(
      local2,
      threshold_ha = threshold_ha,
      max_iter = max_iter,
      verbose_mode = verbose,
      tolerancia_gap = tolerancia_gap_m
    )
  } else {
    local2_corr <- local2
  }

  if (nrow(local3) > 0) {
    if (isTRUE(verbose)) cat("Processar Local 3\n")
    local3_corr <- agregar_pequenos_sf(
      local3,
      threshold_ha = threshold_ha,
      max_iter = max_iter,
      verbose_mode = verbose,
      tolerancia_gap = tolerancia_gap_m
    )
  } else {
    local3_corr <- local3
  }

  shp_stands_interface_final_sf <- rbind(
    local1_corr,
    local2_corr,
    local3_corr,
    outros
  )

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
  st_write(
    shp_stands_interface_final_sf,
    shp_stands_interface_final,
    delete_layer = TRUE,
    quiet = quiet_mode
  )

  invisible(shp_stands_interface_final_sf)
}

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

stands_edificado(
  shp_aglomerados_base = shp_aglomerados_base,
  interface_diss_completa = interface_diss_completa,
  stands_aglom_int = stands_aglom_int,
  stands_aglom_int_diss = stands_aglom_int_diss,
  stands_sem_aglomerado = stands_sem_aglomerado,
  shp_stands_interface_edf = shp_stands_interface_edf
)

correcao_stands_final(
  shp_stands_interface_edf = shp_stands_interface_edf,
  shp_stands_interface_final = shp_stands_interface_final,
  threshold_eliminate_ha = 0.001,
  verbose = TRUE
)


## # - CALCULO DA EXPOSICAO ####

## Pastas de output
dirs_out <- unique(c(
  dirname(df_final0a100_aglomerados),
  dirname(df_final100a500_aglomerados),
  dirname(df_final500a1000_aglomerados),
  dirname(stands_exposicao)
))
for (d in dirs_out) dir.create(d, recursive = TRUE, showWarnings = FALSE)

## Ler stands de interface
stands <- st_read(shp_stands_interface_final, quiet = TRUE)
if (!"Stand_IDv2" %in% names(stands)) stop("Falta Stand_IDv2 em shp_stands_interface_final.")
if (!"Local" %in% names(stands)) stop("Falta Local em shp_stands_interface_final.")

n_cores <- 8

run_exposure_interface <- function(
  shp_donut_path,
  stands_sf,
  raster_path,
  out_rds,
  out_csv,
  metric_col,
  n_cores = 8
) {
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

export_arcgis_copy <- function(sf_obj, gdb_path, layer_name) {
  if (!inherits(sf_obj, "sf")) {
    stop("export_arcgis_copy: sf_obj tem de ser um objeto sf.", call. = FALSE)
  }
  if (!is.character(gdb_path) || length(gdb_path) != 1 || !nzchar(gdb_path)) {
    stop("export_arcgis_copy: gdb_path invalido.", call. = FALSE)
  }
  if (!is.character(layer_name) || length(layer_name) != 1 || !nzchar(layer_name)) {
    stop("export_arcgis_copy: layer_name invalido.", call. = FALSE)
  }

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

  invisible(sf_arcgis)
}

update_stands_exposicao <- function(
  stands_base,
  stands_exposicao_path,
  update_tables = list(),
  recalc_scope = c("interface", "lcp", "all")
) {
  recalc_scope <- match.arg(recalc_scope)
  stands_exposicao_is_gpkg <- grepl("\\.gpkg$", stands_exposicao_path, ignore.case = TRUE)
  stands_exposicao_layer <- "stands_alg_expo"

  stands_out <- tryCatch(
    if (stands_exposicao_is_gpkg) {
      st_read(stands_exposicao_path, layer = stands_exposicao_layer, quiet = TRUE)
    } else {
      st_read(stands_exposicao_path, quiet = TRUE)
    },
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
    if (!col %in% names(stands_out)) stands_out[[col]] <- NA_real_
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
      stands_out[[metric_col]][matched] <- new_values
    }
  }

  if (!"Local" %in% names(stands_out)) {
    stop("Falta Local em stands_exposicao.")
  }
  local_num <- suppressWarnings(as.integer(as.character(stands_out$Local)))
  idx_local1 <- !is.na(local_num) & local_num == 1
  idx_local2 <- !is.na(local_num) & local_num == 2

  stands_out[!idx_local1, interface_cols] <- NA_real_
  stands_out[!idx_local2, lcp_cols] <- NA_real_

  if (recalc_scope %in% c("interface", "all")) {
    stands_out$d100_Ed[idx_local1 & is.na(stands_out$d100_Ed)] <- 0
    stands_out$PFl_Ed[idx_local1] <- stands_out$d100_Ed[idx_local1]
  }

  if (recalc_scope %in% c("lcp", "all")) {
    for (col in lcp_metric_cols) {
      stands_out[[col]][idx_local2 & is.na(stands_out[[col]])] <- 0
    }
    stands_out$PFl_Vn[idx_local2] <- stands_out$d100_Vn[idx_local2]
    stands_out$PFl_Ve[idx_local2] <- stands_out$d100_Ve[idx_local2]
    stands_out$PBr_Ed[idx_local2] <- stands_out$d500_Ed[idx_local2] + stands_out$d1000_Ed[idx_local2]
    stands_out$PBr_Vn[idx_local2] <- stands_out$d500_Vn[idx_local2] + stands_out$d1000_Vn[idx_local2]
    stands_out$PBr_Ve[idx_local2] <- stands_out$d500_Ve[idx_local2] + stands_out$d1000_Ve[idx_local2]
  }

  if (stands_exposicao_is_gpkg) {
    st_write(
      stands_out,
      stands_exposicao_path,
      layer = stands_exposicao_layer,
      delete_layer = TRUE,
      quiet = TRUE
    )
  } else {
    st_write(stands_out, stands_exposicao_path, delete_layer = TRUE, quiet = TRUE)
  }

  arcgis_gdb_path_use <- if (exists("arcgis_gdb_path", inherits = TRUE)) {
    get("arcgis_gdb_path", inherits = TRUE)
  } else {
    file.path(dirname(dirname(dirname(stands_exposicao_path))), "ArcGIS", "stands_arcgis.gdb")
  }
  arcgis_layer_stands_expo_use <- if (exists("arcgis_layer_stands_expo", inherits = TRUE)) {
    get("arcgis_layer_stands_expo", inherits = TRUE)
  } else {
    "stands_alg_expo"
  }
  export_arcgis_copy(
    sf_obj = stands_out,
    gdb_path = arcgis_gdb_path_use,
    layer_name = arcgis_layer_stands_expo_use
  )

  invisible(stands_out)
}

expo_values_correction <- function(stands_exposicao_path) {
  stands_exposicao_is_gpkg <- grepl("\\.gpkg$", stands_exposicao_path, ignore.case = TRUE)
  stands_exposicao_layer <- "stands_alg_expo"

  shape <- if (stands_exposicao_is_gpkg) {
    st_read(stands_exposicao_path, layer = stands_exposicao_layer, quiet = TRUE)
  } else {
    st_read(stands_exposicao_path, quiet = TRUE)
  }

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
    if (stands_exposicao_is_gpkg) {
      st_write(
        shape,
        stands_exposicao_path,
        layer = stands_exposicao_layer,
        delete_layer = TRUE,
        quiet = TRUE
      )
    } else {
      st_write(shape, stands_exposicao_path, delete_layer = TRUE, quiet = TRUE)
    }

    arcgis_gdb_path_use <- if (exists("arcgis_gdb_path", inherits = TRUE)) {
      get("arcgis_gdb_path", inherits = TRUE)
    } else {
      file.path(dirname(dirname(dirname(stands_exposicao_path))), "ArcGIS", "stands_arcgis.gdb")
    }
    arcgis_layer_stands_expo_use <- if (exists("arcgis_layer_stands_expo", inherits = TRUE)) {
      get("arcgis_layer_stands_expo", inherits = TRUE)
    } else {
      "stands_alg_expo"
    }
    export_arcgis_copy(
      sf_obj = shape,
      gdb_path = arcgis_gdb_path_use,
      layer_name = arcgis_layer_stands_expo_use
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
    vals[!idx_local1] <- NA_real_
    vals[mask_zero & idx_local1 & !is.na(vals)] <- 0
    shape[[col]] <- vals
  }

  lcp_existentes <- intersect(lcp_cols, cols_existentes)
  for (col in lcp_existentes) {
    vals <- to_numeric_safe(shape[[col]])
    vals[!idx_local2] <- NA_real_
    vals[mask_zero & idx_local2 & !is.na(vals)] <- 0
    shape[[col]] <- vals
  }

  if (stands_exposicao_is_gpkg) {
    st_write(
      shape,
      stands_exposicao_path,
      layer = stands_exposicao_layer,
      delete_layer = TRUE,
      quiet = TRUE
    )
  } else {
    st_write(shape, stands_exposicao_path, delete_layer = TRUE, quiet = TRUE)
  }

  arcgis_gdb_path_use <- if (exists("arcgis_gdb_path", inherits = TRUE)) {
    get("arcgis_gdb_path", inherits = TRUE)
  } else {
    file.path(dirname(dirname(dirname(stands_exposicao_path))), "ArcGIS", "stands_arcgis.gdb")
  }
  arcgis_layer_stands_expo_use <- if (exists("arcgis_layer_stands_expo", inherits = TRUE)) {
    get("arcgis_layer_stands_expo", inherits = TRUE)
  } else {
    "stands_alg_expo"
  }
  export_arcgis_copy(
    sf_obj = shape,
    gdb_path = arcgis_gdb_path_use,
    layer_name = arcgis_layer_stands_expo_use
  )

  invisible(shape)
}

## PIPELINE INTERFACE (Local == 1)
sum_agl_0_100 <- run_exposure_interface(
  shp_aglomerados_0_100, stands, p_arder2virg5,
  df_final0a100_aglomerados, df_final0a100_weighted_sum_aglomerados,
  metric_col = "d100_Ed",
  n_cores = n_cores
)

update_stands_exposicao(
  stands_base = stands,
  stands_exposicao_path = stands_exposicao,
  update_tables = list(
    sum_agl_0_100
  ),
  recalc_scope = "interface"
)

expo_values_correction(stands_exposicao)

## PIPELINE LCP (Local == 2)
## AGLOMERADOS
sum_agl_100_500 <- run_exposure_lcp(
  shp_aglomerados_100_500, stands, p_arder2virg5,
  df_final100a500_aglomerados, df_final100a500_weighted_sum_aglomerados,
  metric_col = "d500_Ed",
  n_cores = n_cores
)
sum_agl_500_1000 <- run_exposure_lcp(
  shp_aglomerados_500_1000, stands, p_arder3virg5,
  df_final500a1000_aglomerados, df_final500a1000_weighted_sum_aglomerados,
  metric_col = "d1000_Ed",
  n_cores = n_cores
)

## VALOR NATURAL
sum_vn_0_100 <- run_exposure_lcp(
  shp_valor_natural_0_100, stands, p_arder2virg5,
  df_final0a100_valor_natural, df_final0a100_weighted_sum_valor_natural,
  metric_col = "d100_Vn",
  n_cores = n_cores
)
sum_vn_100_500 <- run_exposure_lcp(
  shp_valor_natural_100_500, stands, p_arder2virg5,
  df_final100a500_valor_natural, df_final100a500_weighted_sum_valor_natural,
  metric_col = "d500_Vn",
  n_cores = n_cores
)
sum_vn_500_1000 <- run_exposure_lcp(
  shp_valor_natural_500_1000, stands, p_arder3virg5,
  df_final500a1000_valor_natural, df_final500a1000_weighted_sum_valor_natural,
  metric_col = "d1000_Vn",
  n_cores = n_cores
)

## VALOR ECONOMICO
sum_ve_0_100 <- run_exposure_lcp(
  shp_valor_economico_0_100, stands, p_arder2virg5,
  df_final0a100_valor_economico, df_final0a100_weighted_sum_valor_economico,
  metric_col = "d100_Ve",
  n_cores = n_cores
)
sum_ve_100_500 <- run_exposure_lcp(
  shp_valor_economico_100_500, stands, p_arder2virg5,
  df_final100a500_valor_economico, df_final100a500_weighted_sum_valor_economico,
  metric_col = "d500_Ve",
  n_cores = n_cores
)
sum_ve_500_1000 <- run_exposure_lcp(
  shp_valor_economico_500_1000, stands, p_arder3virg5,
  df_final500a1000_valor_economico, df_final500a1000_weighted_sum_valor_economico,
  metric_col = "d1000_Ve",
  n_cores = n_cores
)

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

expo_values_correction(stands_exposicao)


## # - IDENTIFICAR AREAS PRIORITARIAS - INTERFACE ####
##APENAS UNIDADES DE TRATAMENTO GERIVEIS##
##PRIORIDADE ABSOLUTA - ALGARVE INTEIRO)##

informacao_UTs <- function(
  stands_exposicao_path,
  stands_gestao_interface_path = stands_gestao_interface,
  shp_municipios_path = shp_municipios
) {
  stands_exposicao_is_gpkg <- grepl("\\.gpkg$", stands_exposicao_path, ignore.case = TRUE)
  stands_exposicao_layer <- "stands_alg_expo"
  stands_gestao_is_gpkg <- grepl("\\.gpkg$", stands_gestao_interface_path, ignore.case = TRUE)
  stands_gestao_layer <- "stands_alg_interface"

  stands_exposicao_sf <- if (stands_exposicao_is_gpkg) {
    st_read(stands_exposicao_path, layer = stands_exposicao_layer, quiet = TRUE)
  } else {
    st_read(stands_exposicao_path, quiet = TRUE)
  }
  municipios_sf <- st_read(shp_municipios_path, quiet = TRUE)

  if (!"Municipio" %in% names(municipios_sf)) {
    stop("Falta coluna Municipio em shp_municipios.")
  }

  stands_exposicao_sf <- st_make_valid(stands_exposicao_sf)
  municipios_sf <- st_make_valid(municipios_sf)
  municipios_sf <- st_transform(municipios_sf, st_crs(stands_exposicao_sf))

  stands_exposicao_sf$.row_id <- seq_len(nrow(stands_exposicao_sf))
  stands_exposicao_sf$municipio <- NA_character_

  area_total_stand <- as.numeric(st_area(stands_exposicao_sf))

  inter_sf <- st_intersection(
    stands_exposicao_sf[, ".row_id", drop = FALSE],
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

    stands_exposicao_sf$municipio[inter_df$.row_id] <- as.character(inter_df$Municipio)
  }

  stands_exposicao_sf$.row_id <- NULL

  required_cols <- c("PFl_Ed", "AREA_ha", "Local", "gerivel")
  missing_cols <- setdiff(required_cols, names(stands_exposicao_sf))
  if (length(missing_cols) > 0) {
    stop(
      paste(
        "Faltam colunas obrigatorias em stands_exposicao:",
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

  dir.create(dirname(stands_gestao_interface_path), recursive = TRUE, showWarnings = FALSE)
  if (stands_gestao_is_gpkg) {
    st_write(
      stands_exposicao_sf,
      stands_gestao_interface_path,
      layer = stands_gestao_layer,
      delete_layer = TRUE,
      quiet = TRUE
    )
  } else {
    st_write(stands_exposicao_sf, stands_gestao_interface_path, delete_layer = TRUE, quiet = TRUE)
  }

  arcgis_gdb_path_use <- if (exists("arcgis_gdb_path", inherits = TRUE)) {
    get("arcgis_gdb_path", inherits = TRUE)
  } else {
    file.path(dirname(dirname(dirname(stands_gestao_interface_path))), "ArcGIS", "stands_arcgis.gdb")
  }
  arcgis_layer_stands_interface_use <- if (exists("arcgis_layer_stands_interface", inherits = TRUE)) {
    get("arcgis_layer_stands_interface", inherits = TRUE)
  } else {
    "stands_alg_interface"
  }
  export_arcgis_copy(
    sf_obj = stands_exposicao_sf,
    gdb_path = arcgis_gdb_path_use,
    layer_name = arcgis_layer_stands_interface_use
  )

  stands_exposicao_sf
}

prioridade_absoluta <- function(
  stands_gestao_interface_path = stands_gestao_interface
) {
  stands_gestao_is_gpkg <- grepl("\\.gpkg$", stands_gestao_interface_path, ignore.case = TRUE)
  stands_gestao_layer <- "stands_alg_interface"

  stands_gestao_sf <- if (stands_gestao_is_gpkg) {
    st_read(stands_gestao_interface_path, layer = stands_gestao_layer, quiet = TRUE)
  } else {
    st_read(stands_gestao_interface_path, quiet = TRUE)
  }

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

  stands_gestao_sf$PAbs_pct <- NA_integer_
  idx_class <- !is.na(geriv_num) & geriv_num == 1 & !is.na(stands_gestao_sf$PFl_EdNorm)

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

  dir.create(dirname(stands_gestao_interface_path), recursive = TRUE, showWarnings = FALSE)
  if (stands_gestao_is_gpkg) {
    st_write(
      stands_gestao_sf,
      stands_gestao_interface_path,
      layer = stands_gestao_layer,
      delete_layer = TRUE,
      quiet = TRUE
    )
  } else {
    st_write(stands_gestao_sf, stands_gestao_interface_path, delete_layer = TRUE, quiet = TRUE)
  }

  arcgis_gdb_path_use <- if (exists("arcgis_gdb_path", inherits = TRUE)) {
    get("arcgis_gdb_path", inherits = TRUE)
  } else {
    file.path(dirname(dirname(dirname(stands_gestao_interface_path))), "ArcGIS", "stands_arcgis.gdb")
  }
  arcgis_layer_stands_interface_use <- if (exists("arcgis_layer_stands_interface", inherits = TRUE)) {
    get("arcgis_layer_stands_interface", inherits = TRUE)
  } else {
    "stands_alg_interface"
  }
  export_arcgis_copy(
    sf_obj = stands_gestao_sf,
    gdb_path = arcgis_gdb_path_use,
    layer_name = arcgis_layer_stands_interface_use
  )

  stands_gestao_sf
}

prioridade_relativa <- function(
  stands_gestao_interface_path = stands_gestao_interface
) {
  stands_gestao_is_gpkg <- grepl("\\.gpkg$", stands_gestao_interface_path, ignore.case = TRUE)
  stands_gestao_layer <- "stands_alg_interface"

  stands_gestao_sf <- if (stands_gestao_is_gpkg) {
    st_read(stands_gestao_interface_path, layer = stands_gestao_layer, quiet = TRUE)
  } else {
    st_read(stands_gestao_interface_path, quiet = TRUE)
  }

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

  stands_gestao_sf$PRel_pct <- NA_integer_
  idx_base <- !is.na(geriv_num) &
    geriv_num == 1 &
    !is.na(stands_gestao_sf$PFl_EdNorm) &
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

  dir.create(dirname(stands_gestao_interface_path), recursive = TRUE, showWarnings = FALSE)
  if (stands_gestao_is_gpkg) {
    st_write(
      stands_gestao_sf,
      stands_gestao_interface_path,
      layer = stands_gestao_layer,
      delete_layer = TRUE,
      quiet = TRUE
    )
  } else {
    st_write(stands_gestao_sf, stands_gestao_interface_path, delete_layer = TRUE, quiet = TRUE)
  }

  arcgis_gdb_path_use <- if (exists("arcgis_gdb_path", inherits = TRUE)) {
    get("arcgis_gdb_path", inherits = TRUE)
  } else {
    file.path(dirname(dirname(dirname(stands_gestao_interface_path))), "ArcGIS", "stands_arcgis.gdb")
  }
  arcgis_layer_stands_interface_use <- if (exists("arcgis_layer_stands_interface", inherits = TRUE)) {
    get("arcgis_layer_stands_interface", inherits = TRUE)
  } else {
    "stands_alg_interface"
  }
  export_arcgis_copy(
    sf_obj = stands_gestao_sf,
    gdb_path = arcgis_gdb_path_use,
    layer_name = arcgis_layer_stands_interface_use
  )

  stands_gestao_sf
}

stands_gestao_sf <- informacao_UTs(stands_exposicao, stands_gestao_interface)
stands_gestao_sf <- prioridade_absoluta(stands_gestao_interface)
stands_gestao_sf <- prioridade_relativa(stands_gestao_interface)

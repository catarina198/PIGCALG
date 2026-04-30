
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
nome_analise <- "V2_20260416"

dir_output_analise <- file.path(dir_outputs, nome_analise)

# Unidades Tratamento
dir_unidades_tratamento <- file.path(dir_output_analise, "UTratamento")
shp_stands_interface <- file.path (dir_unidades_tratamento, "stands_alg_interface.shp")
shp_stands_interface_edf <- file.path (dir_unidades_tratamento, "stands_alg_interface_edf.shp")
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
stands_exposicao <- file.path(dir_exposicao, "Shapefile/stands_alg_expo.shp")

# Gestao interface
dir_gestao_interface <- file.path(dir_output_analise, "Gestao_Interface")
stands_gestao_interface <- file.path(dir_gestao_interface, "Shapefile/stands_alg_interface.shp")

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

# Associar os caminhos certos ao valor-chave escolhido
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

## Funcao para criar donuts atraves de diferenca geometrica
pairwise_difference <- function(x, y) {
  if (length(x) != length(y)) {
    stop("x e y tem comprimentos diferentes.")
  }
  
  geoms <- lapply(seq_along(x), function(i) {
    st_difference(x[i], y[i])[[1]]
  })
  
  st_sfc(geoms, crs = st_crs(x))
}

## Ler a shapefile base do valor-chave
valor_chave <- st_read(shp_valor_chave_base, quiet = TRUE)

## Criar um identificador unico para cada poligono
valor_chave$fid_u <- seq_len(nrow(valor_chave))

## Manter apenas o campo fid_u e a geometria
valor_chave <- valor_chave[, "fid_u", drop = FALSE]

## Garantir ordem estavel dos registos
valor_chave <- valor_chave[order(valor_chave$fid_u), ]

## Guardar apenas a geometria para os calculos espaciais
geom_valor_chave <- st_geometry(valor_chave)

## Limpar memoria antes dos buffers
gc()

## Criar buffers de 100 m, 500 m e 1000 m
buffer_100m <- st_buffer(geom_valor_chave, dist = 100, nQuadSegs = 5)
buffer_500m <- st_buffer(geom_valor_chave, dist = 500, nQuadSegs = 5)
buffer_1000m <- st_buffer(geom_valor_chave, dist = 1000, nQuadSegs = 5)

## Criar os donuts por diferenca entre buffers sucessivos
valor_chave_0_100 <- pairwise_difference(buffer_100m, geom_valor_chave)
valor_chave_100_500 <- pairwise_difference(buffer_500m, buffer_100m)
valor_chave_500_1000 <- pairwise_difference(buffer_1000m, buffer_500m)

## Criar os objetos sf finais para guardar em shapefile
resultado_valor_chave_0_100 <- st_sf(fid_u = valor_chave$fid_u, geometry = valor_chave_0_100)
resultado_valor_chave_100_500 <- st_sf(fid_u = valor_chave$fid_u, geometry = valor_chave_100_500)
resultado_valor_chave_500_1000 <- st_sf(fid_u = valor_chave$fid_u, geometry = valor_chave_500_1000)

## Escrever os tres outputs
st_write(resultado_valor_chave_0_100, shp_valor_chave_0_100, delete_layer = TRUE, quiet = TRUE)
st_write(resultado_valor_chave_100_500, shp_valor_chave_100_500, delete_layer = TRUE, quiet = TRUE)
st_write(resultado_valor_chave_500_1000, shp_valor_chave_500_1000, delete_layer = TRUE, quiet = TRUE)

## Remover objetos intermedios para libertar memoria
rm(
  buffer_100m, buffer_500m, buffer_1000m,
  valor_chave_0_100, valor_chave_100_500, valor_chave_500_1000,
  resultado_valor_chave_0_100, resultado_valor_chave_100_500, resultado_valor_chave_500_1000,
  geom_valor_chave
)
gc()


## # - UNIDADES DE TRATAMENTO ####

stands_interface <- function(
  shp_aglomerados_0_100,
  shp_stands_base,
  shp_stands_interface,
  n_cores = 8,
  verbose = TRUE
) {
  prepare_inputs <- function(shp_aglomerados_0_100, shp_stands_base) {
    ## Ler os aglomerados 0-100 m e a layer dos stands
    aglomerados_0_100 <- st_read(shp_aglomerados_0_100, quiet = TRUE)
    stands <- st_read(shp_stands_base, quiet = TRUE)

    ## Garantir que as geometrias sao validas
    aglomerados_0_100 <- st_make_valid(aglomerados_0_100)
    stands <- st_make_valid(stands)
    st_agr(stands) <- "constant"
    st_agr(aglomerados_0_100) <- "constant"

    ## Garantir coluna TIPO_p para processamento interno
    if (!"TIPO_p" %in% names(stands)) {
      stands$TIPO_p <- NA_character_
    }

    ## Transformar os aglomerados para o mesmo CRS dos stands
    aglomerados_0_100 <- st_transform(aglomerados_0_100, st_crs(stands))

    ## Identificar apenas os stands que tocam nos aglomerados 0-100
    idx_touch <- lengths(st_intersects(stands, aglomerados_0_100)) > 0

    ## Separar os stands tocados dos stands nao tocados
    stands_touch <- stands[idx_touch, ]
    stands_notouch <- stands[!idx_touch, ]

    ## Dissolver os aglomerados numa mascara unica para o corte final
    mask_geom <- st_union(st_geometry(aglomerados_0_100))
    mask <- st_sf(
      mask_id = 1,
      geometry = st_sfc(mask_geom, crs = st_crs(stands))
    )

    ## Guardar os nomes dos campos originais sem a geometria
    geom_col <- attr(stands, 'sf_column')
    target_cols <- setdiff(names(stands), geom_col)

    list(
      stands = stands,
      stands_touch = stands_touch,
      stands_notouch = stands_notouch,
      mask = mask,
      target_cols = target_cols
    )
  }

  process_touched_blocks <- function(stands_touch, mask, target_cols, n_cores) {
    ## Dividir os stands tocados em blocos
    ids <- split(
      seq_len(nrow(stands_touch)),
      cut(
        seq_len(nrow(stands_touch)),
        breaks = min(n_cores, nrow(stands_touch)),
        labels = FALSE
      )
    )

    ## Criar cluster paralelo
    cl <- makeCluster(length(ids), type = 'SOCK')
    on.exit({
      stopCluster(cl)
      rm(cl)
      gc()
    }, add = TRUE)
    registerDoSNOW(cl)

    ## Processar cada bloco em paralelo
    partes_list <- foreach(k = seq_along(ids), .packages = 'sf') %dopar% {
      ## Selecionar o bloco atual
      bloco <- stands_touch[ids[[k]], ]

      ## Parte dos stands dentro da mascara
      bloco_in <- suppressWarnings(st_intersection(bloco, mask))
      bloco_in <- st_collection_extract(bloco_in, 'POLYGON')

      ## Remover campo auxiliar da mascara, se existir
      if ('mask_id' %in% names(bloco_in)) {
        bloco_in$mask_id <- NULL
      }

      ## Atribuir Local = 1 a parte interior
      bloco_in$Local <- rep(1, nrow(bloco_in))
      bloco_in <- bloco_in[, c(target_cols, 'Local')]

      ## Parte dos stands fora da mascara
      bloco_out <- st_difference(bloco, mask)
      bloco_out <- bloco_out[!st_is_empty(bloco_out), ]
      bloco_out <- st_collection_extract(bloco_out, 'POLYGON')

      ## Atribuir Local = 2 a parte exterior
      bloco_out$Local <- rep(2, nrow(bloco_out))
      bloco_out <- bloco_out[, c(target_cols, 'Local')]

      ## Juntar parte interior e exterior do bloco
      rbind(bloco_in, bloco_out)
    }

    ## Remover blocos vazios
    partes_list <- Filter(function(x) !is.null(x) && nrow(x) > 0, partes_list)

    ## Juntar todos os blocos processados
    if (length(partes_list) > 0) {
      do.call(rbind, partes_list)
    } else {
      partes <- stands_touch[0, ]
      partes$Local <- integer(0)
      partes[, c(target_cols, 'Local')]
    }
  }

  finalize_output <- function(resultado, shp_stands_interface) {
    ## Recalcular area em hectares
    resultado$AREA_ha <- as.numeric(st_area(resultado)) / 10000

    ## Criar novo identificador unico
    resultado$Stand_IDv2 <- seq_len(nrow(resultado))

    ## Escrever o output final
    dir.create(dirname(shp_stands_interface), recursive = TRUE, showWarnings = FALSE)
    st_write(resultado, shp_stands_interface, delete_layer = TRUE, quiet = TRUE)
    resultado
  }

  prepared <- prepare_inputs(
    shp_aglomerados_0_100 = shp_aglomerados_0_100,
    shp_stands_base = shp_stands_base
  )

  stands_touch <- prepared$stands_touch
  stands_notouch <- prepared$stands_notouch
  mask <- prepared$mask
  target_cols <- prepared$target_cols

  no_touch_case <- nrow(stands_touch) == 0

  ## Se nenhum stand tocar nos aglomerados
  if (no_touch_case) {
    ## Atribuir Local = 2 aos stands nao tocados
    stands_notouch$Local <- 2
    stands_notouch <- stands_notouch[, c(target_cols, "Local")]

    ## Garantir apenas poligonos
    resultado_12 <- st_collection_extract(stands_notouch, "POLYGON")
    resultado_12 <- st_cast(resultado_12, "POLYGON", warn = FALSE)
  } else {
    ## Processar os stands tocados em paralelo
    partes <- process_touched_blocks(
      stands_touch = stands_touch,
      mask = mask,
      target_cols = target_cols,
      n_cores = n_cores
    )

    ## Preparar os stands que nunca tocaram na mascara
    stands_notouch$Local <- 2
    stands_notouch <- st_collection_extract(stands_notouch, "POLYGON")
    stands_notouch <- stands_notouch[, c(target_cols, "Local")]

    ## Juntar todas as partes num unico resultado final
    resultado_12 <- rbind(partes, stands_notouch)
    resultado_12 <- st_cast(resultado_12, "POLYGON", warn = FALSE)
  }

  resultado <- finalize_output(resultado_12, shp_stands_interface)
  cat("stands interface concluida\n")

  invisible(resultado)
}

stands_edificado <- function(
  shp_aglomerados_base,
  shp_stands_interface,
  shp_stands_interface_edf,
  verbose = TRUE
) {
  resolve_col <- function(df, candidates, required = TRUE, label = NULL) {
    nms <- names(df)
    idx <- which(tolower(nms) %in% tolower(candidates))
    if (length(idx) > 0) return(nms[idx[1]])
    if (isTRUE(required)) {
      missing_name <- if (is.null(label)) paste(candidates, collapse = "/") else label
      stop(paste("Falta coluna obrigatoria:", missing_name))
    }
    NULL
  }

  build_local3 <- function(shp_aglomerados_base, stands, target_cols) {
    resolve_col <- function(df, candidates, required = TRUE, label = NULL) {
      nms <- names(df)
      idx <- which(tolower(nms) %in% tolower(candidates))
      if (length(idx) > 0) return(nms[idx[1]])
      if (isTRUE(required)) {
        missing_name <- if (is.null(label)) paste(candidates, collapse = "/") else label
        stop(paste("Falta coluna obrigatoria:", missing_name))
      }
      NULL
    }

    empty_local3 <- stands[0, ]
    empty_local3$Local <- integer(0)
    empty_local3 <- empty_local3[, c(target_cols, "Local")]

    aglomerados_base <- st_read(shp_aglomerados_base, quiet = TRUE)
    aglomerados_base <- st_make_valid(aglomerados_base)
    st_agr(aglomerados_base) <- "constant"
    aglomerados_base <- st_transform(aglomerados_base, st_crs(stands))

    ## Preservar TIPO_p dos aglomerados na intersecao com stands
    tipo_col_agl <- resolve_col(
      aglomerados_base,
      c("TIPO_p", "TIPO_P", "Tipo_p", "tipo_p"),
      required = TRUE,
      label = "TIPO_p"
    )
    aglomerados_base_keep <- aglomerados_base[, tipo_col_agl, drop = FALSE]
    names(aglomerados_base_keep)[1] <- "TIPO_p_agl"
    st_agr(aglomerados_base_keep) <- "constant"

    local3 <- suppressWarnings(st_intersection(stands, aglomerados_base_keep))
    if (nrow(local3) == 0) return(empty_local3)

    local3 <- local3[!st_is_empty(local3), ]
    if (nrow(local3) == 0) return(empty_local3)

    geom_types <- unique(as.character(st_geometry_type(local3, by_geometry = TRUE)))
    if (!all(geom_types %in% c("POLYGON", "MULTIPOLYGON"))) {
      local3 <- st_collection_extract(local3, "POLYGON")
      if (nrow(local3) == 0) return(empty_local3)
    }
    local3 <- st_cast(local3, "POLYGON", warn = FALSE)
    local3$TIPO_p <- local3$TIPO_p_agl
    local3$TIPO_p_agl <- NULL
    local3$Local <- 3
    local3 <- local3[, c(target_cols, "Local")]
    local3
  }

  apply_local3_precedence <- function(resultado_12, local3, target_cols) {
    if (nrow(local3) == 0) return(resultado_12[, c(target_cols, "Local")])
    if (nrow(resultado_12) == 0) return(local3[, c(target_cols, "Local")])

    local3_mask_geom <- st_union(st_geometry(local3))
    local3_mask <- st_sf(
      mask_id = 1,
      geometry = st_sfc(local3_mask_geom, crs = st_crs(resultado_12))
    )

    resultado_12_cut <- st_difference(resultado_12, local3_mask)
    if ("mask_id" %in% names(resultado_12_cut)) {
      resultado_12_cut$mask_id <- NULL
    }

    if (nrow(resultado_12_cut) > 0) {
      resultado_12_cut <- resultado_12_cut[!st_is_empty(resultado_12_cut), ]
      resultado_12_cut <- st_collection_extract(resultado_12_cut, "POLYGON")
      resultado_12_cut <- st_cast(resultado_12_cut, "POLYGON", warn = FALSE)
      resultado_12_cut <- resultado_12_cut[, c(target_cols, "Local")]
    } else {
      resultado_12_cut <- resultado_12[0, ]
      resultado_12_cut$Local <- integer(0)
      resultado_12_cut <- resultado_12_cut[, c(target_cols, "Local")]
    }

    resultado_final <- rbind(resultado_12_cut, local3)
    geom_types <- unique(as.character(st_geometry_type(resultado_final, by_geometry = TRUE)))
    if (!all(geom_types %in% c("POLYGON", "MULTIPOLYGON"))) {
      resultado_final <- st_collection_extract(resultado_final, "POLYGON")
    }
    resultado_final <- st_cast(resultado_final, "POLYGON", warn = FALSE)
    resultado_final[, c(target_cols, "Local")]
  }

  apply_local3_business_rules <- function(resultado) {
    resolve_col <- function(df, candidates, required = TRUE, label = NULL) {
      nms <- names(df)
      idx <- which(tolower(nms) %in% tolower(candidates))
      if (length(idx) > 0) return(nms[idx[1]])
      if (isTRUE(required)) {
        missing_name <- if (is.null(label)) paste(candidates, collapse = "/") else label
        stop(paste("Falta coluna obrigatoria:", missing_name))
      }
      NULL
    }

    local_col <- resolve_col(resultado, c("Local"), required = TRUE, label = "Local")
    gerivel_col <- resolve_col(resultado, c("gerivel"), required = TRUE, label = "gerivel")
    cos_col <- resolve_col(resultado, c("COS23_n4_L"), required = TRUE, label = "COS23_n4_L")
    tipo_col <- resolve_col(resultado, c("TIPO_p", "TIPO_P", "Tipo_p", "tipo_p"), required = FALSE)

    required_cols <- c(local_col, gerivel_col, cos_col)
    missing_cols <- setdiff(required_cols, names(resultado))
    if (length(missing_cols) > 0) {
      stop(
        paste(
          "Faltam colunas obrigatorias para regras de Local=3:",
          paste(missing_cols, collapse = ", ")
        )
      )
    }

    local_num <- suppressWarnings(as.integer(as.character(resultado[[local_col]])))
    idx_local3 <- !is.na(local_num) & local_num == 3

    ## Regra 1: Local == 3 deixa de ser gerivel
    if (is.factor(resultado[[gerivel_col]])) {
      resultado[[gerivel_col]] <- as.character(resultado[[gerivel_col]])
    }
    resultado[[gerivel_col]][idx_local3] <- 0

    ## Regra 2: novo Uso_solo com base em COS23_n4_L
    resultado$Uso_solo <- as.character(resultado[[cos_col]])
    if (is.null(tipo_col)) {
      tipo_p_chr <- rep(NA_character_, nrow(resultado))
    } else {
      tipo_p_chr <- trimws(as.character(resultado[[tipo_col]]))
    }
    has_tipo_p <- !is.na(tipo_p_chr) & nzchar(tipo_p_chr)
    resultado$Uso_solo[idx_local3 & has_tipo_p] <- paste0("\u00c1rea edificada Tipo_p ", tipo_p_chr[idx_local3 & has_tipo_p])
    resultado$Uso_solo[idx_local3 & !has_tipo_p] <- NA_character_

    ## Remover TIPO_p do output final para evitar informacao repetida
    tipo_cols_all <- names(resultado)[tolower(names(resultado)) == "tipo_p"]
    if (length(tipo_cols_all) > 0) {
      resultado <- resultado[, setdiff(names(resultado), tipo_cols_all)]
    }

    resultado
  }

  finalize_output <- function(resultado, shp_stands_interface_edf) {
    ## Recalcular area em hectares
    resultado$AREA_ha <- as.numeric(st_area(resultado)) / 10000

    ## Criar novo identificador unico
    resultado$Stand_IDv2 <- seq_len(nrow(resultado))

    ## Escrever o output final
    dir.create(dirname(shp_stands_interface_edf), recursive = TRUE, showWarnings = FALSE)
    st_write(resultado, shp_stands_interface_edf, delete_layer = TRUE, quiet = TRUE)
    resultado
  }

  stands <- st_read(shp_stands_interface, quiet = TRUE)
  stands <- st_make_valid(stands)
  st_agr(stands) <- "constant"
  if (!"Local" %in% names(stands)) stop("Falta coluna Local em shp_stands_interface.")

  geom_col <- attr(stands, "sf_column")
  target_cols <- setdiff(names(stands), c(geom_col, "Local"))
  resultado_12 <- stands[, c(target_cols, "Local")]

  ## Construir Local = 3 a partir de shp_aglomerados_base e aplicar precedencia
  local3 <- build_local3(
    shp_aglomerados_base = shp_aglomerados_base,
    stands = stands,
    target_cols = target_cols
  )
  resultado_final <- apply_local3_precedence(
    resultado_12 = resultado_12,
    local3 = local3,
    target_cols = target_cols
  )
  resultado_final <- apply_local3_business_rules(resultado_final)

  resultado <- finalize_output(resultado_final, shp_stands_interface_edf)
  cat("stands edificado concluida\n")

  invisible(resultado)
}

correcao_stands <- function(
  shp_stands_in,
  shp_stands_out = shp_stands_in,
  threshold_ha = 0.001,
  max_small_iter = 10,
  verbose = TRUE
) {
  max_small_iter <- suppressWarnings(as.integer(max_small_iter))
  if (is.na(max_small_iter) || max_small_iter < 1) {
    stop("max_small_iter deve ser um inteiro >= 1.")
  }

  stands_sf <- st_read(shp_stands_in, quiet = TRUE)
  stands_sf <- st_make_valid(stands_sf)

  required_cols <- c("Local", "COS23_n4_L")
  missing_cols <- setdiff(required_cols, names(stands_sf))
  if (length(missing_cols) > 0) {
    stop(
      paste(
        "Faltam colunas obrigatorias no input para correcao:",
        paste(missing_cols, collapse = ", ")
      )
    )
  }

  local_num <- suppressWarnings(as.integer(as.character(stands_sf$Local)))
  idx_local1 <- !is.na(local_num) & local_num == 1
  idx_local3 <- !is.na(local_num) & local_num == 3

  local1 <- stands_sf[idx_local1, ]
  local3 <- stands_sf[idx_local3, ]
  outros <- stands_sf[!(idx_local1 | idx_local3), ]

  dissolve_local1 <- function(local1_sf) {
    if (nrow(local1_sf) == 0) return(local1_sf)

    split_ids <- split(seq_len(nrow(local1_sf)), as.character(local1_sf$COS23_n4_L))
    out_rows <- list()
    out_i <- 0

    find_components <- function(adj_list, n) {
      comp <- integer(n)
      comp_id <- 0
      for (i in seq_len(n)) {
        if (comp[i] != 0) next
        comp_id <- comp_id + 1
        queue <- i
        comp[i] <- comp_id
        while (length(queue) > 0) {
          v <- queue[1]
          queue <- queue[-1]
          nei <- adj_list[[v]]
          if (length(nei) == 0) next
          nei_new <- nei[comp[nei] == 0]
          if (length(nei_new) == 0) next
          comp[nei_new] <- comp_id
          queue <- c(queue, nei_new)
        }
      }
      comp
    }

    for (cls in names(split_ids)) {
      idx_cls <- split_ids[[cls]]
      sf_cls <- local1_sf[idx_cls, ]
      area_cls <- as.numeric(st_area(sf_cls))

      ## Continuidade por partilha de fronteira (aresta), nao apenas vertice
      adj_cls <- st_relate(sf_cls, pattern = "F***1****")
      comp_ids <- find_components(adj_cls, nrow(sf_cls))

      for (cid in sort(unique(comp_ids))) {
        idx_comp <- which(comp_ids == cid)
        if (length(idx_comp) == 0) next

        dominant_local <- idx_comp[which.max(area_cls[idx_comp])]
        dominant_row <- sf_cls[dominant_local, ]

        union_geom <- st_union(st_geometry(sf_cls[idx_comp, ]))
        if (inherits(union_geom, "sfc")) {
          st_geometry(dominant_row) <- union_geom
        } else {
          st_geometry(dominant_row) <- st_sfc(union_geom, crs = st_crs(sf_cls))
        }

        dominant_row$Local <- 1
        out_i <- out_i + 1
        out_rows[[out_i]] <- dominant_row
      }
    }

    if (length(out_rows) == 0) return(local1_sf[0, ])

    local1_out <- do.call(rbind, out_rows)
    geom_types <- unique(as.character(st_geometry_type(local1_out, by_geometry = TRUE)))
    if (!all(geom_types %in% c("POLYGON", "MULTIPOLYGON"))) {
      local1_out <- st_collection_extract(local1_out, "POLYGON")
    }
    st_cast(local1_out, "POLYGON", warn = FALSE)
  }

  dissolve_local3 <- function(local3_sf) {
    if (nrow(local3_sf) == 0) return(local3_sf)
    if (!"Uso_solo" %in% names(local3_sf)) {
      stop("Falta coluna Uso_solo para dissolve de Local=3.")
    }

    uso_key <- as.character(local3_sf$Uso_solo)
    uso_key[is.na(local3_sf$Uso_solo)] <- "__USO_SOLO_NA__"
    split_ids <- split(seq_len(nrow(local3_sf)), uso_key)

    out_rows <- list()
    out_i <- 0

    for (k in names(split_ids)) {
      idx_grp <- split_ids[[k]]
      sf_grp <- local3_sf[idx_grp, ]
      area_grp <- as.numeric(st_area(sf_grp))

      dominant_local <- which.max(area_grp)
      dominant_row <- sf_grp[dominant_local, ]

      union_geom <- st_union(st_geometry(sf_grp))
      if (inherits(union_geom, "sfc")) {
        st_geometry(dominant_row) <- union_geom
      } else {
        st_geometry(dominant_row) <- st_sfc(union_geom, crs = st_crs(sf_grp))
      }

      dominant_row$Local <- 3
      out_i <- out_i + 1
      out_rows[[out_i]] <- dominant_row
    }

    if (length(out_rows) == 0) return(local3_sf[0, ])

    local3_out <- do.call(rbind, out_rows)
    geom_types <- unique(as.character(st_geometry_type(local3_out, by_geometry = TRUE)))
    if (!all(geom_types %in% c("POLYGON", "MULTIPOLYGON"))) {
      local3_out <- st_collection_extract(local3_out, "POLYGON")
    }
    st_cast(local3_out, "POLYGON", warn = FALSE)
  }

  shared_border_length <- function(sf_data, i, j) {
    b_i <- st_boundary(st_geometry(sf_data[i, ]))
    b_j <- st_boundary(st_geometry(sf_data[j, ]))
    inter_b <- suppressWarnings(st_intersection(b_i, b_j))
    if (length(inter_b) == 0) return(0)
    len_b <- suppressWarnings(st_length(inter_b))
    if (length(len_b) == 0) return(0)
    as.numeric(sum(len_b, na.rm = TRUE))
  }

  classify_small_polygons <- function(sf_data, threshold_ha) {
    area_ha <- as.numeric(st_area(sf_data)) / 10000
    small_idx <- which(!is.na(area_ha) & area_ha < threshold_ha)
    if (length(small_idx) == 0) {
      return(list(with_neighbor = integer(0), without_neighbor = integer(0)))
    }

    rel <- st_relate(sf_data, pattern = "F***1****")
    with_neighbor <- integer(0)
    without_neighbor <- integer(0)

    for (i in small_idx) {
      nbr <- setdiff(rel[[i]], i)
      if (length(nbr) == 0) {
        without_neighbor <- c(without_neighbor, i)
        next
      }
      border_len <- vapply(nbr, function(j) shared_border_length(sf_data, i, j), numeric(1))
      if (length(border_len) == 0 || all(is.na(border_len)) || max(border_len, na.rm = TRUE) <= 0) {
        without_neighbor <- c(without_neighbor, i)
      } else {
        with_neighbor <- c(with_neighbor, i)
      }
    }

    list(with_neighbor = with_neighbor, without_neighbor = without_neighbor)
  }

  eliminate_small_sf_fallback <- function(sf_data, candidate_orig_ids, threshold_ha) {
    sf_work <- sf_data
    removed <- 0

    if (nrow(sf_work) == 0 || length(candidate_orig_ids) == 0) {
      return(list(sf = sf_work, removed = removed, method = "sf_fallback"))
    }

    area_all <- as.numeric(st_area(sf_work)) / 10000
    candidate_orig_ids <- candidate_orig_ids[order(area_all[match(candidate_orig_ids, sf_work$.orig_id)])]

    for (oid in candidate_orig_ids) {
      row_small <- which(sf_work$.orig_id == oid)
      if (length(row_small) == 0) next
      row_small <- row_small[1]

      area_small <- as.numeric(st_area(sf_work[row_small, ])) / 10000
      if (is.na(area_small) || area_small >= threshold_ha) next

      nbr_idx <- st_relate(sf_work[row_small, ], sf_work, pattern = "F***1****")[[1]]
      nbr_idx <- setdiff(nbr_idx, row_small)
      if (length(nbr_idx) == 0) next

      border_len <- vapply(nbr_idx, function(j) shared_border_length(sf_work, row_small, j), numeric(1))
      if (length(border_len) == 0 || all(is.na(border_len))) next
      best_pos <- which.max(border_len)
      if (length(best_pos) == 0 || is.na(border_len[best_pos]) || border_len[best_pos] <= 0) next

      row_target <- nbr_idx[best_pos]
      merged_geom <- st_union(st_geometry(sf_work[row_target, ]), st_geometry(sf_work[row_small, ]))
      st_geometry(sf_work)[row_target] <- merged_geom

      sf_work <- sf_work[-row_small, ]
      removed <- removed + 1
    }

    list(sf = sf_work, removed = removed, method = "sf_fallback")
  }

  eliminate_small_hybrid <- function(sf_obj, threshold_ha = 0.001) {
    out <- list(
      sf = sf_obj,
      removed = 0,
      preserved_without_neighbor = 0,
      remaining_small = 0,
      method = "none"
    )

    if (nrow(sf_obj) == 0) return(out)

    cls <- classify_small_polygons(sf_obj, threshold_ha)
    idx_preserve <- cls$without_neighbor
    idx_eliminate <- cls$with_neighbor
    out$preserved_without_neighbor <- length(idx_preserve)

    if (length(idx_eliminate) == 0) {
      area_final0 <- as.numeric(st_area(sf_obj)) / 10000
      out$remaining_small <- sum(!is.na(area_final0) & area_final0 < threshold_ha)
      return(out)
    }

    keep_idx <- setdiff(seq_len(nrow(sf_obj)), idx_preserve)
    sf_for_elim <- sf_obj[keep_idx, ]
    sf_for_elim$.orig_id <- keep_idx
    candidate_orig_ids <- keep_idx[match(idx_eliminate, keep_idx)]
    candidate_orig_ids <- candidate_orig_ids[!is.na(candidate_orig_ids)]

    used_qgis <- FALSE
    sf_elim <- NULL

    if (requireNamespace("qgisprocess", quietly = TRUE)) {
      qgis_ok <- FALSE
      alg <- NULL
      try({
        invisible(capture.output({
          suppressWarnings(suppressMessages(qgisprocess::qgis_configure()))
        }, type = "output"))
        algs <- suppressWarnings(suppressMessages(qgisprocess::qgis_algorithms()))
        if ("grass:v.clean" %in% algs) {
          alg <- "grass:v.clean"
        } else if ("grass7:v.clean" %in% algs) {
          alg <- "grass7:v.clean"
        }
        qgis_ok <- !is.null(alg)
      }, silent = TRUE)

      if (qgis_ok) {
        qgis_res <- tryCatch({
          tmp_input <- tempfile(fileext = ".gpkg")
          st_write(sf_for_elim, tmp_input, delete_dsn = TRUE, quiet = TRUE)
          res_qgis <- NULL
          invisible(capture.output({
            res_qgis <- suppressWarnings(suppressMessages(
              tryCatch(
                qgisprocess::qgis_run_algorithm(
                  alg,
                  input = tmp_input,
                  tool = "rmarea",
                  threshold = threshold_ha * 10000,
                  output = "TEMPORARY_OUTPUT",
                  .quiet = TRUE
                ),
                error = function(e) qgisprocess::qgis_run_algorithm(
                  alg,
                  input = tmp_input,
                  tool = "rmarea",
                  threshold = threshold_ha * 10000,
                  output = "TEMPORARY_OUTPUT"
                )
              )
            ))
          }, type = "output"))
          res_qgis
        }, error = function(e) NULL)

        if (!is.null(qgis_res)) {
          sf_elim <- tryCatch(st_read(qgis_res$output, quiet = TRUE), error = function(e) NULL)
          if (inherits(sf_elim, "sf")) {
            used_qgis <- TRUE
            out$method <- "qgis_rmarea"
          }
        }
      }
    }

    if (!used_qgis) {
      fb <- eliminate_small_sf_fallback(sf_for_elim, candidate_orig_ids, threshold_ha)
      sf_elim <- fb$sf
      out$removed <- fb$removed
      out$method <- fb$method
    } else {
      out$removed <- max(0, nrow(sf_for_elim) - nrow(sf_elim))
    }

    if (".orig_id" %in% names(sf_elim)) {
      sf_elim$.orig_id <- NULL
    }

    target_cols <- names(sf_obj)
    for (col in setdiff(target_cols, names(sf_elim))) {
      sf_elim[[col]] <- NA
    }
    sf_elim <- sf_elim[, target_cols]

    if (length(idx_preserve) > 0) {
      sf_preserve <- sf_obj[idx_preserve, ]
      resultado_h <- rbind(sf_elim, sf_preserve)
    } else {
      resultado_h <- sf_elim
    }

    resultado_h <- st_make_valid(resultado_h)
    geom_types <- unique(as.character(st_geometry_type(resultado_h, by_geometry = TRUE)))
    if (!all(geom_types %in% c("POLYGON", "MULTIPOLYGON"))) {
      resultado_h <- st_collection_extract(resultado_h, "POLYGON")
    }
    resultado_h <- st_cast(resultado_h, "POLYGON", warn = FALSE)

    area_final <- as.numeric(st_area(resultado_h)) / 10000
    out$remaining_small <- sum(!is.na(area_final) & area_final < threshold_ha)
    out$sf <- resultado_h
    out
  }

  count_small_polygons <- function(sf_obj, threshold_ha) {
    if (nrow(sf_obj) == 0) return(0L)
    area_ha <- as.numeric(st_area(sf_obj)) / 10000
    as.integer(sum(!is.na(area_ha) & area_ha < threshold_ha))
  }

  local1_corr <- dissolve_local1(local1)
  local3_corr <- dissolve_local3(local3)
  resultado <- rbind(local1_corr, local3_corr, outros)
  resultado <- st_cast(resultado, "POLYGON", warn = FALSE)

  resultado_work <- resultado
  iter <- 0L
  remaining_small <- count_small_polygons(resultado_work, threshold_ha = threshold_ha)
  stop_reason <- "sem pequenos"

  if (isTRUE(verbose)) {
    cat(
      sprintf(
        "Eliminacao pequenos: pequenos_iniciais=%d, max_iter=%d\n",
        remaining_small, max_small_iter
      )
    )
  }

  while (remaining_small > 0 && iter < max_small_iter) {
    iter <- iter + 1L

    if (isTRUE(verbose)) {
      cat(sprintf("Iteracao %d: inicio, pequenos=%d\n", iter, remaining_small))
    }

    elim_out <- eliminate_small_hybrid(resultado_work, threshold_ha = threshold_ha)
    resultado_work <- elim_out$sf
    removed_iter <- as.integer(elim_out$removed)
    remaining_small <- count_small_polygons(resultado_work, threshold_ha = threshold_ha)

    if (isTRUE(verbose)) {
      cat(
        sprintf(
          "Iteracao %d: removidos=%d, pequenos_restantes=%d\n",
          iter, removed_iter, remaining_small
        )
      )
    }

    if (remaining_small == 0) {
      stop_reason <- "sem pequenos"
      break
    }
    if (removed_iter == 0) {
      stop_reason <- "sem mudancas"
      break
    }
  }

  if (remaining_small > 0 && iter >= max_small_iter) {
    stop_reason <- "max_iter"
  }

  if (isTRUE(verbose)) {
    cat(
      sprintf(
        "Eliminacao pequenos: fim (%s), iteracoes=%d, pequenos_restantes=%d\n",
        stop_reason, iter, remaining_small
      )
    )
  }

  resultado <- resultado_work

  area_micro <- as.numeric(st_area(resultado)) / 10000
  idx_drop <- which(!is.na(area_micro) & area_micro < 0.000004)
  micro_removidos <- length(idx_drop)
  if (micro_removidos > 0) {
    resultado <- resultado[-idx_drop, ]
  }

  resultado <- st_make_valid(resultado)
  geom_types <- unique(as.character(st_geometry_type(resultado, by_geometry = TRUE)))
  if (!all(geom_types %in% c("POLYGON", "MULTIPOLYGON"))) {
    resultado <- st_collection_extract(resultado, "POLYGON")
  }
  resultado <- st_cast(resultado, "POLYGON", warn = FALSE)

  if (isTRUE(verbose)) {
    cat(
      sprintf(
        "Limpeza final micro-poligonos: removidos=%d, restantes=%d\n",
        micro_removidos, nrow(resultado)
      )
    )
  }

  resultado$AREA_ha <- as.numeric(st_area(resultado)) / 10000
  resultado$Stand_IDv2 <- seq_len(nrow(resultado))

  dir.create(dirname(shp_stands_out), recursive = TRUE, showWarnings = FALSE)
  st_write(resultado, shp_stands_out, delete_layer = TRUE, quiet = TRUE)
  cat("Correcao de stands concluida\n")

  invisible(resultado)
}

stands_interface(
  shp_aglomerados_0_100 = shp_aglomerados_0_100,
  shp_stands_base = shp_stands_base,
  shp_stands_interface = shp_stands_interface,
  n_cores = 8,
  verbose = FALSE
)
stands_edificado(
  shp_aglomerados_base = shp_aglomerados_base,
  shp_stands_interface = shp_stands_interface,
  shp_stands_interface_edf = shp_stands_interface_edf,
  verbose = FALSE
)
correcao_stands(
  shp_stands_in = shp_stands_interface_edf,
  shp_stands_out = shp_stands_interface_final,
  threshold_ha = 0.001,
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

update_stands_exposicao <- function(
  stands_base,
  stands_exposicao_path,
  update_tables = list(),
  recalc_scope = c("interface", "lcp", "all")
) {
  recalc_scope <- match.arg(recalc_scope)

  stands_out <- tryCatch(
    st_read(stands_exposicao_path, quiet = TRUE),
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

  st_write(stands_out, stands_exposicao_path, delete_layer = TRUE, quiet = TRUE)
  invisible(stands_out)
}

expo_values_correction <- function(stands_exposicao_path) {
  shape <- st_read(stands_exposicao_path, quiet = TRUE)

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
    st_write(shape, stands_exposicao_path, delete_layer = TRUE, quiet = TRUE)
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

  st_write(shape, stands_exposicao_path, delete_layer = TRUE, quiet = TRUE)
  invisible(shape)
}

## Definir quais pipelines correr (TRUE/FALSE)
run_pipeline_interface <- TRUE
run_pipeline_lcp <- TRUE

## PIPELINE INTERFACE (Local == 1)
if (run_pipeline_interface) {
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
}

## PIPELINE LCP (Local == 2)
if (run_pipeline_lcp) {
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
}


## # - IDENTIFICAR ÁREAS PRIORITÁRIAS - INTERFACE ####
##APENAS UNIDADES DE TRATAMENTO GERIVEIS##
##PRIORIDADE ABSOLUTA - ALGARVE INTEIRO)##

informacao_UTs <- function(
  stands_exposicao_path,
  stands_gestao_interface_path = stands_gestao_interface,
  shp_municipios_path = shp_municipios
) {
  stands_exposicao_sf <- st_read(stands_exposicao_path, quiet = TRUE)
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
  st_write(stands_exposicao_sf, stands_gestao_interface_path, delete_layer = TRUE, quiet = TRUE)

  stands_exposicao_sf
}

prioridade_absoluta <- function(
  stands_gestao_interface_path = stands_gestao_interface
) {
  stands_gestao_sf <- st_read(stands_gestao_interface_path, quiet = TRUE)

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
  st_write(stands_gestao_sf, stands_gestao_interface_path, delete_layer = TRUE, quiet = TRUE)

  stands_gestao_sf
}

stands_gestao_sf <- informacao_UTs(stands_exposicao, stands_gestao_interface)
stands_gestao_sf <- prioridade_absoluta(stands_gestao_interface)

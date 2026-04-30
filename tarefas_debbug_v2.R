library(sf)
library(dplyr)


## # - UNIDADES DE TRATAMENTO ####


## FUNCAO AUXILIAR: NORMALIZAR POLIGONOS


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


##STANDS VS INTERFACE

# inputs
# shp_aglomerados_0_100
# shp_stands_base
#
# outputs
# shp_interface_dissolve
# stands_interface_int
# stands_interface_diss
# stands_interface_final
# stands_erase_single
# interface_diss_completa

## =========================================================
## 1) APLICAR MÁSCARA DE INTERFACE COM Local = 1
## =========================================================

shp_aglomerados_0_100 <- st_read(
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Inputs/Valores_Chave/V2_2026/aglomerados/aglomerados_0a100m.shp"
)

shp_aglomerados_0_100 <- normalizar_poligonos(shp_aglomerados_0_100)

interface_diss <- st_union(shp_aglomerados_0_100)

shp_interface_dissolve <- st_cast(interface_diss, "POLYGON")

shp_interface_dissolve <- st_as_sf(
  data.frame(Inter_ID = seq_along(shp_interface_dissolve)),
  geometry = shp_interface_dissolve
)

shp_interface_dissolve$Interf_ha <- as.numeric(
  st_area(shp_interface_dissolve)
) / 10000

st_write(
  shp_interface_dissolve,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/v2_20260422/shp_interface_dissolve.shp",
  delete_layer = TRUE
)

## =========================================================
## 2) FRAGMENTAR STANDS PELA INTERFACE
## =========================================================

shp_stands_base <- st_read(
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Inputs/UTratamento/stands_alg_COS23_base.shp"
)

shp_interface_dissolve <- st_read(
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/v2_20260422/shp_interface_dissolve.shp"
)

shp_stands_base <- normalizar_poligonos(shp_stands_base)


shp_interface_dissolve <- st_transform(
  shp_interface_dissolve,
  st_crs(shp_stands_base)
)

stands_interface_int <- st_intersection(
  shp_stands_base,
  shp_interface_dissolve
)

stands_interface_int <- normalizar_poligonos(stands_interface_int)
stands_interface_int <- st_cast(
  stands_interface_int,
  "POLYGON",
  warn = FALSE
)

stands_interface_int$Origem <- "interface"

if (!"Inter_ID" %in% names(stands_interface_int)) {
  stands_interface_int$Inter_ID <- NA_integer_
}

if (!"Interf_ha" %in% names(stands_interface_int)) {
  stands_interface_int$Interf_ha <- NA_real_
}

stands_interface_int$AREA_ha <- as.numeric(
  st_area(stands_interface_int)
) / 10000

st_write(
  stands_interface_int,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/v2_20260422/stands_interface_int.shp",
  delete_layer = TRUE
)

## =========================================================
## B) DISSOLVE IMEDIATO DA INTERFACE
## =========================================================

stands_interface_dissolver <- stands_interface_int %>%
  filter(Interf_ha < 3)

stands_interface_nao_diss <- stands_interface_int %>%
  filter(Interf_ha >= 3)

stands_interface_dissolver$area_temp <- as.numeric(
  st_area(stands_interface_dissolver)
)

stands_interface_diss <- stands_interface_dissolver %>%
  group_by(Inter_ID, COS23_n4_L) %>%
  summarise(
    ID         = ID[which.max(area_temp)],
    COS23_n4_C = COS23_n4_C[which.max(area_temp)],
    Class      = Class[which.max(area_temp)],
    treatable  = treatable[which.max(area_temp)],
    dec_p90    = dec_p90[which.max(area_temp)],
    dec_p90_wg = dec_p90_wg[which.max(area_temp)],
    gerivel    = gerivel[which.max(area_temp)],
    exclude    = exclude[which.max(area_temp)],
    exposicao  = exposicao[which.max(area_temp)],
    Stand_ID   = Stand_ID[which.max(area_temp)],
    Origem     = Origem[which.max(area_temp)],
    Interf_ha  = Interf_ha[which.max(area_temp)],
    do_union   = TRUE,
    .groups    = "drop"
  )

stands_interface_diss <- normalizar_poligonos(stands_interface_diss)

## =========================================================
## C) SEPARAR PARTES NÃO CONTÍNUAS SEM PERDER POLÍGONOS
## =========================================================

stands_interface_diss <- st_collection_extract(
  stands_interface_diss,
  "POLYGON"
)

atribs <- st_drop_geometry(stands_interface_diss)

geom_multi <- st_cast(
  st_geometry(stands_interface_diss),
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

stands_interface_diss <- st_sf(
  atribs_rep,
  geometry = geom_poly
)

stands_interface_diss <- stands_interface_diss[
  !st_is_empty(stands_interface_diss),
]


stands_interface_diss$AREA_ha <- as.numeric(
  st_area(stands_interface_diss)
) / 10000

stands_interface_diss$Local <- 1L


st_write(
  stands_interface_diss,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/v2_20260422/stands_interface_diss.shp",
  delete_layer = TRUE
)

## =========================================================
## D) JUNTAR INTERFACE DISSOLVIDA + INTERFACE NÃO DISSOLVIDA
## =========================================================

cols_comuns_int <- intersect(
  names(stands_interface_nao_diss),
  names(stands_interface_diss)
)

stands_interface_nao_diss_bind <- stands_interface_nao_diss[, cols_comuns_int]
stands_interface_diss_bind     <- stands_interface_diss[, cols_comuns_int]

stands_interface_final <- rbind(
  stands_interface_nao_diss_bind,
  stands_interface_diss_bind
)


stands_interface_final$AREA_ha <- as.numeric(
  st_area(stands_interface_final)
) / 10000

stands_interface_final$Local <- 1L
stands_interface_final$Origem <- "interface"


st_write(
  stands_interface_final,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/v2_20260422/stands_interface_final.shp",
  delete_layer = TRUE
)

## =========================================================
## E) ERASE
## =========================================================

stands_erase <- st_difference(
  shp_stands_base,
  st_union(shp_interface_dissolve)
)

stands_erase <- normalizar_poligonos(stands_erase)

stands_erase <- st_cast(
  stands_erase,
  "MULTIPOLYGON",
  warn = FALSE
)

stands_erase_single <- st_cast(
  stands_erase,
  "POLYGON",
  warn = FALSE
)

stands_erase_single <- stands_erase_single[
  !st_is_empty(stands_erase_single),
]

stands_erase_single$Origem <- "paisagem"
stands_erase_single$Inter_ID <- NA_integer_

if (!"Interf_ha" %in% names(stands_erase_single)) {
  stands_erase_single$Interf_ha <- NA_real_
}

stands_erase_single$AREA_ha <- as.numeric(
  st_area(stands_erase_single)
) / 10000

stands_erase_single$Local <- 2L

st_write(
  stands_erase_single,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/v2_20260422/stands_erase_inter.shp",
  delete_layer = TRUE
)

## =========================================================
## F) MERGE FINAL
## =========================================================

cols_comuns_final <- intersect(
  names(stands_erase_single),
  names(stands_interface_final)
)

stands_erase_bind <- stands_erase_single[, cols_comuns_final]
stands_interface_bind <- stands_interface_final[, cols_comuns_final]

interface_diss_completa <- rbind(
  stands_erase_bind,
  stands_interface_bind
)

interface_diss_completa$Stand_IDv2 <- seq_len(nrow(interface_diss_completa))

interface_diss_completa$AREA_ha <- as.numeric(
  st_area(interface_diss_completa)
) / 10000

interface_diss_completa$Local <- NA_integer_
interface_diss_completa$Local[interface_diss_completa$Origem == "interface"] <- 1L
interface_diss_completa$Local[interface_diss_completa$Origem == "paisagem"] <- 2L


print(table(interface_diss_completa$Origem, useNA = "ifany"))
print(table(interface_diss_completa$Local, useNA = "ifany"))
print(table(st_geometry_type(interface_diss_completa)))

st_write(
  interface_diss_completa,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/v2_20260422/shp_stands_interface_completa.shp",
  delete_layer = TRUE
)


##STANDS VS AGLOMERADOS

library(sf)
library(dplyr)

## =========================================================
## INPUTS
## =========================================================

shp_aglomerados_base <- st_read(
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Inputs/Valores_Chave/V2_2026/aglomerados/aglomerados.shp"
)

interface_diss_completa <- st_read(
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/v2_20260422/shp_stands_interface_completa.shp"
)

## =========================================================
## PREPARAÇÃO
## =========================================================

shp_aglomerados_base <- st_make_valid(shp_aglomerados_base)
interface_diss_completa <- st_make_valid(interface_diss_completa)

shp_aglomerados_base <- st_transform(
  shp_aglomerados_base,
  st_crs(interface_diss_completa)
)

shp_aglomerados_base_sel <- shp_aglomerados_base[, c(
  "fid_u",
  "TIPO_p",
  attr(shp_aglomerados_base, "sf_column")
)]

## =========================================================
## A) INTERSECT
## =========================================================

stands_aglom_int <- st_intersection(
  interface_diss_completa,
  shp_aglomerados_base_sel
)

stands_aglom_int <- st_make_valid(stands_aglom_int)

stands_aglom_int <- st_collection_extract(stands_aglom_int, "POLYGON")
stands_aglom_int <- stands_aglom_int[!st_is_empty(stands_aglom_int), ]

# área temporária
stands_aglom_int$area_temp <- as.numeric(
  st_area(stands_aglom_int)
)

st_write(
  stands_aglom_int,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/v2_20260422/stands_aglom_int.shp",
  delete_layer = TRUE
)

## =========================================================
## A.1) DISSOLVE
## =========================================================

stands_aglom_int_diss <- stands_aglom_int %>%
  group_by(fid_u, TIPO_p) %>%
  summarise(
    ID         = ID[which.max(area_temp)],
    COS23_n4_C = COS23_n4_C[which.max(area_temp)],
    COS23_n4_L = COS23_n4_L[which.max(area_temp)],
    Class      = Class[which.max(area_temp)],
    treatable  = treatable[which.max(area_temp)],
    dec_p90    = dec_p90[which.max(area_temp)],
    dec_p90_wg = dec_p90_wg[which.max(area_temp)],
    gerivel    = 0,
    exclude    = 0,
    exposicao  = 0,
    Stand_ID   = Stand_ID[which.max(area_temp)],
    Origem     = "edificado",
    Inter_ID   = Inter_ID[which.max(area_temp)],
    Interf_ha  = Interf_ha[which.max(area_temp)],
    Stand_IDv2 = Stand_IDv2[which.max(area_temp)],
    Local      = 3L,
    do_union   = TRUE,
    .groups    = "drop"
  )

stands_aglom_int_diss <- normalizar_poligonos(stands_aglom_int_diss)

# área final
stands_aglom_int_diss$AREA_ha <- as.numeric(
  st_area(stands_aglom_int_diss)
) / 10000

stands_aglom_int_diss <- normalizar_poligonos(stands_aglom_int_diss)

st_write(
  stands_aglom_int_diss,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/v2_20260422/stands_aglom_int_diss.shp",
  delete_layer = TRUE
)

## =========================================================
## B) ERASE
## =========================================================

aglo_union <- st_union(shp_aglomerados_base_sel)

stands_sem_aglomerado <- st_difference(
  interface_diss_completa,
  aglo_union
)

stands_sem_aglomerado <- st_make_valid(stands_sem_aglomerado)

stands_sem_aglomerado <- st_collection_extract(
  stands_sem_aglomerado,
  "POLYGON"
)

stands_sem_aglomerado <- stands_sem_aglomerado[
  !st_is_empty(stands_sem_aglomerado),
]

stands_sem_aglomerado$fid_u  <- NA
stands_sem_aglomerado$TIPO_p <- NA

stands_sem_aglomerado$AREA_ha <- as.numeric(
  st_area(stands_sem_aglomerado)
) / 10000

st_write(
  stands_sem_aglomerado,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/v2_20260422/stands_sem_aglomerado.shp",
  delete_layer = TRUE
)

## =========================================================
## C) MERGE
## =========================================================

cols_comuns <- intersect(
  names(stands_sem_aglomerado),
  names(stands_aglom_int_diss)
)

stands_sem_aglomerado_bind <- stands_sem_aglomerado[, cols_comuns]
stands_aglom_int_diss_bind <- stands_aglom_int_diss[, cols_comuns]

shp_stands_interface_edf <- rbind(
  stands_sem_aglomerado_bind,
  stands_aglom_int_diss_bind
)

shp_stands_interface_edf <- st_make_valid(shp_stands_interface_edf)

## =========================================================
## D) GARANTIR CAMPOS
## =========================================================

shp_stands_interface_edf$Local <- NA_integer_
shp_stands_interface_edf$Local[shp_stands_interface_edf$Origem == "interface"] <- 1L
shp_stands_interface_edf$Local[shp_stands_interface_edf$Origem == "paisagem"]  <- 2L
shp_stands_interface_edf$Local[shp_stands_interface_edf$Origem == "edificado"] <- 3L

# garantir regras obrigatórias para edificado
idx_local3 <- shp_stands_interface_edf$Local == 3

shp_stands_interface_edf$gerivel[idx_local3]   <- 0
shp_stands_interface_edf$exclude[idx_local3]   <- 0
shp_stands_interface_edf$exposicao[idx_local3] <- 0

## =========================================================
## E) USO DO SOLO
## =========================================================

shp_stands_interface_edf$Uso_solo <- shp_stands_interface_edf$COS23_n4_L

shp_stands_interface_edf$Uso_solo[idx_local3] <- ifelse(
  is.na(shp_stands_interface_edf$TIPO_p[idx_local3]),
  "Área edificada",
  paste0("Área edificada tipo_p ", shp_stands_interface_edf$TIPO_p[idx_local3])
)

## =========================================================
## F) ÁREA FINAL + ID
## =========================================================

shp_stands_interface_edf$AREA_ha <- as.numeric(
  st_area(shp_stands_interface_edf)
) / 10000

shp_stands_interface_edf$Stand_IDv2 <- seq_len(nrow(shp_stands_interface_edf))

## =========================================================
## CHECKS
## =========================================================

print(table(st_geometry_type(shp_stands_interface_edf)))
print(table(shp_stands_interface_edf$Origem, useNA = "ifany"))
print(table(shp_stands_interface_edf$Local, useNA = "ifany"))

## =========================================================
## OUTPUT
## =========================================================

st_write(
  shp_stands_interface_edf,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/v2_20260422/shp_stands_interface_edf.shp",
  delete_layer = TRUE
)



##CORRECAO FINAL
# inputs
# shp_stands_interface_edf
#
# outputs
# shp_stands_interface_final

## =========================================================
## 4) CORRIGIR STANDS INTERFACE EDF
## =========================================================

shp_stands_interface_edf <- st_read(
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/v2_20260422/shp_stands_interface_edf.shp"
)

shp_stands_interface_edf <- normalizar_poligonos(shp_stands_interface_edf)

## =========================================================
## PARAMETROS
## =========================================================

threshold_ha <- 0.001
max_iter <- 10
tolerancia_gap_m <- 0.5
verbose <- FALSE

## =========================================================
## PREPARAR DADOS
## =========================================================

shp_stands_interface_final <- shp_stands_interface_edf

shp_stands_interface_final <- normalizar_poligonos(shp_stands_interface_final)

shp_stands_interface_final <- st_cast(
  shp_stands_interface_final,
  "POLYGON",
  warn = FALSE
)

shp_stands_interface_final$AREA_ha <- as.numeric(
  st_area(shp_stands_interface_final)
) / 10000

shp_stands_interface_final <- shp_stands_interface_final[
  !is.na(shp_stands_interface_final$AREA_ha) &
    shp_stands_interface_final$AREA_ha > 0,
]

## =========================================================
## F) SEPARAR POR Local
## =========================================================

local1 <- shp_stands_interface_final[
  !is.na(shp_stands_interface_final$Local) &
    shp_stands_interface_final$Local == 1,
]

local2 <- shp_stands_interface_final[
  !is.na(shp_stands_interface_final$Local) &
    shp_stands_interface_final$Local == 2,
]

local3 <- shp_stands_interface_final[
  !is.na(shp_stands_interface_final$Local) &
    shp_stands_interface_final$Local == 3,
]

outros <- shp_stands_interface_final[
  is.na(shp_stands_interface_final$Local) |
    !(shp_stands_interface_final$Local %in% c(1, 2, 3)),
]

## =========================================================
## F.1) PROCESSAR LOCAL 1
## =========================================================

local1_corr <- local1

if (nrow(local1_corr) > 0) {
  
  local1_corr <- st_make_valid(local1_corr)
  local1_corr <- suppressWarnings(
    st_collection_extract(local1_corr, "POLYGON")
  )
  local1_corr <- local1_corr[!st_is_empty(local1_corr), ]
  
  iter <- 0L
  
  repeat {
    
    iter <- iter + 1L
    
    local1_corr$AREA_ha <- as.numeric(st_area(local1_corr)) / 10000
    local1_corr$tmp_id <- seq_len(nrow(local1_corr))
    
    ids_pequenos <- local1_corr$tmp_id[local1_corr$AREA_ha < threshold_ha]
    n_small_now <- length(ids_pequenos)
    removed_iter <- 0L
    
    if (isTRUE(verbose)) {
      cat(sprintf("Local 1 / Iteracao %d - pequenos: %d\n", iter, n_small_now))
    }
    
    if (n_small_now == 0) break
    if (iter > max_iter) break
    
    for (id_small in ids_pequenos) {
      
      idx_small <- match(id_small, local1_corr$tmp_id)
      if (is.na(idx_small)) next
      
      feat_small <- local1_corr[idx_small, ]
      feat_small <- st_make_valid(feat_small)
      feat_small <- suppressWarnings(
        st_collection_extract(feat_small, "POLYGON")
      )
      feat_small <- feat_small[!st_is_empty(feat_small), ]
      
      if (nrow(feat_small) == 0) next
      
      idx_touch <- st_touches(feat_small, local1_corr)[[1]]
      
      if (length(idx_touch) > 0) {
        idx_candidatos <- setdiff(idx_touch, idx_small)
      } else {
        idx_int <- st_intersects(feat_small, local1_corr)[[1]]
        idx_candidatos <- setdiff(idx_int, idx_small)
      }
      
      if (length(idx_candidatos) == 0 &&
          tolerancia_gap_m > 0 &&
          nrow(local1_corr) > 1) {
        
        idx_gap <- st_is_within_distance(
          feat_small,
          local1_corr,
          dist = tolerancia_gap_m
        )[[1]]
        
        idx_candidatos <- setdiff(idx_gap, idx_small)
      }
      
      if (length(idx_candidatos) == 0) next
      
      vizinhos <- local1_corr[idx_candidatos, ]
      vizinhos <- vizinhos[vizinhos$tmp_id != id_small, ]
      vizinhos <- st_make_valid(vizinhos)
      vizinhos <- suppressWarnings(
        st_collection_extract(vizinhos, "POLYGON")
      )
      vizinhos <- vizinhos[!st_is_empty(vizinhos), ]
      
      if (nrow(vizinhos) == 0) next
      
      vizinhos$AREA_ha_tmp <- as.numeric(st_area(vizinhos)) / 10000
      
      vizinhos_grandes <- vizinhos[vizinhos$AREA_ha_tmp >= threshold_ha, ]
      vizinhos_candidatos <- if (nrow(vizinhos_grandes) > 0) vizinhos_grandes else vizinhos
      
      border_len <- numeric(nrow(vizinhos_candidatos))
      
      for (k in seq_len(nrow(vizinhos_candidatos))) {
        
        feat_small_poly <- suppressWarnings(
          st_collection_extract(st_make_valid(feat_small), "POLYGON")
        )
        
        viz_k_poly <- suppressWarnings(
          st_collection_extract(st_make_valid(vizinhos_candidatos[k, ]), "POLYGON")
        )
        
        if (nrow(feat_small_poly) == 0 || nrow(viz_k_poly) == 0) {
          border_len[k] <- 0
          next
        }
        
        inter_b <- tryCatch(
          suppressWarnings(
            st_intersection(
              st_boundary(feat_small_poly),
              st_boundary(viz_k_poly)
            )
          ),
          error = function(e) NULL
        )
        
        border_len[k] <- 0
        
        if (!is.null(inter_b) && nrow(inter_b) > 0) {
          
          tipos_inter <- unique(as.character(st_geometry_type(inter_b)))
          
          if (any(tipos_inter %in% c("LINESTRING", "MULTILINESTRING"))) {
            
            inter_b_lin <- inter_b[
              st_geometry_type(inter_b) %in% c("LINESTRING", "MULTILINESTRING"),
            ]
            
            if (nrow(inter_b_lin) > 0) {
              len_b <- suppressWarnings(st_length(inter_b_lin))
              
              if (length(len_b) > 0 && any(!is.na(len_b))) {
                border_len[k] <- as.numeric(sum(len_b, na.rm = TRUE))
              }
            }
          }
          
          if (any(tipos_inter == "GEOMETRYCOLLECTION")) {
            
            inter_b_gc <- inter_b[
              st_geometry_type(inter_b) == "GEOMETRYCOLLECTION",
            ]
            
            inter_b_lin_gc <- tryCatch(
              suppressWarnings(st_collection_extract(inter_b_gc, "LINESTRING")),
              error = function(e) NULL
            )
            
            if (!is.null(inter_b_lin_gc) && nrow(inter_b_lin_gc) > 0) {
              len_b <- suppressWarnings(st_length(inter_b_lin_gc))
              
              if (length(len_b) > 0 && any(!is.na(len_b))) {
                border_len[k] <- border_len[k] + as.numeric(sum(len_b, na.rm = TRUE))
              }
            }
          }
        }
      }
      
      vizinhos_candidatos$border_len <- border_len
      
      vizinhos_com_aresta <- vizinhos_candidatos[
        !is.na(vizinhos_candidatos$border_len) &
          vizinhos_candidatos$border_len > 0,
      ]
      
      if (nrow(vizinhos_com_aresta) > 0) {
        
        idx_best <- which.max(vizinhos_com_aresta$border_len)
        id_best <- vizinhos_com_aresta$tmp_id[idx_best]
        feat_best <- local1_corr[local1_corr$tmp_id == id_best, ]
        
        geom_new <- st_union(feat_best, feat_small)
        geom_new <- st_make_valid(geom_new)
        geom_new <- suppressWarnings(
          st_collection_extract(geom_new, "POLYGON")
        )
        
        if (nrow(geom_new) == 0) next
        
        geom_new <- st_union(geom_new)
        
      } else {
        
        d_viz <- suppressWarnings(
          as.numeric(st_distance(
            feat_small,
            vizinhos_candidatos,
            by_element = FALSE
          ))
        )
        
        if (length(d_viz) != nrow(vizinhos_candidatos)) next
        
        ok_d <- which(!is.na(d_viz) & d_viz <= tolerancia_gap_m)
        if (length(ok_d) == 0) next
        
        idx_best <- ok_d[which.min(d_viz[ok_d])]
        id_best <- vizinhos_candidatos$tmp_id[idx_best]
        feat_best <- local1_corr[local1_corr$tmp_id == id_best, ]
        
        bridge_tol <- max(tolerancia_gap_m * 0.75, 0.001)
        
        geom_new <- suppressWarnings(
          st_union(
            st_buffer(feat_best, bridge_tol),
            st_buffer(feat_small, bridge_tol)
          )
        )
        
        geom_new <- suppressWarnings(st_buffer(geom_new, -bridge_tol))
        geom_new <- st_make_valid(geom_new)
        geom_new <- suppressWarnings(
          st_collection_extract(geom_new, "POLYGON")
        )
        
        if (nrow(geom_new) == 0) next
        
        geom_new <- st_union(geom_new)
      }
      
      local1_corr$geometry[local1_corr$tmp_id == id_best] <- st_geometry(geom_new)
      local1_corr <- local1_corr[local1_corr$tmp_id != id_small, ]
      removed_iter <- removed_iter + 1L
    }
    
    local1_corr <- st_make_valid(local1_corr)
    local1_corr <- suppressWarnings(
      st_collection_extract(local1_corr, "POLYGON")
    )
    local1_corr <- local1_corr[!st_is_empty(local1_corr), ]
    
    if (nrow(local1_corr) == 0) break
    if (removed_iter == 0) break
  }
  
  if ("tmp_id" %in% names(local1_corr)) local1_corr$tmp_id <- NULL
  if ("AREA_ha_tmp" %in% names(local1_corr)) local1_corr$AREA_ha_tmp <- NULL
  if ("border_len" %in% names(local1_corr)) local1_corr$border_len <- NULL
}


## =========================================================
## F.2) PROCESSAR LOCAL 2
## =========================================================

local2_corr <- local2

if (nrow(local2_corr) > 0) {
  
  local2_corr <- st_make_valid(local2_corr)
  local2_corr <- suppressWarnings(
    st_collection_extract(local2_corr, "POLYGON")
  )
  local2_corr <- local2_corr[!st_is_empty(local2_corr), ]
  
  iter <- 0L
  
  repeat {
    
    iter <- iter + 1L
    
    local2_corr$AREA_ha <- as.numeric(st_area(local2_corr)) / 10000
    local2_corr$tmp_id <- seq_len(nrow(local2_corr))
    
    ids_pequenos <- local2_corr$tmp_id[local2_corr$AREA_ha < threshold_ha]
    n_small_now <- length(ids_pequenos)
    removed_iter <- 0L
    
    if (n_small_now == 0) break
    if (iter > max_iter) break
    
    for (id_small in ids_pequenos) {
      
      idx_small <- match(id_small, local2_corr$tmp_id)
      if (is.na(idx_small)) next
      
      feat_small <- local2_corr[idx_small, ]
      feat_small <- st_make_valid(feat_small)
      feat_small <- suppressWarnings(
        st_collection_extract(feat_small, "POLYGON")
      )
      feat_small <- feat_small[!st_is_empty(feat_small), ]
      
      if (nrow(feat_small) == 0) next
      
      idx_touch <- st_touches(feat_small, local2_corr)[[1]]
      
      if (length(idx_touch) > 0) {
        idx_candidatos <- setdiff(idx_touch, idx_small)
      } else {
        idx_int <- st_intersects(feat_small, local2_corr)[[1]]
        idx_candidatos <- setdiff(idx_int, idx_small)
      }
      
      if (length(idx_candidatos) == 0 &&
          tolerancia_gap_m > 0 &&
          nrow(local2_corr) > 1) {
        
        idx_gap <- st_is_within_distance(
          feat_small,
          local2_corr,
          dist = tolerancia_gap_m
        )[[1]]
        
        idx_candidatos <- setdiff(idx_gap, idx_small)
      }
      
      if (length(idx_candidatos) == 0) next
      
      vizinhos <- local2_corr[idx_candidatos, ]
      vizinhos <- vizinhos[vizinhos$tmp_id != id_small, ]
      vizinhos <- st_make_valid(vizinhos)
      vizinhos <- suppressWarnings(
        st_collection_extract(vizinhos, "POLYGON")
      )
      vizinhos <- vizinhos[!st_is_empty(vizinhos), ]
      
      if (nrow(vizinhos) == 0) next
      
      vizinhos$AREA_ha_tmp <- as.numeric(st_area(vizinhos)) / 10000
      vizinhos_grandes <- vizinhos[vizinhos$AREA_ha_tmp >= threshold_ha, ]
      vizinhos_candidatos <- if (nrow(vizinhos_grandes) > 0) vizinhos_grandes else vizinhos
      
      border_len <- numeric(nrow(vizinhos_candidatos))
      
      for (k in seq_len(nrow(vizinhos_candidatos))) {
        
        feat_small_poly <- suppressWarnings(
          st_collection_extract(st_make_valid(feat_small), "POLYGON")
        )
        
        viz_k_poly <- suppressWarnings(
          st_collection_extract(st_make_valid(vizinhos_candidatos[k, ]), "POLYGON")
        )
        
        if (nrow(feat_small_poly) == 0 || nrow(viz_k_poly) == 0) {
          border_len[k] <- 0
          next
        }
        
        inter_b <- tryCatch(
          suppressWarnings(
            st_intersection(
              st_boundary(feat_small_poly),
              st_boundary(viz_k_poly)
            )
          ),
          error = function(e) NULL
        )
        
        border_len[k] <- 0
        
        if (!is.null(inter_b) && nrow(inter_b) > 0) {
          
          tipos_inter <- unique(as.character(st_geometry_type(inter_b)))
          
          if (any(tipos_inter %in% c("LINESTRING", "MULTILINESTRING"))) {
            
            inter_b_lin <- inter_b[
              st_geometry_type(inter_b) %in% c("LINESTRING", "MULTILINESTRING"),
            ]
            
            if (nrow(inter_b_lin) > 0) {
              len_b <- suppressWarnings(st_length(inter_b_lin))
              
              if (length(len_b) > 0 && any(!is.na(len_b))) {
                border_len[k] <- as.numeric(sum(len_b, na.rm = TRUE))
              }
            }
          }
          
          if (any(tipos_inter == "GEOMETRYCOLLECTION")) {
            
            inter_b_gc <- inter_b[
              st_geometry_type(inter_b) == "GEOMETRYCOLLECTION",
            ]
            
            inter_b_lin_gc <- tryCatch(
              suppressWarnings(st_collection_extract(inter_b_gc, "LINESTRING")),
              error = function(e) NULL
            )
            
            if (!is.null(inter_b_lin_gc) && nrow(inter_b_lin_gc) > 0) {
              len_b <- suppressWarnings(st_length(inter_b_lin_gc))
              
              if (length(len_b) > 0 && any(!is.na(len_b))) {
                border_len[k] <- border_len[k] + as.numeric(sum(len_b, na.rm = TRUE))
              }
            }
          }
        }
      }
      
      vizinhos_candidatos$border_len <- border_len
      
      vizinhos_com_aresta <- vizinhos_candidatos[
        !is.na(vizinhos_candidatos$border_len) &
          vizinhos_candidatos$border_len > 0,
      ]
      
      if (nrow(vizinhos_com_aresta) > 0) {
        
        idx_best <- which.max(vizinhos_com_aresta$border_len)
        id_best <- vizinhos_com_aresta$tmp_id[idx_best]
        feat_best <- local2_corr[local2_corr$tmp_id == id_best, ]
        
        geom_new <- st_union(feat_best, feat_small)
        geom_new <- st_make_valid(geom_new)
        geom_new <- suppressWarnings(
          st_collection_extract(geom_new, "POLYGON")
        )
        
        if (nrow(geom_new) == 0) next
        
        geom_new <- st_union(geom_new)
        
      } else {
        
        d_viz <- suppressWarnings(
          as.numeric(st_distance(
            feat_small,
            vizinhos_candidatos,
            by_element = FALSE
          ))
        )
        
        if (length(d_viz) != nrow(vizinhos_candidatos)) next
        
        ok_d <- which(!is.na(d_viz) & d_viz <= tolerancia_gap_m)
        if (length(ok_d) == 0) next
        
        idx_best <- ok_d[which.min(d_viz[ok_d])]
        id_best <- vizinhos_candidatos$tmp_id[idx_best]
        feat_best <- local2_corr[local2_corr$tmp_id == id_best, ]
        
        bridge_tol <- max(tolerancia_gap_m * 0.75, 0.001)
        
        geom_new <- suppressWarnings(
          st_union(
            st_buffer(feat_best, bridge_tol),
            st_buffer(feat_small, bridge_tol)
          )
        )
        
        geom_new <- suppressWarnings(st_buffer(geom_new, -bridge_tol))
        geom_new <- st_make_valid(geom_new)
        geom_new <- suppressWarnings(
          st_collection_extract(geom_new, "POLYGON")
        )
        
        if (nrow(geom_new) == 0) next
        
        geom_new <- st_union(geom_new)
      }
      
      local2_corr$geometry[local2_corr$tmp_id == id_best] <- st_geometry(geom_new)
      local2_corr <- local2_corr[local2_corr$tmp_id != id_small, ]
      removed_iter <- removed_iter + 1L
    }
    
    local2_corr <- st_make_valid(local2_corr)
    local2_corr <- suppressWarnings(
      st_collection_extract(local2_corr, "POLYGON")
    )
    local2_corr <- local2_corr[!st_is_empty(local2_corr), ]
    
    if (nrow(local2_corr) == 0) break
    if (removed_iter == 0) break
  }
  
  if ("tmp_id" %in% names(local2_corr)) local2_corr$tmp_id <- NULL
  if ("AREA_ha_tmp" %in% names(local2_corr)) local2_corr$AREA_ha_tmp <- NULL
  if ("border_len" %in% names(local2_corr)) local2_corr$border_len <- NULL
}

## =========================================================
## F.3) PROCESSAR LOCAL 3
## =========================================================

local3_corr <- local3

if (nrow(local3_corr) > 0) {
  
  local3_corr <- st_make_valid(local3_corr)
  local3_corr <- suppressWarnings(
    st_collection_extract(local3_corr, "POLYGON")
  )
  local3_corr <- local3_corr[!st_is_empty(local3_corr), ]
  
  iter <- 0L
  
  repeat {
    
    iter <- iter + 1L
    
    local3_corr$AREA_ha <- as.numeric(st_area(local3_corr)) / 10000
    local3_corr$tmp_id <- seq_len(nrow(local3_corr))
    
    ids_pequenos <- local3_corr$tmp_id[local3_corr$AREA_ha < threshold_ha]
    n_small_now <- length(ids_pequenos)
    removed_iter <- 0L
    
    if (n_small_now == 0) break
    if (iter > max_iter) break
    
    for (id_small in ids_pequenos) {
      
      idx_small <- match(id_small, local3_corr$tmp_id)
      if (is.na(idx_small)) next
      
      feat_small <- local3_corr[idx_small, ]
      feat_small <- st_make_valid(feat_small)
      feat_small <- suppressWarnings(
        st_collection_extract(feat_small, "POLYGON")
      )
      feat_small <- feat_small[!st_is_empty(feat_small), ]
      
      if (nrow(feat_small) == 0) next
      
      idx_touch <- st_touches(feat_small, local3_corr)[[1]]
      
      if (length(idx_touch) > 0) {
        idx_candidatos <- setdiff(idx_touch, idx_small)
      } else {
        idx_int <- st_intersects(feat_small, local3_corr)[[1]]
        idx_candidatos <- setdiff(idx_int, idx_small)
      }
      
      if (length(idx_candidatos) == 0 &&
          tolerancia_gap_m > 0 &&
          nrow(local3_corr) > 1) {
        
        idx_gap <- st_is_within_distance(
          feat_small,
          local3_corr,
          dist = tolerancia_gap_m
        )[[1]]
        
        idx_candidatos <- setdiff(idx_gap, idx_small)
      }
      
      if (length(idx_candidatos) == 0) next
      
      vizinhos <- local3_corr[idx_candidatos, ]
      vizinhos <- vizinhos[vizinhos$tmp_id != id_small, ]
      vizinhos <- st_make_valid(vizinhos)
      vizinhos <- suppressWarnings(
        st_collection_extract(vizinhos, "POLYGON")
      )
      vizinhos <- vizinhos[!st_is_empty(vizinhos), ]
      
      if (nrow(vizinhos) == 0) next
      
      vizinhos$AREA_ha_tmp <- as.numeric(st_area(vizinhos)) / 10000
      vizinhos_grandes <- vizinhos[vizinhos$AREA_ha_tmp >= threshold_ha, ]
      vizinhos_candidatos <- if (nrow(vizinhos_grandes) > 0) vizinhos_grandes else vizinhos
      
      border_len <- numeric(nrow(vizinhos_candidatos))
      
      for (k in seq_len(nrow(vizinhos_candidatos))) {
        
        feat_small_poly <- suppressWarnings(
          st_collection_extract(st_make_valid(feat_small), "POLYGON")
        )
        
        viz_k_poly <- suppressWarnings(
          st_collection_extract(st_make_valid(vizinhos_candidatos[k, ]), "POLYGON")
        )
        
        if (nrow(feat_small_poly) == 0 || nrow(viz_k_poly) == 0) {
          border_len[k] <- 0
          next
        }
        
        inter_b <- tryCatch(
          suppressWarnings(
            st_intersection(
              st_boundary(feat_small_poly),
              st_boundary(viz_k_poly)
            )
          ),
          error = function(e) NULL
        )
        
        border_len[k] <- 0
        
        if (!is.null(inter_b) && nrow(inter_b) > 0) {
          
          tipos_inter <- unique(as.character(st_geometry_type(inter_b)))
          
          if (any(tipos_inter %in% c("LINESTRING", "MULTILINESTRING"))) {
            
            inter_b_lin <- inter_b[
              st_geometry_type(inter_b) %in% c("LINESTRING", "MULTILINESTRING"),
            ]
            
            if (nrow(inter_b_lin) > 0) {
              len_b <- suppressWarnings(st_length(inter_b_lin))
              
              if (length(len_b) > 0 && any(!is.na(len_b))) {
                border_len[k] <- as.numeric(sum(len_b, na.rm = TRUE))
              }
            }
          }
          
          if (any(tipos_inter == "GEOMETRYCOLLECTION")) {
            
            inter_b_gc <- inter_b[
              st_geometry_type(inter_b) == "GEOMETRYCOLLECTION",
            ]
            
            inter_b_lin_gc <- tryCatch(
              suppressWarnings(st_collection_extract(inter_b_gc, "LINESTRING")),
              error = function(e) NULL
            )
            
            if (!is.null(inter_b_lin_gc) && nrow(inter_b_lin_gc) > 0) {
              len_b <- suppressWarnings(st_length(inter_b_lin_gc))
              
              if (length(len_b) > 0 && any(!is.na(len_b))) {
                border_len[k] <- border_len[k] + as.numeric(sum(len_b, na.rm = TRUE))
              }
            }
          }
        }
      }
      
      vizinhos_candidatos$border_len <- border_len
      
      vizinhos_com_aresta <- vizinhos_candidatos[
        !is.na(vizinhos_candidatos$border_len) &
          vizinhos_candidatos$border_len > 0,
      ]
      
      if (nrow(vizinhos_com_aresta) > 0) {
        
        idx_best <- which.max(vizinhos_com_aresta$border_len)
        id_best <- vizinhos_com_aresta$tmp_id[idx_best]
        feat_best <- local3_corr[local3_corr$tmp_id == id_best, ]
        
        geom_new <- st_union(feat_best, feat_small)
        geom_new <- st_make_valid(geom_new)
        geom_new <- suppressWarnings(
          st_collection_extract(geom_new, "POLYGON")
        )
        
        if (nrow(geom_new) == 0) next
        
        geom_new <- st_union(geom_new)
        
      } else {
        
        d_viz <- suppressWarnings(
          as.numeric(st_distance(
            feat_small,
            vizinhos_candidatos,
            by_element = FALSE
          ))
        )
        
        if (length(d_viz) != nrow(vizinhos_candidatos)) next
        
        ok_d <- which(!is.na(d_viz) & d_viz <= tolerancia_gap_m)
        if (length(ok_d) == 0) next
        
        idx_best <- ok_d[which.min(d_viz[ok_d])]
        id_best <- vizinhos_candidatos$tmp_id[idx_best]
        feat_best <- local3_corr[local3_corr$tmp_id == id_best, ]
        
        bridge_tol <- max(tolerancia_gap_m * 0.75, 0.001)
        
        geom_new <- suppressWarnings(
          st_union(
            st_buffer(feat_best, bridge_tol),
            st_buffer(feat_small, bridge_tol)
          )
        )
        
        geom_new <- suppressWarnings(st_buffer(geom_new, -bridge_tol))
        geom_new <- st_make_valid(geom_new)
        geom_new <- suppressWarnings(
          st_collection_extract(geom_new, "POLYGON")
        )
        
        if (nrow(geom_new) == 0) next
        
        geom_new <- st_union(geom_new)
      }
      
      local3_corr$geometry[local3_corr$tmp_id == id_best] <- st_geometry(geom_new)
      local3_corr <- local3_corr[local3_corr$tmp_id != id_small, ]
      removed_iter <- removed_iter + 1L
    }
    
    local3_corr <- st_make_valid(local3_corr)
    local3_corr <- suppressWarnings(
      st_collection_extract(local3_corr, "POLYGON")
    )
    local3_corr <- local3_corr[!st_is_empty(local3_corr), ]
    
    if (nrow(local3_corr) == 0) break
    if (removed_iter == 0) break
  }
  
  if ("tmp_id" %in% names(local3_corr)) local3_corr$tmp_id <- NULL
  if ("AREA_ha_tmp" %in% names(local3_corr)) local3_corr$AREA_ha_tmp <- NULL
  if ("border_len" %in% names(local3_corr)) local3_corr$border_len <- NULL
}

## =========================================================
## F.4) JUNTAR RESULTADOS DA AGREGACAO NORMAL
## =========================================================

shp_stands_interface_final <- rbind(
  local1_corr,
  local2_corr,
  local3_corr,
  outros
)

shp_stands_interface_final <- normalizar_poligonos(shp_stands_interface_final)
shp_stands_interface_final <- st_cast(
  shp_stands_interface_final,
  "POLYGON",
  warn = FALSE
)

## =========================================================
## F.5) SEGUNDA PASSAGEM DE RESGATE
## =========================================================

shp_stands_interface_final$AREA_ha <- as.numeric(
  st_area(shp_stands_interface_final)
) / 10000

shp_stands_interface_final$tmp_id <- seq_len(nrow(shp_stands_interface_final))

ids_sobrantes <- shp_stands_interface_final$tmp_id[
  shp_stands_interface_final$AREA_ha < threshold_ha
]

if (length(ids_sobrantes) > 0) {
  
  for (id_small in ids_sobrantes) {
    
    idx_small <- match(id_small, shp_stands_interface_final$tmp_id)
    if (is.na(idx_small)) next
    
    feat_small <- shp_stands_interface_final[idx_small, ]
    local_small <- feat_small$Local[1]
    
    if (is.na(local_small)) next
    
    candidatos <- shp_stands_interface_final[
      shp_stands_interface_final$Local == local_small &
        shp_stands_interface_final$tmp_id != id_small,
    ]
    
    if (nrow(candidatos) == 0) next
    
    d <- suppressWarnings(
      as.numeric(st_distance(feat_small, candidatos, by_element = FALSE))
    )
    
    if (length(d) != nrow(candidatos)) next
    
    ok_d <- which(!is.na(d) & d <= tolerancia_gap_m)
    if (length(ok_d) == 0) next
    
    idx_best <- ok_d[which.min(d[ok_d])]
    id_best <- candidatos$tmp_id[idx_best]
    feat_best <- shp_stands_interface_final[
      shp_stands_interface_final$tmp_id == id_best,
    ]
    
    bridge_tol <- max(tolerancia_gap_m * 0.75, 0.001)
    
    geom_new <- suppressWarnings(
      st_union(
        st_buffer(feat_best, bridge_tol),
        st_buffer(feat_small, bridge_tol)
      )
    )
    
    geom_new <- suppressWarnings(st_buffer(geom_new, -bridge_tol))
    
    shp_stands_interface_final$geometry[
      shp_stands_interface_final$tmp_id == id_best
    ] <- st_geometry(geom_new)
    
    shp_stands_interface_final <- shp_stands_interface_final[
      shp_stands_interface_final$tmp_id != id_small,
    ]
  }
}

if ("tmp_id" %in% names(shp_stands_interface_final)) {
  shp_stands_interface_final$tmp_id <- NULL
}

if ("AREA_ha_tmp" %in% names(shp_stands_interface_final)) {
  shp_stands_interface_final$AREA_ha_tmp <- NULL
}

if ("border_len" %in% names(shp_stands_interface_final)) {
  shp_stands_interface_final$border_len <- NULL
}

shp_stands_interface_final <- normalizar_poligonos(shp_stands_interface_final)
shp_stands_interface_final <- st_cast(
  shp_stands_interface_final,
  "POLYGON",
  warn = FALSE
)

## =========================================================
## G) RECALCULAR AREA_ha E NOVO ID
## =========================================================

shp_stands_interface_final$AREA_ha <- as.numeric(
  st_area(shp_stands_interface_final)
) / 10000

shp_stands_interface_final$Stand_IDv2 <- seq_len(nrow(shp_stands_interface_final))

## =========================================================
## H) CONFERIR
## =========================================================

table(shp_stands_interface_final$Local, useNA = "ifany")
table(st_geometry_type(shp_stands_interface_final))
summary(shp_stands_interface_final$AREA_ha)

cat(
  sprintf(
    "Poligonos abaixo do limite (< %.6f ha): %d\n",
    threshold_ha,
    sum(shp_stands_interface_final$AREA_ha < threshold_ha, na.rm = TRUE)
  )
)

## =========================================================
## I) GUARDAR
## =========================================================

shp_stands_interface_final <- normalizar_poligonos(shp_stands_interface_final)

st_write(
  shp_stands_interface_final,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/v2_20260422/shp_stands_interface_final.shp",
  delete_layer = TRUE
)





## # - IDENTIFICAR AREAS PRIORITARIAS - INTERFACE ####

library(sf)
library(dplyr)
library(tidyr)

# Ler layer
stands_gestao_interface <- st_read(
  dsn = "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/V4_20260423/Gestao_Interface/stands_arcgis.gdb",
  layer = "stands_alg_interface",
  quiet = TRUE
)

# Área total de interface por município: Local == 1
area_interface_mun <- stands_gestao_interface %>%
  st_drop_geometry() %>%
  filter(
    !is.na(municipio),
    Local == 1
  ) %>%
  group_by(municipio) %>%
  summarise(
    `area interface (ha)` = sum(AREA_ha, na.rm = TRUE),
    .groups = "drop"
  )

# Área por classe PAbs_pct
area_classes_mun <- stands_gestao_interface %>%
  st_drop_geometry() %>%
  filter(
    !is.na(municipio),
    !is.na(PAbs_pct),
    PAbs_pct > 0
  ) %>%
  group_by(municipio, PAbs_pct) %>%
  summarise(
    area_ha = sum(AREA_ha, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = PAbs_pct,
    names_prefix = "P",
    values_from = area_ha,
    values_fill = 0
  ) %>%
  mutate(
    `P>80` = P9 + P10
  ) %>%
  left_join(area_interface_mun, by = "municipio") %>%
  mutate(
    `relativo ao municipio` = (`P>80` / `area interface (ha)`) * 100
  ) %>%
  arrange(municipio)

# Valor fixo da área interface total do Algarve
area_interface_algarve <- sum(
  area_classes_mun$`area interface (ha)`,
  na.rm = TRUE
)

# Linha total Algarve
linha_algarve <- area_classes_mun %>%
  summarise(
    municipio = "Algarve",
    across(
      where(is.numeric),
      ~ sum(.x, na.rm = TRUE)
    )
  ) %>%
  mutate(
    `relativo ao municipio` = (`P>80` / `area interface (ha)`) * 100
  )

# Juntar linha Algarve e calcular relativo ao Algarve
area_classes_mun <- bind_rows(
  area_classes_mun,
  linha_algarve
) %>%
  mutate(
    `Relativo ao Algarve` = (`P>80` / area_interface_algarve) * 100
  )

# Guardar CSV
write.csv(
  area_classes_mun,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/V4_20260423/Gestao_Interface/graficos/area_PAbs_pct_por_municipio.csv",
  row.names = FALSE
)


library(ggplot2)

# remover linha Algarve do gráfico
grafico_df <- area_classes_mun %>%
  filter(municipio != "Algarve")

# fator para manter a ordem da tabela no eixo X
grafico_df$municipio <- factor(grafico_df$municipio, levels = grafico_df$municipio)

# fator de escala para eixo secundário
escala <- max(grafico_df$`relativo ao municipio`, na.rm = TRUE) /
  max(grafico_df$`Relativo ao Algarve`, na.rm = TRUE)

grafico_p80 <- ggplot(grafico_df, aes(x = municipio)) +
  geom_col(aes(y = `relativo ao municipio`), fill = "darkorange") +
  geom_line(
    aes(y = `Relativo ao Algarve` * escala, group = 1),
    color = "darkblue",
    linewidth = 1
  ) +
  geom_point(
    aes(y = `Relativo ao Algarve` * escala),
    color = "darkblue",
    size = 2
  ) +
  scale_y_continuous(
    name = "% Relativamente ao Município",
    sec.axis = sec_axis(
      trans = ~ . / escala,
      name = "% Relativamente ao Algarve"
    )
  ) +
  labs(
    title = "Área por município com exposição muito elevada (>p80)",
    x = NULL
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

print(grafico_p80)

ggsave(
  filename = "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/V4_20260423/Gestao_Interface/grafico_area_p80_municipio.png",
  plot = grafico_p80,
  width = 14,
  height = 7,
  dpi = 300
)
library(sf)
library(qgisprocess)
library(raster)
library(dplyr)
library(exactextractr)
library(tidyr)
library(snow)
library(doSNOW)
library(foreach)

# caminhos 
# shp_aglomerados_0_100 <- file.path(dir_inputs, "Valores_Chave/V2_2026/aglomerados/aglomerados_0a100m.shp")
# shp_interface_dissolve <- file.path(dir_output_analise, "Interface/interface_dissolve.shp")
# stands_interface_int <- file.path(dir_unidades_tratamento, "stands_alg_interface_int.shp")
# stands_erase_single <- file.path(dir_unidades_tratamento, "stands_erase.shp")
# shp_stands_interface <- file.path(dir_unidades_tratamento, "stands_alg_interface.shp")

library(sf)
library(dplyr)

## =========================================================
## 1) APLICAR MÁSCARA DE INTERFACE COM Local = 1
## =========================================================

library(sf)
library(dplyr)
library(qgisprocess)

# Ler aglomerados
shp_aglomerados_0_100 <- st_read(
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Inputs/Valores_Chave/V2_2026/aglomerados/aglomerados_0a100m.shp"
)

# Dissolve
interface_diss <- st_union(shp_aglomerados_0_100)

# Multipart to singlepart
shp_interface_dissolve <- st_cast(interface_diss, "POLYGON")

# Transformar em sf e criar Inter_ID
shp_interface_dissolve <- st_as_sf(
  data.frame(Inter_ID = seq_along(shp_interface_dissolve)),
  geometry = shp_interface_dissolve
)

# Calcular área em hectares
shp_interface_dissolve$AREA_ha <- as.numeric(
  st_area(shp_interface_dissolve)
) / 10000

# Guardar interface dissolve
st_write(
  shp_interface_dissolve,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/shp_interface_dissolve.shp",
  delete_layer = TRUE
)

## =========================================================
## 2) FRAGMENTAR STANDS PELA INTERFACE
## =========================================================

# Ler dados
shp_stands_base <- st_read(
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Inputs/UTratamento/stands_alg_COS23_base.shp"
)

shp_interface_dissolve <- st_read(
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/shp_interface_dissolve.shp"
)

# Garantir geometrias válidas
shp_stands_base <- st_make_valid(shp_stands_base)
shp_interface_dissolve <- st_make_valid(shp_interface_dissolve)

# Garantir o mesmo CRS
shp_interface_dissolve <- st_transform(
  shp_interface_dissolve,
  st_crs(shp_stands_base)
)

## =========================================================
## A) INTERSECT
## =========================================================

stands_interface_int <- st_intersection(
  shp_stands_base,
  shp_interface_dissolve
)

table(st_geometry_type(stands_interface_int))

stands_interface_int <- st_collection_extract(
  stands_interface_int,
  "POLYGON"
)

stands_interface_int <- stands_interface_int[
  !st_is_empty(stands_interface_int),
]

stands_interface_int <- st_cast(
  stands_interface_int,
  "POLYGON",
  warn = FALSE
)

# Origem = interface
stands_interface_int$Origem <- "interface"

if (!"Inter_ID" %in% names(stands_interface_int)) {
  stands_interface_int$Inter_ID <- NA_integer_
}

stands_interface_int$AREA_ha <- as.numeric(
  st_area(stands_interface_int)
) / 10000

table(st_geometry_type(stands_interface_int))

st_write(
  stands_interface_int,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/stands_interface_int.shp",
  delete_layer = TRUE
)

## =========================================================
## B) ERASE
## =========================================================

stands_erase <- st_difference(
  shp_stands_base,
  st_union(shp_interface_dissolve)
)

table(st_geometry_type(stands_erase))

stands_erase <- st_make_valid(stands_erase)

stands_erase <- st_collection_extract(
  stands_erase,
  "POLYGON"
)

stands_erase <- stands_erase[
  !st_is_empty(stands_erase),
]

stands_erase$feat_orig <- seq_len(nrow(stands_erase))

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

# Origem = paisagem
stands_erase_single$Origem <- "paisagem"

stands_erase_single$Inter_ID <- NA_integer_

stands_erase_single$AREA_ha <- as.numeric(
  st_area(stands_erase_single)
) / 10000

table(st_geometry_type(stands_erase_single))

st_write(
  stands_erase_single,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/stands_erase_inter.shp",
  delete_layer = TRUE
)

## =========================================================
## C) MERGE FINAL
## =========================================================

cols_comuns <- intersect(
  names(stands_erase_single),
  names(stands_interface_int)
)

stands_erase_bind <- stands_erase_single[, cols_comuns]
stands_int_bind   <- stands_interface_int[, cols_comuns]

shp_stands_interface <- rbind(
  stands_erase_bind,
  stands_int_bind
)

shp_stands_interface$Stand_IDv2 <- seq_len(nrow(shp_stands_interface))

shp_stands_interface$AREA_ha <- as.numeric(
  st_area(shp_stands_interface)
) / 10000

shp_stands_interface$Local <- NA_integer_
shp_stands_interface$Local[shp_stands_interface$Origem == "interface"] <- 1L
shp_stands_interface$Local[shp_stands_interface$Origem == "paisagem"] <- 2L

table(st_geometry_type(shp_stands_interface))
table(shp_stands_interface$Origem)
table(shp_stands_interface$Local)

st_write(
  shp_stands_interface,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/shp_stands_interface.shp",
  delete_layer = TRUE
)

#####################################################################################################
#####################################################################################################

## =========================================================
## 3) APLICAR MÁSCARA DE ÁREAS EDIFICADAS
## =========================================================

library(sf)
library(dplyr)

# caminhos
# shp_aglomerados_base <- file.path(dir_inputs, "Valores_Chave/V2_2026/aglomerados/aglomerados.shp")
# shp_stands_interface <- file.path(dir_unidades_tratamento, "stands_alg_interface.shp")
# stands_aglom_int <- file.path(dir_output_analise, "Aglomerados/stands_aglom_int.shp")
# stands_aglom_int_diss <- file.path(dir_output_analise, "Aglomerados/stands_aglom_int_diss.shp")
# stands_sem_aglomerado <- file.path(dir_unidades_tratamento, "stands_sem_aglomerado.shp")
# shp_stands_interface_edf <- file.path(dir_unidades_tratamento, "stands_alg_interface_edf.shp")

# Ler dados
shp_aglomerados_base <- st_read(
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Inputs/Valores_Chave/V2_2026/aglomerados/aglomerados.shp"
)

shp_stands_interface <- st_read(
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/shp_stands_interface.shp"
)

# Preparar dados
shp_aglomerados_base <- st_make_valid(shp_aglomerados_base)
shp_stands_interface <- st_make_valid(shp_stands_interface)

shp_aglomerados_base <- st_transform(
  shp_aglomerados_base,
  st_crs(shp_stands_interface)
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
  shp_stands_interface,
  shp_aglomerados_base_sel
)

stands_aglom_int <- st_collection_extract(
  stands_aglom_int,
  "POLYGON"
)

stands_aglom_int <- stands_aglom_int[
  !st_is_empty(stands_aglom_int),
]

stands_aglom_int$area_temp <- as.numeric(
  st_area(stands_aglom_int)
)

st_write(
  stands_aglom_int,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/stands_aglom_int.shp",
  delete_layer = TRUE
)

stands_aglom_int_diss <- stands_aglom_int |>
  group_by(fid_u, TIPO_p) |>
  summarise(
    ID         = ID[which.max(area_temp)],
    COS23_n4_C = COS23_n4_C[which.max(area_temp)],
    COS23_n4_L = COS23_n4_L[which.max(area_temp)],
    Class      = Class[which.max(area_temp)],
    treatable  = treatable[which.max(area_temp)],
    dec_p90    = dec_p90[which.max(area_temp)],
    dec_p90_wg = dec_p90_wg[which.max(area_temp)],
    gerivel    = gerivel[which.max(area_temp)],
    exclude    = exclude[which.max(area_temp)],
    exposicao  = exposicao[which.max(area_temp)],
    Stand_ID   = Stand_ID[which.max(area_temp)],
    Origem     = "edificado",
    Inter_ID   = Inter_ID[which.max(area_temp)],
    Stand_IDv2 = Stand_IDv2[which.max(area_temp)],
    Local      = 3L,
    do_union   = TRUE,
    .groups    = "drop"
  )

stands_aglom_int_diss <- st_make_valid(stands_aglom_int_diss)

stands_aglom_int_diss$AREA_ha <- as.numeric(
  st_area(stands_aglom_int_diss)
) / 10000

st_write(
  stands_aglom_int_diss,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/stands_aglom_int_diss.shp",
  delete_layer = TRUE
)

## =========================================================
## B) ERASE
## =========================================================

aglo_union <- st_union(shp_aglomerados_base_sel)

stands_sem_aglomerado <- st_difference(
  shp_stands_interface,
  aglo_union
)

stands_sem_aglomerado <- st_make_valid(stands_sem_aglomerado)
stands_sem_aglomerado <- st_collection_extract(stands_sem_aglomerado, "POLYGON")
stands_sem_aglomerado <- stands_sem_aglomerado[!st_is_empty(stands_sem_aglomerado), ]

stands_sem_aglomerado$fid_u <- NA
stands_sem_aglomerado$TIPO_p <- NA

stands_sem_aglomerado$AREA_ha <- as.numeric(
  st_area(stands_sem_aglomerado)
) / 10000

st_write(
  stands_sem_aglomerado,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/stands_sem_aglomerado.shp",
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

## =========================================================
## D) GARANTIR CAMPO Local
## =========================================================

shp_stands_interface_edf$Local <- NA_integer_
shp_stands_interface_edf$Local[shp_stands_interface_edf$Origem == "interface"] <- 1L
shp_stands_interface_edf$Local[shp_stands_interface_edf$Origem == "paisagem"] <- 2L
shp_stands_interface_edf$Local[shp_stands_interface_edf$Origem == "edificado"] <- 3L

## =========================================================
## E) CRIAR CAMPO Uso_solo
## =========================================================

shp_stands_interface_edf$Uso_solo <- shp_stands_interface_edf$COS23_n4_L

idx_local3 <- shp_stands_interface_edf$Local == 3

shp_stands_interface_edf$Uso_solo[idx_local3] <- ifelse(
  is.na(shp_stands_interface_edf$TIPO_p[idx_local3]),
  "Área edificada",
  paste0("Área edificada tipo_p ", shp_stands_interface_edf$TIPO_p[idx_local3])
)

## =========================================================
## F) RECALCULAR AREA_ha E NOVO ID
## =========================================================

shp_stands_interface_edf$AREA_ha <- as.numeric(
  st_area(shp_stands_interface_edf)
) / 10000

shp_stands_interface_edf$Stand_IDv2 <- seq_len(nrow(shp_stands_interface_edf))

table(st_geometry_type(shp_stands_interface_edf))
table(shp_stands_interface_edf$Origem, useNA = "ifany")
table(shp_stands_interface_edf$Local, useNA = "ifany")

st_write(
  shp_stands_interface_edf,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/shp_stands_interface_edf.shp",
  delete_layer = TRUE
)


#####################################################################################################
#####################################################################################################

## =========================================================
## 4) CORRIGIR STANDS INTERFACE EDF
## =========================================================

library(sf)
library(dplyr)

# caminhos
# shp_stands_interface_edf <- file.path (dir_unidades_tratamento, "stands_alg_interface_edf_8.shp")
# shp_interface_dissolve <- file.path(dir_output_analise, "Interface/interface_dissolve_1.shp")
# interface_dissolver <- file.path(dir_output_analise, "Interface/interface_dissolver_9.shp")
# interface_dissolvida <- file.path(dir_output_analise, "Interface/interface_dissolvida_10.shp")
# interface_diss_completa <- file.path (dir_unidades_tratamento, "interface_diss_completa_11.shp")
# shp_stands_interface_final <- file.path(dir_unidades_tratamento, "stands_alg_interface_final.shp")

# Ler dados
shp_stands_interface_edf <- st_read(
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/shp_stands_interface_edf.shp"
)

shp_interface_dissolve <- st_read(
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/shp_interface_dissolve.shp"
)

# Garantir geometrias válidas
shp_stands_interface_edf <- st_make_valid(shp_stands_interface_edf)
shp_interface_dissolve <- st_make_valid(shp_interface_dissolve)

# Garantir mesmo CRS
shp_interface_dissolve <- st_transform(
  shp_interface_dissolve,
  st_crs(shp_stands_interface_edf)
)

## =========================================================
## A) IDENTIFICAR Inter_ID COM AREA_ha < 4
## =========================================================

inter_ids_pequenos <- shp_interface_dissolve$Inter_ID[
  shp_interface_dissolve$AREA_ha < 4
]

## =========================================================
## B) SEPARAR O QUE VAI SER DISSOLVIDO
## =========================================================

interface_dissolver <- shp_stands_interface_edf %>%
  filter(
    Local == 1,
    Inter_ID %in% inter_ids_pequenos
  )

st_write(
  interface_dissolver,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/dissolve_COS23_local1/interface_dissolver.shp",
  delete_layer = TRUE
)

stands_restantes <- shp_stands_interface_edf %>%
  filter(
    !(Local == 1 & Inter_ID %in% inter_ids_pequenos)
  )

## =========================================================
## C) DISSOLVE POR Inter_ID + COS23_n4_L
## =========================================================

interface_dissolver$area_temp <- as.numeric(st_area(interface_dissolver))

interface_dissolvida <- interface_dissolver %>%
  group_by(Inter_ID, COS23_n4_L) %>%
  summarise(
    ID         = ID[which.max(area_temp)],
    COS23_n4_C = COS23_n4_C[which.max(area_temp)],
    AREA_ha    = max(AREA_ha, na.rm = TRUE),
    Class      = Class[which.max(area_temp)],
    treatable  = treatable[which.max(area_temp)],
    dec_p90    = dec_p90[which.max(area_temp)],
    dec_p90_wg = dec_p90_wg[which.max(area_temp)],
    gerivel    = gerivel[which.max(area_temp)],
    exclude    = exclude[which.max(area_temp)],
    exposicao  = exposicao[which.max(area_temp)],
    Stand_ID   = Stand_ID[which.max(area_temp)],
    Origem     = Origem[which.max(area_temp)],
    Stand_IDv2 = Stand_IDv2[which.max(area_temp)],
    Local      = Local[which.max(area_temp)],
    fid_u      = fid_u[which.max(area_temp)],
    TIPO_p     = TIPO_p[which.max(area_temp)],
    Uso_solo   = Uso_solo[which.max(area_temp)],
    do_union   = TRUE,
    .groups    = "drop"
  )

interface_dissolvida <- st_make_valid(interface_dissolvida)

## =========================================================
## D) SEPARAR PARTES NÃO CONTÍNUAS SEM PERDER POLÍGONOS
## =========================================================

interface_dissolvida <- st_collection_extract(interface_dissolvida, "POLYGON")

atribs <- st_drop_geometry(interface_dissolvida)

geom_multi <- st_cast(
  st_geometry(interface_dissolvida),
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

interface_dissolvida <- st_sf(
  atribs_rep,
  geometry = geom_poly
)

interface_dissolvida <- interface_dissolvida[
  !st_is_empty(interface_dissolvida),
]

st_write(
  interface_dissolvida,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/dissolve_COS23_local1/interface_dissolvida.shp",
  delete_layer = TRUE
)
## =========================================================
## E) JUNTAR COM O RESTO
## =========================================================

cols_comuns <- intersect(
  names(stands_restantes),
  names(interface_dissolvida)
)

stands_restantes_bind <- stands_restantes[, cols_comuns]
stands_dissolvidos_bind <- interface_dissolvida[, cols_comuns]

interface_diss_completa <- rbind(
  stands_restantes_bind,
  stands_dissolvidos_bind
)

st_write(
  interface_diss_completa,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/dissolve_COS23_local1/interface_dissolvida_completa.shp",
  delete_layer = TRUE
)

## =========================================================
## F) AGREGAR POLÍGONOS MUITO PEQUENOS À VIZINHANÇA COM sf
## =========================================================

shp_stands_interface_final <- interface_diss_completa

threshold_ha <- 0.001
max_iter <- 10

# garantir validade
shp_stands_interface_final <- st_make_valid(shp_stands_interface_final)
shp_stands_interface_final <- shp_stands_interface_final[
  !st_is_empty(shp_stands_interface_final),
]
shp_stands_interface_final <- st_collection_extract(
  shp_stands_interface_final,
  "POLYGON"
)

iter <- 0
n_small_prev <- NA_integer_

repeat {
  
  iter <- iter + 1
  
  # recalcular área atual
  shp_stands_interface_final$AREA_ha <- as.numeric(
    st_area(shp_stands_interface_final)
  ) / 10000
  
  # criar ID temporário interno
  shp_stands_interface_final$tmp_id <- seq_len(nrow(shp_stands_interface_final))
  
  # identificar pequenos nesta iteração
  ids_pequenos <- shp_stands_interface_final$tmp_id[
    shp_stands_interface_final$AREA_ha < threshold_ha
  ]
  
  n_small_now <- length(ids_pequenos)
  
  cat("Iteração", iter, "- polígonos pequenos:", n_small_now, "\n")
  
  # condição 1: já não há pequenos
  if (n_small_now == 0) {
    cat("Paragem: não existem mais polígonos abaixo do limiar.\n")
    break
  }
  
  # condição 2: número de pequenos não mudou face à iteração anterior
  if (!is.na(n_small_prev) && n_small_now == n_small_prev) {
    cat("Paragem: o número de polígonos pequenos manteve-se.\n")
    break
  }
  
  # condição 3: atingiu nº máximo de iterações
  if (iter > max_iter) {
    cat("Paragem: atingido o número máximo de iterações.\n")
    break
  }
  
  for (id_small in ids_pequenos) {
    
    # se já foi removido numa iteração interna, saltar
    if (!(id_small %in% shp_stands_interface_final$tmp_id)) next
    
    feat_small <- shp_stands_interface_final[
      shp_stands_interface_final$tmp_id == id_small,
    ]
    
    # vizinhos que tocam no polígono pequeno
    idx_touch <- st_touches(feat_small, shp_stands_interface_final)[[1]]
    
    if (length(idx_touch) == 0) next
    
    vizinhos <- shp_stands_interface_final[idx_touch, ]
    vizinhos <- vizinhos[vizinhos$tmp_id != id_small, ]
    
    if (nrow(vizinhos) == 0) next
    
    # calcular área dos vizinhos
    vizinhos$AREA_ha_tmp <- as.numeric(st_area(vizinhos)) / 10000
    
    # preferir vizinhos acima do limiar
    vizinhos_grandes <- vizinhos[vizinhos$AREA_ha_tmp >= threshold_ha, ]
    
    if (nrow(vizinhos_grandes) > 0) {
      vizinhos_candidatos <- vizinhos_grandes
    } else {
      vizinhos_candidatos <- vizinhos
    }
    
    # calcular fronteira partilhada
    inter_lin <- suppressWarnings(
      st_intersection(
        st_boundary(vizinhos_candidatos),
        st_boundary(feat_small)
      )
    )
    
    if (nrow(inter_lin) == 0) next
    
    comp_partilhado <- as.numeric(st_length(inter_lin))
    
    if (length(comp_partilhado) == 0 || all(is.na(comp_partilhado))) next
    
    # escolher o vizinho com maior fronteira comum
    idx_best <- which.max(comp_partilhado)
    id_best <- vizinhos_candidatos$tmp_id[idx_best]
    
    feat_best <- shp_stands_interface_final[
      shp_stands_interface_final$tmp_id == id_best,
    ]
    
    # unir geometrias
    geom_new <- st_union(feat_best, feat_small)
    
    # atualizar geometria do vizinho escolhido
    shp_stands_interface_final$geometry[
      shp_stands_interface_final$tmp_id == id_best
    ] <- st_geometry(geom_new)
    
    # remover o polígono pequeno
    shp_stands_interface_final <- shp_stands_interface_final[
      shp_stands_interface_final$tmp_id != id_small,
    ]
  }
  
  # limpeza após cada iteração
  shp_stands_interface_final <- st_make_valid(shp_stands_interface_final)
  shp_stands_interface_final <- shp_stands_interface_final[
    !st_is_empty(shp_stands_interface_final),
  ]
  shp_stands_interface_final <- st_collection_extract(
    shp_stands_interface_final,
    "POLYGON"
  )
  
  # guardar valor para comparar na próxima iteração
  n_small_prev <- n_small_now
}

# remover ID temporário
if ("tmp_id" %in% names(shp_stands_interface_final)) {
  shp_stands_interface_final$tmp_id <- NULL
}

if ("AREA_ha_tmp" %in% names(shp_stands_interface_final)) {
  shp_stands_interface_final$AREA_ha_tmp <- NULL
}

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
sum(shp_stands_interface_final$AREA_ha < threshold_ha, na.rm = TRUE)

## =========================================================
## I) GUARDAR
## =========================================================

st_write(
  shp_stands_interface_final,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/teste_R/dissolve_COS23_local1/shp_stands_interface_final.shp",
  delete_layer = TRUE
)
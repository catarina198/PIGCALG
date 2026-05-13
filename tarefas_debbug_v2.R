library(sf)
library(dplyr)

## # - CONSTRUIR SHAPEFILE DOS VALORES CHAVES ####


##VALOR NATURAL##
library(sf)
library(dplyr)
library(stringr)

##CONSTRUIR CAMPO DE ORIENTACAO DE GESTAO NA SHAPE DOS HABITATS

## NOVA CLASSIFICACAO DE ORIENTACOES DE GESTAO
## 1 - Baixa perigosidade
## 2 - Elevada perigosidade compatível com gestão de combustível
## 3 - Elevada perigosidade não compatível com gestão de combustível

library(sf)
library(stringr)
library(dplyr)

# Ler shapefile
habitats <- st_read(
  "C:/projetos/PIGCALG/03_dados_base/habitats/habitats_zec_UTM29_alg_v2.shp"
)

# Lista de orientações de gestão escrita diretamente no código
orientacao_gestao <- data.frame(
  Codigo = c(
    # Orientacao 1
    "1110", "1140", "1150", "1160", "1210", "1310", "1320", "1420",
    "2110", "2120", "3110", "3140", "3150", "3260", "3280", "3290",
    "8130", "8210", "8240", "8310",
    "1130pt1", "1140pt1", "1150pt2", "1310pt1", "1310pt2",
    "1420pt1", "1420pt2", "1420pt3", "1420pt1/2/3",
    "1420pt4", "1420pt5", "1420pt4/5", "1420pt6", "1420pt7",
    "2130pt1", "2190pt2", "2190pt3", "2230pt1",
    "3140pt1", "3140pt2", "7140pt3", "8130pt3", "8220pt1",
    
    # Orientacao 2
    "1240", "1510", "3170",
    "1310pt4", "8220pt3", "91E0pt1", "91E0pt3",
    "92A0pt2", "92A0pt3", "92A0pt5",
    
    # Orientacao 3
    "1410", "1430", "2260", "2270", "2330", "5410", "6110", "6210",
    "6310", "6420", "9240", "9330", "9340", "9560",
    "1310pt3", "2150pt1", "2230pt2", "2250pt1", "2250pt2",
    "4020pt2", "4030pt3", "4030pt5",
    "5140pt1", "5140pt2", "5210pt2", "5210pt3", "5230pt5",
    "5330pt1", "5330pt2", "5330pt3", "5330pt4",
    "5330pt5", "5330pt6", "5330pt7",
    "6220pt1", "6220pt2", "6220pt3", "6220pt4", "6220pt5",
    "6410pt2", "6430pt2", "8230pt3", "9260pt1",
    "92B0", "92D0", "92D0pt1", "92D0pt2", "92D0pt3",
    "9320pt2", "9340pt1", "9340pt2", "9560pt2"
  ),
  
  `Orientacao de Gestao` = c(
    rep(1, 43),
    rep(2, 10),
    rep(3, 52)
  ),
  
  stringsAsFactors = FALSE,
  check.names = FALSE
)

# Função para limpar texto
limpar_texto <- function(x) {
  x <- as.character(x)
  x <- str_replace_all(x, "[\r\n]+", " ")
  x <- str_replace_all(x, "\\s+", " ")
  x <- str_trim(x)
  x <- str_replace_all(x, "Pt", "pt")
  x
}

# Função para expandir códigos como 5330pt1/2/3
expandir_codigo <- function(codigo) {
  codigo <- limpar_texto(codigo)
  
  if (str_detect(codigo, "^[A-Za-z0-9]+pt[0-9]+(/[0-9]+)+$")) {
    prefixo <- str_extract(codigo, "^[A-Za-z0-9]+pt")
    parte_final <- str_remove(codigo, "^[A-Za-z0-9]+pt")
    numeros <- unlist(str_split(parte_final, "/"))
    return(paste0(prefixo, numeros))
  }
  
  codigo
}

# Limpar códigos da lista
orientacao_gestao$Codigo <- limpar_texto(orientacao_gestao$Codigo)

# Criar campo numérico de orientação
orientacao_gestao$Ori_num <- as.integer(orientacao_gestao$`Orientacao de Gestao`)

# Verificar se existem códigos duplicados
duplicados <- orientacao_gestao |>
  count(Codigo) |>
  filter(n > 1)

if (nrow(duplicados) > 0) {
  print(duplicados)
  stop("Existem códigos duplicados na tabela orientacao_gestao.")
}

# Criar mapa: Codigo -> Orientacao
mapa_codigos <- orientacao_gestao$Ori_num
names(mapa_codigos) <- orientacao_gestao$Codigo

# Função para atribuir orientação a cada registo da shapefile
atribuir_orientacao <- function(x) {
  if (is.na(x) || str_trim(x) == "") return(NA_integer_)
  
  x <- limpar_texto(x)
  
  codigos <- unlist(str_split(x, "\\+"))
  codigos <- str_trim(codigos)
  codigos <- codigos[codigos != ""]
  
  codigos_expandidos <- unlist(lapply(codigos, expandir_codigo))
  codigos_expandidos <- limpar_texto(codigos_expandidos)
  
  valores <- mapa_codigos[codigos_expandidos]
  
  if (any(is.na(valores))) return(NA_integer_)
  if (any(valores == 3)) return(3)
  if (any(valores == 2)) return(2)
  if (all(valores == 1)) return(1)
  
  NA_integer_
}

# Criar ou atualizar o campo Ori_Gestao
habitats$Ori_Gestao <- sapply(habitats$habitats, atribuir_orientacao)

# Identificar linhas onde não foi possível atribuir orientação
linhas_na <- which(is.na(habitats$Ori_Gestao))

linhas_com_na <- data.frame(
  linha = linhas_na,
  habitats = habitats$habitats[linhas_na]
)

print(linhas_com_na)

# Contagens por classe
cat("Classe 1:", sum(habitats$Ori_Gestao == 1, na.rm = TRUE), "\n")
cat("Classe 2:", sum(habitats$Ori_Gestao == 2, na.rm = TRUE), "\n")
cat("Classe 3:", sum(habitats$Ori_Gestao == 3, na.rm = TRUE), "\n")
cat("Sem classificação:", sum(is.na(habitats$Ori_Gestao)), "\n")

# Área por classe
area_ori_gestao <- habitats |>
  st_drop_geometry() |>
  group_by(Ori_Gestao) |>
  summarise(area_ha = sum(area_ha, na.rm = TRUE), .groups = "drop") |>
  mutate(percentagem = 100 * area_ha / sum(area_ha, na.rm = TRUE))

print(area_ori_gestao)

# Gravar shapefile
# ATENÇÃO: isto substitui a shapefile existente
st_write(
  habitats,
  "C:/projetos/PIGCALG/03_dados_base/habitats/habitats_zec_UTM29_alg_v2.shp",
  delete_layer = TRUE
)


## JUNTAR HABITATS, RNAP, MATAS NACIONAIS E LOCAIS DE LOULÉ ####

library(sf)
library(dplyr)
library(stringr)

habitats <- st_read("C:/projetos/PIGCALG/03_dados_base/habitats/habitats_zec_UTM29_alg_v2.shp")
rnap <- st_read("C:/projetos/PIGCALG/06_analises/areas_proteger/valor_natural/rnap_UTM29n_alg.shp")
matas <- st_read("C:/projetos/PIGCALG/06_analises/areas_proteger/valor_natural/matas_nacionais_UTM29n_alg.shp")
nave_barao <- st_read("C:/projetos/PIGCALG/03_dados_base/areas_protegidas/Nave_do_Barao/NaveBarao.shp")
gruta <- st_read("C:/projetos/PIGCALG/03_dados_base/areas_protegidas/Gruta_de_Vale_Telheiro/GrutaValeTelheiro.shp")

# garantir o mesmo CRS
nave_barao <- st_transform(nave_barao, st_crs(habitats))
gruta <- st_transform(gruta, st_crs(habitats))

# remover Z da gruta
gruta <- st_zm(gruta)

# remover o campo area_ha, se existir
habitats <- habitats |> select(-any_of("area_ha"))
rnap <- rnap |> select(-any_of("area_ha"))
matas <- matas |> select(-any_of("area_ha"))
nave_barao <- nave_barao |> select(-any_of("area_ha"))
gruta <- gruta |> select(-any_of("area_ha"))

# juntar mantendo todos os restantes campos
areas_naturais <- bind_rows(
  habitats,
  rnap,
  matas,
  nave_barao,
  gruta
)

# garantir apenas polígonos e converter tudo para MULTIPOLYGON
areas_naturais <- areas_naturais %>%
  filter(st_geometry_type(.) %in% c("POLYGON", "MULTIPOLYGON")) %>%
  st_cast("MULTIPOLYGON")

# calcular/recalcular área em hectares no campo Area_ha
areas_naturais$Area_ha <- as.numeric(st_area(areas_naturais)) / 10000

# guardar shapefile
st_write(
  areas_naturais,
  "C:/projetos/PIGCALG/06_analises/areas_proteger/valor_natural_v2/areas_valor_natural.shp",
  delete_layer = TRUE,
  layer_options = "ENCODING=UTF-8"
)

## CRIAR MÁSCARA COM HABITATS NÃO SUSCETÍVEIS ####

#identificar se existem combinacoes de codigos não suscetiveis

# separar todas as combinações em códigos individuais
codigos <- unlist(strsplit(habitats$habitats, "\\s*\\+\\s*"))

# limpar espaços e normalizar maiúsculas/minúsculas
codigos <- tolower(trimws(codigos))

# ficar só com códigos que têm "/"
codigos_com_barra <- unique(codigos[grepl("/", codigos)])

codigos_com_barra



library(sf)
library(dplyr)
library(stringr)

# Lista de códigos NÃO suscetíveis
codigos_nao_susc <- c(
  "1110","1130pt1","1140","1140pt1","1150","1150pt2","1160",
  "1210",
  "1310","1310pt1","1310pt2","1320",
  "1420","1420pt1","1420pt2", "1420pt3","1420pt1/2/3","1420pt4","1420pt5","1420pt4/5", "1420pt6","1420pt7",
  "2110","2120","2130pt1","2190pt2","2190pt3",
  "2230pt1",
  "3110","3140","3140pt1","3140pt2","3150",
  "3260","3280","3290",
  "7140pt3",
  "8130","8130pt3",
  "8210","8220pt1","8240",
  "8310"
)

# Função: TRUE se todos os códigos do campo habitats forem não suscetíveis
apenas_nao_susc <- function(hab_string) {
  
  hab_string <- str_replace_all(hab_string, "\n", "")
  codigos <- str_split(hab_string, "\\s*\\+\\s*")[[1]]
  codigos <- str_trim(codigos)
  
  all(codigos %in% codigos_nao_susc)
}

# criar shapefile só com habitats não suscetíveis
# remover area_ha e Area_ha antigos, se existirem
habitats_nao_susc <- habitats %>%
  filter(sapply(.data$habitats, apenas_nao_susc)) %>%
  select(-any_of(c("area_ha", "Area_ha")))

# garantir apenas polígonos e MULTIPOLYGON
habitats_nao_susc <- habitats_nao_susc %>%
  filter(st_geometry_type(.) %in% c("POLYGON", "MULTIPOLYGON")) %>%
  st_cast("MULTIPOLYGON")

# calcular/recalcular área em hectares no campo Area_ha
habitats_nao_susc$Area_ha <- as.numeric(st_area(habitats_nao_susc)) / 10000

# verificar número de polígonos
nrow(habitats_nao_susc)

# verificar TRUE/FALSE
table(sapply(habitats$habitats, apenas_nao_susc))

# área total dos habitats não suscetíveis
total_area_habitats_nao_susc <- sum(habitats_nao_susc$Area_ha, na.rm = TRUE)
print(total_area_habitats_nao_susc)

# gravar shapefile
st_write(
  habitats_nao_susc,
  "C:/projetos/PIGCALG/06_analises/areas_proteger/valor_natural_v2/habitats_nao_suscetivel.shp",
  delete_layer = TRUE,
  layer_options = "ENCODING=UTF-8"
)


## CLASSIFICAR HABITATS: 0 = NÃO SUSCETÍVEL; 1 = SUSCETÍVEL ####

habitats_classificado <- habitats %>%
  mutate(
    habit_susc = ifelse(sapply(.data$habitats, apenas_nao_susc), 0, 1)
  )

# verificar classificação
table(habitats_classificado$habit_susc)

# gravar shapefile classificado
st_write(
  habitats_classificado,
  "C:/projetos/PIGCALG/06_analises/areas_proteger/valor_natural_v2/habitats_classificado.shp",
  delete_layer = TRUE
)


##ELIMINAR DO MERGE DAS AREAS DE VALOR NATURAL OS HABITATS NAO SUSCETIVEIS####

habitats_nao_susc <- st_read("C:/projetos/PIGCALG/06_analises/areas_proteger/valor_natural_v2/habitats_nao_suscetivel.shp")
areas_natural <- st_read("C:/projetos/PIGCALG/06_analises/areas_proteger/valor_natural_v2/areas_valor_natural.shp")


#Garantir geometrias válidas
areas_natural <- st_make_valid(areas_natural)
habitats_nao_susc <- st_make_valid(habitats_nao_susc)

#Dissolver a máscara (IMPORTANTE para evitar erros)
habitats_mask <- st_union(habitats_nao_susc)

#ERASE: remover tudo o que intersecta a máscara
areas_natural_filtrado <- st_difference(
  areas_natural,
  habitats_mask
)

#Remover geometrias vazias
areas_natural_filtrado <- areas_natural_filtrado[!st_is_empty(areas_natural_filtrado), ]

#Garantir apenas polígonos
areas_natural_filtrado <- areas_natural_filtrado %>%
  filter(st_geometry_type(.) %in% c("POLYGON", "MULTIPOLYGON")) %>%
  st_cast("MULTIPOLYGON")

#salvar
st_write(areas_natural_filtrado, "C:/projetos/PIGCALG/06_analises/areas_proteger/valor_natural_v2/areas_valor_natural_s_habitats_n_susc.shp", delete_layer = TRUE)

names(areas_natural_filtrado)

#calcular area hectares
areas_natural_filtrado$area_ha <- as.numeric(st_area(areas_natural_filtrado)) / 10000

#Somar a coluna area_ha para obter a área total
total_area <- sum(areas_natural_filtrado$area_ha, na.rm = TRUE)
print(total_area)


##CRAIR UMA MASCARA COM COS 2023 NAO SUSCETIVEL####
COS2023_alg <- st_read("C:/projetos/PIGCALG/03_dados_base/COS/COS_2023/COS2023_alg.shp")
names(COS2023_alg)
as.data.frame(unique(COS2023_alg$COS23_n4_C) , unique(COS2023_alg$COS23_n4_L))

##separar codigos
# garantir que é character
COS2023_alg$COS23_n4_C <- as.character(COS2023_alg$COS23_n4_C)

# separar os códigos
partes <- strsplit(COS2023_alg$COS23_n4_C, "\\.")

# criar novas colunas
COS2023_alg$COS23_n1_C <- sapply(partes, `[`, 1)

COS2023_alg$COS23_n2_C <- sapply(partes, function(x) {
  paste(x[1:2], collapse = ".")
})

COS2023_alg$COS23_n3_C <- sapply(partes, function(x) {
  paste(x[1:3], collapse = ".")
})

#salvar
st_write(COS2023_alg, "C:/projetos/PIGCALG/03_dados_base/COS/COS_2023/COS2023_alg.shp", delete_layer = TRUE)

#CLASSIFICAR COS23 COMO SUSCETIVEL OU NAO SUSCETIVEL

COS2023_alg <- st_read("C:/projetos/PIGCALG/03_dados_base/COS/COS_2023/COS2023_alg.shp")

library(sf)
library(dplyr)

# CLASSIFICAR COS23 COMO SUSCETÍVEL OU NÃO SUSCETÍVEL ####

COS2023_alg <- st_read("C:/projetos/PIGCALG/03_dados_base/COS/COS_2023/COS2023_alg.shp")

# lista de códigos NÃO suscetíveis
codigos_nao_susc <- c(
  "1.1.1.1", "1.1.1.2", "1.1.2.1", "1.1.2.2",
  "1.2.1.1", "1.2.1.2", "1.2.2.1",
  "1.3.1.1", "1.3.2.1", "1.3.2.2", "1.3.2.3", "1.3.2.4",
  "1.3.3.1", "1.3.4.1",
  "1.4.1.2", "1.4.2.1", "1.4.3.1", "1.4.4.1",
  "1.4.4.2", "1.4.5.1", "1.4.5.2", "1.4.6.1",
  "1.5.1.1", "1.5.1.2", "1.5.2.1", "1.5.2.2",
  "1.5.2.3", "1.5.3.1", "1.5.3.2", "1.5.4.1",
  "1.6.1.2",
  "1.7.1.1", "1.7.1.2",
  "1.8.1.1",
  "2.1.1.1", "2.1.1.2",
  "2.2.1.1",
  "2.3.1.1", "2.3.1.2",
  "2.4.1.1",
  "8.1.1.1", "8.1.2.2",
  "9.1.1.1", "9.1.2.1", "9.1.2.2", "9.1.2.3", "9.1.2.4"
)

# criar campo binário:
# 0 = não suscetível
# 1 = suscetível
COS2023_alg <- COS2023_alg %>%
  mutate(
    COS_susc = ifelse(COS23_n4_C %in% codigos_nao_susc, 0, 1)
  )

# verificar resultados
table(COS2023_alg$COS_susc)

# guardar shapefile
st_write(
  COS2023_alg,
  "C:/projetos/PIGCALG/06_analises/areas_proteger/valor_natural_v2/COS2023_alg_classificado.shp",
  delete_layer = TRUE,
  layer_options = "ENCODING=UTF-8"
)


##criar mascara nao suscetivel da cos

library(sf)
library(dplyr)

# Ler a shape COS classificada
cos <- st_read("C:/projetos/PIGCALG/06_analises/areas_proteger/valor_natural_v2/COS2023_alg_classificado.shp")

# Criar a máscara: apenas COS não suscetível
cos_mascara <- cos %>%
  filter(COS_susc == 0) %>%
  st_make_valid() %>%
  filter(st_geometry_type(.) %in% c("POLYGON", "MULTIPOLYGON")) %>%
  st_cast("MULTIPOLYGON")

# Ver quantos polígonos ficaram
nrow(cos_mascara)

names(cos_mascara)

#calcular area hectares
cos_mascara$AREA_ha <- as.numeric(st_area(cos_mascara)) / 10000

#Somar a coluna area_ha para obter a área total
total_area <- sum(cos_mascara$AREA_ha, na.rm = TRUE)
print(total_area)

# Gravar a máscara
st_write(
  cos_mascara,
  "C:/projetos/PIGCALG/06_analises/areas_proteger/valor_natural_v2/COS_n_suscetivel.shp",
  delete_layer = TRUE,
  layer_options = "ENCODING=UTF-8"
)


library(sf)
library(dplyr)

## INTERSETAR COS NÃO SUSCETÍVEL COM ÁREAS NATURAIS ####
## JÁ SEM HABITATS SUSCETÍVEIS ####

cos_n_susc <- st_read("C:/projetos/PIGCALG/06_analises/areas_proteger/valor_natural_v2/COS_n_suscetivel.shp")

areas_natural <- st_read("C:/projetos/PIGCALG/06_analises/areas_proteger/valor_natural_v2/areas_valor_natural_s_habitats_n_susc.shp")

# Garantir geometrias válidas
areas_natural <- st_make_valid(areas_natural)
cos_n_susc <- st_make_valid(cos_n_susc)

# Remover o campo Area_ha das áreas naturais, se existir
# para evitar conflito com AREA_ha da COS
areas_natural <- areas_natural %>%
  select(-any_of(c("Area_ha", "area_ha")))

# Fazer interseção
intersecao <- st_intersection(
  areas_natural,
  cos_n_susc
)

nrow(intersecao)

# Remover geometrias vazias
intersecao <- intersecao[!st_is_empty(intersecao), ]

# Manter apenas polígonos
intersecao <- intersecao %>%
  filter(st_geometry_type(.) %in% c("POLYGON", "MULTIPOLYGON")) %>%
  st_cast("MULTIPOLYGON")

nrow(intersecao)

# Remover AREA_ha antigo e recalcular área da interseção
intersecao <- intersecao %>%
  select(-any_of(c("Area_ha", "area_ha", "AREA_ha")))

intersecao$AREA_ha <- as.numeric(st_area(intersecao)) / 10000

# Gravar resultado final
st_write(
  intersecao,
  "C:/projetos/PIGCALG/06_analises/areas_proteger/valor_natural_v2/areas_valor_natural_vs_cos_n_susc.shp",
  delete_layer = TRUE,
  layer_options = "ENCODING=UTF-8"
)


library(sf)
library(dplyr)

## CRIAR SHAPEFILE FINAL DE ÁREAS DE ELEVADO VALOR NATURAL ####
## sem habitats não suscetíveis
## sem COS23 não suscetível

areas_natural <- st_read(
  "C:/projetos/PIGCALG/06_analises/areas_proteger/valor_natural_v2/areas_valor_natural_s_habitats_n_susc.shp"
)

areas_natural_com_cos_n_susc <- st_read(
  "C:/projetos/PIGCALG/06_analises/areas_proteger/valor_natural_v2/areas_valor_natural_vs_cos_n_susc.shp"
)

# Garantir geometrias válidas
areas_natural <- st_make_valid(areas_natural)
areas_natural_com_cos_n_susc <- st_make_valid(areas_natural_com_cos_n_susc)

# Dissolver a máscara COS não suscetível
cos_mask <- st_union(areas_natural_com_cos_n_susc)

# ERASE: remover da área natural tudo o que está na máscara
areas_natural_filtrado <- st_difference(
  areas_natural,
  cos_mask
)

# Remover geometrias vazias
areas_natural_filtrado <- areas_natural_filtrado[!st_is_empty(areas_natural_filtrado), ]

# Manter apenas polígonos e separar multipart em singlepart
areas_natural_filtrado <- areas_natural_filtrado %>%
  filter(st_geometry_type(.) %in% c("POLYGON", "MULTIPOLYGON")) %>%
  st_cast("POLYGON")

# Remover campos antigos de área
areas_natural_filtrado <- areas_natural_filtrado %>%
  select(-any_of(c("area_ha", "Area_ha", "AREA_ha")))

# Recalcular área em hectares por polígono singlepart
areas_natural_filtrado$AREA_ha <- as.numeric(st_area(areas_natural_filtrado)) / 10000

# Eliminar polígonos com área <= 0.001 ha
areas_natural_filtrado <- areas_natural_filtrado[
  areas_natural_filtrado$AREA_ha > 0.001,
]

# Área total final
total_area_final <- sum(areas_natural_filtrado$AREA_ha, na.rm = TRUE)
print(total_area_final)

# Salvar shapefile final
st_write(
  areas_natural_filtrado,
  "C:/projetos/PIGCALG/06_analises/areas_proteger/valor_natural_v2/areas_valor_natural_final.shp",
  delete_layer = TRUE,
  layer_options = "ENCODING=UTF-8"
)



## # - UNIDADES DE TRATAMENTO ####

##ORGANIZAÇÃO DOS DADOS BASE NA SHAPEFILE ORIGINAL DAS UNIDADES DE TRATAMENTO

##PASSAR A INFO DA COS18 PARA CADA STAND###
library(sf)
library(dplyr)



# shape1: sem classificação (ex: stands)
# shape2: com classificação (ex: COS18)
shape1 <- st_read("C:/projetos/PIGCALG/03_dados_base/unidades_tratamento/COS_2023_vs2/stands_ALG_cos23_final_vs2.shp")
shape2 <- st_read("C:/projetos/PIGCALG/03_dados_base/COS/COS_2023/COS2023_alg.shp")

# criar um identificador único para cada stand
shape1 <- shape1 %>%
  mutate(stand_FID = row_number())

# fazer interseção espacial
intersec <- st_intersection(shape1 %>% mutate(stand_FID = row_number()), 
                            shape2 %>% dplyr::select(COS23_n4_C))

# calcular a área de cada polígono de interseção
intersec$area <- st_area(intersec)


# determinar qual a classe COS dominante em cada stand
dominante <- intersec %>%
  group_by(stand_FID, COS23_n4_C) %>%
  summarise(area = sum(area), .groups = "drop") %>%
  group_by(stand_FID) %>%
  slice_max(area, n = 1) %>%
  ungroup()

# copiar a classe dominante para a shape original dos stands
shape1$COS23_n4_C <- dominante$COS23_n4_C[match(1:nrow(shape1), dominante$stand_FID)]

st_write(shape1, "C:/projetos/PIGCALG/06_analises/unidades_tratamento/stands_alg_COS.shp")


library(raster)
##Declive em percentagem
##CALCULAR O PERCENTIL 90 DO DECLIVE (%) EM CADA STAND###

##UNIDADES DE TRATAMENTO
stands <- st_read("C:/projetos/PIGCALG/06_analises/unidades_tratamento/stands_alg_COS.shp")

##AREA ARDIDA > 500HA
declive <- raster("C:/projetos/PIGCALG/03_dados_base/landscape/slope_percent_alg.tif")

#extrair valores dentro de cada poligono
val_dec <- exactextractr::exact_extract(declive, stands) #extria apelas os valores de todos os pixeis que estao dentro da unidade de tratamento

#criar tabela com todas as data.frames 
val_dec_df <- bind_rows(val_dec, .id = "stand_FID")
val_dec_df$stand_FID <- as.integer(val_dec_df$stand_FID)

#MEDIA ponderada dos valores dentro de cada poligono
media_dec <- data.frame(val_dec_df %>%
                          group_by(stand_FID) %>%
                          summarise(dec_p90=quantile(value,0.9),
                                    dec_p90_wg=quantile(value * coverage_fraction,0.9)))

#juntar soma na tabela da stands
stands$stand_FID <- seq_len(nrow(stands)) #cria coluna em "stands"
stands <- left_join(stands, media_dec, by = "stand_FID")

teste <- subset(val_dec_df,stand_FID==96920)
quantile(teste$value, 0.9)
quantile(teste$value*teste$coverage_fraction, 0.9)

#salvar
st_write(stands, "C:/projetos/PIGCALG/06_analises/unidades_tratamento/stands_alg_COS_DECL.shp")



unique(stands$COS23_n4_L)


##CORRIGIR A SHAPE DAS STANDS EM AREAS NAO ARDIVEIS###
stands <- st_read("C:/projetos/PIGCALG/06_analises/unidades_tratamento/stands_alg_COS_DECL.shp")
unique(stands$COS23_n4_L)

##LISTA DE OCUPACOES DO SOLO EXCLUIDAS DOS PROJETOS - EXCLUDE

#atribuir valor de 1 as classes que nao ardem, o resto == 0
#criar lista 
categorias_exclude <- c(
  
  # TERRITÓRIO ARTIFICIALIZADO
  "Rede rodoviária",
  "Rede ferroviária",
  
  # AGRICULTURA
  "Culturas temporárias de sequeiro e regadio",
  "Arrozais",
  "Vinhas",
  "Pomares",
  "Olivais",
  "Culturas temporárias e/ou pastagens melhoradas associadas a vinha",
  "Culturas temporárias e/ou pastagens melhoradas associadas a pomar",
  "Culturas temporárias e/ou pastagens melhoradas associadas a olival",
  "Mosaicos culturais e parcelares complexos",
  "Agricultura com espaços naturais e seminaturais",
  "Agricultura e viveiros protegidos",
  
  # ZONAS HÚMIDAS
  "Pauis e turfeiras",
  "Sapais",
  "Salinas",
  "Zonas entremarés",
  
  # MASSAS DE ÁGUA
  "Cursos de água naturais",
  "Lagos e lagoas interiores artificiais",
  "Lagos e lagoas interiores naturais",
  "Albufeiras de barragens",
  "Albufeiras de represas ou de açudes",
  "Charcas",
  "Aquicultura",
  "Lagoas costeiras",
  "Desembocaduras fluviais",
  "Oceano"
)

# Atualizar a coluna "exclude"
stands <- stands %>%
  mutate(exclude = if_else(COS23_n4_L %in% categorias_exclude, 1, 0))


##LISTA DE OCUPACOES DO SOLO QUE NAO SAO GERIVEIS - GERIVEL
#atribuir valor de 0 as classes que nao podem ser geridas, o resto == 1


# Lista de categorias que devem ter gerivel = 0
categorias_n_gerivel <- c(
  
  # TERRITÓRIO ARTIFICIALIZADO
  "Áreas edificadas residenciais contínuas predominantemente verticais",
  "Áreas edificadas residenciais contínuas predominantemente horizontais",
  "Áreas edificadas residenciais descontínuas",
  "Áreas edificadas residenciais descontínuas esparsas",
  "Indústria e logística",
  "Comércio e serviços",
  "Instalações agrícolas e pecuárias",
  "Equipamentos desportivos",
  "Equipamentos de lazer",
  "Campos de golfe",
  "Parques de campismo e de caravanismo",
  "Cemitérios",
  "Outros equipamentos e instalações turísticas",
  "Infraestruturas de produção de energia solar",
  "Infraestruturas de produção de energia de fonte fóssil",
  "Subestações e postos de transformação de energia",
  "Infraestruturas de captação e tratamento de águas para consumo",
  "Infraestruturas de drenagem e tratamento de águas residuais",
  "Outras infraestruturas de resíduos",
  "Aterros",
  "Marinas e docas pesca",
  "Terminais portuários de mar e de rio",
  "Áreas de estacionamento",
  "Pedreiras",
  "Áreas em construção",
  "Equipamentos culturais",
  "Espaços verdes",
  "Estaleiros navais e docas secas",
  "Aeroportos",
  "Aeródromos",
  "Vazios sem construção",
  "Outras infraestruturas",
  "Rede rodoviária",
  "Rede ferroviária",
  
  # AGRICULTURA
  "Culturas temporárias de sequeiro e regadio",
  "Arrozais",
  "Vinhas",
  "Pomares",
  "Olivais",
  "Culturas temporárias e/ou pastagens melhoradas associadas a vinha",
  "Culturas temporárias e/ou pastagens melhoradas associadas a pomar",
  "Culturas temporárias e/ou pastagens melhoradas associadas a olival",
  "Mosaicos culturais e parcelares complexos",
  "Agricultura com espaços naturais e seminaturais",
  "Agricultura e viveiros protegidos",
  
  # SUPERFÍCIES AGROSSILVÍCOLAS
  "Superfícies agrossilvícolas de sobreiro",
  "Superfícies agrossilvícolas de azinheira",
  "Superfícies agrossilvícolas de pinheiro manso",
  "Superfícies agrossilvícolas de outras folhosas",
  
  # SUPERFÍCIES SILVOPASTORIS
  "Superfícies silvopastoris de sobreiro",
  "Superfícies silvopastoris de azinheira",
  "Superfícies silvopastoris de outras folhosas",
  "Superfícies silvopastoris de pinheiro manso",
  "Superfícies silvopastoris de outras resinosas",
  
  # ZONAS HÚMIDAS
  "Pauis e turfeiras",
  "Sapais",
  "Salinas",
  "Zonas entremarés",
  
  # MASSAS DE ÁGUA
  "Cursos de água naturais",
  "Lagos e lagoas interiores artificiais",
  "Lagos e lagoas interiores naturais",
  "Albufeiras de barragens",
  "Albufeiras de represas ou de açudes",
  "Charcas",
  "Aquicultura",
  "Lagoas costeiras",
  "Desembocaduras fluviais",
  "Oceano"
)
# Atualizar a coluna "gerivel"
stands <- stands %>%
  mutate(gerivel = if_else(COS23_n4_L %in% categorias_n_gerivel, 0, 1))

##LISTA DE OCUPACOES DO SOLO SEM VALOR DE EXPOSICAO

#definr as classes de ocupacao de solo que passarao a ter o valor de exposicao = 0
categorias_sem_expo <- c(
  
  # TERRITÓRIO ARTIFICIALIZADO
  "Áreas edificadas residenciais contínuas predominantemente verticais",
  "Áreas edificadas residenciais contínuas predominantemente horizontais",
  "Áreas edificadas residenciais descontínuas",
  "Áreas edificadas residenciais descontínuas esparsas",
  "Indústria e logística",
  "Comércio e serviços",
  "Instalações agrícolas e pecuárias",
  "Equipamentos desportivos",
  "Equipamentos de lazer",
  "Campos de golfe",
  "Parques de campismo e de caravanismo",
  "Cemitérios",
  "Outros equipamentos e instalações turísticas",
  "Infraestruturas de produção de energia solar",
  "Infraestruturas de produção de energia de fonte fóssil",
  "Subestações e postos de transformação de energia",
  "Infraestruturas de captação e tratamento de águas para consumo",
  "Infraestruturas de drenagem e tratamento de águas residuais",
  "Outras infraestruturas de resíduos",
  "Aterros",
  "Marinas e docas pesca",
  "Terminais portuários de mar e de rio",
  "Áreas de estacionamento",
  "Pedreiras",
  "Áreas em construção",
  "Equipamentos culturais",
  "Espaços verdes",
  "Estaleiros navais e docas secas",
  "Aeroportos",
  "Aeródromos",
  "Vazios sem construção",
  "Outras infraestruturas",
  "Rede rodoviária",
  "Rede ferroviária",
  
  # ZONAS HÚMIDAS
  "Pauis e turfeiras",
  "Sapais",
  "Salinas",
  "Zonas entremarés",
  
  # MASSAS DE ÁGUA
  "Cursos de água naturais",
  "Lagos e lagoas interiores artificiais",
  "Lagos e lagoas interiores naturais",
  "Albufeiras de barragens",
  "Albufeiras de represas ou de açudes",
  "Charcas",
  "Aquicultura",
  "Lagoas costeiras",
  "Desembocaduras fluviais",
  "Oceano"
)


#atualizar o valor da expo
stands <- stands %>%
  mutate(exposicao = if_else(COS23_n4_L %in% categorias_sem_expo, 0, 1))



# Renomear stand_FID para Stand_ID, se existir
if ("stand_FID" %in% names(stands)) {
  stands <- stands |>
    rename(Stand_ID = stand_FID)
}

# Criar/atualizar Stand_ID com ID único de 1 até n polígonos
stands <- stands |>
  mutate(Stand_ID = row_number())

# Confirmar resultado
names(stands)
summary(stands$Stand_ID)
anyDuplicated(stands$Stand_ID)


st_write(
  stands,
  "C:/projetos/PIGCALG/06_analises/unidades_tratamento/stands_alg_v3_base.shp",
  delete_layer = TRUE
)




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



## ======================================================================================
## UNIDADES DE TRATAMENTO COM HABITATS QUE ENTREM EM CONFLITO COM A GESTAO DE COMBUSTIVEL
## ======================================================================================

library(sf)
library(dplyr)
library(tidyr)

# ============================================================
# 1) LER SHAPEFILES
# ============================================================

shp_habitats <- st_read(
  "C:/projetos/PIGCALG/03_dados_base/habitats/habitats_zec_UTM29_alg_v2.shp"
)

shp_stands_interface_final <- st_read(
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs_Algarve/Analise/V4_20260430/UTratamento/No_Gaps/stands_alg_interface_final.shp"
)


# ============================================================
# 2) GUARDAR CAMPOS ORIGINAIS DOS STANDS
#    Exclui area_inc, perc_inc e habit_inc se já existirem
# ============================================================

campos_originais_stands <- names(shp_stands_interface_final)

campos_originais_stands <- setdiff(
  campos_originais_stands,
  c("area_inc", "perc_inc", "habit_inc")
)


# ============================================================
# 3) VERIFICAÇÕES BÁSICAS
# ============================================================

stopifnot("Ori_Gestao" %in% names(shp_habitats))
stopifnot("area_ha" %in% names(shp_habitats))
stopifnot("Stand_IDv2" %in% names(shp_stands_interface_final))
stopifnot("AREA_ha" %in% names(shp_stands_interface_final))


# ============================================================
# 4) GARANTIR MESMO CRS
# ============================================================

if (st_crs(shp_habitats) != st_crs(shp_stands_interface_final)) {
  shp_habitats <- st_transform(
    shp_habitats,
    st_crs(shp_stands_interface_final)
  )
}


# ============================================================
# 5) VALIDAR GEOMETRIAS
# ============================================================

shp_habitats <- st_make_valid(shp_habitats)
shp_stands_interface_final <- st_make_valid(shp_stands_interface_final)


# ============================================================
# 6) REMOVER CAMPOS ANTIGOS DOS STANDS SE JÁ EXISTIREM
# ============================================================

campos_remover_stands <- c("area_inc", "perc_inc", "habit_inc")

campos_para_remover_stands <- intersect(
  campos_remover_stands,
  names(shp_stands_interface_final)
)

if (length(campos_para_remover_stands) > 0) {
  shp_stands_interface_final <- shp_stands_interface_final %>%
    select(-all_of(campos_para_remover_stands))
}


# ============================================================
# 7) CRIAR / RECRIAR Habit_ID E GCconflit NOS HABITATS
#    Se já existirem, são sobrescritos
#    Ori_Gestao = 1       -> 0
#    Ori_Gestao = 2 ou 3  -> 1
# ============================================================

shp_habitats <- shp_habitats %>%
  mutate(
    Habit_ID = row_number(),
    GCconflit = if_else(Ori_Gestao %in% c(2, 3), 1L, 0L)
  )


# ============================================================
# 8) FILTRAR HABITATS COM GCconflit == 1
# ============================================================

hab_gc <- shp_habitats %>%
  filter(GCconflit == 1) %>%
  select(
    Habit_ID,
    habitat_area_ha = area_ha,
    geometry
  )


# ============================================================
# 9) INTERSETAR STANDS COM HABITATS GCconflit == 1
# ============================================================

inter_gc <- st_intersection(
  shp_stands_interface_final %>% select(Stand_IDv2),
  hab_gc
)


# ============================================================
# 10) CALCULAR ÁREA DE CADA INTERSEÇÃO EM HECTARES
# ============================================================

inter_gc <- inter_gc %>%
  mutate(
    area_inter_ha = as.numeric(st_area(geometry)) / 10000
  )


# ============================================================
# 11) RESUMIR POR STAND
#     area_inc  = soma das áreas reais de interseção
#     habit_inc = soma da área total dos habitats intersetados
# ============================================================

resumo_gc <- inter_gc %>%
  st_drop_geometry() %>%
  group_by(Stand_IDv2) %>%
  summarise(
    area_inc = sum(area_inter_ha, na.rm = TRUE),
    habit_inc = sum(
      habitat_area_ha[!duplicated(Habit_ID)],
      na.rm = TRUE
    ),
    .groups = "drop"
  )


# ============================================================
# 12) JUNTAR area_inc, perc_inc E habit_inc AOS STANDS
#     Sem interseção:
#     area_inc  = 0
#     perc_inc  = 0
#     habit_inc = 0
#
#     Se area_inc < 0.001:
#     area_inc  = 0
#     perc_inc  = 0
#     habit_inc = 0
# ============================================================

shp_stands_interface_final <- shp_stands_interface_final %>%
  left_join(resumo_gc, by = "Stand_IDv2") %>%
  mutate(
    area_inc = replace_na(area_inc, 0),
    habit_inc = replace_na(habit_inc, 0)
  ) %>%
  mutate(
    perc_inc = if_else(
      AREA_ha > 0,
      100 * area_inc / AREA_ha,
      0
    )
  ) %>%
  mutate(
    area_inc = if_else(area_inc < 0.001, 0, area_inc),
    perc_inc = if_else(area_inc == 0, 0, perc_inc),
    habit_inc = if_else(area_inc == 0, 0, habit_inc)
  )


# ============================================================
# 13) GARANTIR QUE SÓ FICAM OS CAMPOS ORIGINAIS + NOVOS
# ============================================================

campos_finais_esperados <- c(
  campos_originais_stands,
  "area_inc",
  "perc_inc",
  "habit_inc"
)

shp_stands_interface_final <- shp_stands_interface_final %>%
  select(all_of(campos_finais_esperados))


# ============================================================
# 14) ESCREVER SHAPEFILE DOS HABITATS
#     com Habit_ID e GCconflit atualizados
# ============================================================

st_write(
  shp_habitats,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Inputs_Algarve/Auxiliar/Habitats/habitats_valor_natural.shp",
  delete_layer = TRUE
)


# ============================================================
# 15) REESCREVER SHAPEFILE DOS STANDS
#     com area_inc, perc_inc e habit_inc recriados
# ============================================================

st_write(
  shp_stands_interface_final,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs_Algarve/Analise/V4_20260430/UTratamento/No_Gaps/stands_alg_interface_final.shp",
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






## ======================================================================================
## UNIDADES DE TRATAMENTO COM HABITATS QUE ENTREM EM CONFLITO COM A GESTAO DE COMBUSTIVEL
## ======================================================================================

library(sf)
library(dplyr)
library(tidyr)

# ============================================================
# 1) LER SHAPEFILES
# ============================================================

shp_habitats <- st_read(
  "C:/projetos/PIGCALG/03_dados_base/habitats/habitats_zec_UTM29_alg_v2.shp"
)

shp_stands_interface_final <- st_read(
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs_Algarve/Analise/V4_20260430/UTratamento/No_Gaps/stands_alg_interface_final.shp"
)


# ============================================================
# 2) GUARDAR CAMPOS ORIGINAIS DOS STANDS
# ============================================================

campos_originais_stands <- names(shp_stands_interface_final)

campos_originais_stands <- setdiff(
  campos_originais_stands,
  c("area_inc", "perc_inc", "habit_inc")
)


# ============================================================
# 3) VERIFICAÇÕES BÁSICAS
# ============================================================

stopifnot("Ori_Gestao" %in% names(shp_habitats))
stopifnot("area_ha" %in% names(shp_habitats))
stopifnot("Stand_IDv2" %in% names(shp_stands_interface_final))
stopifnot("AREA_ha" %in% names(shp_stands_interface_final))


# ============================================================
# 4) GARANTIR MESMO CRS
# ============================================================

if (st_crs(shp_habitats) != st_crs(shp_stands_interface_final)) {
  shp_habitats <- st_transform(
    shp_habitats,
    st_crs(shp_stands_interface_final)
  )
}


# ============================================================
# 5) VALIDAR GEOMETRIAS
# ============================================================

shp_habitats <- st_make_valid(shp_habitats)
shp_stands_interface_final <- st_make_valid(shp_stands_interface_final)


# ============================================================
# 6) REMOVER CAMPOS ANTIGOS DOS STANDS SE JÁ EXISTIREM
# ============================================================

campos_remover_stands <- c("area_inc", "perc_inc", "habit_inc")

campos_para_remover_stands <- intersect(
  campos_remover_stands,
  names(shp_stands_interface_final)
)

if (length(campos_para_remover_stands) > 0) {
  shp_stands_interface_final <- shp_stands_interface_final %>%
    select(-all_of(campos_para_remover_stands))
}


# ============================================================
# 7) CRIAR / RECRIAR Habit_ID E GCconflit NOS HABITATS
# ============================================================

shp_habitats <- shp_habitats %>%
  mutate(
    Habit_ID = row_number(),
    GCconflit = if_else(Ori_Gestao %in% c(2, 3), 1L, 0L)
  )


# ============================================================
# 8) FILTRAR HABITATS COM GCconflit == 1
# ============================================================

hab_gc <- shp_habitats %>%
  filter(GCconflit == 1) %>%
  select(
    Habit_ID,
    habitat_area_ha = area_ha,
    geometry
  )


# ============================================================
# 9) INTERSETAR STANDS COM HABITATS GCconflit == 1
# ============================================================

inter_gc <- st_intersection(
  shp_stands_interface_final %>% select(Stand_IDv2),
  hab_gc
)


# ============================================================
# 10) CALCULAR ÁREA DE CADA INTERSEÇÃO EM HECTARES
# ============================================================

inter_gc <- inter_gc %>%
  mutate(
    area_inter_ha = as.numeric(st_area(geometry)) / 10000
  )


# ============================================================
# 11) RESUMIR POR STAND
# ============================================================

resumo_gc <- inter_gc %>%
  st_drop_geometry() %>%
  group_by(Stand_IDv2) %>%
  summarise(
    area_inc = sum(area_inter_ha, na.rm = TRUE),
    habit_inc = sum(
      habitat_area_ha[!duplicated(Habit_ID)],
      na.rm = TRUE
    ),
    .groups = "drop"
  )


# ============================================================
# 12) JUNTAR RESULTADOS AOS STANDS
# ============================================================

shp_stands_interface_final <- shp_stands_interface_final %>%
  left_join(resumo_gc, by = "Stand_IDv2") %>%
  mutate(
    area_inc = replace_na(area_inc, 0),
    habit_inc = replace_na(habit_inc, 0)
  ) %>%
  
  # calcular percentagem inicial
  mutate(
    perc_inc = if_else(
      AREA_ha > 0,
      100 * area_inc / AREA_ha,
      0
    )
  ) %>%
  
  # corrigir pequenas diferenças numéricas entre AREA_ha e area_inc
  mutate(
    area_inc = if_else(
      abs(area_inc - AREA_ha) < 0.0001,
      AREA_ha,
      area_inc
    ),
    
    perc_inc = if_else(
      AREA_ha > 0,
      100 * area_inc / AREA_ha,
      0
    ),
    
    perc_inc = pmin(perc_inc, 100)
  ) %>%
  
  # aplicar regra: interseções muito pequenas passam a zero
  mutate(
    area_inc = if_else(area_inc < 0.001, 0, area_inc),
    perc_inc = if_else(area_inc == 0, 0, perc_inc),
    habit_inc = if_else(area_inc == 0, 0, habit_inc)
  )


# ============================================================
# 13) GARANTIR QUE SÓ FICAM OS CAMPOS ORIGINAIS + NOVOS
# ============================================================

campos_finais_esperados <- c(
  campos_originais_stands,
  "area_inc",
  "perc_inc",
  "habit_inc"
)

shp_stands_interface_final <- shp_stands_interface_final %>%
  select(all_of(campos_finais_esperados))


# ============================================================
# 14) ESCREVER SHAPEFILE DOS HABITATS
# ============================================================

st_write(
  shp_habitats,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Inputs_Algarve/Auxiliar/Habitats/habitats_valor_natural.shp",
  delete_layer = TRUE
)


# ============================================================
# 15) REESCREVER SHAPEFILE DOS STANDS
# ============================================================

st_write(
  shp_stands_interface_final,
  "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs_Algarve/Analise/V4_20260430/UTratamento/No_Gaps/stands_alg_interface_final.shp",
  delete_layer = TRUE
)

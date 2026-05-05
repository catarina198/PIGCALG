## MAIN - bibliotecas, caminhos, parametros e arranque

# BIBLIOTECAS ##
library(sf)
library(raster)
library(dplyr)
library(exactextractr)
library(tidyr)
library(snow)
library(doSNOW)
library(foreach)

## CAMINHOS ####

dir_inputs <- "C:/projetos/PIGCALG/09_resultados_2026_v2/Inputs_Algarve"
dir_auxiliar <-"C:/projetos/PIGCALG/09_resultados_2026_v2/Inputs_Algarve/Auxiliar"
dir_outputs <- "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs_Algarve/Analise"


##INPUTS PRINCIPAIS ##

# Unidades de tratamento
shp_stands_base <- file.path(dir_inputs, "UTratamento/V2_2026/stands_alg_COS23.shp")

# Valores chave - bases
shp_aglomerados_base <- file.path(dir_inputs, "Valores_Chave/V2_2026/aglomerados/aglomerados.shp")
shp_valor_natural_base <- file.path(dir_inputs, "Valores_Chave/V2_2026/valor_natural/valor_natural.shp")
shp_valor_economico_base <- file.path(dir_inputs, "Valores_Chave/V2_2026/valor_economico/valor_economico.shp")

# Probabilidade de arder com comprimento de chama
p_arder2virg5 <- file.path(dir_inputs, "Simulacoes/BAU_FuelAcum_2030/Prob_condicionada/Prob_cond_sup2virg5.tif")
p_arder3virg5 <- file.path(dir_inputs, "Simulacoes/BAU_FuelAcum_2030/Prob_condicionada/Prob_cond_sup3virg5.tif")

# Municipios Algarve
shp_municipios <- file.path(dir_auxiliar, "Municipios/algarve_mun.shp")

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
shp_valor_economico_100_500 <- file.path(dir_inputs, "Valores_Chave/V2_2026/valor_economico/valor_economico_100a500m.shp")
shp_valor_economico_500_1000 <- file.path(dir_inputs, "Valores_Chave/V2_2026/valor_economico/valor_economico_500a1000m.shp")


##OUTPUTS PRINCIPAIS ##
nome_analise <- "V4_20260430"

dir_output_analise <- file.path(dir_outputs, nome_analise)
README <- file.path(dir_output_analise, "README.txt")

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

#aglomerados na interface no gaps (feito à parte no arcgis)
shp_stands_interface_edf_nogaps <- file.path(dir_aglomerados, "shp_stands_interface_edf_nogaps.shp")

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
dir_shapefile <- file.path(dir_exposicao, "Shapefile")

stands_exposicao <- file.path(dir_shapefile, "stands_alg_expo.shp")
stands_exposicao_limpa <- file.path(dir_shapefile, "stands_alg_expo_limpa.shp")

# Gestao interface
dir_gestao_interface <- file.path(dir_output_analise, "Gestao_Interface")

stands_gestao_interface <- file.path(dir_gestao_interface, "stands_alg_gestao_interface.shp")

# Gestao paisagem
dir_gestao_paisagem <- file.path(dir_output_analise, "Gestao_Paisagem")
stands_gestao_lcp <- file.path(dir_gestao_paisagem, "Shapefile/stands_alg_gestao_lcp.shp")



## PARAMETROS ##
# Comentarios livres para registo no README do output
comentarios <- "preencher '-1' em todos os casos que se quer considerar Null. 
Isto porque o formato shapefile no Arcgis não distingue entre NA e 0"

# criar_donuts_valor_chave() -> valor-chave usado para gerar donuts
tipo_valor_chave <- "valor_economico"  # "aglomerados", "valor_natural", "valor_economico"

# correcao_stands_final() -> limiar de eliminacao e modo verbose
threshold_eliminate_ha_correcao <- 0.1
verbose_correcao_stands_final <- TRUE
n_cores_correcao <- 3
progress_por_core_correcao <- TRUE

# run_exposure_interface() e run_exposure_lcp() -> processamento paralelo
n_cores <- 4


## MODO DE EXECUCAO ##
## COMO USAR ##
# 1) Correr tudo:
#    modo_execucao <- "all"
# 2) Correr um bloco inteiro:
#    modo_execucao <- "bloco_donuts"
#    modo_execucao <- "bloco_unidades_tratamento"
#    modo_execucao <- "bloco_exposicao"
#    modo_execucao <- "bloco_prioridades_interface"
# 3) Correr apenas uma funcao:
#    modo_execucao <- "funcao_especifica"
#    funcao_especifica <- "stands_interface"
#    args_funcao_especifica <- list()
#
# Nota: os blocos sao "puros" (nao correm dependencias automaticamente).
# Se faltarem outputs de blocos anteriores, o bloco escolhido vai falhar com erro.
modo_execucao <- "funcao_especifica"

# Usado apenas quando modo_execucao == "funcao_especifica"
# Exemplos: "criar_donuts_valor_chave", "stands_interface", "stands_edificado",
# "correcao_stands_final", "run_exposure_interface", "run_exposure_lcp",
# "update_stands_exposicao", "expo_values_correction", "informacao_UTs",
# "prioridade_absoluta", "prioridade_relativa", "executar_bloco_donuts", "executar_bloco_exposicao"
funcao_especifica <- "correcao_stands_final"

# Argumentos para a funcao especifica (deixar list() para usar defaults da funcao)
args_funcao_especifica <- list(
  shp_stands_interface_edf = shp_stands_interface_edf_nogaps,
  shp_stands_interface_final = shp_stands_interface_final,
  threshold_eliminate_ha = threshold_eliminate_ha_correcao,
  max_small_iter = 10,
  tolerancia_gap_m = 0.5,
  n_cores_correcao = n_cores_correcao,
  progress_por_core = progress_por_core_correcao,
  verbose = verbose_correcao_stands_final
)



## ARRANQUE ##
source("C:/projetos/PIGCALG/09_resultados_2026_v2/script/R/functions.R")

if (identical(modo_execucao, "all")) {
  source("C:/projetos/PIGCALG/09_resultados_2026_v2/script/R/pipeline.R")
} else if (identical(modo_execucao, "bloco_donuts")) {
  executar_bloco_donuts()
} else if (identical(modo_execucao, "bloco_unidades_tratamento")) {
  executar_bloco_unidades_tratamento(
    n_cores_correcao = n_cores_correcao,
    progress_por_core = progress_por_core_correcao
  )
} else if (identical(modo_execucao, "bloco_exposicao")) {
  executar_bloco_exposicao(n_cores = n_cores)
} else if (identical(modo_execucao, "bloco_prioridades_interface")) {
  executar_bloco_prioridades_interface()
} else if (identical(modo_execucao, "funcao_especifica")) {
  if (!exists(funcao_especifica, mode = "function")) {
    stop(
      paste0(
        "Funcao nao encontrada em R/functions.R: ",
        funcao_especifica
      ),
      call. = FALSE
    )
  }

  resultado_funcao_especifica <- do.call(
    what = get(funcao_especifica, mode = "function"),
    args = args_funcao_especifica
  )
} else {
  stop(
    "modo_execucao invalido. Usa: 'all', 'bloco_donuts', 'bloco_unidades_tratamento', 'bloco_exposicao', 'bloco_prioridades_interface' ou 'funcao_especifica'.",
    call. = FALSE
  )
}

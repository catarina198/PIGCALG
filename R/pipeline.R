## Sequencia das etapas (pipeline)

## # - CRIAR DONNUTS ####
executar_bloco_donuts()

## # - UNIDADES DE TRATAMENTO ####
executar_bloco_unidades_tratamento(
  n_cores_correcao = n_cores_correcao,
  progress_por_core = progress_por_core_correcao
)

## # - CALCULO DA EXPOSICAO ####
executar_bloco_exposicao(n_cores = n_cores)

## # - IDENTIFICAR AREAS PRIORITARIAS - INTERFACE ####
executar_bloco_prioridades_interface()

library(sf)
shp <- st_read("C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/V2_20260416/Exposicao/Shapefile/stands_alg_expo.shp")

library(spdep)

viz <- poly2nb(shp)
mat_adj <- nb2mat(viz, style = "B")
write.csv(mat_adj, "C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/V2_20260416/Exposicao/Shapefile/matriz_adjacencia.csv", row.names = TRUE)


interface <- st_read("C:/projetos/PIGCALG/09_resultados_2026_v2/Outputs/Analise/V3_20260416/UTratamento/stands_alg_interface.dbf")
st_geometry_type(interface)
unique(st_geometry_type(interface))
table(st_geometry_type(interface))

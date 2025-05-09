DROP MATERIALIZED VIEW IF EXISTS {schema}.ls_areas_artificializadas_label_view;
CREATE MATERIALIZED VIEW {schema}.ls_areas_artificializadas_label_view
TABLESPACE pg_default
AS SELECT aa.identificador as areas_artificializadas_id,
    COALESCE(string_agg(DISTINCT ip.nome::text, ' | '::text), string_agg(DISTINCT iga.nome::text, ' | '::text), string_agg(DISTINCT euc.nome, ' | '::text)) AS nome,
    geometria
   FROM {schema}.areas_artificializadas aa
     LEFT JOIN {schema}.inst_producao ip ON aa.inst_producao_id = ip.identificador
     LEFT JOIN {schema}.inst_gestao_ambiental iga ON aa.inst_gestao_ambiental_id = iga.identificador
     LEFT JOIN {schema}.equip_util_coletiva euc ON aa.equip_util_coletiva_id = euc.identificador
  GROUP BY aa.identificador
WITH DATA;


DROP MATERIALIZED VIEW IF EXISTS {schema}.ls_edificio_label_view;
CREATE MATERIALIZED VIEW {schema}.ls_edificio_label_view
TABLESPACE pg_default
AS WITH euc AS (
         SELECT leuce.edificio_id,
            string_agg(euc_1.nome::text, ' | '::text) AS nome
           FROM {schema}.equip_util_coletiva euc_1
             JOIN {schema}.lig_equip_util_coletiva_edificio leuce ON leuce.equip_util_coletiva_id = euc_1.identificador
         WHERE NOT (leuce.equip_util_coletiva_id IN ( SELECT areas_artificializadas.equip_util_coletiva_id
                  FROM {schema}.areas_artificializadas))
          GROUP BY leuce.edificio_id
        ), ap AS (
          with adm_aggr as (
            select nome, unnest(ST_ClusterWithin(geometria, 100)) as aggr from {schema}.adm_publica ap 
              left join {schema}.lig_adm_publica_edificio lape on ap.identificador=lape.adm_publica_id
              left join {schema}.edificio e on lape.edificio_id=e.identificador
            group by nome
          )
         SELECT lap.edificio_id,
            string_agg(DISTINCT ap_1.nome::text, ' | '::text) AS nome
           FROM {schema}.adm_publica ap_1
             JOIN {schema}.lig_adm_publica_edificio lap ON lap.adm_publica_id = ap_1.identificador
             JOIN {schema}.edificio e on lap.edificio_id=e.identificador 
             JOIN adm_aggr on ap_1.nome=adm_aggr.nome
          WHERE ST_intersects(e.geometria, ST_PointOnSurface(adm_aggr.aggr))
          GROUP BY lap.edificio_id
        )
 SELECT e.identificador as edificio_id,
    COALESCE(string_agg(DISTINCT ip.nome::text, ' | '::text), string_agg(DISTINCT iga.nome::text, ' | '::text), string_agg(DISTINCT euc.nome, ' | '::text), string_agg(DISTINCT ap.nome, ' | '::text), string_agg(DISTINCT ne.nome::text, ' | '::text)) AS nome,
    string_agg(DISTINCT lua.valor_utilizacao_atual_id, ' | ') as valor_utilizacao_atual_id
   FROM {schema}.edificio e
     LEFT JOIN {schema}.nome_edificio ne ON ne.edificio_id = e.identificador
     LEFT JOIN {schema}.inst_producao ip ON e.inst_producao_id = ip.identificador AND e.inst_producao_id NOT IN (SELECT inst_producao_id FROM {schema}.areas_artificializadas)
     LEFT JOIN {schema}.inst_gestao_ambiental iga ON e.inst_gestao_ambiental_id = iga.identificador AND e.inst_gestao_ambiental_id NOT IN (SELECT inst_gestao_ambiental_id FROM {schema}.areas_artificializadas)
     LEFT JOIN euc ON euc.edificio_id = e.identificador
     LEFT JOIN ap ON ap.edificio_id = e.identificador
     LEFT JOIN {schema}.lig_valor_utilizacao_atual_edificio lua on lua.edificio_id = e.identificador 
  GROUP BY e.identificador
WITH DATA;


DROP MATERIALIZED VIEW IF EXISTS {schema}.ls_seg_via_rodov_label_view;
CREATE MATERIALIZED VIEW {schema}.ls_seg_via_rodov_label_view
TABLESPACE pg_default
AS SELECT svr.identificador AS seg_via_rodov_id,
    string_agg(DISTINCT vr.nome::text, ' | '::text) AS nome
   FROM {schema}.seg_via_rodov svr
     LEFT JOIN {schema}.lig_segviarodov_viarodov lsv ON lsv.seg_via_rodov_id = svr.identificador
     JOIN {schema}.via_rodov vr ON lsv.via_rodov_id = vr.identificador
  GROUP BY svr.identificador
WITH DATA;


DROP MATERIALIZED VIEW IF EXISTS {schema}.ls_seg_via_ferrea_label_view;
CREATE MATERIALIZED VIEW {schema}.ls_seg_via_ferrea_label_view
TABLESPACE pg_default
AS SELECT svf.identificador AS seg_via_ferrea_id,
    string_agg(DISTINCT lf.nome::text, ' | '::text) AS nome
   FROM {schema}.seg_via_ferrea svf
     LEFT JOIN {schema}.lig_segviaferrea_linhaferrea lsl ON lsl.seg_via_ferrea_id = svf.identificador
     JOIN {schema}.linha_ferrea lf ON lsl.linha_ferrea_id = lf.identificador
  GROUP BY svf.identificador
WITH DATA;

{{ config(
    materialized='incremental',
    unique_key=['id_station', 'dh_utc'],
    on_schema_change='append_new_columns'
) }}

with parsed_releves as (
    select
        _airbyte_data->>'id_station' as id_station,
        -- Tronquage de la date à l'heure exacte (UTC) pour agréger les pas de 10 min
        date_trunc('hour', cast(_airbyte_data->>'dh_utc' as timestamp with time zone)) as dh_utc,
        
        nullif(_airbyte_data->>'temperature', '')::numeric(4,1) as temperature,
        nullif(_airbyte_data->>'pression', '')::numeric(6,1) as pression,
        nullif(_airbyte_data->>'humidite', '')::smallint as humidite,
        nullif(_airbyte_data->>'point_de_rosee', '')::numeric(4,1) as point_de_rosee,
        nullif(_airbyte_data->>'visibilite', '')::integer as visibilite,
        nullif(_airbyte_data->>'vent_moyen', '')::numeric(5,1) as vent_moyen,
        nullif(_airbyte_data->>'vent_rafales', '')::numeric(5,1) as vent_rafales,
        nullif(_airbyte_data->>'vent_direction', '')::smallint as vent_direction,
        nullif(_airbyte_data->>'pluie_1h', '')::numeric(5,2) as pluie_1h,
        nullif(_airbyte_data->>'pluie_3h', '')::numeric(5,2) as pluie_3h,
        nullif(_airbyte_data->>'neige_au_sol', '')::numeric(5,1) as neige_au_sol,
        nullif(_airbyte_data->>'nebulosite', '')::smallint as nebulosite,
        _airbyte_data->>'temps_omm' as temps_omm,
        _airbyte_emitted_at
    from {{ source('airbyte_raw', '_airbyte_raw_meteo_stream') }}
    
    {% if is_incremental() %}
      -- Chargement incrémental : ne traite que les données récentes
      where _airbyte_emitted_at > (select max(created_at) from {{ this }})
    {% endif %}
),

aggregated as (
    select
        id_station,
        dh_utc,
        round(avg(temperature), 1) as temperature,
        round(avg(pression), 1) as pression,
        round(avg(humidite))::smallint as humidite,
        round(avg(point_de_rosee), 1) as point_de_rosee,
        round(avg(visibilite))::integer as visibilite,
        round(avg(vent_moyen), 1) as vent_moyen,
        max(vent_rafales) as vent_rafales, -- Conservation de la rafale max horaire
        round(avg(vent_direction))::smallint as vent_direction,
        max(pluie_1h) as pluie_1h,
        max(pluie_3h) as pluie_3h,
        max(neige_au_sol) as neige_au_sol,
        round(avg(nebulosite))::smallint as nebulosite,
        max(temps_omm) as temps_omm,
        max(_airbyte_emitted_at) as created_at
    from parsed_releves
    group by id_station, dh_utc
)

select * from aggregated
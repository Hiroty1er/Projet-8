{{ config(
    materialized='table',
    unique_key='id'
) }}

with raw_data as (
    select
        _airbyte_data->>'id' as id,
        _airbyte_data->>'nom' as nom,
        cast(_airbyte_data->>'latitude' as numeric(8,5)) as latitude,
        cast(_airbyte_data->>'longitude' as numeric(8,5)) as longitude,
        cast(_airbyte_data->>'altitude' as numeric(6,2)) as altitude,
        _airbyte_data->>'type' as type,
        _airbyte_data->>'licence_nom' as licence_nom,
        _airbyte_data->>'licence_url' as licence_url,
        _airbyte_data->>'source' as source,
        _airbyte_data->>'metadonnees_url' as metadonnees_url,
        _airbyte_emitted_at as created_at,
        row_number() over (
            partition by _airbyte_data->>'id' 
            order by _airbyte_emitted_at desc
        ) as rn
    from {{ source('airbyte_raw', '_airbyte_raw_meteo_stream') }}
)

select
    id,
    nom,
    latitude,
    longitude,
    altitude,
    type,
    licence_nom,
    licence_url,
    source,
    metadonnees_url,
    created_at
from raw_data
where rn = 1 -- Déduplication des métadonnées station
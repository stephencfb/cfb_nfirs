WITH single_stair_plutos AS (
    SELECT
        plutos.*
    FROM pluto_records AS plutos
    WHERE plutos.numfloors BETWEEN 4 AND 6 -- Taller than IBC allows, within NYC BC single-stair height limit
    AND plutos.yearbuilt >= 1968 -- Everything since 1968 building code (birth of modern single-stair section)
    AND -- Single-stair buildings...
    (plutos.unitsres >= 3 -- At least three units (definitely has sprinklers)
    -- AND plutos.yearbuilt >= 1968 -- Built since single-stair allowed in 1968 BC
    AND ((plutos.lotarea * 0.6 <= 2000 AND plutos.lottype != '3') OR plutos.lotarea <= 2000) -- R6 districts (which allow the heights that single-stair buildings are built to) allow 60% lot coverage if the building is not on a corner (lottype = 3), so we back into the max allowed floor size from there; otherwise, we assume it might be on a corner and do not allow lot area to exceed 2,000 sq. ft.
    AND plutos.bldgarea / plutos.numfloors <= 2000) -- Average floor size is at most 2,000 sq. ft.
), nfirs_deaths AS ( -- See cfb_nfirs/nyc-total-residential-deaths.sql for explanation

    SELECT
        basic_fires.alarm_at,
        basic_fires.other_deaths,
        basic_fires.fire_service_deaths,
        basic_fires.nfirs_basic_incident_id,
        basic_fires.nfirs_fire_incident_id,
        basic_fires.incident_type,
        address_plutos.pluto_record_id
    FROM nfirs_basic_fire_incidents AS basic_fires
    JOIN nfirs_incident_addresses AS addresses
    ON basic_fires.nfirs_basic_incident_id = addresses.nfirs_basic_incident_id
    JOIN nfirs_incident_address_pluto_records AS address_plutos
    ON addresses.id = address_plutos.nfirs_incident_address_id
    WHERE (basic_fires.other_deaths > 0 OR basic_fires.fire_service_deaths > 0)
    AND basic_fires.incident_type = '111'
)

SELECT
    nfirs_deaths.incident_type,
    nfirs_deaths.nfirs_basic_incident_id,
    nfirs_deaths.nfirs_fire_incident_id,
    nfirs_deaths.alarm_at,
    medias.date_of_fire,
    plutos.address,
    plutos.borough,
    plutos.yearbuilt,
    nfirs_deaths.other_deaths AS nfirs_civilian_deaths,
    nfirs_deaths.fire_service_deaths AS nfirs_firefighter_deaths,
    medias.civilian_deaths AS manual_civilian_deaths
FROM single_stair_plutos AS plutos -- Start with PLUTO
LEFT JOIN nfirs_deaths -- Join what's documented on line 12
ON plutos.id = nfirs_deaths.pluto_record_id
LEFT JOIN fdny_media_account_pluto_records AS media_plutos -- Join FDNY media/PLUTO join table
ON plutos.id = media_plutos.pluto_record_id
LEFT JOIN fdny_media_accounts AS medias -- Join FDNY media dataset (Pew/CfB created)
ON media_plutos.fdny_media_account_id = medias.id
WHERE (nfirs_deaths.other_deaths > 0 OR nfirs_deaths.fire_service_deaths > 0 OR medias.civilian_deaths > 0) -- Find records with a death
AND (EXTRACT(YEAR FROM nfirs_deaths.alarm_at) > plutos.yearbuilt OR EXTRACT(YEAR FROM medias.date_of_fire) > plutos.yearbuilt); -- Make sure the year of the fire was before the year of construction (will not capture year-of-construction fire deaths, but these are highly unlikely, and yearbuilt often reflects permit, not certificate of occupcancy anyway)

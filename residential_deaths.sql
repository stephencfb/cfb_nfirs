WITH residential_plutos AS (
    SELECT
        plutos.*
    FROM pluto_records AS plutos
    WHERE plutos.unitsres > 0
), nfirs_deaths AS (
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
    nfirs_deaths.other_deaths AS nfirs_other_deaths,
    nfirs_deaths.fire_service_deaths AS nfirs_fire_service_deaths,
    medias.civilian_deaths AS media_civilian_deaths,
    GREATEST(nfirs_deaths.other_deaths, medias.civilian_deaths) AS likely_civilian_deaths,
    CASE WHEN ((nfirs_deaths.fire_service_deaths IS NOT NULL AND nfirs_deaths.fire_service_deaths != 0) OR ((nfirs_deaths.other_deaths IS NOT NULL AND medias.civilian_deaths IS NOT NULL) AND nfirs_deaths.other_deaths != medias.civilian_deaths)) THEN TRUE ELSE FALSE END AS death_complication -- Is there a firefighter death, or does the number of civilian deaths reported to NFIRS differ from the manual count of deaths?
FROM residential_plutos AS plutos
LEFT JOIN nfirs_deaths
ON plutos.id = nfirs_deaths.pluto_record_id
LEFT JOIN fdny_media_account_pluto_records AS media_plutos
ON plutos.id = media_plutos.pluto_record_id
LEFT JOIN fdny_media_accounts AS medias
ON media_plutos.fdny_media_account_id = medias.id
WHERE (nfirs_deaths.other_deaths > 0 OR nfirs_deaths.fire_service_deaths > 0 OR medias.civilian_deaths > 0)
AND (EXTRACT(YEAR FROM nfirs_deaths.alarm_at) > plutos.yearbuilt OR EXTRACT(YEAR FROM medias.date_of_fire) > plutos.yearbuilt); -- Make sure the year of the fire was before the year of construction (will not capture year-of-construction fire deaths, but these are highly unlikely, and yearbuilt often reflects permit, not certificate of occupcancy anyway)

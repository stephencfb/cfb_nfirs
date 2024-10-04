WITH residential_plutos AS ( -- Isolate only residential buildings
    SELECT
        plutos.*
    FROM pluto_records AS plutos
    WHERE plutos.unitsres > 0
), nfirs_deaths AS 
    SELECT
        basic_fires.alarm_at,
        basic_fires.other_deaths,
        basic_fires.fire_service_deaths,
        basic_fires.nfirs_basic_incident_id,
        basic_fires.nfirs_fire_incident_id,
        basic_fires.incident_type,
        address_plutos.pluto_record_id
    FROM nfirs_basic_fire_incidents AS basic_fires -- Start with the base dataset (nfirs_basic_fire_incidents, which is a joining of the NFIRS basic incidents module and the NFIRS fire module)
    JOIN nfirs_incident_addresses AS addresses -- Join to the NFIRS addresses file
    ON basic_fires.nfirs_basic_incident_id -- addresses.nfirs_basic_incident_id
    JOIN nfirs_incident_address_pluto_records AS address_plutos -- Join to Center for Buildings' proprietary joining of NFIRS addresses and PLUTO
    ON addresses.id = address_plutos.nfirs_incident_address_id
    WHERE (basic_fires.other_deaths > 0 OR basic_fires.fire_service_deaths > 0) -- Look for incidents with a death
    AND basic_fires.incident_type = '111' -- Look for structure fires
)


SELECT -- Output all of the incidents with a death in them (which later gets summed up)
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
FROM residential_plutos AS plutos -- Base of PLUTO dataset
LEFT JOIN nfirs_deaths -- Join the above table created starting on line 6
ON plutos.id = nfirs_deaths.pluto_record_id
LEFT JOIN fdny_media_account_pluto_records AS media_plutos -- Join the FDNY media/PLUTO join table
ON plutos.id = media_plutos.pluto_record_id
LEFT JOIN fdny_media_accounts AS medias -- Join the FDNY media table (Pew/CfB dataset )
ON media_plutos.fdny_media_account_id = medias.id
WHERE (nfirs_deaths.other_deaths > 0 OR nfirs_deaths.fire_service_deaths > 0 OR medias.civilian_deaths > 0) -- Look for records where there was one death recorded in one of the datasets
AND (EXTRACT(YEAR FROM nfirs_deaths.alarm_at) > plutos.yearbuilt OR EXTRACT(YEAR FROM medias.date_of_fire) > plutos.yearbuilt) -- Make sure the year of the fire was before the year of construction (will not capture year-of-construction fire deaths, but these are highly unlikely, and yearbuilt often reflects permit, not certificate of occupcancy anyway)

SELECT
    SUM(plutos.unitsres) AS total_unitsres, SUM(plutos.bldgarea) AS total_bldgarea, COUNT(plutos.*) AS total_buildings
FROM pluto_records AS plutos
WHERE plutos.unitsres > 0;

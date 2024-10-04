-- This one's pretty simple – get the total number of residential units in NYC, the total building area thereof, and the total number of buildings

SELECT
    SUM(plutos.unitsres) AS total_unitsres, SUM(plutos.bldgarea) AS total_bldgarea, COUNT(plutos.*) AS total_buildings
FROM pluto_records AS plutos
WHERE plutos.unitsres > 0;

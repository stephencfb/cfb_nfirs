SELECT
    SUM((2024 - plutos.yearbuilt) * plutos.unitsres) AS total_unit_years, SUM(plutos.unitsres) AS total_units, COUNT(*) AS total_buildings
FROM pluto_records AS plutos
WHERE plutos.numfloors BETWEEN 4 AND 6 -- Taller than IBC allows, within NYC BC single-stair height limit
AND -- NOT single-stair buildings...
(plutos.unitsres >= 3 -- At least three units (definitely has sprinklers)
AND plutos.yearbuilt >= 2000 -- Built since single-stair allowed in 1968 BC
AND ((plutos.lotarea * 0.6 <= 2000 AND plutos.lottype != '3') OR plutos.lotarea <= 2000) -- R6 districts (which allow the heights that single-stair buildings are built to) allow 60% lot coverage if the building is not on a corner (lottype = 3), so we back into the max allowed floor size from there; otherwise, we assume it might be on a corner and do not allow lot area to exceed 2,000 sq. ft.
AND plutos.bldgarea / plutos.numfloors <= 2000) -- Average floor size is at most 2,000 sq. ft.


-- RESULTS
-- total_unit_years  total_units   total_buildings
-- 305,905.0	      25,899.0	    4,088

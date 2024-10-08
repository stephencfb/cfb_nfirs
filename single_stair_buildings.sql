SELECT
    plutos.address,
    plutos.borough,
    plutos.unitsres
FROM pluto_records AS plutos
WHERE plutos.numfloors BETWEEN 4 AND 6 -- Taller than IBC allows, within NYC BC single-stair height limit
-- AND plutos.yearbuilt >= 2000 -- Post-sprinkler requirement
AND -- Single-stair buildings...
(plutos.unitsres >= 3 -- At least three units (definitely has sprinklers, per NYC BC)
AND plutos.yearbuilt >= 1968 -- Built since single-stair allowed in 1968 BC
AND ((plutos.lotarea * 0.6 <= 2000 AND plutos.lottype != '3') OR plutos.lotarea <= 2000) -- R6 zoning districts (which allow the heights that single-stair buildings are built to) allow 60% lot coverage if the building is not on a corner (lottype = 3), so we back into the max allowed floor size from there; otherwise, we assume it might be on a corner and do not allow lot area to exceed 2,000 sq. ft.
AND plutos.bldgarea / plutos.numfloors <= 2000) -- Average floor size is at most 2,000 sq. ft.

-- 05_region.sql
-- 행정동 경계(geom) + 인구를 합쳐 region 테이블 구성, 각 역(stop)을 행정동에 매핑
-- 사전: 아래 셸 명령으로 region_raw(경계)를 먼저 적재해야 함 (ogr2ogr)
-- 실행: 프로젝트 루트에서  psql transit -f sql/05_region.sql

-- 1) 정제된 동별 인구 적재 (Python으로 만든 population_clean.csv)
DROP TABLE IF EXISTS dong_population;
CREATE TABLE dong_population (
    adm_cd        varchar(10) PRIMARY KEY,
    dong          varchar(40),
    sgg           varchar(20),
    total_pop     integer,
    elderly_pop   integer,
    elderly_ratio numeric(5,2)
);
\copy dong_population FROM 'data/population_clean.csv' WITH (FORMAT csv, HEADER true)

-- 2) region = 경계(region_raw.geom) + 인구(dong_population)
--    adm_cd(행정동코드)로 조인
DROP TABLE IF EXISTS region CASCADE;
CREATE TABLE region AS
SELECT r.adm_cd,
       r.adm_nm,
       r.sggnm        AS sgg,
       p.total_pop,
       p.elderly_pop,
       p.elderly_ratio,
       r.geom
FROM region_raw r
JOIN dong_population p ON p.adm_cd = r.adm_cd;

ALTER TABLE region ADD PRIMARY KEY (adm_cd);
CREATE INDEX region_geom_idx ON region USING GIST (geom);

-- 3) 공간 조인: 각 역이 어느 행정동 안에 있나 (점 ∈ 폴리곤)
--    ST_Contains(폴리곤, 점) = 이 동 경계가 이 역을 품고 있나?
ALTER TABLE stop ADD COLUMN IF NOT EXISTS adm_cd varchar(10);
UPDATE stop s
SET adm_cd = r.adm_cd
FROM region r
WHERE ST_Contains(r.geom, s.geom);

-- 4) 확인
-- 몇 개 역이 동에 매핑됐나 (경계 밖 역은 NULL로 남음)
SELECT count(*) AS total_stops,
       count(adm_cd) AS mapped_stops
FROM stop;

-- 동별 역 개수 + 인구 (역 많은 순)
SELECT r.sgg, r.adm_nm, count(s.stop_code) AS n_stops,
       r.total_pop, r.elderly_ratio
FROM region r
LEFT JOIN stop s ON s.adm_cd = r.adm_cd
GROUP BY r.adm_cd, r.sgg, r.adm_nm, r.total_pop, r.elderly_ratio
ORDER BY n_stops DESC
LIMIT 10; 

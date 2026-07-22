-- 06_accessibility.sql
-- 교통 접근성 분석: 인구(특히 고령자) 대비 지하철 공급이 부족한 행정동 찾기
-- 실행: psql transit -f sql/06_accessibility.sql

-- 동별 접근성 요약을 머티리얼라이즈드 뷰로 (자주 쓰는 집계 → 캐싱)
DROP MATERIALIZED VIEW IF EXISTS dong_access;
CREATE MATERIALIZED VIEW dong_access AS
SELECT r.adm_cd, r.sgg, r.adm_nm,
       r.total_pop, r.elderly_pop, r.elderly_ratio,
       count(s.stop_code) AS n_stops
FROM region r
LEFT JOIN stop s ON s.adm_cd = r.adm_cd
GROUP BY r.adm_cd, r.sgg, r.adm_nm, r.total_pop, r.elderly_pop, r.elderly_ratio;

-- 분석 1) 역이 하나도 없는데 고령자가 많은 동 (교통 소외 최우선 후보)
SELECT sgg, adm_nm, total_pop, elderly_pop, elderly_ratio
FROM dong_access
WHERE n_stops = 0
ORDER BY elderly_pop DESC
LIMIT 15;

-- 분석 2) 역 1개당 인구 (역은 있으나 인구 대비 과부하)
SELECT sgg, adm_nm, n_stops, total_pop,
       round(total_pop::numeric / n_stops) AS pop_per_stop
FROM dong_access
WHERE n_stops > 0
ORDER BY pop_per_stop DESC
LIMIT 15;

-- 분석 3) 전체 요약
SELECT count(*)                              AS total_dong,
       count(*) FILTER (WHERE n_stops = 0)   AS dong_no_station,
       round(avg(n_stops), 2)                AS avg_stops
FROM dong_access;

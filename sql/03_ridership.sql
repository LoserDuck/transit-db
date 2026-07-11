-- 03_ridership.sql
-- 지하철 역별·시간대별 승하차 (wide -> long, 연도별 파티셔닝)
-- 전제: data/ridership_wide.csv (UTF-8, 52컬럼, 헤더 있음)
-- 실행: 프로젝트 루트에서  psql transit -f sql/03_ridership.sql

-- ============================================================
-- 1) 원본(wide)을 그대로 받는 staging 테이블 (52컬럼, 전부 text)
-- ============================================================
DROP TABLE IF EXISTS stg_ridership;
CREATE TABLE stg_ridership (
    ym text,
    line text,
    station text,
    h04_on  text,
    h04_off text,
    h05_on  text,
    h05_off text,
    h06_on  text,
    h06_off text,
    h07_on  text,
    h07_off text,
    h08_on  text,
    h08_off text,
    h09_on  text,
    h09_off text,
    h10_on  text,
    h10_off text,
    h11_on  text,
    h11_off text,
    h12_on  text,
    h12_off text,
    h13_on  text,
    h13_off text,
    h14_on  text,
    h14_off text,
    h15_on  text,
    h15_off text,
    h16_on  text,
    h16_off text,
    h17_on  text,
    h17_off text,
    h18_on  text,
    h18_off text,
    h19_on  text,
    h19_off text,
    h20_on  text,
    h20_off text,
    h21_on  text,
    h21_off text,
    h22_on  text,
    h22_off text,
    h23_on  text,
    h23_off text,
    h00_on  text,
    h00_off text,
    h01_on  text,
    h01_off text,
    h02_on  text,
    h02_off text,
    h03_on  text,
    h03_off text,
    work_date text
);

\copy stg_ridership FROM 'data/ridership_wide.csv' WITH (FORMAT csv, HEADER true)

-- ============================================================
-- 2) 정제된 long 테이블 (연도별 RANGE 파티셔닝)
--    한 줄 = 한 역 · 한 달 · 한 시간대
-- ============================================================
DROP TABLE IF EXISTS ridership CASCADE;
CREATE TABLE ridership (
    station     varchar(50) NOT NULL,   -- 지하철역(역명)
    line        varchar(20) NOT NULL,   -- 호선명
    ride_month  date        NOT NULL,   -- 사용월(매월 1일로 저장)
    hour_band   smallint    NOT NULL,   -- 시간대 시작시(4 = 04~05시)
    board_cnt   integer     NOT NULL,   -- 승차인원
    alight_cnt  integer     NOT NULL    -- 하차인원
) PARTITION BY RANGE (ride_month);

-- 연도별 파티션 (2015~2026)
CREATE TABLE IF NOT EXISTS ridership_2015 PARTITION OF ridership
    FOR VALUES FROM ('2015-01-01') TO ('2016-01-01');
CREATE TABLE IF NOT EXISTS ridership_2016 PARTITION OF ridership
    FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');
CREATE TABLE IF NOT EXISTS ridership_2017 PARTITION OF ridership
    FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');
CREATE TABLE IF NOT EXISTS ridership_2018 PARTITION OF ridership
    FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');
CREATE TABLE IF NOT EXISTS ridership_2019 PARTITION OF ridership
    FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');
CREATE TABLE IF NOT EXISTS ridership_2020 PARTITION OF ridership
    FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');
CREATE TABLE IF NOT EXISTS ridership_2021 PARTITION OF ridership
    FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');
CREATE TABLE IF NOT EXISTS ridership_2022 PARTITION OF ridership
    FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');
CREATE TABLE IF NOT EXISTS ridership_2023 PARTITION OF ridership
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
CREATE TABLE IF NOT EXISTS ridership_2024 PARTITION OF ridership
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE IF NOT EXISTS ridership_2025 PARTITION OF ridership
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE IF NOT EXISTS ridership_2026 PARTITION OF ridership
    FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

-- 범위 밖 데이터 방어용 기본 파티션
CREATE TABLE IF NOT EXISTS ridership_default PARTITION OF ridership DEFAULT;

-- ============================================================
-- 3) wide -> long 변환 (unpivot): 48개 시간대 컬럼을 24행으로 펼침
-- ============================================================
INSERT INTO ridership (station, line, ride_month, hour_band, board_cnt, alight_cnt)
SELECT s.station,
       s.line,
       to_date(s.ym, 'YYYYMM')            AS ride_month,
       v.hour_band,
       COALESCE(NULLIF(trim(v.board),  '')::int, 0) AS board_cnt,
       COALESCE(NULLIF(trim(v.alight), '')::int, 0) AS alight_cnt
FROM stg_ridership s
CROSS JOIN LATERAL (VALUES
    (4::smallint, s.h04_on,  s.h04_off),
    (5::smallint, s.h05_on,  s.h05_off),
    (6::smallint, s.h06_on,  s.h06_off),
    (7::smallint, s.h07_on,  s.h07_off),
    (8::smallint, s.h08_on,  s.h08_off),
    (9::smallint, s.h09_on,  s.h09_off),
    (10::smallint, s.h10_on,  s.h10_off),
    (11::smallint, s.h11_on,  s.h11_off),
    (12::smallint, s.h12_on,  s.h12_off),
    (13::smallint, s.h13_on,  s.h13_off),
    (14::smallint, s.h14_on,  s.h14_off),
    (15::smallint, s.h15_on,  s.h15_off),
    (16::smallint, s.h16_on,  s.h16_off),
    (17::smallint, s.h17_on,  s.h17_off),
    (18::smallint, s.h18_on,  s.h18_off),
    (19::smallint, s.h19_on,  s.h19_off),
    (20::smallint, s.h20_on,  s.h20_off),
    (21::smallint, s.h21_on,  s.h21_off),
    (22::smallint, s.h22_on,  s.h22_off),
    (23::smallint, s.h23_on,  s.h23_off),
    (0::smallint, s.h00_on,  s.h00_off),
    (1::smallint, s.h01_on,  s.h01_off),
    (2::smallint, s.h02_on,  s.h02_off),
    (3::smallint, s.h03_on,  s.h03_off)
) AS v(hour_band, board, alight);

-- ============================================================
-- 4) 확인 (인덱스는 튜닝 단계에서 before/after 측정하며 추가 예정)
-- ============================================================
SELECT count(*) AS ridership_rows FROM ridership;
SELECT ride_month, count(*) FROM ridership GROUP BY ride_month ORDER BY ride_month LIMIT 5;

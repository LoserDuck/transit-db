-- 02_stop.sql
-- 지하철 역 위치 데이터 적재 (staging 패턴)
-- 전제: data/stop.csv  (CP949 원본을 UTF-8로 변환, 콤마 구분, 헤더 있음)
-- 실행: 프로젝트 루트에서  psql transit -f sql/02_stop.sql

-- 1) 원본을 그대로 받는 임시(staging) 테이블
DROP TABLE IF EXISTS stg_stop;
CREATE TABLE stg_stop (
    seq        text,
    line       text,
    stop_code  text,
    name       text,
    lat        text,
    lon        text,
    created_at text,
    ref_date   text
);

-- CSV 통째로 적재 (psql 메타명령, 경로는 실행 위치 기준)
\copy stg_stop FROM 'data/stop.csv' WITH (FORMAT csv, HEADER true)

-- 2) 정제된 stop 테이블
DROP TABLE IF EXISTS stop;
CREATE TABLE stop (
    stop_code varchar(10) PRIMARY KEY,   -- 고유역번호
    name      varchar(50) NOT NULL,       -- 역명
    line      varchar(10) NOT NULL,       -- 호선
    lat       double precision NOT NULL,  -- 위도
    lon       double precision NOT NULL,  -- 경도
    geom      geometry(Point, 4326)       -- 공간 좌표 (lat/lon 기반)
);

INSERT INTO stop (stop_code, name, line, lat, lon)
SELECT stop_code, name, line,
       lat::double precision,
       lon::double precision
FROM stg_stop;

-- 3) geom 채우기 + 공간 인덱스(GiST)
UPDATE stop SET geom = ST_SetSRID(ST_MakePoint(lon, lat), 4326);
CREATE INDEX stop_geom_idx ON stop USING GIST (geom);

-- 4) 확인
SELECT count(*) AS stop_count FROM stop;
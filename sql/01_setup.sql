-- 01_setup.sql
-- 프로젝트 초기 설정 (DB당 1회)
-- 전제: 셸에서 먼저  createdb transit로 DB를 만들어 둔다.
-- 실행:  psql transit -f sql/01_setup.sql

-- PostGIS: 공간 데이터 타입/함수 활성화 (반경 검색, 거리 계산 등)
CREATE EXTENSION IF NOT EXISTS postgis;

-- 설치 확인 (버전 출력)
SELECT postgis_version();
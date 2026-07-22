-- 04_explore.sql
-- ridership 기본 탐색 쿼리 + 발견한 인사이트
-- 실행:  psql transit -f sql/04_explore.sql   (또는 psql에서 하나씩)

-- 쿼리 1) 11년간 제일 붐빈 역 TOP 10 (승하차 합계)
-- 결과: 강남 > 홍대입구 > 잠실 > 신림 > 구로디지털단지 ...
--       TOP 10 중 8개가 2호선 (강남 업무지구 + 순환선 효과)
SELECT station, line, sum(board_cnt + alight_cnt) AS total
FROM ridership
GROUP BY station, line
ORDER BY total DESC
LIMIT 10;

-- 쿼리 2) 시간대별 승하차 패턴 (몇 시가 붐비나)
-- 결과: 출퇴근 물결이 뚜렷.
--   - 아침: 8시 승차 피크(출발) → 8~9시 하차 피크(직장 도착)
--   - 저녁: 18시 승차 피크(퇴근 출발) → 19시 하차 피크(귀가 도착)
--   - 새벽 2~4시 거의 0, 자정 하차 큼(막차 귀가)
SELECT hour_band AS hour,
       sum(board_cnt)  AS board,
       sum(alight_cnt) AS alight
FROM ridership
GROUP BY hour_band
ORDER BY hour_band;

-- 쿼리 3) 파티셔닝 효과 확인 (파티션 프루닝)
-- 기간 조건을 주면 해당 연도 파티션만 스캔한다.

-- (a) 2024년만 조회 → ridership_2024 파티션 하나만 스캔됨 (프루닝 O)
EXPLAIN (ANALYZE, BUFFERS)
SELECT sum(board_cnt)
FROM ridership
WHERE ride_month >= '2024-01-01' AND ride_month < '2025-01-01';

-- (b) 전체 조회 → 모든 연도 파티션(2015~2026)이 전부 스캔됨 (비교용)
EXPLAIN (ANALYZE, BUFFERS)
SELECT sum(board_cnt) FROM ridership;

-- 관찰: (a)는 ridership_2024만, (b)는 전 파티션.
-- → 기간 조건 하나로 스캔 범위를 1/11로 줄임. (파티셔닝의 핵심 이점)

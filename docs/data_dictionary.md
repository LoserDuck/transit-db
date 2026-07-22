# 데이터 사전 (Data Dictionary)

각 테이블의 컬럼(열)과 의미 정리. "한 행(row)이 무엇인지"를 먼저 보면 이해가 쉬움.

---

## stop — 지하철 역
**한 행 = 지하철 역 하나** (총 276개)

| 컬럼 | 타입 | 의미 | 예시 |
|---|---|---|---|
| stop_code | varchar(10) PK | 고유 역번호 | `150` |
| name | varchar(50) | 역 이름 | `서울` |
| line | varchar(10) | 호선 | `1` |
| lat | double | 위도 | `37.5532` |
| lon | double | 경도 | `126.9725` |
| geom | geometry(Point,4326) | 위치(점, PostGIS) | (내부값) |
| adm_cd | varchar(10) | 이 역이 속한 행정동코드 (공간조인으로 채움) | `11030530` |

---

## ridership — 시간대별 승하차
**한 행 = 한 역 · 한 달 · 한 시간대의 승하차** (총 199만개)

| 컬럼 | 타입 | 의미 | 예시 |
|---|---|---|---|
| station | varchar(50) | 역 이름 | `강남` |
| line | varchar(20) | 호선명 | `2호선` |
| ride_month | date | 사용월 (매월 1일로 저장) | `2024-06-01` |
| hour_band | smallint | 시간대 시작 시 (8 = 08~09시) | `8` |
| board_cnt | integer | 승차 인원 (탄 사람) | `25000` |
| alight_cnt | integer | 하차 인원 (내린 사람) | `30000` |

---

## region — 행정동
**한 행 = 행정동 하나** (서울 426개)

| 컬럼 | 타입 | 의미 | 예시 |
|---|---|---|---|
| adm_cd | varchar(10) PK | 행정동코드 | `11680xx` |
| adm_nm | text | 행정동 전체 이름 | `서울특별시 강남구 수서동` |
| sgg | varchar(20) | 자치구 이름 | `강남구` |
| total_pop | integer | 총인구 | `13454` |
| elderly_pop | integer | 65세 이상 인구 | `5538` |
| elderly_ratio | numeric | 고령 비율(%) | `41.16` |
| geom | geometry(MultiPolygon,4326) | 동 경계(면, PostGIS) | (내부값) |

---

## 테이블 연결 방법 (JOIN 키)
- stop ↔ region : `stop.adm_cd = region.adm_cd` (역이 속한 동)
- ridership ↔ stop : `ridership.station = stop.name` (역 이름으로) ⚠️ 주의: 호선 표기 다름
  (stop.line = `1`, ridership.line = `1호선`)

## 보조 테이블 (재료/부품)
| 테이블 | 역할 |
|---|---|
| stg_stop, stg_ridership | 원본 CSV를 그대로 받는 임시 창고 |
| region_raw | GeoJSON 경계 원본 (ogr2ogr 적재) |
| dong_population | 동별 인구 정제본 (region 재료) |
| ridership_2015~2026 | ridership의 연도별 파티션 조각 |
| dong_access | 동별 역 개수 요약 (머티리얼라이즈드 뷰) |

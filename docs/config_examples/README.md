# 데이터 계약 예시

이 폴더의 JSON은 **실제 구현 파일이 아닌 설계·샘플 데이터**입니다. Antigravity가 P01/P08/P12/P15/P17 단계에서 검사·변환해 `data/`에 복사합니다.

- `balance_v0.json`: FPS, 동시 활성 적 12의 초기값, 난이도/병사/적/소총/포탑/경제 예시. 수치는 **제안 초기값**이고 확정 밸런스 아님.
- `wave_plan_v0.json`: 1~15웨이브의 **누적 적 구성 예시**. `max_active_enemies=12`는 **동시 출현 상한**이며 각 행의 enemy_total 수량과 혼동하지 말 것. 5/10/15 보스 고정.
- `sample_profile_v1.json`: 영구 프로필 구조 예시.
- `sample_checkpoint_v1.json`: 웨이브 경계 active_run 구조 예시.

**검증:** 실제 구현하기 전에 JSON 파싱, ID 일관성, 포탑 설치 비용 통화, 보스 5/10/15, 첫 3웨이브 적 2종, 정면 스폰, 동시 활성 적 상한, `schema_version`, 실패 파일 복원 정책을 검증할 것.

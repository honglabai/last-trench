# 개발 환경 및 버전 잠금 보고서 (P00)

- **점검 일시:** 2026-11-14
- **프로젝트:** LAST TRENCH (최후의 참호)
- **대상 플랫폼:** Android (우선 개발 및 테스트)
- **개발 머신:** macOS Darwin (arm64, Apple Silicon)

---

## 1. 하드웨어 및 운영체제
- **OS:** macOS Darwin 25.6.0 (arm64)
- **아키텍처:** Apple Silicon (ARM64)

## 2. 형상 관리 (Git)
- **상태:** 설치됨 (정상)
- **버전:** git version 2.50.1 (Apple Git-155)
- **프로젝트 저장소:** `/Users/kobujang/Desktop/cording/LAST_TRENCH` (git 초기화 완료)

## 3. 게임 엔진 (Godot Engine)
- **상태:** **설치 완료 및 버전 잠금 (PASS)**
- **실행 경로:** `/opt/homebrew/bin/godot` (`/Applications/Godot.app/Contents/MacOS/Godot`)
- **잠금 버전:** `4.7.2.stable.official.ed1daf0bf` (Standard / GDScript 지원)
- **렌더러 설정 방향:** Mobile (Android 3D 최적화, 호환성 문제 시 Compatibility 실측 비교)
- **검증 명령 결과:**
  - `godot --version` -> `4.7.2.stable.official.ed1daf0bf`
  - `godot --help` -> 정상 반환 확인

## 4. Android 개발 환경 (Android SDK / ADB / Java)
- **Android SDK 경로:** `/Users/kobujang/Library/Android/sdk`
- **ADB 경로:** `/Users/kobujang/Library/Android/sdk/platform-tools/adb`
- **ADB 버전:** Android Debug Bridge version 1.0.41 (36.0.2)
- **설치된 빌드 도구 (build-tools):** 35.0.0, 36.1.0
- **설치된 플랫폼 (platforms):** android-36
- **Java (JDK) 경로:** `/Applications/Android Studio.app/Contents/jbr/Contents/Home`
- **Java 버전:** OpenJDK 21.0.8 (Android Studio 내장 JBR)
- **Android 빌드 준비도:** 양호 (SDK 및 JDK가 정상 감지됨)

---

## 5. 단계 판정 (Gate Status)
- **P00 상태:** **PASS**
- **달성 요구사항:** Q11, Q12
- **후속 단계 승인 요청:** P01. 프로젝트 초기화·기초 구조

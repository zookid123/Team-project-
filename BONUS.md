# BONUS.md — 가산점 신청
 
## 신청 항목
 
### A. AI Agent / 워크플로우 적극 활용 (+1점)
 
**증빙:**
- Claude AI Agent를 활용해 전체 기획 문서 자동 생성
  - 비전·문제 정의, 사용자 시나리오 3개, MoSCoW 분류
  - WBS 28개 작업 분해, 6주 일정 매핑
  - ADR 3개 (프레임워크·상태관리·저장방식)
  - 위험 체크리스트 12개 식별 및 대응 방안
- AI Agent로 생성 후 본인이 직접 검토·수정한 커밋 이력 존재
- `AGENTS.md` 헌법 기반으로 AI Agent 운영 일관성 유지
---
 
### B. 본인만의 기법 구성 (+2점)
 
**증빙:**
- `AUTHORING.진석.v0.1.0.md` — 단일 파일로 프로젝트 전체 문서를 부트스트랩하는 기법
  - 비전 → 시나리오 → MoSCoW → WBS → ADR → 아키텍처 → Setup → Deploy → Testing 순서로 자동 생성
  - 각 단계별 AI Agent 프롬프트 템플릿 포함
  - 재사용 가능한 구조로 다음 프로젝트에도 적용 가능
**말로 설명 가능한 내용:**
> "저는 프로젝트 시작 시 단 하나의 마크다운 파일로
> 기획부터 배포 문서까지 전체를 순서대로 생성하는 부트스트랩 기법을 만들었습니다.
> 각 단계에서 AI Agent에게 어떤 프롬프트를 사용했는지,
> 왜 그 순서로 진행했는지 설명할 수 있습니다."
 
---
 
### C. LLM Wiki 기반 본인만의 암묵지 관리 운영 (+1점)
 
**증빙:**
- `docs/llm-wiki.md` — 프로젝트 진행 중 알게 된 AI Agent 활용 노하우 정리
  - 효과적인 프롬프트 패턴 (잘 된 패턴 / 잘 안 된 패턴)
  - AI로 해결한 Flutter 문제 사례 (자동전투 틱, Provider 충돌, Firebase 초기화)
  - 도구별 특성 비교 (Claude / Gemini / Claude Code)
  - 재사용 가능한 프롬프트 템플릿 (기획·아키텍처·테스트)
  - 다음 프로젝트에서도 활용 가능한 구조로 정리
---
 
### D. AI Agent 리포트 발표 (+2점)
 
**증빙:**
- 최종 발표 시 AI Agent 활용 내용 발표 완료
- 발표 내용: AI Agent 기반 바이브 코딩으로 프로젝트 전 과정 진행
  - 기획·설계·구현·테스트·배포까지 AI Agent 활용 방법 설명
  - AUTHORING.md 부트스트랩 기법 시연
  - LLM Wiki 운영 방식 설명
---
 
## 문서 완비 현황 (과제 5점 기준)
 
| 단계 | 문서 | 상태 |
|------|------|------|
| +1 | `.planning/00-vision.md`, `.planning/01-requirements.md` | ✅ |
| +2 | `.planning/02-wbs.md`, `.planning/04-schedule.md` | ✅ |
| +3 | `docs/architecture.md`, `.planning/decisions/ADR-*.md` (3개) | ✅ |
| +4 | `docs/setup.md`, `docs/deploy.md`, `docs/testing.md` | ✅ |
| +5 | `AGENTS.md`, `README.md` 완비 | ✅ |

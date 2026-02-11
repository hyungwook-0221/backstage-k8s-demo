# 📚 문서 인덱스 (Documentation Index)

이 프로젝트의 모든 문서 위치와 용도를 정리한 가이드입니다.

## 📖 주요 문서

### 1. 시작하기

| 문서 | 용도 | 대상 |
|-----|------|------|
| **[README.md](README.md)** | 프로젝트 개요 및 빠른 시작 | 모든 사용자 |
| **[SETUP.md](SETUP.md)** | 🏠 **Kind 클러스터 설치 가이드** (로컬 빌드) | Kind 환경 사용자 |
| **[SETUP-GENERIC-K8S.md](SETUP-GENERIC-K8S.md)** | ☁️ **일반 K8s 클러스터 설치 가이드** (Docker Hub) | EKS, AKS, GKE, 온프렘 사용자 |
| **[SUMMARY.md](SUMMARY.md)** | 프로젝트 완료 요약 | 프로젝트 상태 확인 |

### 2. 상세 가이드

| 문서 | 용도 | 길이 |
|-----|------|------|
| **[docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)** | 전체 배포 프로세스 상세 설명 | ~1,500줄 |
| **[docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)** | 자주 사용하는 명령어 모음 | ~500줄 |

### 3. 공유 관련

| 문서 | 용도 | 필수 여부 |
|-----|------|----------|
| **[SHARING_CHECKLIST.md](SHARING_CHECKLIST.md)** | 공유 전 체크리스트 | ✅ 공유 전 필수 |
| **[verify.sh](verify.sh)** | 자동 검증 스크립트 | ✅ 공유 전 실행 |
| **[.gitignore](.gitignore)** | Git 제외 파일 목록 | ✅ GitHub 공유 시 |

---

## 📂 디렉토리별 가이드

### `/` (프로젝트 루트)

```
backstage-k8s-demo/
├── README.md                      # ⭐ 시작점
├── SETUP.md                       # ⭐ 설치 가이드
├── SUMMARY.md                     # 완료 요약
├── INDEX.md                       # 이 문서
├── SHARING_CHECKLIST.md           # 공유 체크리스트
├── verify.sh                      # 검증 스크립트
├── .gitignore                     # Git 제외 파일
└── kind-config.yaml               # Kind 클러스터 설정
```

### `/backstage-app` (Backstage 소스 코드)

```
backstage-app/
├── app-config.yaml                # 기본 설정
├── app-config.production.yaml     # Production 설정
├── app-config.kubernetes.yaml     # K8s 전용 설정
├── package.json                   # 의존성 정의
├── packages/
│   ├── app/                       # Frontend
│   └── backend/                   # Backend + Dockerfile
├── templates/                     # Software Templates
│   └── terraform-ec2/             # EC2 템플릿
└── examples/                      # 예제 엔티티
```

**참조 문서:**
- [SETUP.md](SETUP.md#2단계-docker-이미지-빌드)
- [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md#step-2-backstage-애플리케이션-생성)

### `/k8s` (Kubernetes 매니페스트 - Kind 전용)

```
k8s/
├── 00-namespace.yaml              # Namespace
├── 01-postgres-secrets.yaml       # PostgreSQL 시크릿
├── 02-postgres-storage.yaml       # PV/PVC
├── 03-postgres-deployment.yaml    # PostgreSQL 배포
├── 04-backstage-secrets.yaml      # Backstage 시크릿
└── 05-backstage-deployment.yaml   # Backstage 배포 (image: backstage:local)
```

**참조 문서:**
- [SETUP.md](SETUP.md)
- [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md#step-5-kubernetes-매니페스트-작성)

### `/k8s-generic` (Kubernetes 매니페스트 - 일반 K8s)

```
k8s-generic/
├── 00-namespace.yaml              # Namespace
├── 01-postgres-secrets.yaml       # PostgreSQL 시크릿
├── 02-postgres-storage.yaml       # PV/PVC
├── 03-postgres-deployment.yaml    # PostgreSQL 배포
├── 04-backstage-secrets.yaml      # Backstage 시크릿
└── 05-backstage-deployment.yaml   # Backstage 배포 (image: hyungwookhub/backstage:latest)
```

**참조 문서:**
- [SETUP-GENERIC-K8S.md](SETUP-GENERIC-K8S.md)

### `/templates` (Software Template 소스)

```
templates/
└── terraform-ec2/
    ├── template.yaml              # 템플릿 정의
    └── skeleton/                  # 템플릿 파일들
        ├── terraform/             # Terraform 코드
        ├── .github/workflows/     # GitHub Actions
        └── catalog-info.yaml      # 카탈로그 등록
```

**참조 문서:**
- [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md#github-actions--terraform-카탈로그-사용)

### `/docs` (상세 문서)

```
docs/
├── DEPLOYMENT_GUIDE.md            # 전체 배포 가이드
└── QUICK_REFERENCE.md             # 빠른 참조
```

---

## 🎯 사용 시나리오별 가이드

### 시나리오 1: 처음 설치하는 경우

**Option A: Kind (로컬 환경)**
1. **[SETUP.md](SETUP.md)** 읽기
2. 단계별로 따라하기 (이미지 직접 빌드)
3. 문제 발생 시 → [DEPLOYMENT_GUIDE.md 트러블슈팅](docs/DEPLOYMENT_GUIDE.md#트러블슈팅)

**Option B: 일반 K8s 클러스터 (EKS, AKS, GKE 등)**
1. **[SETUP-GENERIC-K8S.md](SETUP-GENERIC-K8S.md)** 읽기
2. 단계별로 따라하기 (Docker Hub 이미지 사용)
3. 문제 발생 시 → [SETUP-GENERIC-K8S.md 트러블슈팅](SETUP-GENERIC-K8S.md#트러블슈팅)

### 시나리오 2: 이미 설치되어 있는 경우

1. **[README.md](README.md)** 빠른 시작 섹션
2. 필요 시 → [QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)

### 시나리오 3: 설정 변경이 필요한 경우

1. **[QUICK_REFERENCE.md - 설정 변경](docs/QUICK_REFERENCE.md#설정-변경-워크플로우)**
2. 상세 정보 → [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)

### 시나리오 4: 다른 사람과 공유하는 경우

1. **[SHARING_CHECKLIST.md](SHARING_CHECKLIST.md)** 확인
2. **[verify.sh](verify.sh)** 실행
3. **[README.md - 공유하기](README.md#프로젝트-공유하기)** 섹션 참조

### 시나리오 5: 문제가 발생한 경우

1. **[QUICK_REFERENCE.md - 트러블슈팅](docs/QUICK_REFERENCE.md#빠른-트러블슈팅)**
2. 더 자세한 내용 → [DEPLOYMENT_GUIDE.md - 트러블슈팅](docs/DEPLOYMENT_GUIDE.md#트러블슈팅)

### 시나리오 6: 템플릿 사용법을 알고 싶은 경우

1. **[DEPLOYMENT_GUIDE.md - 카탈로그 사용](docs/DEPLOYMENT_GUIDE.md#github-actions--terraform-카탈로그-사용)**

---

## 🔍 키워드별 문서 찾기

### Docker 관련
- 이미지 빌드: [SETUP.md#2단계](SETUP.md#2단계-docker-이미지-빌드)
- 이미지 공유: [README.md#공유하기](README.md#프로젝트-공유하기)

### Kubernetes 관련
- 클러스터 생성: [SETUP.md#3단계](SETUP.md#3단계-kind-클러스터-생성)
- 매니페스트 설명: [DEPLOYMENT_GUIDE.md#step-5](docs/DEPLOYMENT_GUIDE.md#step-5-kubernetes-매니페스트-작성)
- kubectl 명령어: [QUICK_REFERENCE.md#kubectl](docs/QUICK_REFERENCE.md#kubectl-명령어)

### Backstage 관련
- 설정 파일: [DEPLOYMENT_GUIDE.md#설정-구조](docs/DEPLOYMENT_GUIDE.md#설정-구조-요약)
- 템플릿 사용: [DEPLOYMENT_GUIDE.md#템플릿-사용](docs/DEPLOYMENT_GUIDE.md#github-actions--terraform-카탈로그-사용)

### 트러블슈팅
- 빠른 해결: [QUICK_REFERENCE.md#트러블슈팅](docs/QUICK_REFERENCE.md#빠른-트러블슈팅)
- 상세 가이드: [DEPLOYMENT_GUIDE.md#트러블슈팅](docs/DEPLOYMENT_GUIDE.md#트러블슈팅)

### 공유 관련
- 체크리스트: [SHARING_CHECKLIST.md](SHARING_CHECKLIST.md)
- 공유 방법: [README.md#공유하기](README.md#프로젝트-공유하기)
- 검증 스크립트: [verify.sh](verify.sh)

---

## 📝 문서 작성 원칙

이 프로젝트의 문서는 다음 원칙으로 작성되었습니다:

1. **계층적 구조**: README → SETUP → DEPLOYMENT_GUIDE
2. **실용적**: 실제 명령어와 예제 포함
3. **검증됨**: 모든 단계가 실제로 테스트됨
4. **최신 유지**: 2026-02-12 기준 최신 상태

---

## 🆘 도움이 필요한 경우

### 빠른 도움말

```bash
# 1. 문서 검색
grep -r "키워드" docs/

# 2. 특정 명령어 찾기
grep -r "kubectl\|docker\|yarn" docs/QUICK_REFERENCE.md

# 3. 트러블슈팅
cat docs/DEPLOYMENT_GUIDE.md | grep -A 10 "트러블슈팅"
```

### 추천 읽기 순서

**처음 사용자:**
1. README.md (5분)
2. SETUP.md (10분)
3. DEPLOYMENT_GUIDE.md 필요 섹션만 (10-30분)

**경험 있는 사용자:**
1. README.md (2분)
2. QUICK_REFERENCE.md (5분)

**공유하려는 사용자:**
1. SHARING_CHECKLIST.md (5분)
2. verify.sh 실행 (1분)
3. README.md 공유 섹션 (3분)

---

## 📊 문서 통계

| 문서 | 줄 수 | 크기 | 소요 시간 |
|-----|-------|------|----------|
| README.md | ~300줄 | ~15KB | 5-10분 |
| SETUP.md | ~600줄 | ~30KB | 10-20분 |
| DEPLOYMENT_GUIDE.md | ~1,500줄 | ~75KB | 30-60분 |
| QUICK_REFERENCE.md | ~500줄 | ~25KB | 10-15분 |
| SHARING_CHECKLIST.md | ~400줄 | ~20KB | 5-10분 |
| **총계** | **~3,300줄** | **~165KB** | **60-115분** |

---

## 🔄 문서 업데이트

문서 업데이트가 필요한 경우:

1. **날짜 업데이트**: 문서 하단의 "최종 업데이트" 날짜 변경
2. **버전 관리**: CHANGELOG.md 추가 (선택사항)
3. **링크 확인**: 모든 내부 링크가 작동하는지 확인

---

**작성자:** Claude Sonnet 4.5
**최종 업데이트:** 2026-02-12
**버전:** 1.0.0
**총 문서 수:** 10개 (markdown 7개, script 1개, yaml 1개, gitignore 1개)

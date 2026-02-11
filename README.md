# Backstage on Kubernetes - Demo Project

![Backstage](https://backstage.io/img/backstage-logo-cncf.svg)

로컬 Kind 클러스터에 Backstage를 배포하고, GitHub Actions + Terraform을 활용한 AWS EC2 프로비저닝 카탈로그를 구현한 데모 프로젝트입니다.

## 🎯 프로젝트 개요

이 프로젝트는 다음을 포함합니다:

- ✅ **Kind 클러스터** - 로컬 Kubernetes 환경
- ✅ **Backstage** - CNCF 오픈소스 Developer Portal
- ✅ **PostgreSQL** - Backstage 데이터베이스
- ✅ **Terraform + GitHub Actions** - IaC 자동화 템플릿
- ✅ **AWS EC2 프로비저닝** - Software Template 예제

## 🚀 빠른 시작

### 배포 환경 선택

이 프로젝트는 **두 가지 배포 방식**을 지원합니다:

| 배포 환경 | 가이드 문서 | 이미지 소스 | 용도 |
|----------|------------|------------|------|
| **🏠 Kind (로컬)** | [SETUP.md](SETUP.md) | 로컬 빌드 (`backstage:local`) | 개발, 테스트, 학습 |
| **☁️ 일반 K8s** | [SETUP-GENERIC-K8S.md](SETUP-GENERIC-K8S.md) | Docker Hub (`hyungwookhub/backstage:latest`) | 모든 K8s 클러스터 (EKS, AKS, GKE 등) |

---

### Option 1: Kind (로컬 환경) - 직접 빌드

**사전 요구사항:**
```bash
brew install kind kubectl node
npm install -g yarn
docker --version  # Docker Desktop 실행 필요
```

**빠른 시작:**
```bash
# 1. 이미지 빌드 (필수!)
cd ~/backstage-k8s-demo/backstage-app
docker image build . -f packages/backend/Dockerfile --tag backstage:local

# 2. Kind 클러스터 생성
kind create cluster --config kind-config.yaml

# 3. 이미지 로드
kind load docker-image backstage:local --name backstage

# 4. 배포
kubectl apply -f k8s/

# 5. 접속
open http://localhost:30000
```

👉 **전체 가이드:** [SETUP.md](SETUP.md)

---

### Option 2: 일반 K8s 클러스터 - Docker Hub 이미지 사용

**사전 요구사항:**
- 운영 중인 Kubernetes 클러스터 (EKS, AKS, GKE, On-premise 등)
- kubectl CLI 도구

**빠른 시작:**
```bash
# 1. 클러스터 접근 확인
kubectl cluster-info

# 2. 배포
kubectl apply -f k8s-generic/00-namespace.yaml
kubectl apply -f k8s-generic/01-postgres-secrets.yaml
kubectl apply -f k8s-generic/02-postgres-storage.yaml
kubectl apply -f k8s-generic/03-postgres-deployment.yaml
kubectl apply -f k8s-generic/04-backstage-secrets.yaml
kubectl apply -f k8s-generic/05-backstage-deployment.yaml

# 3. 접속 (LoadBalancer EXTERNAL-IP 확인)
kubectl get service backstage -n backstage
# http://<EXTERNAL-IP>
```

👉 **전체 가이드:** [SETUP-GENERIC-K8S.md](SETUP-GENERIC-K8S.md)

👉 **Docker Hub 이미지:** https://hub.docker.com/r/hyungwookhub/backstage

## 📂 프로젝트 구조

```
backstage-k8s-demo/
├── backstage-app/              # Backstage 애플리케이션
│   ├── packages/
│   │   ├── app/                # Frontend
│   │   └── backend/            # Backend API
│   ├── templates/              # Software Templates
│   │   └── terraform-ec2/      # EC2 프로비저닝 템플릿
│   └── app-config*.yaml        # 설정 파일들
├── k8s/                        # Kubernetes 매니페스트 (Kind 전용)
│   ├── 00-namespace.yaml
│   ├── 01-postgres-secrets.yaml
│   ├── 02-postgres-storage.yaml
│   ├── 03-postgres-deployment.yaml
│   ├── 04-backstage-secrets.yaml
│   └── 05-backstage-deployment.yaml  # image: backstage:local
├── k8s-generic/                # Kubernetes 매니페스트 (일반 K8s)
│   ├── 00-namespace.yaml
│   ├── 01-postgres-secrets.yaml
│   ├── 02-postgres-storage.yaml
│   ├── 03-postgres-deployment.yaml
│   ├── 04-backstage-secrets.yaml
│   └── 05-backstage-deployment.yaml  # image: hyungwookhub/backstage:latest
├── docs/                       # 문서
│   ├── DEPLOYMENT_GUIDE.md     # 상세 배포 가이드
│   └── QUICK_REFERENCE.md      # 빠른 참조 가이드
├── SETUP.md                    # Kind 환경 설치 가이드
├── SETUP-GENERIC-K8S.md        # 일반 K8s 환경 설치 가이드
└── kind-config.yaml            # Kind 클러스터 설정
```

## 📖 문서

### 주요 가이드

| 문서 | 설명 | 대상 환경 | 링크 |
|-----|------|----------|------|
| **Kind 설치 가이드** | Kind 클러스터 전용 (로컬 빌드) | Kind | [SETUP.md](SETUP.md) |
| **일반 K8s 가이드** | 모든 K8s 클러스터 (Docker Hub) | EKS, AKS, GKE, 온프렘 | [SETUP-GENERIC-K8S.md](SETUP-GENERIC-K8S.md) |
| **배포 가이드** | 전체 배포 과정 상세 설명 | 모든 환경 | [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) |
| **빠른 참조** | 자주 사용하는 명령어 모음 | 모든 환경 | [QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md) |

### 주요 내용

- ✅ Step-by-step 배포 가이드
- ✅ Kubernetes 매니페스트 설명
- ✅ Terraform 템플릿 사용법
- ✅ GitHub Actions CI/CD 설정
- ✅ 트러블슈팅 가이드
- ✅ 보안 체크리스트

## 🏗️ 아키텍처

### 시스템 구성

```
┌──────────────────────────────────────┐
│         Kind Cluster                 │
│                                      │
│  ┌──────────┐      ┌──────────┐    │
│  │PostgreSQL│◄─────┤Backstage │    │
│  │  :5432   │      │  :7007   │    │
│  └──────────┘      └──────────┘    │
│                          │          │
└──────────────────────────┼──────────┘
                           │
                    NodePort :30000
                           │
                    http://localhost:30000
```

### 템플릿 워크플로우

```
Backstage UI → GitHub Repo 생성 → GitHub Actions 실행 → Terraform Apply → AWS EC2 프로비저닝
```

## 🎓 Software Template

### AWS EC2 with Terraform

이 템플릿으로 다음을 생성할 수 있습니다:

1. **GitHub Repository**
   - Terraform 인프라 코드
   - GitHub Actions 워크플로우
   - 문서화된 README

2. **EC2 Infrastructure**
   - Security Group (HTTP, HTTPS, SSH)
   - EC2 Instance with Apache
   - Elastic IP (옵션)

3. **CI/CD Pipeline**
   - Terraform Plan (PR 시)
   - Terraform Apply (머지 시)
   - Terraform Destroy (수동)

### 템플릿 사용 예시

```yaml
# 입력 파라미터
프로젝트 이름: demo-ec2
리전: us-east-1
인스턴스 타입: t2.micro
퍼블릭 IP: true

# 출력
GitHub Repo: https://github.com/org/demo-ec2
EC2 Public IP: 54.123.45.67
Web URL: http://54.123.45.67
```

### ⚙️ AWS 크레덴셜 설정 (필수)

템플릿으로 생성된 Repository에서 GitHub Actions가 작동하려면 AWS 자격 증명을 설정해야 합니다.

#### 1. GitHub Repository Secrets 추가

생성된 Repository → `Settings` → `Secrets and variables` → `Actions`

**필수 Secrets:**
| Name | 설명 | 예시 |
|------|------|------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | `wJalrXUtn...` |
| `AWS_REGION` | AWS 리전 (선택사항) | `us-east-1` |

#### 2. AWS IAM 사용자 생성 방법

```bash
# AWS Console에서:
# 1. IAM → Users → Create user
# 2. Permissions: AmazonEC2FullAccess (또는 최소 권한)
# 3. Security credentials → Create access key
# 4. "Application running outside AWS" 선택
# 5. 생성된 Access Key를 GitHub Secrets에 추가
```

#### 3. 배포 확인

```bash
# Secrets 추가 후:
# 1. terraform/ 디렉토리 수정하여 커밋
# 2. Pull Request 생성 → Plan 결과 확인
# 3. PR 머지 → Apply 자동 실행
# 4. GitHub Actions 탭에서 실행 상태 확인
```

**⚠️ 보안 주의:**
- Access Key는 절대 코드에 포함하지 마세요
- 프로덕션 환경에서는 IAM Role + OIDC 사용 권장
- 최소 권한 원칙을 적용하세요

## 🔧 커스터마이징

### Backstage 설정 변경

```bash
# 1. 설정 파일 수정
vim backstage-app/app-config.kubernetes.yaml

# 2. 이미지 재빌드
docker image build . -f packages/backend/Dockerfile --tag backstage:local
kind load docker-image backstage:local --name backstage

# 3. 배포 재시작
kubectl rollout restart deployment/backstage -n backstage
```

### 새 템플릿 추가

```bash
# 1. 템플릿 디렉토리 생성
mkdir -p templates/my-template/skeleton

# 2. template.yaml 작성
vim templates/my-template/template.yaml

# 3. Backstage에 복사
cp -r templates/* backstage-app/templates/

# 4. app-config.kubernetes.yaml 업데이트
# catalog.locations에 새 템플릿 경로 추가

# 5. 재배포
# (위 커스터마이징 과정 참조)
```

## 🐛 트러블슈팅

### 일반적인 문제

| 문제 | 해결 방법 |
|-----|---------|
| Pod이 시작되지 않음 | `kubectl logs -n backstage <pod>` 로그 확인 |
| 포트 30000 접속 불가 | Kind 포트 매핑 확인, Service 상태 확인 |
| 템플릿이 보이지 않음 | 이미지 재빌드, catalog-info.yaml 경로 확인 |

자세한 내용은 [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md#트러블슈팅)를 참조하세요.

## 📊 리소스 요구사항

### 최소 사양

- **CPU:** 2 cores
- **메모리:** 4GB RAM
- **디스크:** 10GB 여유 공간

### 권장 사양

- **CPU:** 4 cores
- **메모리:** 8GB RAM
- **디스크:** 20GB 여유 공간

## 🔐 보안 고려사항

### ⚠️ 주의사항

이 프로젝트는 **데모 목적**으로 만들어졌습니다. 프로덕션 환경에서 사용하기 전에:

- [ ] Secret 기본값 변경 (PostgreSQL 비밀번호 등)
- [ ] 실제 GitHub Token 설정
- [ ] AWS 자격 증명 안전하게 관리
- [ ] HTTPS/TLS 설정
- [ ] 인증/인가 구현
- [ ] RBAC 설정
- [ ] Network Policy 적용

## 🧹 정리

### 전체 삭제

```bash
# Kind 클러스터 삭제
kind delete cluster --name backstage

# Docker 이미지 삭제
docker rmi backstage:local

# 프로젝트 디렉토리 삭제 (선택)
rm -rf ~/backstage-k8s-demo
```

## 🤝 프로젝트 공유하기

### 다른 사람들과 공유하는 방법

#### Option 1: GitHub Repository (권장)

```bash
# 1. GitHub에 Repository 생성
# 2. 프로젝트 업로드
cd ~/backstage-k8s-demo
git init
git add .
git commit -m "Initial commit: Backstage on K8s demo"
git remote add origin https://github.com/YOUR_ORG/backstage-k8s-demo.git
git push -u origin main

# 3. 다른 사람들이 사용
git clone https://github.com/YOUR_ORG/backstage-k8s-demo.git
cd backstage-k8s-demo
# SETUP.md 가이드 따라하기
```

#### Option 2: Docker Hub (이미지 공유)

```bash
# 1. 이미지 푸시
docker tag backstage:local YOUR_USERNAME/backstage:latest
docker push YOUR_USERNAME/backstage:latest

# 2. 다른 사람들이 사용
docker pull YOUR_USERNAME/backstage:latest
docker tag YOUR_USERNAME/backstage:latest backstage:local
kind load docker-image backstage:local --name backstage
kubectl apply -f k8s/
```

#### Option 3: TAR 파일 (로컬 공유)

```bash
# 1. 이미지 저장
docker save backstage:local -o backstage-image.tar

# 2. 프로젝트와 함께 공유
tar czf backstage-k8s-demo.tar.gz backstage-k8s-demo/ backstage-image.tar

# 3. 받는 사람이 사용
tar xzf backstage-k8s-demo.tar.gz
docker load -i backstage-image.tar
cd backstage-k8s-demo
# 3단계부터 진행 (SETUP.md 참조)
```

### 공유 시 주의사항

⚠️ **다음은 공유하지 마세요:**
- `k8s/04-backstage-secrets.yaml` - 실제 비밀번호 포함 시
- `.env` 파일 - AWS 자격 증명 등
- `node_modules/` - 용량이 큼 (재설치 가능)
- Docker 이미지 (1.5GB) - 직접 빌드 권장

✅ **공유해야 할 것:**
- 소스 코드 (`backstage-app/`)
- Kubernetes 매니페스트 (`k8s/`)
- 템플릿 (`templates/`)
- 문서 (`docs/`, `README.md`, `SETUP.md`)
- 설정 파일 (`kind-config.yaml`)

---

## 📚 참고 자료

### 공식 문서

- [Backstage 공식 문서](https://backstage.io/docs)
- [Backstage GitHub](https://github.com/backstage/backstage)
- [Kind 문서](https://kind.sigs.k8s.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### 커뮤니티

- [Backstage Discord](https://discord.gg/backstage-687207715902193673)
- [CNCF Backstage](https://www.cncf.io/projects/backstage/)

## 🤝 기여

이 프로젝트는 학습 및 데모 목적으로 만들어졌습니다.
개선 사항이나 버그를 발견하시면 이슈를 등록해주세요.

## 📝 라이선스

이 프로젝트는 MIT 라이선스 하에 제공됩니다.

## 👨‍💻 작성자

**Created by:** Claude Sonnet 4.5
**Date:** 2026-02-11
**Version:** 1.0.0

---

## ⭐ 주요 기능

- ✅ Kind 클러스터에 Backstage 배포
- ✅ PostgreSQL 통합
- ✅ GitHub Actions + Terraform 템플릿
- ✅ AWS EC2 자동 프로비저닝
- ✅ 완전한 CI/CD 파이프라인
- ✅ 상세한 배포 가이드
- ✅ 트러블슈팅 가이드

## 🎯 다음 단계

1. **추가 템플릿 개발**
   - Lambda 함수 배포
   - RDS 데이터베이스 생성
   - S3 버킷 관리

2. **프로덕션 준비**
   - 외부 데이터베이스 사용
   - Ingress Controller 설정
   - 모니터링 & 로깅

3. **고급 기능**
   - TechDocs 활성화
   - Kubernetes 플러그인 설정
   - 커스텀 플러그인 개발

---

**Happy Hacking! 🚀**

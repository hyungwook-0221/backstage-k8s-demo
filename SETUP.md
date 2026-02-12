# 🚀 처음부터 설치하기 (Setup from Scratch)

다른 사람들이 이 프로젝트를 **완전히 재현**할 수 있도록 하는 단계별 가이드입니다.

## 📋 사전 요구사항

### 필수 도구 설치

```bash
# macOS (Homebrew 사용)
brew install kind kubectl node

# Node.js & Yarn
npm install -g yarn

# Docker Desktop 실행 확인
docker ps
```

### 버전 확인

```bash
docker --version      # 20.10+
kind --version        # 0.20+
kubectl version       # 1.28+
node --version        # 20+
yarn --version        # 1.22+
```

## 📦 1단계: 프로젝트 다운로드

### Option A: Git Clone (권장)

```bash
# GitHub에 업로드된 경우
git clone https://github.com/YOUR_ORG/backstage-k8s-demo.git
cd backstage-k8s-demo
```

### Option B: ZIP 다운로드

```bash
# ZIP 파일을 받아서 압축 해제
unzip backstage-k8s-demo.zip
cd backstage-k8s-demo
```

### Option C: 로컬 복사

```bash
# 이 머신에서 다른 위치로 복사
cp -r ~/backstage-k8s-demo ~/my-location/
cd ~/my-location/backstage-k8s-demo
```

## 🏗️ 2단계: Docker 이미지 빌드

**중요**: Docker 이미지는 포함되어 있지 않으므로 직접 빌드해야 합니다!

```bash
# 1. backstage-app 디렉토리로 이동
cd backstage-app

# 2. 의존성 설치 (최초 1회, 5-10분 소요)
yarn install

# 3. TypeScript 컴파일 (2-3분 소요)
yarn tsc

# 4. Backend 빌드 (3-5분 소요)
yarn build:backend

# 5. Docker 이미지 빌드 (2-3분 소요)
docker image build . -f packages/backend/Dockerfile --tag backstage:local

# 6. 이미지 확인
docker images | grep backstage
```

**💡 참고: 멀티 아키텍처 빌드 (선택사항)**

다른 아키텍처에서도 사용하려면:
```bash
# Buildx로 멀티 아키텍처 빌드 (amd64 + arm64)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f packages/backend/Dockerfile \
  -t backstage:local \
  --load \
  .
```

**참고:**
- 로컬 Kind 클러스터에서는 현재 아키텍처 이미지만 있으면 됨
- Docker Hub 공개 이미지는 이미 멀티 아키텍처 지원
- 자세한 내용: [SETUP-GENERIC-K8S.md](SETUP-GENERIC-K8S.md)
```

**예상 출력:**
```
backstage   local   abc123def456   2 minutes ago   1.5GB
```

## 🎪 3단계: Kind 클러스터 생성

```bash
# 프로젝트 루트로 이동
cd ..  # backstage-app에서 나가기

# Kind 클러스터 생성 (1-2분 소요)
kind create cluster --config kind-config.yaml

# 클러스터 확인
kubectl cluster-info --context kind-backstage
kubectl get nodes
```

**예상 출력:**
```
NAME                      STATUS   ROLES           AGE   VERSION
backstage-control-plane   Ready    control-plane   30s   v1.35.0
```

## 📥 4단계: 이미지 로드

**중요**: Kind 클러스터에 로컬 이미지를 로드해야 합니다!

```bash
# Docker 이미지를 Kind에 로드 (1-2분 소요)
kind load docker-image backstage:local --name backstage

# 확인
docker exec -it backstage-control-plane crictl images | grep backstage
```

## 🚀 5단계: Kubernetes 리소스 배포

```bash
# 모든 매니페스트 적용
kubectl apply -f k8s/

# 배포 확인 (2-3분 대기)
kubectl get pods -n backstage -w
```

**Ctrl+C로 watch 종료 후 확인:**
```bash
kubectl get pods -n backstage
```

**예상 출력:**
```
NAME                         READY   STATUS    RESTARTS   AGE
backstage-xxx                1/1     Running   0          2m
postgres-xxx                 1/1     Running   0          2m
```

## 🌐 6단계: 접속 확인

### 브라우저 접속

```
http://localhost:30000
```

### Health Check

```bash
curl http://localhost:30000/healthcheck
```

**정상 응답:** HTML 또는 JSON 리턴

### Context 확인 (중요!)

다른 Kubernetes 클러스터를 사용 중이라면:

```bash
# 현재 context 확인
kubectl config current-context

# kind-backstage가 아니면 전환
kubectl config use-context kind-backstage
```

## 🎯 전체 과정 요약 (한 번에)

```bash
# 1. 프로젝트 디렉토리로 이동
cd backstage-k8s-demo

# 2. 이미지 빌드
cd backstage-app
yarn install
yarn tsc
yarn build:backend
docker image build . -f packages/backend/Dockerfile --tag backstage:local
cd ..

# 3. 클러스터 생성
kind create cluster --config kind-config.yaml

# 4. 이미지 로드
kind load docker-image backstage:local --name backstage

# 5. 리소스 배포
kubectl apply -f k8s/

# 6. 대기 및 확인
sleep 120
kubectl get pods -n backstage
open http://localhost:30000
```

**총 소요 시간:** 약 15-20분

## 🐛 트러블슈팅

### 문제 1: "backstage:local" 이미지를 찾을 수 없음

**증상:**
```
Failed to pull image "backstage:local"
```

**해결:**
```bash
# 이미지 빌드 단계를 다시 실행
cd backstage-app
docker image build . -f packages/backend/Dockerfile --tag backstage:local
cd ..
kind load docker-image backstage:local --name backstage
kubectl rollout restart deployment/backstage -n backstage
```

### 문제 2: Pod이 CrashLoopBackOff

**확인:**
```bash
kubectl logs -n backstage deployment/backstage --tail=50
```

**일반적인 원인:**
- PostgreSQL 미준비 → 1-2분 대기
- 설정 오류 → 로그 확인

### 문제 3: 401 Unauthorized

**해결:**
```bash
# Context 확인
kubectl config use-context kind-backstage

# Pod 재시작
kubectl rollout restart deployment/backstage -n backstage
```

### 문제 4: Port 30000이 이미 사용 중

**확인:**
```bash
lsof -i :30000
```

**해결:**
- 다른 프로세스 종료
- 또는 kind-config.yaml에서 포트 변경

## 📚 다음 단계

설치가 완료되면:

1. **템플릿 사용**: [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md#github-actions--terraform-카탈로그-사용)
2. **설정 변경**: [QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md#설정-변경-워크플로우)
3. **문서 읽기**: [README.md](README.md)

## 🔧 자주 묻는 질문 (FAQ)

### Q1: 이미지를 Docker Hub에 올릴 수 있나요?

**A:** 네, 가능합니다:

```bash
# 이미지 태그 추가
docker tag backstage:local YOUR_USERNAME/backstage:latest

# Docker Hub에 푸시
docker login
docker push YOUR_USERNAME/backstage:latest

# 다른 사람이 사용
docker pull YOUR_USERNAME/backstage:latest
docker tag YOUR_USERNAME/backstage:latest backstage:local
kind load docker-image backstage:local --name backstage
```

### Q2: 이미 빌드된 이미지를 공유할 수 있나요?

**A:** 네, 가능합니다:

```bash
# 이미지 저장
docker save backstage:local -o backstage-image.tar

# 파일 공유 후
# 다른 사람이 로드
docker load -i backstage-image.tar
kind load docker-image backstage:local --name backstage
```

**주의**: 이미지 크기가 ~1.5GB이므로 파일 공유가 어려울 수 있습니다.

### Q3: Windows/Linux에서도 작동하나요?

**A:** 네, 다음 차이점만 주의하세요:

**Windows (WSL2):**
```powershell
# Docker Desktop for Windows 필요
# Kind, kubectl는 WSL2 내부에서 설치
```

**Linux:**
```bash
# apt/yum으로 도구 설치
sudo apt-get install docker.io
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
```

### Q4: 기존 클러스터를 삭제하고 다시 시작하려면?

**A:**
```bash
# 클러스터 삭제
kind delete cluster --name backstage

# 이미지는 보존되므로 3단계부터 다시 시작
kind create cluster --config kind-config.yaml
kind load docker-image backstage:local --name backstage
kubectl apply -f k8s/
```

### Q5: 프로덕션 환경에서 사용할 수 있나요?

**A:** 이 프로젝트는 **데모/학습 목적**입니다. 프로덕션 사용 전:

- ✅ Secret 변경 (기본 비밀번호 사용 중)
- ✅ 외부 데이터베이스 사용
- ✅ Ingress/TLS 설정
- ✅ 실제 OAuth 인증 (GitHub, Google 등)
- ✅ RBAC 설정
- ✅ 모니터링/로깅 추가

자세한 내용: [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md#다음-단계)

## 📞 도움말

문제가 발생하면:

1. **로그 확인**: `kubectl logs -n backstage deployment/backstage`
2. **문서 확인**: [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md#트러블슈팅)
3. **Quick Reference**: [QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)

---

**작성자:** Claude Sonnet 4.5
**최종 업데이트:** 2026-02-12
**버전:** 1.0.0

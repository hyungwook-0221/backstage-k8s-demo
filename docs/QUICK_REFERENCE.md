# Backstage on Kubernetes - 빠른 참조 가이드

## 🚀 빠른 시작

### 클러스터 생성부터 배포까지 (5분)

```bash
# 1. 클러스터 생성
cd ~/backstage-k8s-demo
kind create cluster --config kind-config.yaml

# 2. 이미지 로드
kind load docker-image backstage:local --name backstage

# 3. 리소스 배포
kubectl apply -f k8s/

# 4. 상태 확인
kubectl get pods -n backstage -w
```

### 접속

- **Backstage UI:** http://localhost:30000
- **Health Check:** http://localhost:30000/healthcheck

---

## 📝 자주 사용하는 명령어

### Kubectl 명령어

```bash
# Pod 상태 확인
kubectl get pods -n backstage

# 실시간 로그 확인
kubectl logs -n backstage deployment/backstage -f

# Pod 재시작
kubectl rollout restart deployment/backstage -n backstage

# 전체 리소스 확인
kubectl get all -n backstage

# Secret 확인
kubectl get secrets -n backstage

# ConfigMap 확인
kubectl get configmaps -n backstage
```

### Docker 명령어

```bash
# 이미지 빌드
docker image build . -f packages/backend/Dockerfile --tag backstage:local

# 이미지 확인
docker images | grep backstage

# Kind에 이미지 로드
kind load docker-image backstage:local --name backstage

# 이미지 삭제
docker rmi backstage:local
```

### Kind 명령어

```bash
# 클러스터 목록
kind get clusters

# 클러스터 상태 확인
kubectl cluster-info --context kind-backstage

# 클러스터 삭제
kind delete cluster --name backstage

# 노드 확인
kubectl get nodes
```

---

## 🔧 설정 변경 워크플로우

### Backstage 설정 변경

1. **설정 파일 수정**
```bash
cd ~/backstage-k8s-demo/backstage-app
vim app-config.kubernetes.yaml
```

2. **이미지 재빌드**
```bash
docker image build . -f packages/backend/Dockerfile --tag backstage:local
```

3. **Kind에 로드**
```bash
kind load docker-image backstage:local --name backstage
```

4. **배포 재시작**
```bash
kubectl rollout restart deployment/backstage -n backstage
```

5. **상태 확인**
```bash
kubectl get pods -n backstage -w
kubectl logs -n backstage deployment/backstage --tail=50
```

### Secret 변경

```bash
# Secret 삭제
kubectl delete secret backstage-secrets -n backstage

# 새 Secret 적용
kubectl apply -f k8s/04-backstage-secrets.yaml

# Deployment 재시작
kubectl rollout restart deployment/backstage -n backstage
```

---

## 🐛 빠른 트러블슈팅

### Pod이 시작되지 않을 때

```bash
# 1. Pod 상태 확인
kubectl get pods -n backstage

# 2. 상세 정보 확인
kubectl describe pod -n backstage <pod-name>

# 3. 로그 확인
kubectl logs -n backstage <pod-name>

# 4. 이전 로그 확인 (재시작된 경우)
kubectl logs -n backstage <pod-name> --previous
```

### 설정 오류 디버깅

```bash
# ConfigMap 내용 확인
kubectl get configmap -n backstage -o yaml

# Secret 키 확인 (값은 base64 인코딩됨)
kubectl get secret backstage-secrets -n backstage -o yaml

# 환경 변수 확인
kubectl exec -n backstage <pod-name> -- env | grep POSTGRES
```

### 네트워크 연결 테스트

```bash
# PostgreSQL 연결 테스트
kubectl exec -n backstage <backstage-pod> -- nc -zv postgres 5432

# DNS 확인
kubectl exec -n backstage <backstage-pod> -- nslookup postgres

# 내부 접속 테스트
kubectl exec -n backstage <backstage-pod> -- curl http://localhost:7007/healthcheck
```

---

## 📊 모니터링

### 리소스 사용량 확인

```bash
# Pod 리소스 사용량
kubectl top pods -n backstage

# 노드 리소스 사용량
kubectl top nodes

# Describe로 상세 정보
kubectl describe pod -n backstage <pod-name> | grep -A 5 Resources
```

### 이벤트 확인

```bash
# 네임스페이스 이벤트
kubectl get events -n backstage --sort-by='.lastTimestamp'

# 특정 Pod 이벤트
kubectl describe pod -n backstage <pod-name> | grep -A 10 Events
```

---

## 🔄 업데이트 프로세스

### 1. Backstage 버전 업그레이드

```bash
cd ~/backstage-k8s-demo/backstage-app

# 패키지 업데이트
yarn backstage-cli versions:bump

# 의존성 설치
yarn install

# 빌드
yarn tsc
yarn build:backend

# 이미지 빌드 및 배포
docker image build . -f packages/backend/Dockerfile --tag backstage:local
kind load docker-image backstage:local --name backstage
kubectl rollout restart deployment/backstage -n backstage
```

### 2. 템플릿 추가/수정

```bash
# 1. 템플릿 수정
vim templates/terraform-ec2/template.yaml

# 2. Backstage 앱에 복사
cp -r templates/* backstage-app/templates/

# 3. 이미지 재빌드 및 배포
cd backstage-app
docker image build . -f packages/backend/Dockerfile --tag backstage:local
kind load docker-image backstage:local --name backstage
kubectl rollout restart deployment/backstage -n backstage
```

---

## 📦 백업 및 복원

### 데이터베이스 백업

```bash
# PostgreSQL Pod 이름 확인
POSTGRES_POD=$(kubectl get pod -n backstage -l app=postgres -o jsonpath='{.items[0].metadata.name}')

# 백업 생성
kubectl exec -n backstage $POSTGRES_POD -- pg_dump -U backstage backstage > backstage-backup.sql

# 백업 파일 확인
ls -lh backstage-backup.sql
```

### 데이터베이스 복원

```bash
# 백업 파일을 Pod에 복사
kubectl cp backstage-backup.sql backstage/$POSTGRES_POD:/tmp/

# 복원 실행
kubectl exec -n backstage $POSTGRES_POD -- psql -U backstage backstage < /tmp/backstage-backup.sql
```

---

## 🎯 성능 최적화 팁

### 리소스 조정

```yaml
# Backstage Deployment에서 리소스 조정
resources:
  requests:
    memory: "1Gi"      # 증가
    cpu: "1000m"       # 증가
  limits:
    memory: "2Gi"      # 증가
    cpu: "2000m"       # 증가
```

### 이미지 빌드 최적화

```bash
# Docker BuildKit 사용
DOCKER_BUILDKIT=1 docker image build \
  . -f packages/backend/Dockerfile \
  --tag backstage:local

# 빌드 캐시 활용
docker image build \
  --cache-from backstage:local \
  . -f packages/backend/Dockerfile \
  --tag backstage:local
```

---

## 🔐 보안 체크리스트

### 배포 전 확인사항

- [ ] Secret에 실제 비밀번호 사용 (기본값 변경)
- [ ] GitHub Token 설정 (실제 값 사용)
- [ ] AWS 자격 증명 확인
- [ ] PostgreSQL 비밀번호 변경
- [ ] 불필요한 포트 노출 제거
- [ ] RBAC 설정 확인

### 운영 중 모니터링

- [ ] 비인가 접근 시도 로그 확인
- [ ] Resource Quota 설정
- [ ] Network Policy 적용
- [ ] Pod Security Policy/Standards 적용

---

## 📚 유용한 스크립트

### 전체 재배포

```bash
#!/bin/bash
cd ~/backstage-k8s-demo/backstage-app
docker image build . -f packages/backend/Dockerfile --tag backstage:local
kind load docker-image backstage:local --name backstage
kubectl rollout restart deployment/backstage -n backstage
kubectl rollout status deployment/backstage -n backstage
echo "Deployment complete! Access at http://localhost:30000"
```

### 로그 모니터링

```bash
#!/bin/bash
kubectl logs -n backstage deployment/backstage -f | \
  grep -E "error|Error|ERROR|warn|Warning|WARN" --color=always
```

### 헬스 체크

```bash
#!/bin/bash
echo "Checking Backstage health..."
curl -s http://localhost:30000/healthcheck | jq .
echo ""
echo "Pod Status:"
kubectl get pods -n backstage
```

---

## 🎓 학습 리소스

### 튜토리얼

1. **Backstage 기본:**
   - https://backstage.io/docs/getting-started/

2. **Software Templates:**
   - https://backstage.io/docs/features/software-templates/

3. **Kubernetes 배포:**
   - https://backstage.io/docs/deployment/k8s

### 예제 프로젝트

- Backstage 공식 데모: https://demo.backstage.io/
- Software Templates 저장소: https://github.com/backstage/software-templates

---

**Tip:** 이 가이드를 프린트하거나 즐겨찾기에 추가하여 빠르게 참조하세요!

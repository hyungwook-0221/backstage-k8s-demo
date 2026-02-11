# Backstage 일반 K8s 클러스터 배포 가이드

Docker Hub의 공개 이미지를 사용하여 **어떤 Kubernetes 클러스터에서든** Backstage를 배포하는 가이드입니다.

## 🎯 대상 환경

이 가이드는 다음과 같은 환경에서 사용할 수 있습니다:

- ✅ AWS EKS
- ✅ Azure AKS
- ✅ Google GKE
- ✅ On-premise Kubernetes
- ✅ Minikube
- ✅ K3s
- ✅ 기타 모든 Kubernetes 클러스터 (v1.21+)

## 📋 사전 요구사항

### 1. Kubernetes 클러스터

이미 운영 중인 Kubernetes 클러스터가 필요합니다.

```bash
# 클러스터 접근 확인
kubectl cluster-info
kubectl get nodes

# 버전 확인 (1.21 이상 권장)
kubectl version --short
```

### 2. 필수 도구

```bash
# kubectl 설치 (없는 경우)
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Windows
choco install kubernetes-cli
```

### 3. 클러스터 리소스 요구사항

**최소 사양:**
- CPU: 2 cores
- Memory: 4GB RAM
- Storage: 10GB

**권장 사양:**
- CPU: 4 cores
- Memory: 8GB RAM
- Storage: 20GB

---

## 🚀 배포 단계

### 1단계: 프로젝트 준비

```bash
# 프로젝트 클론 또는 다운로드
git clone https://github.com/YOUR_ORG/backstage-k8s-demo.git
cd backstage-k8s-demo

# 또는 ZIP 파일 압축 해제
unzip backstage-k8s-demo.zip
cd backstage-k8s-demo
```

### 2단계: Namespace 생성

```bash
kubectl apply -f k8s-generic/00-namespace.yaml
```

**확인:**
```bash
kubectl get namespace backstage
```

### 3단계: PostgreSQL 배포

#### 3-1. Secrets 생성

```bash
kubectl apply -f k8s-generic/01-postgres-secrets.yaml
```

**⚠️ 프로덕션 사용 시:**
Secret 값을 반드시 변경하세요!

```bash
# Base64 인코딩된 새 비밀번호 생성
echo -n 'your-new-password' | base64

# Secret 파일 수정
vim k8s-generic/01-postgres-secrets.yaml
```

#### 3-2. 영구 스토리지 생성

```bash
kubectl apply -f k8s-generic/02-postgres-storage.yaml
```

**클라우드별 StorageClass:**

```yaml
# AWS EKS
storageClassName: gp2  # 또는 gp3

# Azure AKS
storageClassName: managed-premium  # 또는 managed

# Google GKE
storageClassName: standard-rwo  # 또는 premium-rwo

# On-premise (기본값)
storageClassName: standard
```

**StorageClass 확인:**
```bash
kubectl get storageclass
```

필요시 `k8s-generic/02-postgres-storage.yaml` 파일에서 수정:
```yaml
spec:
  storageClassName: gp3  # 환경에 맞게 변경
```

#### 3-3. PostgreSQL 배포

```bash
kubectl apply -f k8s-generic/03-postgres-deployment.yaml
```

**배포 확인:**
```bash
# Pod 상태 확인
kubectl get pods -n backstage -l app=postgres

# 로그 확인
kubectl logs -n backstage -l app=postgres

# 대기 (Ready 상태까지)
kubectl wait --for=condition=ready pod -l app=postgres -n backstage --timeout=300s
```

### 4단계: Backstage 배포

#### 4-1. Backstage Secrets 생성

```bash
kubectl apply -f k8s-generic/04-backstage-secrets.yaml
```

**⚠️ 중요: GitHub Token 설정**

실제 GitHub Token을 사용하려면:

1. GitHub에서 Personal Access Token 생성:
   - https://github.com/settings/tokens
   - Scopes: `repo`, `workflow`, `write:packages`

2. Secret 파일 수정:
```bash
vim k8s-generic/04-backstage-secrets.yaml
```

3. `GITHUB_TOKEN` 값을 실제 토큰으로 변경:
```yaml
stringData:
  GITHUB_TOKEN: "ghp_your_real_token_here"
```

#### 4-2. Backstage 배포

```bash
kubectl apply -f k8s-generic/05-backstage-deployment.yaml
```

**배포 확인:**
```bash
# Pod 상태 확인
kubectl get pods -n backstage -l app=backstage

# 실시간 로그 확인
kubectl logs -n backstage -l app=backstage -f

# 대기 (Ready 상태까지, 최대 5분)
kubectl wait --for=condition=ready pod -l app=backstage -n backstage --timeout=300s
```

### 5단계: 서비스 접근

기본적으로 `LoadBalancer` 타입으로 배포됩니다.

#### Option 1: LoadBalancer (클라우드 환경)

```bash
# 외부 IP 확인
kubectl get service backstage -n backstage

# 출력 예시:
# NAME        TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)
# backstage   LoadBalancer   10.100.200.1    52.123.45.67     80:31234/TCP
```

**접속:**
```bash
# EXTERNAL-IP 확인 후
http://<EXTERNAL-IP>

# 예시
http://52.123.45.67
```

#### Option 2: ClusterIP + Ingress

LoadBalancer를 사용하지 않는다면 ClusterIP + Ingress를 사용하세요.

**Service 타입 변경:**
```bash
vim k8s-generic/05-backstage-deployment.yaml

# type을 LoadBalancer → ClusterIP로 변경
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 7007
```

**Ingress 예시 (NGINX Ingress):**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: backstage-ingress
  namespace: backstage
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: backstage.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backstage
            port:
              number: 80
```

#### Option 3: NodePort (테스트 환경)

**Service 타입 변경:**
```bash
vim k8s-generic/05-backstage-deployment.yaml

# type을 LoadBalancer → NodePort로 변경
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 7007
    nodePort: 30000  # 30000-32767 범위
```

**접속:**
```bash
# Node IP 확인
kubectl get nodes -o wide

# 접속
http://<NODE-IP>:30000
```

#### Option 4: Port Forward (로컬 테스트)

```bash
kubectl port-forward -n backstage service/backstage 7007:80
```

**접속:**
```
http://localhost:7007
```

---

## ✅ 배포 검증

### 1. 모든 리소스 확인

```bash
# 모든 리소스 조회
kubectl get all -n backstage

# 예상 출력:
# NAME                            READY   STATUS    RESTARTS   AGE
# pod/backstage-xxxxxxxxx-xxxxx   1/1     Running   0          5m
# pod/postgres-xxxxxxxxx-xxxxx    1/1     Running   0          10m
#
# NAME                TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)
# service/backstage   LoadBalancer   10.100.1.1     52.1.2.3       80:31234/TCP
# service/postgres    ClusterIP      10.100.1.2     <none>         5432/TCP
#
# NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/backstage   1/1     1            1           5m
# deployment.apps/postgres    1/1     1            1           10m
```

### 2. Pod 상태 확인

```bash
kubectl get pods -n backstage

# 모두 Running 상태여야 함
```

### 3. 로그 확인

```bash
# Backstage 로그
kubectl logs -n backstage -l app=backstage --tail=50

# PostgreSQL 로그
kubectl logs -n backstage -l app=postgres --tail=50
```

### 4. 상태 체크

```bash
# Backstage Health Check
kubectl exec -n backstage deploy/backstage -- curl -f http://localhost:7007/healthcheck

# 성공 시: {"status":"ok"}
```

### 5. 브라우저 접속 테스트

1. 외부 IP 또는 설정한 접근 방법으로 접속
2. Backstage UI가 로드되는지 확인
3. "Create" 메뉴에서 템플릿이 보이는지 확인

---

## 🔧 커스터마이징

### 이미지 버전 변경

다른 버전을 사용하려면:

```bash
vim k8s-generic/05-backstage-deployment.yaml

# image 수정
image: hyungwookhub/backstage:v1.0.0  # 특정 버전
# 또는
image: hyungwookhub/backstage:latest  # 최신 버전
```

### 리소스 제한 조정

```yaml
# k8s-generic/05-backstage-deployment.yaml
resources:
  requests:
    memory: "1Gi"      # 기본: 512Mi
    cpu: "1000m"       # 기본: 500m
  limits:
    memory: "2Gi"      # 기본: 1Gi
    cpu: "2000m"       # 기본: 1000m
```

### 레플리카 증가

```yaml
# k8s-generic/05-backstage-deployment.yaml
spec:
  replicas: 3  # 기본: 1
```

### PostgreSQL 외부 데이터베이스 사용

프로덕션에서는 외부 관리형 데이터베이스 사용을 권장합니다:

```bash
# Secret 수정
vim k8s-generic/04-backstage-secrets.yaml
```

```yaml
stringData:
  POSTGRES_HOST: "your-rds-endpoint.rds.amazonaws.com"  # AWS RDS
  # 또는
  POSTGRES_HOST: "your-cloudsql-instance"               # GCP Cloud SQL
  # 또는
  POSTGRES_HOST: "your-postgres-server.postgres.database.azure.com"  # Azure
  POSTGRES_PORT: "5432"
  POSTGRES_USER: "backstage"
  POSTGRES_PASSWORD: "your-secure-password"
```

**PostgreSQL 배포 건너뛰기:**
```bash
# 02, 03 파일 적용하지 않음
kubectl apply -f k8s-generic/00-namespace.yaml
kubectl apply -f k8s-generic/01-postgres-secrets.yaml
kubectl apply -f k8s-generic/04-backstage-secrets.yaml
kubectl apply -f k8s-generic/05-backstage-deployment.yaml
```

---

## 🐛 트러블슈팅

### Pod이 ImagePullBackOff 상태

**원인:** 이미지를 Pull할 수 없음

**해결:**
```bash
# 1. 이미지가 public인지 확인
docker pull hyungwookhub/backstage:latest

# 2. Private인 경우 ImagePullSecret 생성
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=hyungwookhub \
  --docker-password=YOUR_PASSWORD \
  --docker-email=YOUR_EMAIL \
  -n backstage

# 3. Deployment에 추가
vim k8s-generic/05-backstage-deployment.yaml
```

```yaml
spec:
  imagePullSecrets:
  - name: dockerhub-secret
  containers:
  - name: backstage
    # ...
```

### Pod이 CrashLoopBackOff 상태

**원인:** 애플리케이션 시작 실패

**해결:**
```bash
# 로그 확인
kubectl logs -n backstage -l app=backstage --tail=100

# 일반적인 원인:
# 1. PostgreSQL 연결 실패 → Secret 확인
# 2. 설정 오류 → 이미지 재빌드 필요
# 3. 리소스 부족 → 리소스 limits 증가
```

### PostgreSQL PVC가 Pending 상태

**원인:** StorageClass가 없거나 PV 프로비저닝 실패

**해결:**
```bash
# 1. StorageClass 확인
kubectl get storageclass

# 2. 없는 경우 기본 StorageClass 설정
kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# 3. 또는 다른 StorageClass 사용
vim k8s-generic/02-postgres-storage.yaml
# storageClassName 변경

# 4. PVC 재생성
kubectl delete pvc postgres-pvc -n backstage
kubectl apply -f k8s-generic/02-postgres-storage.yaml
```

### LoadBalancer EXTERNAL-IP가 <pending>

**원인:** 클러스터가 LoadBalancer를 지원하지 않음

**해결:**

**Option 1: MetalLB 설치 (On-premise)**
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
```

**Option 2: NodePort 사용**
```bash
vim k8s-generic/05-backstage-deployment.yaml
# type: LoadBalancer → NodePort 변경
```

**Option 3: Ingress 사용**
- NGINX Ingress Controller 설치
- Ingress 리소스 생성 (위 예시 참조)

### 401 Unauthorized 에러

**원인:** Guest 인증이 비활성화됨

**해결:**

이 이미지는 이미 guest 인증이 활성화되어 있습니다. 하지만 만약 커스텀 이미지를 사용한다면:

```yaml
# app-config.kubernetes.yaml
auth:
  providers:
    guest:
      dangerouslyAllowOutsideDevelopment: true
```

---

## 🧹 정리

### 전체 삭제

```bash
# Backstage 네임스페이스 전체 삭제
kubectl delete namespace backstage

# 확인
kubectl get namespace backstage
# Error from server (NotFound): namespaces "backstage" not found
```

### 개별 리소스 삭제

```bash
# 역순으로 삭제
kubectl delete -f k8s-generic/05-backstage-deployment.yaml
kubectl delete -f k8s-generic/04-backstage-secrets.yaml
kubectl delete -f k8s-generic/03-postgres-deployment.yaml
kubectl delete -f k8s-generic/02-postgres-storage.yaml
kubectl delete -f k8s-generic/01-postgres-secrets.yaml
kubectl delete -f k8s-generic/00-namespace.yaml
```

---

## 🔐 프로덕션 체크리스트

프로덕션 환경에 배포하기 전에:

- [ ] PostgreSQL 비밀번호 변경
- [ ] 실제 GitHub Token 설정
- [ ] 외부 관리형 데이터베이스 사용 (RDS, Cloud SQL 등)
- [ ] HTTPS/TLS 설정 (Ingress + cert-manager)
- [ ] 리소스 제한 적절히 설정
- [ ] 백업 전략 수립
- [ ] 모니터링 설정 (Prometheus, Grafana)
- [ ] 로깅 설정 (ELK, Loki)
- [ ] RBAC 설정
- [ ] Network Policy 적용
- [ ] Pod Security Standards 적용
- [ ] 정기적인 업데이트 계획

---

## 📊 리소스 사용량

**기본 배포 시:**

```
NAMESPACE   NAME         CPU(cores)   MEMORY(bytes)
backstage   backstage    500m-1000m   512Mi-1Gi
backstage   postgres     100m-250m    256Mi-512Mi
-------------------------------------------------
Total                    600m-1250m   768Mi-1.5Gi
```

---

## 🆚 Kind vs 일반 K8s 비교

| 항목 | Kind (로컬) | 일반 K8s (클라우드/온프렘) |
|-----|-------------|---------------------------|
| **이미지** | `backstage:local` (직접 빌드) | `hyungwookhub/backstage:latest` (Docker Hub) |
| **이미지 Pull** | `imagePullPolicy: Never` | `imagePullPolicy: Always` |
| **이미지 로드** | `kind load docker-image` 필요 | 자동으로 Docker Hub에서 Pull |
| **서비스 타입** | `NodePort` (30000) | `LoadBalancer`, `Ingress`, `NodePort` |
| **접근 방법** | `localhost:30000` | External IP, Ingress URL, NodePort |
| **포트 매핑** | `kind-config.yaml`에 명시 필요 | 불필요 |
| **스토리지** | 로컬 PV | 클라우드 PV (EBS, Disk 등) |
| **고가용성** | 단일 노드 | 멀티 노드, 리전 분산 가능 |
| **프로덕션 사용** | ❌ 불가능 | ✅ 가능 |

---

## 🔗 관련 문서

- [Kind 환경 가이드](SETUP.md) - Kind 클러스터 전용 가이드
- [배포 가이드](docs/DEPLOYMENT_GUIDE.md) - 상세 배포 가이드
- [빠른 참조](docs/QUICK_REFERENCE.md) - 자주 사용하는 명령어
- [Docker Hub 이미지](https://hub.docker.com/r/hyungwookhub/backstage)

---

## 📝 요약

**일반 K8s 클러스터에 배포하는 3단계:**

```bash
# 1. Namespace 및 PostgreSQL 배포
kubectl apply -f k8s-generic/00-namespace.yaml
kubectl apply -f k8s-generic/01-postgres-secrets.yaml
kubectl apply -f k8s-generic/02-postgres-storage.yaml
kubectl apply -f k8s-generic/03-postgres-deployment.yaml

# 2. Backstage 배포
kubectl apply -f k8s-generic/04-backstage-secrets.yaml
kubectl apply -f k8s-generic/05-backstage-deployment.yaml

# 3. 접속
kubectl get service backstage -n backstage
# EXTERNAL-IP로 접속
```

**전체 과정 소요 시간:** 5-10분

---

**작성자:** Claude Sonnet 4.5
**최종 업데이트:** 2026-02-12
**버전:** 1.0.0
**Docker Hub 이미지:** `hyungwookhub/backstage:latest`

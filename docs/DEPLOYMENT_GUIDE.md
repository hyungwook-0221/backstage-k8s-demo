# Backstage on Kubernetes 배포 가이드

이 가이드는 로컬 Kind 클러스터에 Backstage를 배포하고, GitHub Actions와 Terraform을 연계한 EC2 프로비저닝 카탈로그를 설정하는 전체 과정을 설명합니다.

## 📋 목차

1. [사전 요구사항](#사전-요구사항)
2. [아키텍처 개요](#아키텍처-개요)
3. [Step-by-Step 배포 가이드](#step-by-step-배포-가이드)
4. [GitHub Actions + Terraform 카탈로그 사용](#github-actions--terraform-카탈로그-사용)
5. [트러블슈팅](#트러블슈팅)
6. [리소스 정리](#리소스-정리)

---

## 사전 요구사항

### 필수 도구

다음 도구들이 설치되어 있어야 합니다:

```bash
# Docker Desktop
https://www.docker.com/products/docker-desktop

# Kind (Kubernetes in Docker)
brew install kind

# kubectl
brew install kubectl

# Node.js & Yarn
brew install node
npm install -g yarn

# (Optional) AWS CLI
brew install awscli
```

### 버전 확인

```bash
docker --version      # Docker version 20.10+
kind --version        # kind v0.20+
kubectl version       # v1.28+
node --version        # v20+
yarn --version        # v1.22+
```

---

## 아키텍처 개요

### 시스템 구성도

```
┌─────────────────────────────────────────────────┐
│            로컬 개발 환경 (Mac)                  │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │   Kind Cluster (backstage)                │ │
│  │                                           │ │
│  │  ┌─────────────────┐  ┌────────────────┐ │ │
│  │  │   PostgreSQL    │  │   Backstage    │ │ │
│  │  │                 │  │                │ │ │
│  │  │  - Database     │  │  - Frontend    │ │ │
│  │  │  - PVC Storage  │  │  - Backend API │ │ │
│  │  │                 │  │  - Catalog     │ │ │
│  │  └─────────────────┘  └────────────────┘ │ │
│  │         ↑                    ↑            │ │
│  │         │                    │            │ │
│  │    Port: 5432          Port: 30000       │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  Access: http://localhost:30000                │
└─────────────────────────────────────────────────┘

                    ↓ (템플릿 실행 시)

┌─────────────────────────────────────────────────┐
│              GitHub Repository                   │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │   Terraform + GitHub Actions              │ │
│  │                                           │ │
│  │   terraform/                              │ │
│  │   ├── main.tf      (EC2 정의)             │ │
│  │   ├── variables.tf (변수)                 │ │
│  │   └── outputs.tf   (출력)                 │ │
│  │                                           │ │
│  │   .github/workflows/                      │ │
│  │   └── terraform.yml (CI/CD 파이프라인)    │ │
│  └───────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘

                    ↓ (Terraform Apply)

┌─────────────────────────────────────────────────┐
│                AWS Cloud                         │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │   EC2 Instance                            │ │
│  │   - Auto-configured                       │ │
│  │   - Security Group                        │ │
│  │   - Apache Web Server                     │ │
│  └───────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

### 주요 컴포넌트

| 컴포넌트 | 설명 | 포트/접속 |
|---------|------|----------|
| **Kind Cluster** | 로컬 Kubernetes 클러스터 | - |
| **PostgreSQL** | Backstage 데이터베이스 | ClusterIP:5432 |
| **Backstage** | Developer Portal | NodePort:30000 |
| **Terraform Template** | EC2 프로비저닝 템플릿 | Backstage Catalog |
| **GitHub Actions** | CI/CD 파이프라인 | GitHub |

---

## Step-by-Step 배포 가이드

### Step 1: Kind 클러스터 생성

#### 1.1 클러스터 설정 파일 생성

```bash
mkdir -p ~/backstage-k8s-demo
cd ~/backstage-k8s-demo

cat > kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: backstage
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000
    hostPort: 30000
    protocol: TCP
  - containerPort: 30001
    hostPort: 30001
    protocol: TCP
EOF
```

**설명:**
- `extraPortMappings`: NodePort 서비스를 위한 포트 매핑 설정
- Port 30000: Backstage 웹 UI 접속용
- Port 30001: 향후 확장을 위한 예비 포트

#### 1.2 클러스터 생성

```bash
kind create cluster --config kind-config.yaml
```

#### 1.3 클러스터 확인

```bash
kubectl cluster-info --context kind-backstage
kubectl get nodes
```

**예상 출력:**
```
NAME                      STATUS   ROLES           AGE   VERSION
backstage-control-plane   Ready    control-plane   30s   v1.35.0
```

---

### Step 2: Backstage 애플리케이션 생성

#### 2.1 Backstage 앱 생성

```bash
cd ~/backstage-k8s-demo
npx @backstage/create-app@latest
# 프롬프트에서 앱 이름 입력: backstage-app
```

#### 2.2 의존성 설치

```bash
cd backstage-app
yarn install
```

**소요 시간:** 약 1-2분

#### 2.3 Kubernetes 전용 설정 파일 생성

```bash
cat > app-config.kubernetes.yaml <<'EOF'
app:
  title: Backstage on Kubernetes
  baseUrl: http://localhost:30000

organization:
  name: Demo Organization

backend:
  baseUrl: http://localhost:30000
  listen:
    port: 7007
  csp:
    connect-src: ["'self'", 'http:', 'https:']
  cors:
    origin: http://localhost:30000
    methods: [GET, HEAD, PATCH, POST, PUT, DELETE]
    credentials: true
  database:
    client: pg
    connection:
      host: ${POSTGRES_HOST}
      port: ${POSTGRES_PORT}
      user: ${POSTGRES_USER}
      password: ${POSTGRES_PASSWORD}

auth:
  providers:
    guest: {}

catalog:
  import:
    entityFilename: catalog-info.yaml
    pullRequestBranchName: backstage-integration
  rules:
    - allow: [Component, System, API, Resource, Location, Template]
  locations:
    - type: file
      target: /app/templates/terraform-ec2/template.yaml
      rules:
        - allow: [Template]
    - type: file
      target: ./examples/entities.yaml
    - type: file
      target: ./examples/org.yaml
      rules:
        - allow: [User, Group]

scaffolder:
  defaultAuthor:
    name: Backstage
    email: backstage@example.com
  defaultCommitMessage: 'Initial commit from Backstage'

techdocs:
  builder: 'local'
  generator:
    runIn: 'local'
  publisher:
    type: 'local'

permission:
  enabled: false
EOF
```

#### 2.4 Production 설정 파일 수정

```bash
# app-config.production.yaml에서 listen 설정 수정
sed -i '' "s/listen: ':7007'/listen:\\n    port: 7007\\n    host: 0.0.0.0/" app-config.production.yaml
```

---

### Step 3: Backstage 빌드

#### 3.1 TypeScript 컴파일

```bash
yarn tsc
```

#### 3.2 Backend 빌드

```bash
yarn build:backend
```

**소요 시간:** 약 3-5분

**예상 출력 (마지막 부분):**
```
Moving backend into dist workspace
Moving app into dist workspace
```

---

### Step 4: Docker 이미지 빌드

#### 4.1 Dockerfile 수정 (템플릿 포함)

Dockerfile에 템플릿 디렉토리를 추가합니다:

```bash
# packages/backend/Dockerfile 편집
# 다음 내용을 examples 복사 라인 다음에 추가:
# COPY --chown=node:node templates ./templates
```

#### 4.2 이미지 빌드

```bash
docker image build . -f packages/backend/Dockerfile --tag backstage:local
```

**소요 시간:** 약 2-3분 (최초), 이후 캐시로 1분 이내

#### 4.3 Kind 클러스터에 이미지 로드

```bash
kind load docker-image backstage:local --name backstage
```

---

### Step 5: Kubernetes 매니페스트 작성

#### 5.1 매니페스트 디렉토리 생성

```bash
mkdir -p ~/backstage-k8s-demo/k8s
cd ~/backstage-k8s-demo/k8s
```

#### 5.2 Namespace 생성

```bash
cat > 00-namespace.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: backstage
EOF
```

#### 5.3 PostgreSQL Secrets

```bash
cat > 01-postgres-secrets.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secrets
  namespace: backstage
type: Opaque
stringData:
  POSTGRES_USER: backstage
  POSTGRES_PASSWORD: backstage123
  POSTGRES_DB: backstage
EOF
```

#### 5.4 PostgreSQL Storage

```bash
cat > 02-postgres-storage.yaml <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/backstage-postgres-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: backstage
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
EOF
```

#### 5.5 PostgreSQL Deployment

```bash
cat > 03-postgres-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: backstage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secrets
              key: POSTGRES_USER
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secrets
              key: POSTGRES_PASSWORD
        - name: POSTGRES_DB
          valueFrom:
            secretKeyRef:
              name: postgres-secrets
              key: POSTGRES_DB
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: backstage
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
EOF
```

#### 5.6 Backstage Secrets

```bash
cat > 04-backstage-secrets.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: backstage-secrets
  namespace: backstage
type: Opaque
stringData:
  POSTGRES_HOST: postgres
  POSTGRES_PORT: "5432"
  POSTGRES_USER: backstage
  POSTGRES_PASSWORD: backstage123
  GITHUB_TOKEN: "ghp_dummy_token_for_demo_purposes_only"
  AWS_ACCESS_KEY_ID: ""
  AWS_SECRET_ACCESS_KEY: ""
  AWS_DEFAULT_REGION: "us-east-1"
EOF
```

**중요:** 실제 사용 시 GitHub 토큰과 AWS 자격 증명을 설정해야 합니다.

#### 5.7 Backstage Deployment

```bash
cat > 05-backstage-deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backstage
  namespace: backstage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backstage
  template:
    metadata:
      labels:
        app: backstage
    spec:
      containers:
      - name: backstage
        image: backstage:local
        imagePullPolicy: Never
        ports:
        - containerPort: 7007
          name: http
        env:
        - name: POSTGRES_HOST
          valueFrom:
            secretKeyRef:
              name: backstage-secrets
              key: POSTGRES_HOST
        - name: POSTGRES_PORT
          valueFrom:
            secretKeyRef:
              name: backstage-secrets
              key: POSTGRES_PORT
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: backstage-secrets
              key: POSTGRES_USER
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: backstage-secrets
              key: POSTGRES_PASSWORD
        - name: GITHUB_TOKEN
          valueFrom:
            secretKeyRef:
              name: backstage-secrets
              key: GITHUB_TOKEN
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /healthcheck
            port: 7007
          initialDelaySeconds: 60
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /healthcheck
            port: 7007
          initialDelaySeconds: 30
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: backstage
  namespace: backstage
spec:
  selector:
    app: backstage
  ports:
  - port: 80
    targetPort: 7007
    nodePort: 30000
  type: NodePort
EOF
```

---

### Step 6: Kubernetes에 배포

#### 6.1 순서대로 리소스 배포

```bash
cd ~/backstage-k8s-demo/k8s

# Namespace 생성
kubectl apply -f 00-namespace.yaml

# PostgreSQL 배포
kubectl apply -f 01-postgres-secrets.yaml
kubectl apply -f 02-postgres-storage.yaml
kubectl apply -f 03-postgres-deployment.yaml

# Backstage 배포
kubectl apply -f 04-backstage-secrets.yaml
kubectl apply -f 05-backstage-deployment.yaml
```

#### 6.2 배포 상태 확인

```bash
# Pod 상태 확인
kubectl get pods -n backstage

# 서비스 확인
kubectl get svc -n backstage

# 로그 확인
kubectl logs -n backstage deployment/backstage --tail=50
```

**예상 출력:**
```
NAME                         READY   STATUS    RESTARTS   AGE
backstage-6cc4c95648-z84rs   1/1     Running   0          2m
postgres-cf47bbbb4-tjxsc     1/1     Running   0          3m

NAME        TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
backstage   NodePort    10.96.142.23   <none>        80:30000/TCP   2m
postgres    ClusterIP   10.96.73.171   <none>        5432/TCP       3m
```

#### 6.3 Backstage 접속

웹 브라우저에서 다음 URL로 접속:

```
http://localhost:30000
```

---

## GitHub Actions + Terraform 카탈로그 사용

### 템플릿 개요

이 템플릿은 다음을 자동으로 생성합니다:

1. **GitHub Repository** - 인프라 코드 저장소
2. **Terraform 코드** - EC2 프로비저닝 정의
3. **GitHub Actions 워크플로우** - 자동 배포 파이프라인
4. **Backstage 카탈로그 등록** - 인프라 추적

### 사용 방법

#### 1. Backstage에서 템플릿 찾기

1. Backstage 접속: http://localhost:30000
2. 왼쪽 메뉴에서 `Create...` 클릭
3. `AWS EC2 with Terraform and GitHub Actions` 템플릿 선택

#### 2. 프로젝트 정보 입력

| 필드 | 설명 | 예시 |
|-----|------|-----|
| **프로젝트 이름** | GitHub 저장소 이름 | `demo-ec2-infrastructure` |
| **설명** | 프로젝트 설명 | `데모용 EC2 인스턴스` |
| **Owner** | 프로젝트 소유자 | `platform-team` |

#### 3. AWS EC2 설정

| 필드 | 설명 | 권장 값 |
|-----|------|--------|
| **AWS 리전** | EC2 배포 리전 | `us-east-1` |
| **인스턴스 타입** | 인스턴스 크기 | `t2.micro` (Free Tier) |
| **AMI ID** | (선택사항) 특정 AMI | 비워두면 최신 AL2023 사용 |
| **퍼블릭 IP** | 공개 IP 할당 여부 | `true` |
| **인스턴스 이름** | EC2 Name 태그 | `demo-ec2` |

#### 4. GitHub 저장소 설정

Repository URL 입력:
- Format: `github.com?owner=YOUR_ORG&repo=YOUR_REPO`
- 예: `github.com?owner=my-company&repo=demo-ec2-infrastructure`

#### 5. GitHub Secrets 설정

생성된 저장소의 Settings > Secrets에서 다음 추가:

```
AWS_ACCESS_KEY_ID=<your-access-key>
AWS_SECRET_ACCESS_KEY=<your-secret-key>
AWS_REGION=us-east-1
```

**AWS IAM 권한:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "vpc:*"
      ],
      "Resource": "*"
    }
  ]
}
```

#### 6. 배포 프로세스

**자동 배포 (권장):**

1. Pull Request 생성 시:
   - Terraform Plan 자동 실행
   - PR에 Plan 결과 코멘트

2. Pull Request 머지 시:
   - Terraform Apply 자동 실행
   - EC2 인스턴스 생성

**수동 배포:**

1. GitHub Actions 탭에서 `Terraform CI/CD` 선택
2. `Run workflow` 클릭
3. Action 선택 (`plan`, `apply`, `destroy`)

#### 7. 결과 확인

**GitHub Actions 출력:**
```json
{
  "instance_id": "i-0123456789abcdef0",
  "instance_public_ip": "54.123.45.67",
  "instance_public_dns": "ec2-54-123-45-67.compute-1.amazonaws.com",
  "web_url": "http://54.123.45.67"
}
```

**웹 서버 접속:**
```bash
curl http://54.123.45.67
# 출력: <h1>Hello from demo-ec2</h1>
```

#### 8. 리소스 삭제

```bash
# 방법 1: GitHub Actions에서
# Actions > Terraform CI/CD > Run workflow > destroy 선택

# 방법 2: 로컬에서
cd terraform
terraform destroy -auto-approve
```

---

## 설정 구조 요약

### 디렉토리 구조

```
backstage-k8s-demo/
├── backstage-app/                    # Backstage 애플리케이션
│   ├── app-config.yaml              # 기본 설정
│   ├── app-config.production.yaml   # Production 설정
│   ├── app-config.kubernetes.yaml   # K8s 전용 설정
│   ├── packages/
│   │   ├── app/                     # Frontend
│   │   └── backend/                 # Backend + Dockerfile
│   ├── templates/                   # Software Templates
│   │   └── terraform-ec2/
│   │       ├── template.yaml        # 템플릿 정의
│   │       └── skeleton/            # 템플릿 파일들
│   │           ├── terraform/       # Terraform 코드
│   │           ├── .github/         # GitHub Actions
│   │           └── catalog-info.yaml
│   └── examples/                    # 예제 엔티티
├── k8s/                             # Kubernetes 매니페스트
│   ├── 00-namespace.yaml
│   ├── 01-postgres-secrets.yaml
│   ├── 02-postgres-storage.yaml
│   ├── 03-postgres-deployment.yaml
│   ├── 04-backstage-secrets.yaml
│   └── 05-backstage-deployment.yaml
├── kind-config.yaml                 # Kind 클러스터 설정
└── docs/                            # 문서
    └── DEPLOYMENT_GUIDE.md          # 이 가이드
```

### 주요 설정 파일 역할

| 파일 | 역할 | 핵심 설정 |
|-----|------|----------|
| `app-config.yaml` | 기본 설정 | 앱 제목, GitHub 통합 |
| `app-config.production.yaml` | Production 환경 | PostgreSQL, 배포 설정 |
| `app-config.kubernetes.yaml` | K8s 오버라이드 | baseURL, 카탈로그 위치 |
| `packages/backend/Dockerfile` | 컨테이너 이미지 | 빌드 설정, 템플릿 포함 |
| `template.yaml` | 소프트웨어 템플릿 | 파라미터, 실행 단계 |

---

## 트러블슈팅

### 1. Backstage Pod이 CrashLoopBackOff

**증상:**
```bash
kubectl get pods -n backstage
NAME                         READY   STATUS             RESTARTS   AGE
backstage-xxx                0/1     CrashLoopBackOff   5          3m
```

**원인 및 해결:**

#### A. 설정 오류

```bash
# 로그 확인
kubectl logs -n backstage deployment/backstage --tail=50

# 일반적인 오류:
# - "Invalid type in config for key 'backend.listen'"
#   → app-config.production.yaml의 listen을 object 형식으로 수정

# - "Invalid type in config for key 'integrations.github[0].token', got empty-string"
#   → GitHub 토큰을 더미값으로 설정 또는 통합 제거
```

#### B. PostgreSQL 연결 실패

```bash
# PostgreSQL 상태 확인
kubectl get pods -n backstage -l app=postgres

# PostgreSQL이 Running이 아니면:
kubectl logs -n backstage -l app=postgres
```

### 2. Kind 클러스터가 생성되지 않음

**증상:**
```
ERROR: failed to create cluster: failed to get docker info
```

**해결:**
```bash
# Docker Desktop이 실행 중인지 확인
open -a Docker

# 잠시 대기 후 재시도
sleep 10
kind create cluster --config kind-config.yaml
```

### 3. 템플릿이 카탈로그에 표시되지 않음

**원인:**
- 템플릿 파일 경로 오류
- Docker 이미지에 템플릿 미포함

**해결:**
```bash
# 1. 템플릿 파일 복사 확인
ls -la ~/backstage-k8s-demo/backstage-app/templates/

# 2. Dockerfile에 COPY 라인 확인
cat packages/backend/Dockerfile | grep templates

# 3. 이미지 재빌드
docker image build . -f packages/backend/Dockerfile --tag backstage:local
kind load docker-image backstage:local --name backstage
kubectl rollout restart deployment/backstage -n backstage

# 4. 로그에서 템플릿 로딩 확인
kubectl logs -n backstage deployment/backstage | grep template
```

### 4. GitHub Actions에서 Terraform이 실패

**일반적인 오류:**

#### A. AWS 자격 증명 오류
```
Error: No valid credential sources found
```

**해결:**
- GitHub Secrets에 AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY 확인
- IAM 사용자 권한 확인

#### B. Terraform State Lock
```
Error: Error acquiring the state lock
```

**해결:**
```bash
# 강제 unlock (주의해서 사용)
terraform force-unlock <LOCK_ID>
```

### 5. 포트 30000에 접속 불가

**확인 사항:**

```bash
# 1. Service 확인
kubectl get svc -n backstage backstage
# NodePort가 30000인지 확인

# 2. Pod 상태 확인
kubectl get pods -n backstage
# Backstage Pod이 Running인지 확인

# 3. 로컬 포트 사용 확인
lsof -i :30000
# 다른 프로세스가 사용 중이면 종료

# 4. Kind 클러스터 포트 매핑 확인
docker ps | grep backstage-control-plane
# 30000 포트가 매핑되어 있는지 확인
```

---

## 리소스 정리

### 전체 환경 삭제

```bash
# 1. Kind 클러스터 삭제
kind delete cluster --name backstage

# 2. Docker 이미지 삭제
docker rmi backstage:local

# 3. 프로젝트 디렉토리 삭제 (선택사항)
rm -rf ~/backstage-k8s-demo
```

### AWS 리소스 정리

생성된 EC2 인스턴스는 Terraform으로 관리되므로:

```bash
# 각 프로젝트의 terraform 디렉토리에서:
cd <your-project>/terraform
terraform destroy -auto-approve
```

또는 GitHub Actions에서 `destroy` 워크플로우 실행

---

## 참고 자료

### 공식 문서

- [Backstage 공식 문서](https://backstage.io/docs)
- [Backstage K8s 배포 가이드](https://backstage.io/docs/deployment/k8s)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions 문서](https://docs.github.com/en/actions)

### 관련 저장소

- [Backstage GitHub](https://github.com/backstage/backstage)
- [Backstage Software Templates](https://github.com/backstage/software-templates)

### 커뮤니티

- [Backstage Discord](https://discord.gg/backstage-687207715902193673)
- [CNCF Backstage](https://www.cncf.io/projects/backstage/)

---

## 다음 단계

### 프로덕션 환경으로 발전시키기

1. **외부 데이터베이스 사용**
   - AWS RDS PostgreSQL
   - Cloud SQL (GCP)
   - Azure Database for PostgreSQL

2. **Ingress 설정**
   - NGINX Ingress Controller
   - TLS/SSL 인증서
   - 도메인 연결

3. **인증 설정**
   - OAuth 2.0 (Google, GitHub)
   - SAML
   - LDAP/Active Directory

4. **모니터링 & 로깅**
   - Prometheus + Grafana
   - ELK Stack
   - Datadog

5. **고가용성 (HA)**
   - 다중 Replica
   - Load Balancer
   - Auto-scaling

6. **GitOps**
   - ArgoCD 통합
   - Flux CD

---

**마지막 업데이트:** 2026-02-11
**작성자:** Claude Sonnet 4.5
**버전:** 1.0.0

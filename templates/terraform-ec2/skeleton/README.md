# ${{ values.name }}

${{ values.description }}

## 📋 프로젝트 정보

이 프로젝트는 Backstage에서 생성된 Terraform 인프라 코드입니다.
로컬에서 직접 Terraform을 실행하여 AWS EC2 인스턴스를 생성합니다.

### AWS EC2 설정

- **리전**: ${{ values.region }}
- **인스턴스 타입**: ${{ values.instance_type }}
- **퍼블릭 IP**: ${{ values.enable_public_ip }}
- **인스턴스 이름**: ${{ values.instance_name }}

### Terraform State 관리

- **Backend**: S3
- **Bucket**: ${{ values.s3_bucket }}
- **Key**: ${{ values.name }}/terraform.tfstate
- **암호화**: 활성화

---

## 🚀 빠른 시작

### 사전 요구사항

1. **Terraform 설치** (v1.0+)
   ```bash
   # macOS
   brew install terraform

   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/

   # Windows
   choco install terraform
   ```

2. **AWS CLI 설치** (선택사항)
   ```bash
   # macOS
   brew install awscli

   # Linux
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   ```

3. **S3 Bucket 생성** (State 저장용)
   ```bash
   # AWS Console에서 생성하거나
   aws s3api create-bucket \
     --bucket ${{ values.s3_bucket }} \
     --region ${{ values.region }}

   # 버전 관리 활성화 (권장)
   aws s3api put-bucket-versioning \
     --bucket ${{ values.s3_bucket }} \
     --versioning-configuration Status=Enabled
   ```

---

## 🔐 AWS 인증 설정

### 방법 1: 환경변수 (권장)

```bash
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_KEY"
export AWS_DEFAULT_REGION="${{ values.region }}"
```

**보안 Tip:** 환경변수는 현재 세션에만 유효합니다.

### 방법 2: AWS CLI 프로파일

```bash
# AWS CLI 설정
aws configure

# 또는 특정 프로파일 사용
aws configure --profile backstage
export AWS_PROFILE=backstage
```

### 방법 3: .env 파일 (개발용)

```bash
# .env 파일 생성 (Git에는 절대 커밋하지 마세요!)
cat > .env <<EOF
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_KEY"
export AWS_DEFAULT_REGION="${{ values.region }}"
EOF

# 환경변수 로드
source .env
```

---

## 📦 배포 방법

### 1단계: Terraform 초기화

```bash
cd terraform
terraform init
```

**예상 출력:**
```
Initializing the backend...
Successfully configured the backend "s3"!
Initializing provider plugins...
Terraform has been successfully initialized!
```

### 2단계: 실행 계획 확인

```bash
terraform plan
```

생성될 리소스를 확인하세요:
- EC2 Instance
- Security Group
- VPC (기본값 사용)

### 3단계: 인프라 배포

```bash
terraform apply
```

**확인 프롬프트가 나오면 `yes` 입력**

배포 완료 후 출력 예시:
```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:
instance_id = "i-0123456789abcdef0"
instance_public_ip = "54.123.45.67"
instance_private_ip = "10.0.1.10"
security_group_id = "sg-0123456789abcdef0"
```

### 4단계: 배포 확인

```bash
# EC2 인스턴스 확인
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw instance_id)

# 웹 서버 접속 (Apache가 설치되어 있는 경우)
curl http://$(terraform output -raw instance_public_ip)

# 또는 브라우저에서:
open http://$(terraform output -raw instance_public_ip)
```

---

## 🔄 업데이트 및 재배포

코드를 수정한 후:

```bash
# 변경사항 확인
terraform plan

# 적용
terraform apply
```

---

## 🗑️ 리소스 삭제

**주의:** 모든 AWS 리소스가 영구적으로 삭제됩니다!

```bash
terraform destroy
```

확인 프롬프트에서 `yes` 입력

---

## 📊 Terraform 명령어 참고

| 명령어 | 설명 |
|--------|------|
| `terraform init` | 초기화 (Backend 및 Provider 설정) |
| `terraform validate` | 문법 검증 |
| `terraform plan` | 실행 계획 미리보기 |
| `terraform apply` | 인프라 배포 |
| `terraform destroy` | 인프라 삭제 |
| `terraform show` | 현재 State 조회 |
| `terraform output` | Output 값 조회 |
| `terraform state list` | 관리 중인 리소스 목록 |

---

## 🔧 고급 사용법

### State 파일 관리

```bash
# State 파일 조회
terraform state list

# 특정 리소스 상세 정보
terraform state show aws_instance.main

# State 파일 Pull (S3에서)
terraform state pull > terraform.tfstate.backup
```

### Terraform Workspace 사용

```bash
# Workspace 목록
terraform workspace list

# 새 Workspace 생성 (dev, staging, prod)
terraform workspace new dev
terraform workspace new prod

# Workspace 전환
terraform workspace select dev
```

각 workspace는 별도의 state 파일을 사용합니다:
- `${{ values.name }}/env:/dev/terraform.tfstate`
- `${{ values.name }}/env:/prod/terraform.tfstate`

### 변수 오버라이드

```bash
# 커맨드라인에서 변수 지정
terraform apply -var="instance_type=t3.medium"

# 변수 파일 사용
terraform apply -var-file="production.tfvars"
```

---

## 🛡️ 보안 주의사항

### ⚠️ 중요

1. **AWS 크레덴셜 보호**
   - ❌ 절대 Git에 커밋하지 마세요
   - ✅ 환경변수 또는 AWS CLI 프로파일 사용
   - ✅ `.env` 파일은 `.gitignore`에 추가

2. **State 파일 보안**
   - ✅ S3 bucket 암호화 활성화
   - ✅ S3 bucket 버전 관리 활성화
   - ✅ S3 bucket 접근 제한 (IAM Policy)

3. **최소 권한 원칙**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Action": [
         "ec2:*",
         "s3:GetObject",
         "s3:PutObject"
       ],
       "Resource": "*"
     }]
   }
   ```

4. **리소스 태깅**
   - 모든 리소스에 Owner, Project, Environment 태그 추가
   - 비용 추적 및 관리 용이

---

## 📚 문서 및 참고 자료

### Terraform

- [Terraform 공식 문서](https://www.terraform.io/docs)
- [AWS Provider 문서](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [S3 Backend 설정](https://www.terraform.io/docs/language/settings/backends/s3.html)

### AWS

- [EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [S3 Versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)

---

## 🐛 트러블슈팅

### "Error: NoSuchBucket"

**문제:** S3 bucket이 없음

**해결:**
```bash
aws s3api create-bucket --bucket ${{ values.s3_bucket }} --region ${{ values.region }}
```

### "Error: UnauthorizedOperation"

**문제:** AWS 권한 부족

**해결:**
1. IAM 권한 확인
2. AWS 크레덴셜 확인
3. 리전 확인

### "Error: Invalid credentials"

**문제:** AWS 크레덴셜 문제

**해결:**
```bash
# 환경변수 확인
echo $AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY

# 재설정
export AWS_ACCESS_KEY_ID="YOUR_KEY"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET"
```

### State Lock 에러

**문제:** 다른 실행이 진행 중

**해결:**
```bash
# Force unlock (주의: 확실할 때만)
terraform force-unlock LOCK_ID
```

---

## 💡 FAQ

**Q: S3 bucket이 없어도 되나요?**
A: 아니요. Terraform backend로 S3를 사용하므로 미리 생성해야 합니다.

**Q: 여러 번 apply해도 되나요?**
A: 네. Terraform은 idempotent하므로 변경사항만 적용합니다.

**Q: State 파일은 어디에 있나요?**
A: S3 bucket의 `${{ values.name }}/terraform.tfstate`에 저장됩니다.

**Q: 팀원과 공유하려면?**
A: 팀원도 같은 S3 bucket 접근 권한이 있으면 자동으로 state를 공유합니다.

**Q: 비용은 얼마나 나오나요?**
A: t2.micro (Free Tier) 사용 시 월 $0, 그 외는 AWS Pricing 참고

---

## 📞 문의

문제가 발생하거나 도움이 필요하면 ${{ values.owner }}에게 연락하세요.

---

**Created by:** Backstage Software Templates
**Terraform Version:** 1.6+
**AWS Provider Version:** 5.x
**Last Updated:** $(date +%Y-%m-%d)

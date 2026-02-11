# ${{ values.name }}

${{ values.description }}

## 개요

이 프로젝트는 Backstage에서 생성된 Terraform 인프라 코드입니다.
GitHub Actions를 통해 자동으로 배포됩니다.

## 구성 요소

- **Terraform 코드**: `terraform/` 디렉토리에 AWS EC2 인프라 정의
- **GitHub Actions**: `.github/workflows/` 디렉토리에 자동 배포 워크플로우

## AWS EC2 설정

- **리전**: ${{ values.region }}
- **인스턴스 타입**: ${{ values.instance_type }}
- **퍼블릭 IP**: ${{ values.enable_public_ip }}
- **인스턴스 이름**: ${{ values.instance_name }}

## 사용 방법

### 1. AWS 자격 증명 설정

#### GitHub Secrets 추가 방법:

1. **GitHub Repository 설정으로 이동**
   - 생성된 Repository로 이동
   - `Settings` → `Secrets and variables` → `Actions` 클릭

2. **New repository secret 클릭하여 추가:**

   | Secret Name | 설명 | 예시 |
   |------------|------|------|
   | `AWS_ACCESS_KEY_ID` | AWS Access Key ID | `AKIA...` |
   | `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | `wJalrXUtn...` |
   | `AWS_REGION` | AWS 리전 (선택사항) | `${{ values.region }}` |

3. **AWS IAM 사용자 생성 (처음 사용하는 경우)**
   ```bash
   # AWS Console에서:
   # 1. IAM → Users → Create user
   # 2. Attach policies: AmazonEC2FullAccess (또는 최소 권한 정책)
   # 3. Security credentials → Create access key
   # 4. Application running outside AWS 선택
   # 5. Access Key와 Secret Key를 GitHub Secrets에 추가
   ```

**⚠️ 보안 주의:**
- Access Key는 한 번만 표시되므로 안전한 곳에 저장하세요
- 프로덕션 환경에서는 IAM Role + OIDC 사용을 권장합니다

### 2. Terraform 배포

#### 자동 배포 (GitHub Actions)

- `main` 브랜치에 푸시하면 자동으로 `terraform plan`이 실행됩니다
- Pull Request에 코멘트로 plan 결과가 표시됩니다
- Pull Request가 머지되면 자동으로 `terraform apply`가 실행됩니다

#### 수동 배포

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 3. 리소스 삭제

```bash
cd terraform
terraform destroy
```

## 보안 참고사항

⚠️ **중요**:
- AWS 자격 증명은 절대 코드에 포함하지 마세요
- GitHub Secrets를 사용하여 안전하게 관리하세요
- 최소 권한 원칙에 따라 IAM 정책을 설정하세요
- 사용하지 않는 리소스는 즉시 삭제하세요

## 모니터링

생성된 EC2 인스턴스는 다음에서 확인할 수 있습니다:
- AWS Console: https://console.aws.amazon.com/ec2/
- Terraform State: `terraform show`

## 문의

문제가 발생하거나 도움이 필요하면 ${{ values.owner }}에게 연락하세요.

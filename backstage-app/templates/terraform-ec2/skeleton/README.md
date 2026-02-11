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

GitHub 저장소의 Secrets에 다음을 추가하세요:

- `AWS_ACCESS_KEY_ID`: AWS Access Key ID
- `AWS_SECRET_ACCESS_KEY`: AWS Secret Access Key
- `AWS_REGION`: AWS 리전 (기본값: ${{ values.region }})

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

# Terraform State Backend Configuration
# S3를 사용하여 state 파일을 원격으로 관리합니다.
# 이렇게 하면 팀원들과 state를 공유하고, 동시 실행을 방지할 수 있습니다.

terraform {
  backend "s3" {
    bucket = "${{ values.s3_bucket }}"
    key    = "${{ values.name }}/terraform.tfstate"
    region = "${{ values.region }}"

    # DynamoDB를 사용한 State Locking (선택사항)
    # 동시 실행 방지를 위해 권장
    # dynamodb_table = "terraform-state-lock"

    # State 파일 암호화
    encrypt = true
  }
}

# 참고:
# 1. S3 bucket은 미리 생성되어 있어야 합니다
# 2. AWS 크레덴셜은 환경변수 또는 AWS CLI 프로파일로 설정
# 3. DynamoDB 테이블은 선택사항 (동시 실행 방지용)

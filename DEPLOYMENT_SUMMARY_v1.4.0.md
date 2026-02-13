# Backstage v1.4.0 배포 완료 보고서

## 📋 요약

Backstage 템플릿의 GitHub Token 입력 방식을 Backstage 공식 방법인 `requestUserCredentials`로 변경하여 **v1.4.0**을 배포했습니다.

## ✅ 완료된 작업

### 1. 템플릿 수정
- **파일**: `templates/terraform-ec2/template.yaml`
- **변경 내용**:
  - ❌ 제거: 별도의 `github_token` 파라미터 필드
  - ❌ 제거: `allowedHosts` (지원되지 않는 파라미터)
  - ✅ 추가: `RepoUrlPicker`에 `requestUserCredentials` 설정
    ```yaml
    ui:options:
      requestUserCredentials:
        secretsKey: USER_OAUTH_TOKEN
        additionalScopes:
          github:
            - workflow
    ```
  - ✅ 변경: `publish:github` 액션의 token 참조
    - 이전: `token: ${{ parameters.github_token }}`
    - 현재: `token: ${{ secrets.USER_OAUTH_TOKEN }}`

### 2. Docker 이미지 빌드 및 배포
- **이미지**: `hyungwookhub/backstage:v1.4.0` (latest)
- **플랫폼**: linux/amd64, linux/arm64 (multi-architecture)
- **빌드 옵션**: `--no-cache` (완전 새로 빌드)
- **배포 상태**: ✅ Docker Hub에 푸시 완료

### 3. GitHub 저장소 업데이트
- **Commit**: `40120f3` - feat: Implement proper user token input using requestUserCredentials
- **푸시 상태**: ✅ origin/main에 푸시 완료
- **변경된 파일**:
  - `backstage-app/templates/terraform-ec2/template.yaml`
  - `templates/terraform-ec2/template.yaml`

### 4. Kubernetes 클러스터 배포
- **클러스터**: Kind (로컬)
- **네임스페이스**: backstage
- **Pod 상태**: ✅ Running (새 이미지로 재시작 완료)
- **이미지 검증**: ✅ Pod 내부 template.yaml 확인 완료

## 🔍 검증 결과

### 템플릿 파일 검증
```bash
# Pod 내부에서 확인한 설정
kubectl exec -n backstage deployment/backstage -- cat /app/templates/terraform-ec2/template.yaml
```

**확인 사항**:
1. ✅ `requestUserCredentials` 설정 존재
2. ✅ `secretsKey: USER_OAUTH_TOKEN` 설정 확인
3. ✅ `token: ${{ secrets.USER_OAUTH_TOKEN }}` 사용 확인
4. ✅ 불필요한 `github_token` 파라미터 제거 확인

### Pod 상태
```bash
kubectl get pods -n backstage
```
```
NAME                         READY   STATUS    RESTARTS      AGE
backstage-7d9f54b8d4-jtp77   1/1     Running   0             XX분
postgres-cf47bbbb4-kzpfq     1/1     Running   1             39h
```

## 📝 사용 방법

### Backstage 접속
```bash
# 포트 포워딩
kubectl port-forward -n backstage svc/backstage 7007:7007

# 브라우저에서 접속
open http://localhost:7007
```

### 템플릿 실행 단계
1. **Create → Templates** 클릭
2. **"AWS EC2 with Terraform and GitHub Actions"** 템플릿 선택
3. **프로젝트 정보** 입력
   - 프로젝트 이름
   - 설명
   - Owner
4. **AWS EC2 설정** 입력
   - AWS 리전
   - 인스턴스 타입
   - 기타 설정
5. **AWS 인증 정보** 입력
   - AWS Access Key ID
   - AWS Secret Access Key
   - S3 Bucket
6. **GitHub 저장소 설정** 📌 **여기서 Token 입력!**
   - Repository Location 선택
   - **Backstage가 자동으로 GitHub Token 입력 요청**
   - Token 입력: `ghp_...` (본인의 GitHub Personal Access Token)

### GitHub Token 생성
1. GitHub → Settings → Developer settings
2. Personal access tokens → Tokens (classic)
3. Generate new token (classic)
4. 권한 선택:
   - ✅ `repo` (전체)
   - ✅ `workflow`
5. Generate token
6. Token 복사 (ghp_로 시작)

## 🎯 주요 개선 사항

### 문제점 (v1.3.0 이전)
- ❌ `github_token` 파라미터가 전달되지 않음
- ❌ "Bad credentials" 에러 발생
- ❌ GitHub 저장소 생성 실패
- ❌ 로그에 `github_token` 값이 보이지 않음

### 해결 방법 (v1.4.0)
- ✅ Backstage 공식 `requestUserCredentials` 사용
- ✅ `USER_OAUTH_TOKEN` 시크릿으로 자동 저장
- ✅ `publish:github` 액션이 올바르게 Token 사용
- ✅ GitHub 저장소 생성 성공 예상

## 🧪 테스트 방법

### 1. 템플릿 로드 확인
```bash
kubectl logs -n backstage deployment/backstage --tail=100 | grep -i template
```

### 2. 실제 템플릿 실행 테스트
1. Backstage UI에서 템플릿 실행
2. 모든 정보 입력 (특히 GitHub Token)
3. "Create" 버튼 클릭
4. GitHub에서 저장소 생성 확인

### 3. 로그 확인
```bash
# 실시간 로그 확인
kubectl logs -n backstage -f deployment/backstage
```

### 예상 동작
- ✅ Token 입력 필드가 RepoUrlPicker와 통합되어 표시
- ✅ Token 입력 시 `USER_OAUTH_TOKEN` 시크릿으로 저장
- ✅ `publish:github` 액션이 Token을 사용하여 저장소 생성
- ✅ GitHub에 저장소가 정상적으로 생성됨
- ✅ Catalog에 컴포넌트가 등록됨

## 📚 참고 문서

- [GITHUB_TOKEN_CONFIGURATION.md](./docs/GITHUB_TOKEN_CONFIGURATION.md) - 상세 설정 가이드
- [Backstage RepoUrlPicker 문서](https://backstage.io/docs/features/software-templates/builtin-actions#publishgithub)
- [GitHub Personal Access Token 생성](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

## 🔄 버전 히스토리

| 버전 | 날짜 | 변경 사항 |
|------|------|----------|
| v1.4.0 | 2026-02-13 | ✅ requestUserCredentials 구현 (공식 방법) |
| v1.3.0 | 2026-02-13 | ⚠️ allowedHosts 제거 (지원 안됨) |
| v1.2.0 | 2026-02-13 | ⚠️ github_token 파라미터 추가 (동작 안함) |
| v1.1.0 | 2026-02-13 | ⚠️ 초기 구현 시도 |

## ⚙️ 기술 스택

- **Backstage**: Latest
- **Docker**: Multi-architecture (amd64, arm64)
- **Kubernetes**: Kind (local cluster)
- **Node.js**: 24 (trixie-slim)
- **PostgreSQL**: 14
- **Template Engine**: Nunjucks

## ✨ 다음 단계

1. ✅ 배포 완료
2. 🔄 사용자 테스트 대기
3. 📝 피드백 수집
4. 🚀 프로덕션 배포 준비

---

**배포자**: Claude Sonnet 4.5
**배포 일시**: 2026-02-13
**상태**: ✅ 배포 완료, 테스트 준비 완료

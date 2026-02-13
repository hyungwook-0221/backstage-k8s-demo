# GitHub Token Configuration Guide

## Version 1.4.0 - Proper User Token Input Implementation

### 변경 사항 (What Changed)

이전 버전에서는 GitHub Token을 별도의 파라미터로 입력받으려 했으나, Backstage의 `publish:github` 액션이 파라미터를 제대로 인식하지 못하는 문제가 있었습니다.

**v1.4.0부터는 Backstage의 공식 방법인 `requestUserCredentials`를 사용합니다.**

### 주요 변경 내용

#### 1. RepoUrlPicker 설정
```yaml
repoUrl:
  title: Repository Location
  type: string
  description: "저장소를 생성할 위치"
  ui:field: RepoUrlPicker
  ui:options:
    requestUserCredentials:
      secretsKey: USER_OAUTH_TOKEN
      additionalScopes:
        github:
          - workflow
```

#### 2. publish:github 액션
```yaml
- id: publish
  name: Publish to GitHub
  action: publish:github
  input:
    description: ${{ parameters.description }}
    repoUrl: ${{ parameters.repoUrl }}
    repoVisibility: private
    defaultBranch: main
    token: ${{ secrets.USER_OAUTH_TOKEN }}
```

### 사용 방법 (How to Use)

1. **템플릿 실행**
   - Backstage UI에서 "AWS EC2 with Terraform and GitHub Actions" 템플릿 선택
   - 프로젝트 정보, AWS 설정, AWS 인증 정보 입력

2. **GitHub 저장소 설정 단계**
   - Repository Location에서 Owner와 Repository 이름 선택
   - Backstage가 자동으로 GitHub Token 입력을 요청합니다
   - **이때 사용자의 GitHub Personal Access Token을 입력하면 됩니다**

3. **필요한 Token 권한**
   - `repo` (전체)
   - `workflow`

4. **Token 생성 방법**
   - GitHub → Settings → Developer settings
   - Personal access tokens → Tokens (classic)
   - Generate new token
   - 필요한 권한 선택: repo, workflow
   - Generate token

### 동작 원리 (How It Works)

1. `RepoUrlPicker`가 `requestUserCredentials` 옵션으로 설정되어 있으면, Backstage가 자동으로 사용자에게 GitHub 인증을 요청합니다.
2. 사용자가 입력한 Token은 `USER_OAUTH_TOKEN`이라는 secret key로 저장됩니다.
3. `publish:github` 액션이 실행될 때 `${{ secrets.USER_OAUTH_TOKEN }}`을 통해 사용자가 입력한 Token을 사용합니다.

### 이전 버전과의 차이점

| 항목 | 이전 버전 (v1.3.0) | 현재 버전 (v1.4.0) |
|------|-------------------|-------------------|
| Token 입력 방식 | 별도 파라미터 필드 | RepoUrlPicker 통합 |
| Token 참조 방식 | `${{ parameters.github_token }}` | `${{ secrets.USER_OAUTH_TOKEN }}` |
| Token 전달 여부 | ❌ 전달 안됨 | ✅ 정상 전달 |
| Backstage 호환성 | ⚠️ 비공식 방법 | ✅ 공식 방법 |

### 배포 정보

- **Docker Image**: `hyungwookhub/backstage:v1.4.0` (latest)
- **빌드 날짜**: 2026-02-13
- **Git Commit**: 40120f3
- **Multi-architecture**: amd64, arm64

### 테스트 방법

1. **Kind 클러스터 접속**
   ```bash
   kubectl get pods -n backstage
   ```

2. **Backstage UI 접속**
   ```bash
   kubectl port-forward -n backstage svc/backstage 7007:7007
   ```
   - 브라우저에서 http://localhost:7007 접속

3. **템플릿 테스트**
   - Create → Templates → "AWS EC2 with Terraform and GitHub Actions" 선택
   - 모든 정보 입력
   - GitHub 저장소 설정에서 Token 입력 (ghp_...)
   - Create 버튼 클릭
   - GitHub에 저장소가 정상 생성되는지 확인

### 문제 해결 (Troubleshooting)

#### 1. Token 입력 필드가 보이지 않는 경우
- 브라우저 캐시 삭제 후 새로고침
- Backstage pod 재시작 확인

#### 2. "Bad credentials" 에러
- Token 권한 확인 (repo, workflow 필수)
- Token이 만료되지 않았는지 확인
- Token이 올바르게 복사되었는지 확인

#### 3. Repository 생성 실패
- Owner가 본인 계정이거나 권한이 있는 Organization인지 확인
- Repository 이름이 이미 존재하지 않는지 확인

### 참고 자료

- [Backstage RepoUrlPicker Documentation](https://backstage.io/docs/features/software-templates/builtin-actions#publishgithub)
- [GitHub Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

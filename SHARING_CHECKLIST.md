# 📋 공유 전 체크리스트

이 프로젝트를 다른 사람들과 공유하기 전에 확인해야 할 사항들입니다.

## ✅ 필수 체크리스트

### 1. 보안 검사

- [ ] `k8s/04-backstage-secrets.yaml`에 실제 비밀번호가 없는지 확인
- [ ] AWS 자격 증명이 코드에 포함되지 않았는지 확인
- [ ] GitHub Token이 더미값인지 확인
- [ ] `.gitignore`가 제대로 설정되었는지 확인
- [ ] `.env` 파일이 제외되었는지 확인

### 2. 문서 완성도

- [ ] `README.md`가 최신 상태인지 확인
- [ ] `SETUP.md`의 모든 단계가 정확한지 확인
- [ ] `DEPLOYMENT_GUIDE.md`의 내용이 정확한지 확인
- [ ] 트러블슈팅 섹션이 최신인지 확인
- [ ] FAQ가 충분한지 확인

### 3. 코드 품질

- [ ] 불필요한 주석 제거
- [ ] console.log 디버깅 코드 제거
- [ ] TODO 주석 정리
- [ ] 테스트 가능한지 확인
- [ ] 에러 핸들링이 적절한지 확인

### 4. 파일 정리

- [ ] `node_modules/` 디렉토리 제거 (`.gitignore`로 차단)
- [ ] `dist/`, `build/` 디렉토리 제거
- [ ] 임시 파일 (`.tmp`, `.bak`) 제거
- [ ] 로그 파일 제거
- [ ] Docker 이미지 TAR 파일 제거 (필요시 별도 공유)

### 5. 테스트 검증

- [ ] 클러스터 삭제 후 재생성 테스트
- [ ] 이미지 빌드가 정상 작동하는지 확인
- [ ] `SETUP.md` 가이드대로 따라해보기
- [ ] 모든 Pod이 정상 실행되는지 확인
- [ ] Backstage UI 접속 확인
- [ ] 템플릿이 정상 작동하는지 확인

## 📝 공유 방법별 체크리스트

### GitHub Repository로 공유

- [ ] Repository를 Public/Private 중 선택
- [ ] LICENSE 파일 추가
- [ ] Repository Description 작성
- [ ] Topics/Tags 추가 (backstage, kubernetes, terraform)
- [ ] README에 스크린샷 추가 (선택사항)
- [ ] CONTRIBUTING.md 작성 (선택사항)
- [ ] Issues/Pull Requests 활성화

**명령어:**
```bash
cd ~/backstage-k8s-demo
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_ORG/backstage-k8s-demo.git
git push -u origin main
```

### Docker Hub로 공유

- [ ] Docker Hub 계정 확인
- [ ] Repository 생성
- [ ] README 업데이트 (이미지 pull 명령어 포함)
- [ ] 이미지 태그 버전 관리
- [ ] 이미지 설명 작성

**명령어:**
```bash
docker tag backstage:local YOUR_USERNAME/backstage:v1.0.0
docker push YOUR_USERNAME/backstage:v1.0.0
docker tag backstage:local YOUR_USERNAME/backstage:latest
docker push YOUR_USERNAME/backstage:latest
```

### ZIP/TAR 파일로 공유

- [ ] 불필요한 파일 제외
- [ ] 압축 파일 이름 명확하게 설정
- [ ] 버전 명시 (예: backstage-k8s-demo-v1.0.0.tar.gz)
- [ ] README에 압축 해제 방법 명시
- [ ] 파일 크기 확인 (이미지 포함 시 ~2GB)

**명령어:**
```bash
# 소스 코드만 (권장)
cd ~
tar czf backstage-k8s-demo-v1.0.0.tar.gz \
  --exclude=node_modules \
  --exclude=dist \
  --exclude=.git \
  backstage-k8s-demo/

# 이미지 포함 (큰 파일)
docker save backstage:local -o backstage-image.tar
tar czf backstage-k8s-demo-full-v1.0.0.tar.gz \
  backstage-k8s-demo/ \
  backstage-image.tar
```

## 🔍 검증 스크립트

공유 전에 이 스크립트로 검증하세요:

```bash
#!/bin/bash

echo "🔍 공유 전 검증 시작..."

# 1. 민감한 파일 확인
echo "1. 민감한 파일 검사..."
if grep -r "AKIA\|aws_access_key" . 2>/dev/null; then
    echo "❌ AWS 키가 발견되었습니다!"
    exit 1
fi

if grep -r "ghp_[a-zA-Z0-9]" . 2>/dev/null | grep -v "ghp_dummy"; then
    echo "❌ 실제 GitHub 토큰이 발견되었습니다!"
    exit 1
fi

# 2. 불필요한 파일 확인
echo "2. 불필요한 파일 검사..."
if [ -d "node_modules" ]; then
    echo "⚠️  node_modules 디렉토리가 있습니다"
fi

if [ -f "backstage-image.tar" ]; then
    echo "⚠️  Docker 이미지 TAR 파일이 있습니다"
fi

# 3. 필수 파일 확인
echo "3. 필수 파일 검사..."
required_files=(
    "README.md"
    "SETUP.md"
    "kind-config.yaml"
    "k8s/00-namespace.yaml"
    "backstage-app/package.json"
    "docs/DEPLOYMENT_GUIDE.md"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ 필수 파일 누락: $file"
        exit 1
    fi
done

# 4. 문서 링크 확인
echo "4. 문서 링크 검사..."
if ! grep -q "SETUP.md" README.md; then
    echo "⚠️  README.md에 SETUP.md 링크가 없습니다"
fi

echo "✅ 검증 완료!"
echo ""
echo "📦 공유 준비가 완료되었습니다!"
```

**사용 방법:**
```bash
cd ~/backstage-k8s-demo
chmod +x verify.sh
./verify.sh
```

## 📊 공유 후 피드백

공유 후 다음을 추적하세요:

- [ ] 다른 사람이 성공적으로 설치했는지 확인
- [ ] 발생한 문제점 수집
- [ ] FAQ 업데이트
- [ ] 트러블슈팅 섹션 개선
- [ ] 문서 개선사항 반영

## 🎯 체크리스트 요약

**최소 요구사항:**
1. ✅ 민감 정보 제거
2. ✅ SETUP.md 작성
3. ✅ .gitignore 설정
4. ✅ 한 번 이상 테스트

**권장사항:**
1. ✅ GitHub Repository 생성
2. ✅ LICENSE 추가
3. ✅ 스크린샷/GIF 추가
4. ✅ 버전 관리
5. ✅ 변경 이력 (CHANGELOG.md)

---

**마지막 업데이트:** 2026-02-12
**작성자:** Claude Sonnet 4.5

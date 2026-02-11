#!/bin/bash

echo "🔍 공유 전 검증 시작..."
echo ""

# 색상 정의
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

errors=0
warnings=0

# 1. 민감한 파일 확인
echo "1️⃣  민감한 정보 검사..."
if grep -r "AKIA[0-9A-Z]\{16\}" --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.yarn --exclude="*.sh" --exclude="*CHECKLIST.md" . 2>/dev/null | grep -v "example\|dummy"; then
    echo -e "${RED}❌ 실제 AWS 키가 발견되었습니다!${NC}"
    ((errors++))
else
    echo -e "${GREEN}✓ AWS 키 검사 통과${NC}"
fi

if grep -r "ghp_[a-zA-Z0-9]\{36\}" --exclude-dir=node_modules --exclude-dir=.git . 2>/dev/null | grep -v "ghp_dummy"; then
    echo -e "${RED}❌ 실제 GitHub 토큰이 발견되었습니다!${NC}"
    ((errors++))
else
    echo -e "${GREEN}✓ GitHub 토큰 검사 통과${NC}"
fi

# 2. 불필요한 파일 확인
echo ""
echo "2️⃣  불필요한 파일 검사..."
if [ -d "backstage-app/node_modules" ]; then
    echo -e "${YELLOW}⚠️  node_modules 디렉토리가 있습니다 (제외 권장)${NC}"
    ((warnings++))
else
    echo -e "${GREEN}✓ node_modules 없음${NC}"
fi

if [ -f "backstage-image.tar" ]; then
    echo -e "${YELLOW}⚠️  Docker 이미지 TAR 파일이 있습니다 (별도 공유 권장)${NC}"
    ((warnings++))
else
    echo -e "${GREEN}✓ 이미지 TAR 없음${NC}"
fi

if find . -name "*.log" -o -name "*.tmp" | grep -q .; then
    echo -e "${YELLOW}⚠️  임시/로그 파일이 있습니다${NC}"
    ((warnings++))
else
    echo -e "${GREEN}✓ 임시 파일 없음${NC}"
fi

# 3. 필수 파일 확인
echo ""
echo "3️⃣  필수 파일 검사..."
required_files=(
    "README.md"
    "SETUP.md"
    "SHARING_CHECKLIST.md"
    ".gitignore"
    "kind-config.yaml"
    "k8s/00-namespace.yaml"
    "k8s/01-postgres-secrets.yaml"
    "k8s/02-postgres-storage.yaml"
    "k8s/03-postgres-deployment.yaml"
    "k8s/04-backstage-secrets.yaml"
    "k8s/05-backstage-deployment.yaml"
    "backstage-app/package.json"
    "docs/DEPLOYMENT_GUIDE.md"
    "docs/QUICK_REFERENCE.md"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ 필수 파일 누락: $file${NC}"
        ((errors++))
    fi
done
echo -e "${GREEN}✓ 모든 필수 파일 존재${NC}"

# 4. 문서 링크 확인
echo ""
echo "4️⃣  문서 링크 검사..."
if ! grep -q "SETUP.md" README.md; then
    echo -e "${YELLOW}⚠️  README.md에 SETUP.md 링크가 없습니다${NC}"
    ((warnings++))
else
    echo -e "${GREEN}✓ SETUP.md 링크 존재${NC}"
fi

if ! grep -q "DEPLOYMENT_GUIDE.md" README.md; then
    echo -e "${YELLOW}⚠️  README.md에 DEPLOYMENT_GUIDE.md 링크가 없습니다${NC}"
    ((warnings++))
else
    echo -e "${GREEN}✓ DEPLOYMENT_GUIDE.md 링크 존재${NC}"
fi

# 5. 파일 크기 확인
echo ""
echo "5️⃣  파일 크기 검사..."
total_size=$(du -sh . | cut -f1)
echo "총 프로젝트 크기: $total_size"

if [ -d "backstage-app/node_modules" ]; then
    nm_size=$(du -sh backstage-app/node_modules 2>/dev/null | cut -f1)
    echo -e "${YELLOW}node_modules 크기: $nm_size${NC}"
fi

# 6. Git 상태 확인
echo ""
echo "6️⃣  Git 상태 검사..."
if [ -d ".git" ]; then
    if git status --porcelain 2>/dev/null | grep -q '^??'; then
        echo -e "${YELLOW}⚠️  추적되지 않은 파일이 있습니다${NC}"
        ((warnings++))
    else
        echo -e "${GREEN}✓ 모든 파일 추적 중${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Git 저장소가 초기화되지 않았습니다${NC}"
    ((warnings++))
fi

# 결과 요약
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 검증 결과"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    echo -e "${GREEN}✅ 모든 검사 통과! 공유 준비 완료${NC}"
    echo ""
    echo "다음 단계:"
    echo "  1. git init (아직 안 했다면)"
    echo "  2. git add ."
    echo "  3. git commit -m 'Initial commit'"
    echo "  4. GitHub에 푸시 또는 ZIP 생성"
    exit 0
elif [ $errors -eq 0 ]; then
    echo -e "${YELLOW}⚠️  경고 ${warnings}개 발견 (공유 가능하지만 권장사항 확인)${NC}"
    echo ""
    echo "경고 사항을 확인하고 필요시 수정하세요."
    exit 0
else
    echo -e "${RED}❌ 오류 ${errors}개 발견! 수정 필요${NC}"
    echo -e "${YELLOW}⚠️  경고 ${warnings}개${NC}"
    echo ""
    echo "오류를 수정한 후 다시 실행하세요."
    exit 1
fi

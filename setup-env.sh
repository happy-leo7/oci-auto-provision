#!/bin/bash

# ============================================
# OCI 환경변수 파일(.env) 자동 생성 스크립트
# OCI CLI가 설정되어 있어야 합니다
# ============================================

ENV_FILE=".env"

echo "=== OCI 환경변수 설정 시작 ==="
echo ""

# 1. Compartment(Tenancy) OCID
echo "[1/5] Compartment OCID 조회 중..."
COMPARTMENT_OCID=$(oci iam compartment list --include-root \
    --query "data[?\"compartment-id\"==null].id | [0]" --raw-output 2>/dev/null)

if [ -z "$COMPARTMENT_OCID" ]; then
    echo "❌ Compartment OCID를 가져올 수 없습니다. OCI CLI 설정을 확인하세요."
    exit 1
fi
echo "✅ $COMPARTMENT_OCID"

# 2. Availability Domain
echo "[2/5] Availability Domain 조회 중..."
AVAILABILITY_DOMAIN=$(oci iam availability-domain list \
    -c "$COMPARTMENT_OCID" \
    --query "data[0].name" --raw-output 2>/dev/null)
echo "✅ $AVAILABILITY_DOMAIN"

# 3. Subnet OCID (public subnet 자동 선택)
echo "[3/5] Public Subnet OCID 조회 중..."
SUBNET_OCID=$(oci network subnet list \
    -c "$COMPARTMENT_OCID" \
    --query "data[?starts_with(\"display-name\",'public')].id | [0]" --raw-output 2>/dev/null)

if [ -z "$SUBNET_OCID" ] || [ "$SUBNET_OCID" = "None" ]; then
    echo "⚠️  Public subnet을 찾을 수 없습니다. 전체 목록에서 선택합니다..."
    SUBNET_OCID=$(oci network subnet list \
        -c "$COMPARTMENT_OCID" \
        --query "data[0].id" --raw-output 2>/dev/null)
fi
echo "✅ $SUBNET_OCID"

# 4. Image OCID (Ubuntu 24.04 ARM)
echo "[4/5] Ubuntu 24.04 ARM 이미지 조회 중..."
IMAGE_OCID=$(oci compute image list \
    -c "$COMPARTMENT_OCID" \
    --shape "VM.Standard.A1.Flex" \
    --operating-system "Canonical Ubuntu" \
    --operating-system-version "24.04" \
    --query "data[0].id" --raw-output 2>/dev/null)
echo "✅ $IMAGE_OCID"

# 5. SSH 공개키 경로
SSH_PUBLIC_KEY_PATH="$HOME/.ssh/id_rsa.pub"
if [ ! -f "$SSH_PUBLIC_KEY_PATH" ]; then
    echo "[5/5] SSH 키가 없습니다. 생성 중..."
    ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N ""
fi
echo "✅ SSH 키: $SSH_PUBLIC_KEY_PATH"

# .env 파일 생성
cat > "$ENV_FILE" << EOF
# OCI 인스턴스 자동 생성 환경변수
# 생성일: $(date '+%Y-%m-%d %H:%M:%S')

COMPARTMENT_OCID="$COMPARTMENT_OCID"
SUBNET_OCID="$SUBNET_OCID"
IMAGE_OCID="$IMAGE_OCID"
AVAILABILITY_DOMAIN="$AVAILABILITY_DOMAIN"
SSH_PUBLIC_KEY_PATH="$SSH_PUBLIC_KEY_PATH"

# 인스턴스 설정
INSTANCE_NAME="happy-arm-server"
OCPUS=4
MEMORY_GB=24
RETRY_INTERVAL=1800

echo ""
echo "============================================"
echo "✅ $ENV_FILE 파일이 생성되었습니다!"
echo "============================================"
echo ""
cat "$ENV_FILE"
echo ""
echo "다음 단계: ./auto-provision.sh 실행"
#!/bin/bash

# ============================================
# OCI ARM 인스턴스 생성 매크로
# 용량이 확보될 때까지 반복 시도하는 자동 생성 매크로
# ============================================

# .env 파일 로드
ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ $ENV_FILE 파일이 없습니다."
    echo "먼저 ./auto-setup-env.sh 를 실행하세요."
    exit 1
fi
source "$ENV_FILE"

echo "=== OCI ARM 인스턴스 생성 매크로 시작 ==="
echo "인스턴스: $INSTANCE_NAME"
echo "Shape: VM.Standard.A1.Flex ($OCPUS OCPU, ${MEMORY_GB}GB RAM)"
echo "재시도 간격: ${RETRY_INTERVAL}초"
echo "중단하려면 Ctrl+C를 누르세요"
echo ""

ATTEMPT=0

while true; do
    ATTEMPT=$((ATTEMPT + 1))
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] 시도 #$ATTEMPT..."

    RESULT=$(oci compute instance launch \
        --no-retry \
        --auth api_key \
        --compartment-id "$COMPARTMENT_OCID" \
        --availability-domain "$AVAILABILITY_DOMAIN" \
        --shape "VM.Standard.A1.Flex" \
        --shape-config "{\"ocpus\": $OCPUS, \"memoryInGBs\": $MEMORY_GB}" \
        --subnet-id "$SUBNET_OCID" \
        --image-id "$IMAGE_OCID" \
        --assign-public-ip true \
        --display-name "$INSTANCE_NAME" \
        --ssh-authorized-keys-file "$SSH_PUBLIC_KEY_PATH" \
        2>&1)

    if echo "$RESULT" | grep -q '"lifecycle-state": "PROVISIONING"\|"lifecycle-state": "RUNNING"'; then
        echo ""
        echo "============================================"
        echo "✅ 인스턴스 생성 성공!"
        echo "============================================"
        echo "$RESULT" | python3 -c "
import sys,json
d=json.load(sys.stdin)['data']
print(f\"이름: {d['display-name']}\")
print(f\"상태: {d['lifecycle-state']}\")
print(f\"ID: {d['id']}\")
" 2>/dev/null || echo "$RESULT"
        echo ""
        echo "OCI 콘솔에서 Public IP를 확인한 후:"
        echo "ssh -i [프라이빗키경로] ubuntu@[퍼블릭IP]"
        break
    elif echo "$RESULT" | grep -qi "out of capacity\|out of host capacity"; then
        echo "[$TIMESTAMP] 용량 부족 - ${RETRY_INTERVAL}초 후 재시도..."
    else
        echo "[$TIMESTAMP] 응답:"
        echo "$RESULT" | tail -5
        echo "${RETRY_INTERVAL}초 후 재시도..."
    fi

    sleep $RETRY_INTERVAL
done
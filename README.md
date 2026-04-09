# auto-oci-instance

Oracle Cloud Free Tier ARM 인스턴스(4 OCPU, 24GB RAM) 자동 생성 매크로.
"Out of capacity" 발생 시 용량 확보될 때까지 반복 시도하는 인스턴스 생성 매크로입니다.

## 사전 준비

- [Oracle Cloud 계정](https://cloud.oracle.com) 및 VCN/Public Subnet 생성
- SSH 키 페어 (`~/.ssh/id_rsa`)

## 사용법

```bash
# 1. OCI CLI 설치
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# 2. OCI CLI 설정 (완료 후 공개키를 콘솔 → My profile → API keys에 등록)
oci setup config

# 3. 환경변수 파일 생성
./setup-env.sh

# 4. 인스턴스 생성 매크로 실행 (성공 시 자동 종료, 중단: Ctrl+C)
./create-instance-macro.sh

# 5. SSH 접속
ssh -i ~/.ssh/id_rsa ubuntu@[퍼블릭IP]
```

## 참고

- `.env`에 OCID 등 민감 정보 포함 → `.gitignore` 등록됨
- 기본 설정: VM.Standard.A1.Flex / 4 OCPU / 24GB / Ubuntu 24.04
- 재시도 간격은 `.env`의 `RETRY_INTERVAL`로 조절 가능

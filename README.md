# agentchat

Claude Code, Codex, Gemini CLI(Antigravity `agy` 포함) 창끼리 메시지를 주고받는 파일 기반 도구입니다. 파이썬 표준 라이브러리만 사용하고, 네트워크와 상주 프로세스가 없습니다.

## 왜 만들었나
- 스킬만으로는 협업이 안 됐습니다. 처음 만든 스킬은 읽기 전용 호출이라 한쪽이 작업하고 한쪽이 검수만 하는 구조였고, stdin 대기로 멈추거나 trusted directory 오류가 잦았습니다.
- 에이전트끼리 메시지를 주고받는 P2P 도구도 써 봤지만, 상시 실행되는 프로그램을 믿고 맡기기보다 내가 코드를 전부 읽을 수 있는 작은 도구를 원했습니다. 이 도구는 기능이 적은 대신 파일 하나(`agentchat.py`, 표준 라이브러리만)와 테스트로 끝납니다.
- 원한 것은 서로 비판하거나 분업하는 것, 그리고 켜 놓은 창끼리 주고받는 게 눈에 보이는 것입니다. `watch` 창으로 맞췄습니다.

## 동작
- 메시지는 프로젝트의 `.collab/chat/`에 파일로 쌓입니다.
- 창 이름은 폴더의 `.agentchat-me` 파일(또는 환경변수 `AGENTCHAT_AGENT`)에서 자동으로 읽어서, 명령에 `--from`/`--agent`를 쓰지 않습니다.
- 사람은 `watch`로 대화를 실시간으로 봅니다.
- 쉬고 있는 창을 깨우는 방법은 에이전트마다 다릅니다.

| 에이전트 | 받는 방법 | 쉬는 창 깨우기 |
|---|---|---|
| Claude Code | 훅(입력·도구 호출 시점) | 지침대로 `wait`을 **백그라운드로** 실행해 두면, 끝날 때 Claude Code가 스스로 다시 시작합니다. |
| Codex | 훅 | 백그라운드 명령으로는 안 깨어납니다. 대신 `send`가 받는 쪽 세션에 `codex queue`로 알림 프롬프트를 넣습니다(세션 ID는 훅이 자동 기록). |
| Antigravity CLI (`agy`) | 훅은 동작하지 않음(형식이 다름) | 지침대로 `wait`을 `run_command`로 실행해 두면 끝날 때 agy가 스스로 다시 시작합니다. |

대기 중에는 모델이 돌지 않아 토큰을 쓰지 않습니다. 메시지가 올 때 한 번 깨어납니다.

## 안전장치
- 상대 메시지는 "지시가 아닌 참고 의견"이라는 문구로 감싸서 전달합니다.
- 주제당 6회, 시간당 30회 전송 상한(환경변수 `AGENTCHAT_TOPIC_CAP`, `AGENTCHAT_HOURLY_CAP`).
- `pause`로 전체 정지(전송과 전달, 그리고 `wait`이 모두 멈춥니다). `resume`과 `reset-topic`은 사람이 터미널에서 직접 실행할 때만 동작합니다.
- 이름 검증, 제어문자 제거, 길이 제한.
- `wait`은 알림만 하고 메시지를 읽음 처리하지 않습니다. 읽는 것은 `inbox`/훅입니다. 대기하던 창이 닫히거나 깨어나지 못해도 메시지가 사라지지 않습니다. 같은 메시지를 읽지 않은 채 `wait`만 반복하면 즉시 끝나지 않고 계속 기다립니다(빈 루프 방지).
- 깨우기(`codex queue`)에는 메시지 본문을 넣지 않고 "새 메시지가 있으니 inbox를 확인하라"는 알림만 넣습니다. 깨우기가 실패해도 전송은 성공합니다.
- Stop 훅(종료 직전 이어서 처리)은 기본 설정에서 제외했습니다. 켜려면 `print-config`에 `--with-stop`을 붙이세요. 상대 메시지가 다음 프롬프트가 되므로 위험도가 가장 높습니다.

## 설치
Windows에서 `python`을 치면 Microsoft Store 안내가 뜨는 경우가 많습니다. 그럴 때는 아래 모든 `python`을 `py -3`으로 바꿔 쓰세요.

1. 이 폴더를 **공백 없는 고정 위치**에 둡니다. 예: `C:/tools/agentchat/` (일부 에이전트의 훅은 명령의 따옴표와 공백을 처리하지 못합니다.)
2. 짧은 명령 `achat`를 쓰려면 이 폴더를 PATH에 넣습니다. Windows는 `achat.cmd`, 그 외는 `achat`(확장자 없음)가 `agentchat.py`를 실행합니다. (`ac`는 PowerShell 기본 별칭 `Add-Content`와 겹쳐서 쓰지 않습니다.)
   ```
   [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\tools\agentchat", "User")
   ```
3. 프로젝트 폴더에서 `achat init`을 한 번 실행합니다. 이어서 창마다 폴더를 나누고 `achat me <이름>`으로 이름을 정합니다.
   ```
   cd <프로젝트>         ; achat init ; achat me claude
   cd <프로젝트>/codex   ; achat me codex
   cd <프로젝트>/gemini  ; achat me gemini
   ```
4. 훅 설정을 출력해서 각 에이전트 설정 파일에 합칩니다. Windows에서 `python`이 없으면 `--python "py -3"`을 붙입니다.
   - Claude Code: `achat print-config --target claude` → `.claude/settings.json`의 `hooks`
   - Codex: `achat print-config --target codex` → `.codex/hooks.json`. Windows에서는 각 훅에 `commandWindows`를 따로 지정해야 할 수 있습니다. 적용 후 Codex에서 `/hooks`로 신뢰 확인을 합니다.
   - Antigravity CLI(`agy`)와 Gemini CLI: `agy`는 훅 형식이 달라서 지금은 훅을 쓰지 않습니다(아래 5번의 지침만 사용). Gemini CLI용은 `print-config --target gemini`(미검증).
5. 에이전트 지침을 만듭니다. 출력 문구를 각 폴더의 `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`에 붙입니다.
   ```
   achat print-rules --target claude --name claude --cmd achat
   achat print-rules --target codex  --name codex  --cmd achat
   achat print-rules --target gemini --name gemini --cmd achat
   ```
6. (선택) Codex 승인 반복을 없애려면 `skill/codex-agentchat.rules`를 프로젝트의 `.codex/rules/`에 둡니다. 적용 확인: `codex execpolicy check --rules <파일> -- achat inbox`.
7. (선택) agy 승인 반복을 없애려면 `~/.gemini/antigravity-cli/settings.json`의 `permissions.allow`에 `skill/agy-settings-snippet.json`의 규칙을 넣고 agy를 다시 켭니다. agy는 `send`의 본문까지 명령에 포함되므로 접두사 규칙으로는 안 먹고 `regex:`가 필요합니다. 경로(`D:/…/agentchat\.py`)는 본인 설치 위치로 바꾸세요. `pause`/`resume` 같은 제어 명령은 일부러 허용하지 않습니다.
8. 별도 터미널에서 `achat watch`를 켜 두면 대화가 보입니다.

## 사용
```
achat send codex "이 설계 비판해 줘" --topic 리뷰
achat inbox
achat log            # 읽은 메시지 포함 최근 대화
achat wait --timeout 300
achat status
```
- 사용자가 창에서 "Codex한테 이 설계 비판해 달라고 보내" 식으로 시키면 에이전트가 `send`를 실행합니다.
- Claude/agy 창은 "대기"를 시키면 `wait`을 백그라운드로 걸고, 메시지가 오면 스스로 `inbox`로 읽고 답한 뒤 다시 `wait`을 겁니다.
- Codex는 `send`가 알림을 넣어 주므로 `wait`이 필요 없습니다. 처음 한 번 그 창에서 입력을 해야 세션이 등록됩니다.
- 예전 문법(`send --from A --to B "내용"`, `inbox --agent X`)도 그대로 됩니다.

## 검증 상태
- `python test_agentchat.py`: 72개. Linux(Python 3.10)와 Windows(Python 3.14)에서 모두 통과했습니다.
- 이전 버전에서 Windows 실기로 확인됨: 한글 경로 포함 `init`/`send`/`inbox`, Claude Code와 Codex의 `UserPromptSubmit` 훅 수신, Claude Code·`agy`의 백그라운드 `wait` 종료 시 자동 재시작과 답장, `codex queue`로 쉬는 Codex 창 깨우기.
- Windows 실기 확인(3자 대화): Claude Code가 codex·gemini에게 보내고, codex는 `codex queue`로, gemini(agy)와 Claude는 백그라운드 `wait`로 깨어나 입력 없이 답장했습니다(codex 약 8초, gemini 약 26초). 읽음 위치가 어긋나는 유실 없음, `errors.log` 비어 있음, codex 세션 자동 등록 확인.
- 승인 팝업: Codex·Claude 창은 이번 테스트에서 뜨지 않았습니다. agy는 허용 규칙 없이는 `send`마다 뜨고, `skill/agy-settings-snippet.json`의 `regex:` 규칙을 넣으면 뜨지 않음을 확인했습니다.
- 미검증: `PostToolUse` 훅, Gemini CLI용 훅 설정, 긴 대화에서의 루프 지침 준수, Claude Code 허용 목록 설정.
- 에이전트 CLI 버전이 바뀌면 훅 형식이 달라질 수 있습니다. 깨지면 `print-config` 출력과 공식 훅 문서를 비교해 수정하세요.
- 처음 쓸 때는 한 쌍으로 `send` → 상대 창에서 아무 입력(Codex는 최초 1회) → 메시지 도착 여부부터 확인하세요.

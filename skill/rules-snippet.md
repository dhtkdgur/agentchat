## agentchat 지침 문구 만들기
지침 문구는 직접 쓰지 않고 이 명령의 출력을 `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`에 붙인다.

```
achat print-rules --target claude --name claude --cmd achat
achat print-rules --target codex  --name codex  --cmd achat
achat print-rules --target gemini --name gemini --cmd achat     # agy 포함
```
`achat`를 PATH에 넣지 않았다면 `--cmd 'py -3 "C:/tools/agentchat/agentchat.py"'`처럼 실제 실행 명령을 넘긴다.

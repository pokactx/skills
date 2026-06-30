# pokactx-skills

APM (Agent Package Manager) Producer パッケージ。`forge-loop` / `url-summarize` スキルと、それぞれで使う sub-agent（`implementer` / `reviewer` / `verifier` / `deliverer` / `summarizer`）を同梱し、Cursor / Claude Code / Codex の各 harness へ `apm install` 一発で配布できる。

- [APM 公式ドキュメント](https://microsoft.github.io/apm/)
- [Targets matrix（配布先一覧）](https://microsoft.github.io/apm/reference/targets-matrix/)
- [Package Types](https://microsoft.github.io/apm/reference/package-types/)

## 構成

```
.
├── apm.yml                          # Producer manifest
├── .gitignore
└── .apm/
    ├── agents/
    │   ├── implementer.agent.md     # forge-loop Phase 4 implement pass
    │   ├── reviewer.agent.md        # forge-loop Phase 4 review pass
    │   ├── verifier.agent.md        # forge-loop Phase 5 verify pass
    │   ├── deliverer.agent.md       # forge-loop Phase 5 deliver pass (PR / commit)
    │   └── summarizer.agent.md      # url-summarize Phase 2 summarization pass
    └── skills/
        ├── forge-loop/
        │   ├── SKILL.md             # 承認ゲート付き plan→implement/review→verify/deliver ループ
        │   └── TEMPLATES.md         # 調査ブロック・計画テンプレート
        ├── rework-tracker/
        │   ├── SKILL.md             # 同一 root-cause の連続失敗を数えて安全弁を発火
        │   └── scripts/loop_state.sh
        ├── smell-detector/
        │   ├── SKILL.md             # レビューの root-cause を repo 全体で検出し residual risk 化
        │   └── scripts/detect.sh
        ├── url-summarize/
        │   └── SKILL.md             # 単一 URL を compact 要約 + Action plan で提示
        └── apple-container/
            └── SKILL.md             # Apple `container` CLI の操作リファレンス（macOS 26+/Apple silicon）
```

### 含まれるもの

| 種類 | ファイル | 役割 |
|------|----------|------|
| Skill | `.apm/skills/forge-loop/SKILL.md` | 曖昧さを解消し計画を承認させた上で、implement/review をクリアになるまでループし、verify/deliver まで回すオーケストレータ |
| Skill | `.apm/skills/rework-tracker/SKILL.md` | 同一 root-cause の再実装パス連続失敗を決定的に数え、3 連続で安全弁発火。状態ファイル + スクリプト |
| Skill | `.apm/skills/smell-detector/SKILL.md` | レビューで見つけた root-cause パターンを承認スコープ外も含めて repo 全体で検出し residual risk として列挙 |
| Agent | `.apm/agents/implementer.agent.md` | 承認後の implement pass 専用。編集可 |
| Agent | `.apm/agents/reviewer.agent.md` | implement pass 後の review pass 専用。読み取り専用、P0–P3 findings を返す |
| Agent | `.apm/agents/verifier.agent.md` | review クリア後の verify pass 専用。読み取り専用、検証結果と `All pass` を返す |
| Agent | `.apm/agents/deliverer.agent.md` | verify クリア後の deliver pass 専用。PR を開く、または commit-only で納品 |
| Skill | `.apm/skills/url-summarize/SKILL.md` | 単一 URL を取得し、compact 要約・キーポイント・Action plan を提示 |
| Skill | `.apm/skills/apple-container/SKILL.md` | Apple `container` CLI（macOS 26+/Apple silicon）の build/run/exec/system 操作リファレンス |
| Agent | `.apm/agents/summarizer.agent.md` | URL 取得後の summarization pass 専用。読み取り専用、構造化ダイジェストを返す |

## Producer（このリポジトリ）の運用

### 変更フロー

1. `.apm/` 配下のスキル・エージェントを編集する。
2. 必要に応じて `apm.yml` の `version` を上げる。
3. タグを打って公開する（Consumer はタグで pin できる）。

```bash
git tag v0.1.0
git push origin v0.1.0
```

### ローカル検証

`apm` CLI がインストール済みなら、このリポジトリ自身で dry-run 的に展開を確認できる。

```bash
apm install --target cursor --target claude --target codex
```

期待される展開先:

| Primitive | Cursor | Claude Code | Codex |
|-----------|--------|-------------|-------|
| agents | `.cursor/agents/*.md` | `.claude/agents/*.md` | `.codex/agents/*.toml` |
| skills | `.agents/skills/forge-loop/` | `.agents/skills/forge-loop/` | `.agents/skills/forge-loop/` |

skills は Skills convergence により全 harness 共通で `.agents/skills/` に配置される。`.cursor/skills/` 等の harness 固有パスに戻したい場合は `--legacy-skill-paths` を使う。

> `apm` のインストール: `curl -sSL https://aka.ms/apm-unix | sh`（macOS/Linux）、または `brew install microsoft/apm/apm`。

## Consumer（アプリリポジトリ）からの利用

### 1. `apm.yml` を用意

アプリリポジトリのルートに `apm.yml` を置く。`pokactx/skills` のリモートが確定したら `pokactx/skills#v0.1.0` を実際の `org/repo#tag` に差し替えること。

```yaml
name: my-app
version: 1.0.0
targets:
  - cursor
  - claude
  - codex
dependencies:
  apm:
    - pokactx/skills#v0.1.0
```

`targets:` で展開先 harness を指定する。Producer 側には `targets:` は不要。

### 2. 認証（private リポジトリの場合）

APM は内部で `gh` を使う。事前に認証しておくと private/org リポジトリも取得できる。

```bash
gh auth login
```

### 3. インストール

```bash
apm install
```

依存グラフを解決し、各 harness のディレクトリへ agents / skills を展開し、`apm.lock.yaml` を生成する。

### 4. commit 方針

`apm.yml` と `apm.lock.yaml` は必ず commit する（再現性のため）。展開された `.cursor/` / `.claude/` / `.codex/` / `.agents/` を commit するかはチームの方針による:

- **commit する**: clone 直後から CI や cloud Copilot が即座に agent context を持てる。`apm install` 前に動く。
- **commit しない**: `.gitignore` で除外し、全員が `apm install` で生成する。手元と CI で必ず最新になる。

`apm_modules/` はキャッシュ用なので commit しない（`.gitignore` 推奨）。

## ライセンス

MIT

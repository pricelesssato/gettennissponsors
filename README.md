# GetTennisSponsors — SPONSOR OS

テニス特化スポンサーシップ仲介事業。**表側**＝公開ブランド `GetTennisSponsors`（ティザー＋申込/相談）、**裏側**＝管理システム SPONSOR OS（admin/staff）。「実はTennis Collective運営」の種明かしファネル。

> 設計の正本：[`docs/sponsor-os-claude-code-handoff.md`](docs/sponsor-os-claude-code-handoff.md) と [`docs/GOAL_GetTennisSponsors.md`](docs/GOAL_GetTennisSponsors.md)。
> 2026-06-23 の grill-me で主要10判断を確定済み（蒸し返さない）。

## ディレクトリ構成

```
gettennissponsors/
├─ README.md
├─ docs/
│  ├─ GOAL_GetTennisSponsors.md        … ゴール・確定判断・Phase計画（北極星）
│  ├─ sponsor-os-claude-code-handoff.md … 実装正本（データモデル/RLS/画面/段階）
│  ├─ sponsor-system-design.md          … コンセプト補足
│  └─ sponsor-system-mock.html          … 操作可能モック（UIの基準・英語）
├─ db/
│  ├─ 01_schema.sql   … Phase 1 テーブル・enum・生成列・ビュー
│  ├─ 02_rls.sql      … RLSポリシー＋公開フォームの安全なRPC
│  └─ 03_seed.sql     … モックと整合するサンプルデータ
└─ .claude/launch.json … モックのプレビュー設定（python http.server）
```

## 確定スタック

- フロント：静的 HTML/CSS/JS。**2フロント**（裏=admin / 表=public site）、同一バックエンド。
- バック：**Supabase**（Postgres + Auth + RLS + Storage）。
- 言語：**英語のみ**（UI英語、データは自由テキスト＝日本語も入る）。国は ISO2 コード。
- 認証：staff=email+pw、agent=マジックリンク（Phase 3）。

## Phase 1 スコープ（MVP）

- **裏側**：sponsorables（type別タブ）/ companies / contacts / deals パイプライン（案件ごとフィー）/ activities / ダッシュボード。
- **表側（最小）**：published のティザー一覧 / 相談フォーム / 申込フォーム / About。
- 完了条件は `docs/GOAL_GetTennisSponsors.md` §4 を参照。

## DB セットアップ（Supabase）

1. Supabase プロジェクトを作成（Site URL は本番ドメインに一致させる＝localhost不可）。
2. SQL Editor で順に実行：`db/01_schema.sql` → `db/02_rls.sql` → `db/03_seed.sql`。
3. 管理者ユーザーを作成（**Auto Confirm User を有効化**）し、`profiles` に `role='admin'` で1行追加：
   ```sql
   insert into profiles(id, role, name, email)
   values ('<auth.users.id>', 'admin', 'Sato', 'yasuhito.sato@gmail.com');
   ```
4. 既存 seed の `owner_id` を必要に応じてこの管理者IDで更新。

### スキーマの肝
- `sponsorables` は単一テーブル。`type`(player/club/tournament/other) × `sport`(既定tennis) × `details(jsonb)`。`is_published` は `status='published'` の**生成列**。
- `deals.tc_fee_amount` は `amount × tc_fee_pct/100` の**生成列**。エージェント配分・TC手残りは `deal_economics` ビューで算出（二重書き込みを避ける）。
- 公開は `public_sponsorables` **ビュー**（安全列のみ）を anon に grant。基底テーブルへの anon アクセスは無し。
- 公開フォームは `submit_sponsor_application()` / `submit_consult_request()` の **SECURITY DEFINER RPC** のみが anon の書き込み経路。供給は `status='pending'`（非公開）、需要は `companies.source='inbound'` で隔離。

## モックのプレビュー

`docs/sponsor-system-mock.html` を静的配信（例）：
```
python -m http.server 8791 --directory docs
# → http://localhost:8791/sponsor-system-mock.html
```
上部トグルで Admin Console / Public Site を切替。

## 現状と次の一手

- [x] Step 1：設計書を確定差分で更新
- [x] Step 2：モックを新仕様（英語・type別タブ・公開ティザー）で再構築・プレビュー検証
- [x] Step 3a：Phase 1 DBスキーマ／RLS／seed（本リポジトリ）
- [ ] Step 3b：**Supabase 実プロジェクトに適用**（provisioning＝佐藤さんの環境準備待ち）
- [ ] Step 3c：管理画面フロントを Supabase に結線（モックを実データ化）
- [ ] Step 3d：公開サイト（ティザー＋フォームRPC結線）

> alliance-system と同様、RLSテスト・デプロイは provisioning 完了後。スキーマはコード先行で確定済み。

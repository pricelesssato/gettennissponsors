# GOAL — GetTennisSponsors（旧称 TennisSponsor / SPONSOR OS）

> grill-me で詰めた設計判断を反映した**ゴール定義**。Claude Code 実装の北極星。
> 既存の `sponsor-system-design.md` / `sponsor-os-claude-code-handoff.md` / `sponsor-system-mock.html` を上書きする"確定差分"として参照する。
> 最終確定: 2026-06-23 / オーナー: 佐藤 安人

---

## 0. ゴール文（North Star）

**テニスのスポンサーシップ仲介（ブローカー）事業を、属人営業から"回り続ける仕組み"にする。**
供給側（協賛を募集する選手・クラブ・大会）と需要側（協賛企業）を、TC＋エージェントが繋ぎ、成約額から手数料を取る。表側＝公開ブランド `GetTennisSponsors`、裏側＝管理システム（SPONSOR OS）。「実はTennis Collective運営」という種明かしで信頼とファネルを作る。

**事業の本質**：テニス特化のスポンサーシップ・マーケットプレイス＋CRM。競合 OpenSponsorship（全競技横断）が取れていない"テニス専門"ニッチを取り切る。

---

## 1. 確定した設計判断（LOCKED — 蒸し返さない）

| # | 論点 | 確定 |
|---|---|---|
| 1 | マッチング vs 提案 | **提案パイプライン（deals）が背骨。マッチングは独立機能化せず、「企業の課題カテゴリ × sponsorable」を突き合わせる"サジェスト層"** |
| 2 | 在庫エンティティ | **単一テーブル `sponsorables`。`type ∈ {player, club, tournament, other}` ＋ `sport`（既定 tennis）＋ type固有項目は `details(jsonb)`。UIでtype別タブに分離。物理分割しない** |
| 3 | 供給側の入口 | **自己登録できるが審査ゲート必須**（`status: draft/pending/published`）。初期は運営入力が呼び水、定常は審査付き自己登録。「供給は放っておいても集まる」前提 |
| 4 | 需要側の入口 | **エージェントによるアウトバウンドが主。** 公開プロフィールの「協賛を相談する」フォームからの inbound は少数（`companies.source=inbound`） |
| 5 | エージェント報酬の起点 | **需要側（スポンサー企業）を連れてきた時のみ。** 供給側の紹介には報酬を出さない。`referrals` は需要側1本（`side`列不要） |
| 6 | 公開範囲 | **ティザー公開**：一覧は安全な概要のみ（`public_summary`）。金額・連絡先・詳細・成約状況は非公開。連絡は必ず運営経由 |
| 7 | 多言語 | **英語のみ。** UIは英語、データは自由テキスト1本（日本語入力も可・並行翻訳しない）、`{en,ja}` jsonb層は作らない |
| 8 | 国 | `sponsorables` / `companies` / `contacts` に **`country`（ISO 3166-1 alpha-2）**。表示は英語名、データに国名文字列を直書きしない |
| 9 | 手数料モデル | **既定Z＝TCフィー20%は契約が続く限り毎年／エージェントフィー(5–10%)は初回契約分のみ。ただし案件ごとに可変**（`tc_fee_pct` / `agent_fee_pct` / `payout_basis ∈ {initial_term, every_year}` を deal/contract に持つ） |
| 10 | ブランド/スコープ | **テニス特化でローンチ（ブランド=GetTennisSponsors）。ただしスキーマは `sport` 列でスポーツ非依存に作り、将来"開けるだけ"にする。多スポーツ展開は今やらない** |

**算出ルール（共通・パラメータだけ案件ごと）**：
`tc_fee_amount = amount × tc_fee_pct`／`agent_payout = amount × agent_fee_pct`／`tc_net = tc_fee_amount − agent_payout`。
TCフィーは `payout_basis=every_year` 時は契約各年度に計上。`agent_payout` は既定 `initial_term`＝初回成約時1回のみ生成。

---

## 2. データモデル確定差分（既存設計からの変更点）

1. `properties` → **`sponsorables`** にリネーム＆一般化。追加列：`type`、`sport`(既定 tennis)、`status`(draft/pending/published)、`is_published`、`public_summary`、`country`、`details(jsonb)`。
2. `deals.property_id` → **`deals.sponsorable_id`**（外部キー1本のまま全type対応）。
3. `deals` / `contracts` に **手数料パラメータ**（`tc_fee_pct`, `agent_fee_pct`, `payout_basis`）。
4. `companies` / `contacts` に **`country`**。`companies.source` に `inbound` を追加。
5. `referrals` は**需要側のみ**（紹介先は `company_id`）。`side` 列は作らない。
6. **i18n層は作らない**（UI英語固定、`{en,ja}` jsonb 不要）。

---

## 3. Phase計画（表＋裏を薄く同時に立ち上げる）

> オーナー方針：エラーを嫌う・一気に作らない・各Phaseでレビュー。表側も早く欲しい（種明かしファネル）ため、Phase 1 に**最小の公開ティザー**を含める。

### ★ Phase 1（MVP — まず回す）
**裏側（管理画面 / admin）**
- `sponsorables`（type別タブUI・英語・国コード・公開フラグと `public_summary` の入れ物）登録/編集
- `companies` / `contacts` 登録/編集
- `deals` パイプライン（候補→アプローチ→交渉中→契約／案件ごとフィー設定／サジェスト層の最小版＝課題カテゴリ一致の候補表示）
- `activities`（活動ログ）
- ダッシュボード（KPI・要対応タスク）

**表側（公開 / GetTennisSponsors.com）— 最小ティザー**
- `is_published=true` の sponsorables の**ティザー一覧**（read-only・概要のみ・国フィルタ）
- 各プロフィールに **「協賛を相談する」フォーム**（→ `companies.source=inbound` で起票）
- 供給側の **「協賛を募集する」申込みフォーム**（→ `sponsorables.status=pending` で起票・非公開）
- 「実はTennis Collective運営」のブランドLP（About）

### Phase 2（複利装置）
- `contracts` / `reports`（経過・成果報告＋証跡Storage）／更新管理（`renewal_due` 自動フラグ・更新提案）

### Phase 3（エージェント開放）
- 紹介リンク（`/r/{agent_code}` → GetTennisSponsors のティザーへ着地・cookie帰属）＋ `referrals` ＋ agent権限/RLS ＋ `payouts`

### Phase 4
- サーキット束売り集計、通知自動化（更新期日・要対応メール）、多スポーツ展開判断

---

## 4. Phase 1 完了条件（Definition of Done）

- [ ] admin が選手/クラブ/大会/その他を `sponsorables` に登録でき、type別タブで一覧できる
- [ ] admin が企業・連絡先を登録でき、deal を作って候補→交渉→契約のパイプラインで動かせる
- [ ] deal ごとに手数料率を設定し、TCフィー/エージェント配分/TC手残りが自動計算で表示される
- [ ] ダッシュボードに KPI（募集中数・進行商談・パイプライン総額・想定TCフィー）と要対応タスクが出る
- [ ] 公開サイトで published な sponsorable のティザーが見え、相談フォーム/申込みフォームが送信でき、裏側に起票される
- [ ] 全UI英語・国コードで絞り込み可・Supabase RLSで agent/inbound が金額・連絡先・商談を見られない
- [ ] 各画面はモック（`sponsor-system-mock.html`）のトーン準拠。各ステップで動作確認＆レビューを挟んだ

---

## 5. 残・要決定（Phase 1 では止めない／将来詰める）

1. **同一成約に供給/需要の別エージェントが絡む場合の按分** → 起きてから（Phase 3+）。
2. **紹介リンクの着地ページ**：sponsorable個別ティザー or 共通問い合わせ → Phase 3で決定。
3. **agent_code 採番ルール** → Phase 3。
4. **通知手段**（メール/画面/両方・送信元 heteml SMTP）→ Phase 2–3。
5. **多スポーツ展開の出し方**（親ブランド乗せ替え or 兄弟サイト）→ テニスのループが回ってから。
6. **`tennissponsorship.com` 等キーワードドメインのリダイレクト取得**（SEO受け皿）→ 任意・早めでも可。

---

## 6. 技術スタック（既存パターン踏襲・確定）

- フロント：静的 HTML/CSS/JS。**裏側＝管理コンソール / 表側＝GetTennisSponsors 公開サイト** の2フロント、同一 Supabase バックエンド。
- バック：Supabase（Postgres + Auth + RLS + Storage）。命名 snake_case。
- 認証：staff=email+password、agent=マジックリンク（Phase 3）。Site URLは本番ドメイン一致・Auto Confirm有効。
- メール：heteml SMTP（Supabase 429回避）。
- フォント：Noto Sans JP（UI）。ただし表示は英語。
- 既知のハマり：`create_file` は既存パスで失敗→`rm -f`/heredoc 上書き。

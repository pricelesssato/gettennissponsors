# Claude Code 引継ぎ書 — GetTennisSponsors / SPONSOR OS（確定版 2026-06-23）

> テニス特化スポンサーシップ仲介事業の実装正本。2026-06-23 の grill-me で確定した10判断を反映済み。
> 旧版（`properties` 前提・EN/JA二言語前提）から**全面改訂**。本書と `GOAL_GetTennisSponsors.md` が最新の正。`sponsor-system-design.md` はコンセプト補足。
>
> **参照成果物（同梱）**：`sponsor-system-mock.html`（UIの基準）、`GOAL_GetTennisSponsors.md`（ゴール・確定判断一覧）。

---

## 0. 進め方（重要）

- **Phase単位で、段階的に・各ステップ確認しながら**実装する（オーナーはエラーを強く嫌う。一気に作らない）。
- 各Phaseの完了時に動作確認とレビューを挟む。
- UIはモック（`sponsor-system-mock.html`）の構成・トーンを基準とする。勝手に構成を変えない。
- **UIは英語のみ**（後述）。

## 1. プロダクト概要

テニスのスポンサー獲得を「属人営業」から「回り続ける仕組み」へ。**TCがスポンサーシップの仲介業（ブローカー）**になる。供給側（協賛を募る選手/クラブ/大会）と需要側（協賛企業）を、TC＋エージェントが繋ぎ、成約額から手数料を取る。

- **表側**：公開ブランド **GetTennisSponsors**（`gettennissponsors.com`）。ティザー公開＋申込み/相談フォーム。
- **裏側**：管理システム **SPONSOR OS**（admin/staff）。在庫・商談・報告・更新・紹介の全管理。
- **種明かし**：「実はTennis Collective運営」で信頼とファネルを作る。表側は独立ブランドとして立てる。

4機能：①在庫（sponsorables）②商談CRM（deals）③実務フロー（報告・更新＝複利装置）④紹介（エージェント）。

## 2. 利用者・ロール

| ロール | 説明 | 権限 |
|---|---|---|
| `admin` | 佐藤（管理者） | 全データ・設定・フィー確定・分配管理 |
| `staff` | 運営スタッフ | 担当する商談・報告（範囲限定可） |
| `agent` | TCユーザー＝エージェント | 募集中案件の閲覧、紹介リンク付き紹介文のコピー。**需要側（協賛企業）紹介のみ報酬対象**。状況表示は将来（Phase 3） |

> エージェントは乙（Tennis Collective Japan／OÜ）の下に起用。フィー分配は本システム側で計算・記録（上流契約 第5条整合）。「成約額 → TC手数料 → エージェント配分 → TC手残り」を記録できること。

## 3. 確定した設計判断（LOCKED — 蒸し返さない）

1. **マッチングは独立機能化しない**。`deals`（企業×sponsorable）の提案パイプラインが背骨。マッチングは「企業の課題カテゴリ × sponsorable」のサジェスト層。
2. **在庫は単一テーブル `sponsorables`**。`type ∈ {player, club, tournament, other}` ＋ `sport`（既定 tennis）＋ type固有は `details(jsonb)`。UIでtype別タブに分離。物理分割しない。
3. **供給側は自己登録可だが審査ゲート必須**（`status: draft/pending/published`）。供給は放っておいても集まる前提。
4. **需要側はエージェントのアウトバウンドが主**。inboundは相談フォーム経由の少数（`companies.source=inbound`）。
5. **エージェント報酬は需要側を連れてきた時のみ**。供給紹介は無報酬。`referrals` は需要側1本。
6. **公開はティザーのみ**（`public_summary`）。金額・連絡先・商談・成約状況は非公開。連絡は運営経由。
7. **英語のみ**。UI英語固定、データは自由テキスト1本（日本語入力も可）、`{en,ja}` jsonb翻訳層は作らない。
8. **国は `country`（ISO 3166-1 alpha-2）**。表示は英語名。
9. **手数料は案件ごと可変**。既定Z＝TC20%は契約継続中毎年／エージェント5-10%は初回契約分のみ。`tc_fee_pct`/`agent_fee_pct`/`payout_basis` を deal/contract に持つ。
10. **テニス特化ローンチ**（ブランドはtennis）。schemaは `sport` 列で非依存。多スポーツ展開は今やらない。

## 4. 技術スタック

- フロント：静的 HTML/CSS/JS（フレームワーク無し or 軽量）。**2フロント**：裏側＝管理コンソール／表側＝GetTennisSponsors 公開サイト。
- バック：**Supabase**（Postgres + Auth + RLS + Storage）。同一バックエンドを2フロントが共有。
- 認証：`staff`＝email+password、`agent`＝マジックリンク（OTP, Phase 3）。Ellisアプリと同方式。
- メール：heteml の SMTP（Supabaseのレート制限/429回避）。
- フォント：Noto Sans JP（記号・等幅含む。ただし**表示文言は英語**）。
- i18n：**無し（英語のみ）**。

### 既知のハマりどころ（過去の学び）
- Supabase の **Site URL は本番ドメインに一致**させる（localhost不可）。
- 管理者ユーザー作成時は **Auto Confirm User を有効化**。
- SMTP未設定だとメール429。heteml SMTPで解消。
- ファイル生成系スクリプトは `create_file` が既存パスで失敗 → `rm -f` か heredoc で上書き。

## 5. データモデル（実装テーブル）

> 命名 snake_case。`*` は必須相当。型・制約は実装側で詳細化。

- **sponsorables**（在庫／協賛を募る対象）: id*, **type**(player/club/tournament/other)*, **sport**(default 'tennis')*, name*, location, country(ISO2), period, operator(大会の運営), **details**(jsonb: type固有項目＝選手のランク/SNS、クラブの規模、大会のITF種別 等), tiers(jsonb: 冠/メイン/サポート/サプライヤー), open_slots, price_range, **status**(draft/pending/published)*, **is_published**(bool, default false), **public_summary**(text: 公開ティザー用の安全な概要), primary_contact_id→contacts, notes
- **companies**（スポンサー企業）: id*, name*, industry, size, country(ISO2), need_category(A売上/Bブランド/C人/D節目), **source**(form/agent/direct/inbound), primary_contact_id→contacts, notes
- **contacts**（連絡先）: id*, name, title, email, phone, country(ISO2), belongs_to(company/sponsorable), note
- **deals**（商談）★中心: id*, company_id→companies, **sponsorable_id→sponsorables**, stage(候補/アプローチ/交渉中/契約/運用中/更新/失注)*, proposed_tier, activations(jsonb: メニュー番号配列), amount, **tc_fee_pct**(default 20), tc_fee_amount(算出), **agent_fee_pct**(5-10, nullable), **payout_basis**(initial_term/every_year, default initial_term), agent_id→users(nullable), owner_id→users, next_action, next_action_due
- **activities**（活動ログ）: id*, deal_id→deals*, date*, type(mail/call/visit/form/memo), body, user_id
- **contracts**（契約）: id*, deal_id→deals*, start, end, amount, term_years, **fee_per_year**(bool: TCフィーを各年度計上するか), auto_renew(bool), right_to_match(bool), renewal_due, status
- **reports**（レポート）: id*, deal_id→deals*, kind(経過/成果)*, period, metrics(jsonb: qr_scans, code_uses, est_sales, impressions, applications…), evidence(Storageパス配列), status(下書き/送付済), sent_at
- **referrals**（紹介・需要側のみ）: id*, agent_id→users*, **company_id→companies**(紹介先企業), source(referral_link), status(受付/連絡済/商談化/成約/見送り), deal_id→deals(nullable), expected_fee, note
- **users**: id*, role(admin/staff/agent)*, name, email, agent_code(エージェント固有・紹介リンク用, nullable), agent_profile(任意)
- **payouts**（Phase 3+）: id*, agent_id→users*, referral_id→referrals, deal_id→deals, amount, status(予定/確定/支払済), paid_at

**算出ルール**：`tc_fee_amount = amount × tc_fee_pct`／`agent_payout = amount × agent_fee_pct`／`tc_net = tc_fee_amount − agent_payout`。
TCフィーは `contracts.fee_per_year=true` のとき契約各年度に計上。`agent_payout` は `payout_basis=initial_term`（既定）なら初回成約時1回のみ生成。

## 6. 権限（Supabase RLS 方針）

- `agent`：`sponsorables` は `is_published=true` の公開列（`public_summary` 等）のみ。`referrals` は `agent_id = auth.uid()` のみ。`deals`/`companies`/`amount`/連絡先は不可視。
- `staff`：`deals.owner_id = auth.uid()`（または管理者が共有指定）。
- `admin`：全行。
- 公開サイト（匿名）：`sponsorables` の `is_published=true` の安全列のみ read。フォーム送信は anon insert を専用テーブル/RPCで受け、`status=pending` 等で隔離。
- Storage（証跡）：署名付きURL配布。`agent`・匿名は不可。
- 機密（口座等）はシステムに保存しない（本人管理）。

## 7. 主要フロー

**① 営業**：sponsorable選定 → ターゲット企業特定 → アプローチ(フォーム営業/紹介) → ヒアリングで課題を4カテゴリに特定 → 提案(ティア×アクティベーション) → 契約 → 運用。
**② 報告（複利装置・Phase 2）**：運用中dealに定期「経過報告」→ 期末「成果報告（QR・限定コード・アプリ計測の実数＋証跡）」→ `renewal_due` 前に「更新提案」を自動フラグ。
**③ 紹介（リンク方式・Phase 3）**：エージェントが公開ティザーの**紹介文（紹介リンク付き）をコピー** → 協賛しそうな企業へ共有 → 企業がリンク流入＝**誰の紹介か自動記録** → 運営が連絡・dealに紐付け → 成約 → `agent_payout` 確定 → 分配。クローズは運営担当。

## 8. 公開サイト（GetTennisSponsors）仕様

- **ティザー一覧**：`is_published=true` の sponsorables を type別/国別に表示。概要のみ（`public_summary`）。金額・連絡先は出さない。
- **「協賛を相談する」フォーム**（需要inbound）：企業 → `companies.source=inbound` で起票。
- **「協賛を募集する」申込みフォーム**（供給）：選手/クラブ/大会 → `sponsorables.status=pending`（非公開）で起票。運営が審査して `published` に上げる。
- **About**：「実はTennis Collective運営」のブランドストーリー。
- 紹介リンク `gettennissponsors.com/r/{agent_code}` の着地はこのティザー（Phase 3で帰属記録）。

## 9. 画面（モック基準）

**管理画面（admin/staff）**：① ダッシュボード（KPI・要対応・最近の紹介）／② 在庫 sponsorables（**type別タブ：選手/クラブ/大会/その他**・公開フラグ・連絡先）／③ 商談パイプライン（候補/交渉中/契約中/更新のボード）／④ 商談詳細ドロワー（企業・連絡先・ティア・アクティベーション・**フィー計算**・活動ログ・報告・契約）／⑤ レポート（Phase 2）／⑥ 更新管理（Phase 2）／⑦ 紹介管理（Phase 3）。
**公開（GetTennisSponsors）**：⑧ ティザー一覧／⑨ 相談フォーム／⑩ 申込みフォーム／⑪ About。

## 10. 段階構築

- **★ Phase 1（MVP）**：
  - 裏側：users/sponsorables/companies/contacts/deals/activities ＋ ダッシュボード・在庫(type別タブ)・パイプライン・商談詳細(フィー計算)。
  - 表側（最小）：ティザー一覧（read-only）＋ 相談フォーム ＋ 申込みフォーム ＋ About。
- **Phase 2（複利装置）**：contracts/reports ＋ 更新管理・成果報告（証跡Storage）。
- **Phase 3（エージェント開放）**：紹介リンク帰属＋referrals＋agent権限/RLS＋payouts。
- **Phase 4**：サーキット束売り集計、通知自動化（更新期日・要対応メール）、多スポーツ展開判断。

> Phase順は事業の検証順（自分でクローズ→継続→エージェント開放）と一致。**Phase 3を前倒ししない**。

## 11. 残・要決定（Phase 1 では止めない）

1. 同一成約に供給/需要の別エージェントが絡む場合の按分（Phase 3+）。
2. 紹介リンク着地ページの細部（個別ティザー or 共通問い合わせ）。
3. agent_code 採番ルールとコピーUX。
4. 通知手段（メール/画面/両方・送信元 heteml SMTP）。
5. 多スポーツ展開の出し方（親ブランド乗せ替え or 兄弟サイト）。
6. `tennissponsorship.com` 等キーワードドメインのリダイレクト取得（SEO受け皿・任意）。

## 12. 非ゴール / 制約

- 口座情報・決済処理はシステムに持たせない（分配は記録のみ）。
- agent には金額・商談・他人の紹介・連絡先を一切見せない（RLSで厳格化）。
- UIトーンはモック準拠（深いコートグリーン＋白基調、過度な装飾なし）。**文言は英語**。
- 多スポーツは器（`sport`列）だけ用意し、当面テニスのみ運用。

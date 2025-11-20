# Requirements Document

## Project Description (Input)
junitifyは、Dartのテストフレームワークが出力するJSON形式のテスト結果を、CI/CDシステムやテストレポートツールで広く使用されているJUnit XML形式に変換するコマンドラインツールです。

## Requirements

### Requirement 1: TestSuiteモデルへのsystem-outフィールド追加
**Objective:** As a 開発者, I want TestSuiteモデルにsystem-out用のフィールドを追加する機能, so that テストスイートレベルの標準出力を保持できる

#### Acceptance Criteria
1. The TestSuite class shall `systemOut` という名前のオプショナルなString型フィールドを持つ
2. When systemOutフィールドがnullの場合, the TestSuite shall 従来通り動作し、後方互換性を保つ
3. When systemOutフィールドが空文字列の場合, the system shall それを有効な値として扱う
4. The systemOutフィールド shall テストスイートに属するすべてのprint出力を改行区切りで連結した文字列を含む
5. The TestSuite constructor shall systemOutパラメータをオプショナルとして受け入れる

### Requirement 2: パーサーでのprintイベント収集
**Objective:** As a 開発者, I want パーサーがprintイベントを収集してテストスイートに紐付ける機能, so that テストスイートレベルの標準出力を記録できる

#### Acceptance Criteria
1. When JSON内に`type: "print"`イベントが含まれている場合, the parser shall そのイベントの`testID`から対応するテストスイートを特定する
2. When printイベントを処理する場合, the parser shall そのイベントの`message`フィールドの内容を取得する
3. When 同じテストスイートに複数のprintイベントが存在する場合, the parser shall それらを時系列順に改行区切りで連結する
4. When printイベントの`message`が空文字列の場合, the parser shall 改行文字として扱う
5. When テストスイートに属するprintイベントが存在しない場合, the parser shall systemOutフィールドをnullのままにする
6. When printイベントの`testID`が存在しない、または対応するテストケースが見つからない場合, the parser shall そのイベントを無視する（エラーを発生させない）

### Requirement 3: JUnit XMLでのsystem-outタグ生成
**Objective:** As a 開発者, I want JUnit XMLの`<testsuite>`要素に`<system-out>`タグを生成する機能, so that CI/CDツールでテストスイートの標準出力を確認できる

#### Acceptance Criteria
1. When TestSuiteのsystemOutフィールドがnullでない場合, the converter shall `<testsuite>`要素内に`<system-out>`子要素を生成する
2. When `<system-out>`タグを生成する場合, the converter shall systemOutフィールドの内容をそのタグのテキストコンテンツとして設定する
3. When TestSuiteのsystemOutフィールドがnullまたは空文字列の場合, the converter shall `<system-out>`タグを生成しない
4. When `<system-out>`タグを生成する場合, the converter shall XMLエスケープ（&lt;, &gt;, &amp;等）を適切に処理する
5. The `<system-out>`タグ shall `<testcase>`要素の前に配置される（JUnit XMLスキーマに準拠）
6. The XML output shall 既存のCI/CDツール（Jenkins、GitLab CI、GitHub Actions等）と互換性を保つ

### Requirement 4: 後方互換性の維持
**Objective:** As a 開発者, I want system-out機能の追加が既存の動作に影響を与えないようにする機能, so that 既存のワークフローが壊れない

#### Acceptance Criteria
1. When TestSuiteのsystemOutフィールドがnullの場合, the system shall 従来通り動作し、XML出力に変更がない
2. When printイベントが存在しないJSONを処理する場合, the system shall エラーを発生させず、従来通り処理する
3. When printイベントの構造が不正な場合, the system shall そのイベントを無視し、エラーを発生させない
4. The system shall 既存のテストケースの動作（passed、failed、skipped）に影響を与えない
5. The system shall 既存のAPIインターフェースを変更しない（オプショナルパラメータの追加のみ）

### Requirement 5: パフォーマンスへの影響最小化
**Objective:** As a 開発者, I want system-out機能の追加がパフォーマンスに大きな影響を与えないようにする機能, so that 大規模なテスト結果でも効率的に処理できる

#### Acceptance Criteria
1. When printイベントを処理する場合, the parser shall 効率的な文字列連結方法（StringBuffer等）を使用する
2. When 大量のprintイベントが存在する場合, the system shall メモリ使用量を適切に管理する
3. The system shall 既存のパフォーマンス要件（10,000件のテストケースを10秒以内に処理）を満たす
4. When systemOutフィールドがnullの場合, the system shall 追加の処理オーバーヘッドを最小限に抑える


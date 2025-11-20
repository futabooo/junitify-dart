# Requirements Document

## Project Description (Input)
junitifyは、Dartのテストフレームワークが出力するJSON形式のテスト結果を、CI/CDシステムやテストレポートツールで広く使用されているJUnit XML形式に変換するコマンドラインツールです。

## Requirements

### Requirement 1: TestSuiteモデルへのsystem-errフィールド追加
**Objective:** As a 開発者, I want TestSuiteモデルにsystem-err用のフィールドを追加する機能, so that テストスイートレベルの標準エラー出力を保持できる

#### Acceptance Criteria
1. The TestSuite class shall `systemErr` という名前のオプショナルなString型フィールドを持つ
2. When systemErrフィールドがnullの場合, the TestSuite shall 従来通り動作し、後方互換性を保つ
3. When systemErrフィールドが空文字列の場合, the system shall それを有効な値として扱う
4. The systemErrフィールド shall テストスイートに属するすべてのエラー出力を改行区切りで連結した文字列を含む
5. The TestSuite constructor shall systemErrパラメータをオプショナルとして受け入れる

### Requirement 2: パーサーでのエラー出力イベント収集
**Objective:** As a 開発者, I want パーサーがエラー出力イベントを収集してテストスイートに紐付ける機能, so that テストスイートレベルの標準エラー出力を記録できる

#### Acceptance Criteria
1. When JSON内にエラー出力を表すイベントが含まれている場合, the parser shall そのイベントの`testID`から対応するテストスイートを特定する
2. When エラー出力イベントを処理する場合, the parser shall そのイベントの`message`フィールドの内容を取得する
3. When 同じテストスイートに複数のエラー出力イベントが存在する場合, the parser shall それらを時系列順に改行区切りで連結する
4. When エラー出力イベントの`message`が空文字列の場合, the parser shall 改行文字として扱う
5. When テストスイートに属するエラー出力イベントが存在しない場合, the parser shall systemErrフィールドをnullのままにする
6. When エラー出力イベントの`testID`が存在しない、または対応するテストケースが見つからない場合, the parser shall そのイベントを無視する（エラーを発生させない）
7. The parser shall `print`イベントの`messageType`フィールドが`"stderr"`または`"error"`の場合、エラー出力として扱う（Dart テストフレームワークの仕様に準拠）

### Requirement 3: JUnit XMLでのsystem-errタグ生成
**Objective:** As a 開発者, I want JUnit XMLの`<testsuite>`要素に`<system-err>`タグを生成する機能, so that CI/CDツールでテストスイートの標準エラー出力を確認できる

#### Acceptance Criteria
1. When TestSuiteのsystemErrフィールドがnullでない場合, the converter shall `<testsuite>`要素内に`<system-err>`子要素を生成する
2. When `<system-err>`タグを生成する場合, the converter shall systemErrフィールドの内容をそのタグのテキストコンテンツとして設定する
3. When TestSuiteのsystemErrフィールドがnullまたは空文字列の場合, the converter shall `<system-err>`タグを生成しない
4. When `<system-err>`タグを生成する場合, the converter shall XMLエスケープ（&lt;, &gt;, &amp;等）を適切に処理する
5. The `<system-err>`タグ shall `<testcase>`要素の前に配置される（JUnit XMLスキーマに準拠）
6. The `<system-err>`タグ shall `<system-out>`タグの後に配置される（JUnit XMLスキーマに準拠）
7. The XML output shall 既存のCI/CDツール（Jenkins、GitLab CI、GitHub Actions等）と互換性を保つ

### Requirement 4: 後方互換性の維持
**Objective:** As a 開発者, I want system-err機能の追加が既存の動作に影響を与えないようにする機能, so that 既存のワークフローが壊れない

#### Acceptance Criteria
1. When TestSuiteのsystemErrフィールドがnullの場合, the system shall 従来通り動作し、XML出力に変更がない
2. When エラー出力イベントが存在しないJSONを処理する場合, the system shall エラーを発生させず、従来通り処理する
3. When エラー出力イベントの構造が不正な場合, the system shall そのイベントを無視し、エラーを発生させない
4. The system shall 既存のテストケースの動作（passed、failed、skipped）に影響を与えない
5. The system shall 既存のAPIインターフェースを変更しない（オプショナルパラメータの追加のみ）
6. The system shall 既存の`system-out`機能と独立して動作する（両方のフィールドが同時に設定可能）

### Requirement 5: パフォーマンスへの影響最小化
**Objective:** As a 開発者, I want system-err機能の追加がパフォーマンスに大きな影響を与えないようにする機能, so that 大規模なテスト結果でも効率的に処理できる

#### Acceptance Criteria
1. When エラー出力イベントを処理する場合, the parser shall 効率的な文字列連結方法（StringBuffer等）を使用する
2. When 大量のエラー出力イベントが存在する場合, the system shall メモリ使用量を適切に管理する
3. The system shall 既存のパフォーマンス要件（10,000件のテストケースを10秒以内に処理）を満たす
4. When systemErrフィールドがnullの場合, the system shall 追加の処理オーバーヘッドを最小限に抑える


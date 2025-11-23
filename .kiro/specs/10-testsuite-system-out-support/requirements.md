# Requirements Document

## Project Description (Input)
testsuiteタグにsystem-outタグを内容できるようにします。testcaseのsystem-outに変更はありません。testcaseタグの中でprintしたものはtestsuiteタグには含めないようにします。

## Requirements

### Requirement 1: パーサーでのTestSuiteレベルのprintイベント収集
**Objective:** As a 開発者, I want パーサーがtestcaseに紐付かないprintイベントを収集してテストスイートに紐付ける機能, so that テストスイートレベルの標準出力を記録できる

#### Acceptance Criteria
1. When JSON内に`type: "print"`イベントが含まれている場合, the parser shall そのイベントの`testID`フィールドの有無を確認する
2. When printイベントの`testID`が存在しない場合, the parser shall そのイベントをテストスイートレベルで処理する
3. When printイベントの`testID`が存在するが、対応するテストケースが見つからない場合, the parser shall そのイベントをテストスイートレベルで処理する
4. When printイベントの`testID`が存在し、対応するテストケースが見つかる場合, the parser shall そのイベントをテストケースレベルのみで処理し、テストスイートレベルには含めない
5. When printイベントをテストスイートレベルで処理する場合, the parser shall そのイベントの`message`フィールドの内容を取得する
6. When 同じテストスイートに複数のprintイベントが存在する場合, the parser shall それらを時系列順に改行区切りで連結する
7. When printイベントの`message`が空文字列の場合, the parser shall 改行文字として扱う
8. When テストスイートに属するprintイベントが存在しない場合, the parser shall systemOutフィールドをnullのままにする
9. When `_SuiteBuilder`クラスを使用する場合, the parser shall systemOutフィールドを`StringBuffer?`型で保持する
10. When `_buildResult`メソッドでTestSuiteを作成する場合, the parser shall 収集したsystemOutをTestSuiteコンストラクタに渡す
11. When printイベントを処理する場合, the parser shall テストケースレベルのsystemOut処理を変更しない（既存のテストケースレベルの処理は維持する）

### Requirement 2: JUnit XMLでのtestsuiteレベルのsystem-outタグ生成
**Objective:** As a 開発者, I want JUnit XMLの`<testsuite>`要素に`<system-out>`タグを生成する機能, so that CI/CDツールでテストスイートの標準出力を確認できる

#### Acceptance Criteria
1. When TestSuiteのsystemOutフィールドがnullでない場合, the converter shall `<testsuite>`要素内に`<system-out>`子要素を生成する
2. When `<system-out>`タグを生成する場合, the converter shall systemOutフィールドの内容をそのタグのテキストコンテンツとして設定する
3. When TestSuiteのsystemOutフィールドがnullまたは空文字列の場合, the converter shall `<system-out>`タグを生成しない
4. When `<system-out>`タグを生成する場合, the converter shall XMLエスケープ（&lt;, &gt;, &amp;等）を適切に処理する
5. The `<system-out>`タグ shall `<testcase>`要素の前に配置される（JUnit XMLスキーマに準拠）
6. The XML output shall 既存のCI/CDツール（Jenkins、GitLab CI、GitHub Actions等）と互換性を保つ
7. When `<testsuite>`要素内に`<system-out>`タグを生成する場合, the converter shall 既存の`<testcase>`要素内の`<system-out>`タグの生成に影響を与えない（testcaseのsystem-outは変更しない）

### Requirement 3: testcaseレベルのprintイベントの除外
**Objective:** As a 開発者, I want testcaseに紐付くprintイベントがtestsuiteレベルのsystem-outに含まれないようにする機能, so that テストケースレベルの出力とテストスイートレベルの出力が適切に分離される

#### Acceptance Criteria
1. When printイベントの`testID`が存在し、対応するテストケースが見つかる場合, the parser shall そのイベントをテストケースレベルのsystemOutにのみ追加する
2. When printイベントの`testID`が存在し、対応するテストケースが見つかる場合, the parser shall そのイベントをテストスイートレベルのsystemOutに追加しない
3. When テストケースに紐付くprintイベントのみが存在する場合, the parser shall TestSuiteのsystemOutフィールドをnullのままにする
4. When testcaseに紐付くprintイベントとtestcaseに紐付かないprintイベントの両方が存在する場合, the parser shall testcaseに紐付かないprintイベントのみをテストスイートレベルのsystemOutに含める

### Requirement 4: 後方互換性の維持
**Objective:** As a 開発者, I want testsuite-level system-out機能の追加が既存の動作に影響を与えないようにする機能, so that 既存のワークフローが壊れない

#### Acceptance Criteria
1. When TestSuiteのsystemOutフィールドがnullの場合, the system shall 従来通り動作し、XML出力に変更がない
2. When printイベントが存在しないJSONを処理する場合, the system shall エラーを発生させず、従来通り処理する
3. When printイベントの構造が不正な場合, the system shall そのイベントを無視し、エラーを発生させない
4. The system shall 既存のテストケースの動作（passed、failed、skipped）に影響を与えない
5. The system shall 既存のテストケースレベルのsystem-out機能に影響を与えない（testcaseのsystem-outは変更しない）
6. The system shall 既存のAPIインターフェースを変更しない（オプショナルパラメータの追加のみ）

### Requirement 5: パフォーマンスへの影響最小化
**Objective:** As a 開発者, I want testsuite-level system-out機能の追加がパフォーマンスに大きな影響を与えないようにする機能, so that 大規模なテスト結果でも効率的に処理できる

#### Acceptance Criteria
1. When printイベントを処理する場合, the parser shall 効率的な文字列連結方法（StringBuffer等）を使用する
2. When 大量のprintイベントが存在する場合, the system shall メモリ使用量を適切に管理する
3. The system shall 既存のパフォーマンス要件（10,000件のテストケースを10秒以内に処理）を満たす
4. When systemOutフィールドがnullの場合, the system shall 追加の処理オーバーヘッドを最小限に抑える
5. When テストケースレベルとテストスイートレベルの両方でprintイベントを処理する場合, the parser shall 効率的なデータ構造を使用して重複処理を避ける



# Requirements Document

## Project Description (Input)
testsuiteタグの子どもにpropertiesタグを追加して出力する属性はplatform

## Requirements

### Requirement 1: TestSuiteモデルへのplatformフィールド追加
**Objective:** As a 開発者, I want TestSuiteモデルにplatform用のフィールドを追加する機能, so that テストスイートの実行プラットフォーム情報を保持できる

#### Acceptance Criteria
1. The TestSuite class shall `platform` という名前のオプショナルなString型フィールドを持つ
2. When platformフィールドがnullの場合, the TestSuite shall 従来通り動作し、後方互換性を保つ
3. When platformフィールドが空文字列の場合, the system shall それを有効な値として扱う
4. The platformフィールド shall JSONのsuiteイベントから取得したプラットフォーム情報を含む（例: "vm", "chrome"）
5. The platformフィールド shall Dartの`Platform.operatingSystem`から取得したプラットフォーム情報を含むこともできる（例: "linux", "macos", "windows"）
6. The TestSuite constructor shall platformパラメータをオプショナルとして受け入れる
7. When platformフィールドがnullの場合, the system shall XML生成時に`Platform.operatingSystem`を使用して動的に取得する

### Requirement 2: JUnit XMLでのpropertiesタグ生成
**Objective:** As a 開発者, I want JUnit XMLの`<testsuite>`要素に`<properties>`タグを生成する機能, so that CI/CDツールでテストスイートの実行プラットフォーム情報を確認できる

#### Acceptance Criteria
1. When TestSuiteのplatformフィールドがnullでない場合, the converter shall `<testsuite>`要素内に`<properties>`子要素を生成する
2. When `<properties>`タグを生成する場合, the converter shall その中に`<property>`子要素を生成する
3. When `<property>`タグを生成する場合, the converter shall `name="platform"`属性と`value`属性（platformフィールドの値）を設定する
4. When TestSuiteのplatformフィールドがnullの場合, the converter shall XML生成時に`Platform.operatingSystem`を使用して動的に取得し、`<properties>`タグを生成する
5. When platform情報が空文字列の場合, the converter shall `<properties>`タグを生成しない
6. The `<properties>`タグ shall `<testcase>`要素の前に配置される（JUnit XMLスキーマに準拠）
7. When `<properties>`タグを生成する場合, the converter shall XMLエスケープ（&lt;, &gt;, &amp;等）を適切に処理する
8. The XML output shall 既存のCI/CDツール（Jenkins、GitLab CI、GitHub Actions等）と互換性を保つ

### Requirement 3: プラットフォーム情報の取得
**Objective:** As a 開発者, I want プラットフォーム情報を正確に取得する機能, so that テスト実行環境の情報を正確に記録できる

#### Acceptance Criteria
1. When JSONのsuiteイベントに`platform`フィールドが含まれている場合, the parser shall その値をTestSuiteのplatformフィールドに設定する
2. When JSONのsuiteイベントに`platform`フィールドが含まれていない場合, the parser shall platformフィールドをnullのままにする
3. When プラットフォーム情報を取得する場合（platformフィールドがnullの場合）, the system shall Dartの`dart:io`パッケージの`Platform.operatingSystem`を使用する
4. When `Platform.operatingSystem`が返す値は, the system shall 標準的な値（"linux", "macos", "windows", "android", "ios", "fuchsia"）をそのまま使用する
5. When プラットフォーム情報を取得できない場合（例: Web環境）, the system shall エラーを発生させず、platformフィールドをnullのままにする
6. When platformフィールドがnullで、かつプラットフォーム情報を取得できない場合, the converter shall `<properties>`タグを生成しない
7. The プラットフォーム情報の取得 shall パフォーマンスに大きな影響を与えない（既存の処理時間の5%以内の増加）

### Requirement 4: 後方互換性の維持
**Objective:** As a 開発者, I want propertiesタグ機能の追加が既存の動作に影響を与えないようにする機能, so that 既存のワークフローが壊れない

#### Acceptance Criteria
1. When TestSuiteのplatformフィールドがnullの場合, the system shall 従来通り動作し、XML出力に変更がない（platform情報が取得可能な場合を除く）
2. When プラットフォーム情報を取得できない環境で処理する場合, the system shall エラーを発生させず、従来通り処理する
3. The system shall 既存のテストケースの動作（passed、failed、skipped）に影響を与えない
4. The system shall 既存のAPIインターフェースを変更しない（オプショナルパラメータの追加のみ）
5. When 既存のXMLファイルを処理する場合, the system shall エラーを発生させず、従来通り処理する
6. The system shall 既存の`<testcase>`要素、`<system-out>`要素、`<system-err>`要素の生成に影響を与えない

### Requirement 5: テストと検証
**Objective:** As a 開発者, I want propertiesタグが正しく実装されていることを検証する機能, so that JUnit XML標準に準拠していることを確認できる

#### Acceptance Criteria
1. When `<testsuite>`要素を生成する場合, the tests shall `<properties>`タグが`<testcase>`要素の前に配置されることを検証する
2. When `<properties>`タグを生成する場合, the tests shall `<property>`タグが`name="platform"`属性と適切な`value`属性を持つことを検証する
3. When platform情報が取得可能な場合, the tests shall 生成されたXMLに`<properties>`タグが含まれることを検証する
4. When platform情報が取得できない場合, the tests shall 生成されたXMLに`<properties>`タグが含まれないことを検証する
5. When 既存のテストを実行する場合, the tests shall すべてのテストが正常に通過することを確認する
6. When CI/CDツールでXMLファイルを処理する場合, the tests shall 正常に処理されることを確認する
7. When 生成されたXMLファイルを検証する場合, the tests shall JUnit XML標準スキーマに準拠していることを確認する



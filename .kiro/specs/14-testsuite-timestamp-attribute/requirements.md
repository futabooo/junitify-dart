# Requirements Document

## Project Description (Input)
testtuiteタグにtimestamp属性を追加する、formatは右記`2025-12-02T14:25:31`

## Requirements

### Requirement 1: TestSuiteモデルへのtimestampフィールド追加
**Objective:** As a 開発者, I want TestSuiteモデルにtimestamp用のフィールドを追加する機能, so that テストスイートの実行開始時刻を保持できる

#### Acceptance Criteria
1. The TestSuite class shall `timestamp` という名前のオプショナルなDateTime型フィールドを持つ
2. When timestampフィールドがnullの場合, the TestSuite shall 従来通り動作し、後方互換性を保つ
3. The TestSuite constructor shall timestampパラメータをオプショナルとして受け入れる
4. When timestampフィールドがnullの場合, the system shall 以下の優先順位でタイムスタンプを取得する:
   - `--timestamp`オプションが指定されている場合:
     - `now`が指定されている場合、現在時刻（`DateTime.now()`）を使用する
     - `none`が指定されている場合、timestamp属性を生成しない
     - `yyyy-MM-ddTHH:mm:ss`形式の文字列が指定されている場合、その値をDateTimeに変換して使用する
   - `--timestamp`オプションが指定されていない場合:
     - `--input`オプションが使われている場合、そのファイルの変更日時を使用する
     - それ以外の場合、XML生成時に現在時刻（`DateTime.now()`）を使用する

### Requirement 2: JUnit XMLでのtimestamp属性生成
**Objective:** As a 開発者, I want JUnit XMLの`<testsuite>`要素に`timestamp`属性を生成する機能, so that CI/CDツールでテストスイートの実行開始時刻を確認できる

#### Acceptance Criteria
1. When `<testsuite>`要素を生成する場合, the converter shall `timestamp`属性を`time`属性の後に配置する（JUnit XML標準スキーマに準拠）
2. When TestSuiteのtimestampフィールドがnullでない場合, the converter shall `timestamp`属性を生成し、その値をISO 8601形式（`YYYY-MM-DDTHH:mm:ss`、タイムゾーンなし）で出力する
3. When TestSuiteのtimestampフィールドがnullの場合, the converter shall 以下の優先順位でタイムスタンプを取得し、`timestamp`属性を生成する:
   - `--timestamp`オプションが指定されている場合:
     - `now`が指定されている場合、現在時刻（`DateTime.now()`）を使用する
     - `none`が指定されている場合、timestamp属性を生成しない
     - `yyyy-MM-ddTHH:mm:ss`形式の文字列が指定されている場合、その値をDateTimeに変換して使用する
   - `--timestamp`オプションが指定されていない場合:
     - `--input`オプションが使われている場合、そのファイルの変更日時を使用する
     - それ以外の場合、XML生成時に現在時刻（`DateTime.now()`）を使用する
4. The `timestamp`属性のフォーマット shall `2025-12-02T14:25:31`形式（ISO 8601、タイムゾーンなし）に準拠する
5. When timestamp属性を生成する場合, the converter shall 秒単位まで正確に出力する（ミリ秒は含めない）
6. The XML output shall 既存のCI/CDツール（Jenkins、GitLab CI、GitHub Actions等）と互換性を保つ

### Requirement 3: タイムスタンプ情報の取得と変換
**Objective:** As a 開発者, I want タイムスタンプ情報を正確に取得し、適切な形式に変換する機能, so that テスト実行開始時刻を正確に記録できる

#### Acceptance Criteria
1. When タイムスタンプを取得する場合（timestampフィールドがnullの場合）, the system shall 以下の優先順位でタイムスタンプを取得する:
   - `--timestamp`オプションが指定されている場合:
     - `now`が指定されている場合、現在時刻（`DateTime.now()`）を使用する
     - `none`が指定されている場合、timestamp属性を生成しない
     - `yyyy-MM-ddTHH:mm:ss`形式の文字列が指定されている場合、その値をDateTimeに変換して使用する
   - `--timestamp`オプションが指定されていない場合:
     - `--input`オプションが使われている場合、そのファイルの変更日時を使用する
     - それ以外の場合、XML生成時にDartの`DateTime.now()`を使用する
2. When DateTimeをISO 8601形式に変換する場合, the system shall `YYYY-MM-DDTHH:mm:ss`形式（タイムゾーンなし）を使用する
3. When タイムスタンプ情報を取得できない場合, the system shall エラーを発生させず、timestampフィールドをnullのままにする
4. When `--timestamp`オプションに無効な値が指定された場合, the system shall エラーメッセージを表示し、処理を終了する
5. The タイムスタンプ情報の取得と変換 shall パフォーマンスに大きな影響を与えない（既存の処理時間の5%以内の増加）

### Requirement 6: CLIオプションの追加
**Objective:** As a 開発者, I want `--timestamp`オプションを追加する機能, so that タイムスタンプの生成方法を制御できる

#### Acceptance Criteria
1. The CLI shall `--timestamp`オプションを追加する
2. When `--timestamp`オプションが指定されている場合, the system shall 以下の値を受け入れる:
   - `now`: 現在時刻を使用する
   - `none`: timestamp属性を生成しない
   - `yyyy-MM-ddTHH:mm:ss`形式の文字列: 指定された時刻を使用する
3. When `--timestamp`オプションに無効な値が指定された場合, the system shall エラーメッセージを表示し、処理を終了する
4. When `--timestamp`オプションが指定されていない場合, the system shall 従来の動作（`--input`オプションの有無に応じた処理）を維持する

### Requirement 4: 後方互換性の維持
**Objective:** As a 開発者, I want timestamp属性機能の追加が既存の動作に影響を与えないようにする機能, so that 既存のワークフローが壊れない

#### Acceptance Criteria
1. When TestSuiteのtimestampフィールドがnullの場合, the system shall 従来通り動作し、XML出力に変更がない（timestamp情報が取得可能な場合を除く）
2. When タイムスタンプ情報を取得できない環境で処理する場合, the system shall エラーを発生させず、従来通り処理する
3. The system shall 既存のテストケースの動作（passed、failed、skipped）に影響を与えない
4. The system shall 既存のAPIインターフェースを変更しない（オプショナルパラメータの追加のみ）
5. When 既存のXMLファイルを処理する場合, the system shall エラーを発生させず、従来通り処理する
6. The system shall 既存の`<testcase>`要素、`<properties>`要素、`<system-out>`要素、`<system-err>`要素の生成に影響を与えない

### Requirement 5: テストと検証
**Objective:** As a 開発者, I want timestamp属性が正しく実装されていることを検証する機能, so that JUnit XML標準に準拠していることを確認できる

#### Acceptance Criteria
1. When `<testsuite>`要素を生成する場合, the tests shall `timestamp`属性が`time`属性の後に配置されることを検証する
2. When `<testsuite>`要素を生成する場合, the tests shall `timestamp`属性が`YYYY-MM-DDTHH:mm:ss`形式（タイムゾーンなし）であることを検証する
3. When timestamp情報が取得可能な場合, the tests shall 生成されたXMLに`timestamp`属性が含まれることを検証する
4. When timestamp情報が取得できない場合, the tests shall 生成されたXMLに`timestamp`属性が含まれることを検証する（現在時刻を使用）
5. When 既存のテストを実行する場合, the tests shall すべてのテストが正常に通過することを確認する
6. When CI/CDツールでXMLファイルを処理する場合, the tests shall 正常に処理されることを確認する
7. When 生成されたXMLファイルを検証する場合, the tests shall JUnit XML標準スキーマに準拠していることを確認する



# Requirements Document

## Project Description (Input)
testcaseのタグにはfileとlineを追加してどのファイルのテストなのかと行数を出力

## Requirements

### Requirement 1: TestCaseモデルへのfileとlineフィールド追加
**Objective:** As a 開発者, I want TestCaseモデルにfileとline用のフィールドを追加する機能, so that テストケースのソースファイル位置を保持できる

#### Acceptance Criteria
1. The TestCase class shall `file` という名前のオプショナルなString型フィールドを持つ
2. The TestCase class shall `line` という名前のオプショナルなint型フィールドを持つ
3. When fileフィールドがnullの場合, the TestCase shall 従来通り動作し、後方互換性を保つ
4. When lineフィールドがnullの場合, the TestCase shall 従来通り動作し、後方互換性を保つ
5. The fileフィールド shall テストケースが定義されているソースファイルのパスを含む（相対パス形式）
6. The lineフィールド shall テストケースが定義されているソースファイル内の行番号を含む
7. The TestCase constructor shall fileとlineパラメータをオプショナルとして受け入れる
8. The TestCase class shall equals、hashCode、toStringメソッドでfileとlineフィールドを適切に処理する

### Requirement 2: パーサーでのfileとline情報の取得
**Objective:** As a 開発者, I want パーサーがtestStartイベントからfileとline情報を取得してテストケースに紐付ける機能, so that テストケースのソース位置を記録できる

#### Acceptance Criteria
1. When JSON内に`type: "testStart"`イベントが含まれている場合, the parser shall そのイベントの`test`オブジェクトから`line`フィールドを取得する
2. When JSON内に`type: "testStart"`イベントが含まれている場合, the parser shall そのイベントの`test`オブジェクトから`url`フィールドを取得する
3. When `url`フィールドが`file://`で始まるURI形式の場合, the parser shall それをファイルパスに変換する
4. When `url`フィールドからファイルパスを抽出する場合, the parser shall 絶対パスから相対パスへの変換を試みる（可能な場合）
5. When `url`フィールドがnullまたは空文字列の場合, the parser shall fileフィールドをnullのままにする
6. When `line`フィールドがnullの場合, the parser shall lineフィールドをnullのままにする
7. When `line`フィールドが数値の場合, the parser shall それをint型として保存する
8. When テストケースが作成される前にtestStartイベントが発生する場合, the parser shall その情報をテストケースIDで紐付けて保持する
9. When testStartイベントの`test`オブジェクトが存在しない、または必要なフィールドが存在しない場合, the parser shall そのイベントを無視する（エラーを発生させない）
10. When testDoneイベント時にfileとline情報が存在する場合, the parser shall それをTestCaseに設定する

### Requirement 3: JUnit XMLでのfileとline属性の生成
**Objective:** As a 開発者, I want JUnit XMLの`<testcase>`要素に`file`と`line`属性を生成する機能, so that CI/CDツールでテストケースのソース位置を確認できる

#### Acceptance Criteria
1. When TestCaseのfileフィールドがnullでない場合, the converter shall `<testcase>`要素に`file`属性を生成する
2. When TestCaseのlineフィールドがnullでない場合, the converter shall `<testcase>`要素に`line`属性を生成する
3. When `<testcase>`要素に`file`属性を生成する場合, the converter shall fileフィールドの内容をその属性値として設定する
4. When `<testcase>`要素に`line`属性を生成する場合, the converter shall lineフィールドの内容を文字列としてその属性値として設定する
5. When TestCaseのfileフィールドがnullの場合, the converter shall `file`属性を生成しない
6. When TestCaseのlineフィールドがnullの場合, the converter shall `line`属性を生成しない
7. When `<testcase>`要素に`file`と`line`属性を生成する場合, the converter shall XMLエスケープ（&lt;, &gt;, &amp;等）を適切に処理する
8. The `file`と`line`属性 shall `<testcase>`要素の属性として配置され、既存の属性（name、classname、time等）と共に出力される
9. The XML output shall 既存のCI/CDツール（Jenkins、GitLab CI、GitHub Actions等）と互換性を保つ
10. The `file`と`line`属性の形式 shall JUnit XMLスキーマに準拠する

### Requirement 4: 後方互換性の維持
**Objective:** As a 開発者, I want fileとline属性の追加が既存の動作に影響を与えないようにする機能, so that 既存のワークフローが壊れない

#### Acceptance Criteria
1. When TestCaseのfileフィールドがnullの場合, the system shall 従来通り動作し、XML出力に変更がない
2. When TestCaseのlineフィールドがnullの場合, the system shall 従来通り動作し、XML出力に変更がない
3. When testStartイベントに`url`または`line`フィールドが存在しないJSONを処理する場合, the system shall エラーを発生させず、従来通り処理する
4. When testStartイベントの構造が不正な場合, the system shall そのイベントを無視し、エラーを発生させない
5. The system shall 既存のテストケースの動作（passed、failed、skipped）に影響を与えない
6. The system shall 既存のAPIインターフェースを変更しない（オプショナルパラメータの追加のみ）
7. When fileとline情報が存在しない場合, the system shall 従来通りXMLを生成し、fileとline属性なしで出力する

### Requirement 5: エッジケースの処理
**Objective:** As a 開発者, I want 様々な入力形式に対して適切に処理できる, so that 予期しないエラーが発生しない

#### Acceptance Criteria
1. When `url`フィールドが`file://`で始まらない場合（例：`http://`、`https://`等）, the parser shall そのURLをそのままfileフィールドに設定するか、またはnullとして扱う
2. When `url`フィールドが絶対パスを含む場合（例：`file:///home/user/project/test.dart`）, the parser shall 可能であれば相対パスに変換し、不可能な場合は絶対パスをそのまま使用する
3. When `line`フィールドが負の値の場合, the parser shall それを無効な値として扱い、lineフィールドをnullのままにする
4. When `line`フィールドが0の場合, the parser shall それを有効な値として扱う（行番号は1から始まるが、0も許容する）
5. When `url`フィールドが空文字列の場合, the parser shall fileフィールドをnullとして扱う
6. When `line`フィールドが文字列形式で数値が含まれている場合, the parser shall それを数値に変換してから保存する
7. When `line`フィールドが数値でない型（文字列、bool等）の場合, the parser shall それを無視し、lineフィールドをnullのままにする
8. When 複数のtestStartイベントが同じテストIDに対して発生する場合, the parser shall 最初のイベントの情報を使用する

### Requirement 6: パフォーマンスへの影響最小化
**Objective:** As a 開発者, I want fileとline属性の追加がパフォーマンスに大きな影響を与えないようにする機能, so that 大規模なテスト結果でも効率的に処理できる

#### Acceptance Criteria
1. When testStartイベントを処理する場合, the parser shall 効率的なデータ構造を使用してfileとline情報を保存する
2. When 大量のtestStartイベントが存在する場合, the system shall メモリ使用量を適切に管理する
3. The system shall 既存のパフォーマンス要件（10,000件のテストケースを10秒以内に処理）を満たす
4. When fileとlineフィールドがnullの場合, the system shall 追加の処理オーバーヘッドを最小限に抑える
5. When URLからファイルパスへの変換を行う場合, the parser shall 効率的な文字列処理方法を使用する



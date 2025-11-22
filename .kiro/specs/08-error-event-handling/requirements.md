# Requirements Document

## Project Description (Input)
失敗したテストに対応する

## Requirements

### Requirement 1: errorイベントの処理
**Objective:** As a 開発者, I want パーサーが`type: "error"`イベントを処理する機能, so that 失敗したテストケースのエラー情報を取得できる

#### Acceptance Criteria
1. When JSON内に`type: "error"`イベントが含まれている場合, the parser shall そのイベントを処理する
2. When `error`イベントが`testID`フィールドを含む場合, the parser shall その`testID`を取得する
3. When `error`イベントが`error`フィールドを含む場合, the parser shall そのエラーメッセージを取得する（複数行のエラーメッセージも含む）
4. When `error`イベントが`stackTrace`フィールドを含む場合, the parser shall そのスタックトレースを取得する（複数行のスタックトレースも含む）
5. When `error`イベントの`testID`が存在しない場合, the parser shall そのイベントを無視する（エラーを発生させない）
6. When `error`イベントの`error`フィールドが存在しない場合, the parser shall エラーメッセージをnullとして扱う
7. When `error`イベントの`stackTrace`フィールドが存在しない場合, the parser shall スタックトレースをnullとして扱う
8. When `error`イベントに`isFailure`フィールドが含まれている場合, the parser shall それを無視する（エラー情報の取得には使用しない）
9. When `error`イベントが`testDone`イベントより前に発生する場合, the parser shall エラー情報を一時保存し、後で`testDone`イベント時に使用する
10. When 同じ`testID`に対して複数の`error`イベントが発生する場合, the parser shall 最後のイベントの情報を使用する（後から来るイベントで上書きする）

### Requirement 2: errorイベント情報の保存と取得
**Objective:** As a 開発者, I want errorイベントから取得したエラー情報を一時保存し、testDoneイベント時に取得できる機能, so that テストケースにエラー情報を設定できる

#### Acceptance Criteria
1. When `error`イベントを処理する場合, the parser shall エラー情報を`testID`でグループ化して保存する
2. When エラー情報を保存する場合, the parser shall `error`フィールドと`stackTrace`フィールドの両方を保存する
3. When `error`イベントの`testID`に対応する`_TestInfo`がまだ存在しない場合でも, the parser shall エラー情報を保存する（後で`testDone`イベントが来る可能性があるため）
4. When `testDone`イベントを処理する場合, the parser shall 対応する`testID`のエラー情報を取得する
5. When `testDone`イベントに`error`フィールドが含まれている場合, the parser shall testDoneイベントの`error`フィールドを優先する（errorイベントの情報より優先）
6. When `testDone`イベントに`stackTrace`フィールドが含まれている場合, the parser shall testDoneイベントの`stackTrace`フィールドを優先する（errorイベントの情報より優先）
7. When `testDone`イベントに`error`フィールドが含まれていない場合（実際のデータでは通常含まれない）, the parser shall errorイベントから取得したエラー情報を使用する
8. When `testDone`イベントに`stackTrace`フィールドが含まれていない場合（実際のデータでは通常含まれない）, the parser shall errorイベントから取得したスタックトレース情報を使用する
9. When `testDone`イベント処理後, the parser shall 使用済みのエラー情報を削除する（メモリ効率のため）
10. When `testDone`イベントが`error`イベントより前に発生する場合（通常は発生しないが、エッジケースとして）, the parser shall testDoneイベントの`error`フィールドを使用し、後から来る`error`イベントは無視する

### Requirement 3: TestCaseへのエラー情報の設定
**Objective:** As a 開発者, I want 取得したエラー情報をTestCaseに設定する機能, so that 失敗したテストケースのエラーメッセージとスタックトレースを保持できる

#### Acceptance Criteria
1. When TestCaseを作成する場合, the parser shall `errorMessage`フィールドにエラーメッセージを設定する
2. When TestCaseを作成する場合, the parser shall `stackTrace`フィールドにスタックトレースを設定する
3. When エラーメッセージがnullの場合, the parser shall `errorMessage`フィールドをnullのままにする
4. When スタックトレースがnullの場合, the parser shall `stackTrace`フィールドをnullのままにする
5. When テストケースのステータスが`failed`（`result: "failure"`）の場合, the parser shall エラーメッセージが設定されていることを確認する（TestCase.isValidの要件）
6. When テストケースのステータスが`error`（`result: "error"`）の場合, the parser shall エラーメッセージが設定されていることを確認する（TestCase.isValidの要件）
7. When テストケースのステータスが`passed`（`result: "success"`）または`skipped`の場合, the parser shall エラーメッセージがnullでも問題ない
8. When `error`イベントから取得したエラーメッセージが複数行を含む場合, the parser shall そのまま保持する（改行文字を含む）
9. When `error`イベントから取得したスタックトレースが複数行を含む場合, the parser shall そのまま保持する（改行文字を含む）

### Requirement 4: 後方互換性の維持
**Objective:** As a 開発者, I want errorイベント処理機能の追加が既存の動作に影響を与えないようにする機能, so that 既存のワークフローが壊れない

#### Acceptance Criteria
1. When JSON内に`error`イベントが存在しない場合, the system shall 従来通り動作し、エラーを発生させない
2. When `testDone`イベントに`error`フィールドが含まれている場合, the system shall 従来通りtestDoneイベントの`error`フィールドを使用する
3. When `testDone`イベントに`stackTrace`フィールドが含まれている場合, the system shall 従来通りtestDoneイベントの`stackTrace`フィールドを使用する
4. The system shall 既存のテストケースの動作（passed、failed、skipped）に影響を与えない
5. The system shall 既存のAPIインターフェースを変更しない
6. When `error`イベントの構造が不正な場合, the system shall そのイベントを無視し、エラーを発生させない

### Requirement 5: エッジケースの処理
**Objective:** As a 開発者, I want 様々な入力形式に対して適切に処理できる, so that 予期しないエラーが発生しない

#### Acceptance Criteria
1. When `error`イベントの`testID`が存在しない場合, the parser shall そのイベントを無視する
2. When `error`イベントの`testID`に対応する`_TestInfo`が見つからない場合でも, the parser shall エラー情報を保存する（後で`testDone`イベントが来る可能性があるため）
3. When `error`イベントの`error`フィールドが空文字列の場合, the parser shall それをnullとして扱う
4. When `error`イベントの`stackTrace`フィールドが空文字列の場合, the parser shall それをnullとして扱う
5. When `error`イベントの`error`フィールドが数値やbool等の非文字列型の場合, the parser shall それを文字列に変換するか、または無視する
6. When `testDone`イベントが`error`イベントより前に発生する場合（通常は発生しないが、エッジケースとして）, the parser shall testDoneイベントの`error`フィールドを使用し、後から来る`error`イベントは無視する
7. When 同じ`testID`に対して複数の`error`イベントが発生する場合, the parser shall 最後のイベントの情報を使用する（後から来るイベントで上書きする）
8. When `error`イベントに`isFailure`フィールドが含まれている場合, the parser shall それを無視する（エラー情報の取得には使用しない）
9. When `error`イベントの`error`フィールドに改行文字（`\n`）が含まれている場合, the parser shall そのまま保持する
10. When `error`イベントの`stackTrace`フィールドに改行文字（`\n`）が含まれている場合, the parser shall そのまま保持する

### Requirement 6: パフォーマンスへの影響最小化
**Objective:** As a 開発者, I want errorイベント処理機能の追加がパフォーマンスに大きな影響を与えないようにする機能, so that 大規模なテスト結果でも効率的に処理できる

#### Acceptance Criteria
1. When `error`イベントを処理する場合, the parser shall 効率的なデータ構造を使用してエラー情報を保存する
2. When 大量の`error`イベントが存在する場合, the system shall メモリ使用量を適切に管理する
3. The system shall 既存のパフォーマンス要件（10,000件のテストケースを10秒以内に処理）を満たす
4. When `error`イベントが存在しない場合, the system shall 追加の処理オーバーヘッドを最小限に抑える
5. When `testDone`イベント処理後, the parser shall 使用済みのエラー情報を即座に削除する（メモリ効率のため）



# Requirements Document

## Project Description (Input)
テスト失敗時のXML出力が間違ってる。以下のようになるようにして

```
            <failure message="1 failure, see stacktrace for details" type="AssertionError">
                Failure:
                <!-- Error message printed here -->
            </failure>            

```

## Requirements

### Requirement 1: failure要素のtype属性の変更
**Objective:** As a 開発者, I want failure要素の`type`属性を`AssertionError`に変更する機能, so that JUnit XMLの標準的な形式に準拠する

#### Acceptance Criteria
1. When 失敗したテストケースのXMLを生成する場合, the generator shall `failure`要素の`type`属性を`AssertionError`に設定する
2. When 現在の実装では`type="TestFailure"`となっている場合, the generator shall それを`type="AssertionError"`に変更する
3. When `error`要素の`type`属性についても, the generator shall 必要に応じて適切な型名を設定する（本要件ではfailure要素のみを対象とする）

### Requirement 2: failure要素のフォーマット変更
**Objective:** As a 開発者, I want failure要素の内容を指定されたフォーマットで出力する機能, so that エラーメッセージが適切に表示される

#### Acceptance Criteria
1. When failure要素を生成する場合, the generator shall `message`属性にfailure数を含むメッセージを設定する（例: "1 failure, see stacktrace for details"）
2. When failure要素を生成する場合, the generator shall 要素の内容として"Failure:\n"プレフィックスとエラーメッセージ全体を出力する
3. When エラーメッセージがnullの場合, the generator shall 要素の内容を出力しない
4. When エラーメッセージが複数行を含む場合, the generator shall そのまま保持する（改行文字を含む）
5. When 複数のfailureがある場合, the generator shall `message`属性に複数形を使用する（例: "3 failures, see stacktrace for details"）

### Requirement 3: error要素のフォーマット変更
**Objective:** As a 開発者, I want error要素の内容もfailure要素と同様のフォーマットで出力する機能, so that エラー情報が適切に表示される

#### Acceptance Criteria
1. When error要素を生成する場合, the generator shall failure要素と同様のフォーマットを適用する
2. When error要素を生成する場合, the generator shall `message`属性にerror数を含むメッセージを設定する（例: "1 error, see stacktrace for details"）
3. When error要素を生成する場合, the generator shall 要素の内容として"Error:\n"プレフィックスとエラーメッセージ全体を出力する
4. When エラーメッセージがnullの場合, the generator shall 要素の内容を出力しない
5. When エラーメッセージが複数行を含む場合, the generator shall そのまま保持する（改行文字を含む）
6. When 複数のerrorがある場合, the generator shall `message`属性に複数形を使用する（例: "2 errors, see stacktrace for details"）

### Requirement 4: 後方互換性の維持
**Objective:** As a 開発者, I want フォーマット変更が既存の動作に影響を与えないようにする機能, so that 既存のワークフローが壊れない

#### Acceptance Criteria
1. When XML出力のフォーマットを変更する場合, the system shall 既存のXMLパーサーが正常に処理できることを確認する
2. When `message`属性と`type`属性の値が変更される場合, the system shall 既存のCI/CDツールとの互換性を維持する
3. The system shall 既存のテストケースの動作（passed、failed、skipped、error）に影響を与えない
4. The system shall 既存のAPIインターフェースを変更しない

### Requirement 5: エッジケースの処理
**Objective:** As a 開発者, I want 様々な入力形式に対して適切に処理できる, so that 予期しないエラーが発生しない

#### Acceptance Criteria
1. When エラーメッセージがnullの場合, the generator shall `message`属性を出力しない
2. When エラーメッセージが存在する場合, the generator shall `message`属性に`"{failure_count} failure(s), see stacktrace for details"`形式のメッセージを設定する（failure_countはTestSuiteのtotalFailures値）
3. When error要素の場合, the generator shall `message`属性に`"{error_count} error(s), see stacktrace for details"`形式のメッセージを設定する（error_countはTestSuiteのtotalErrors値）
4. When 要素の内容として, the generator shall "Failure:\n"プレフィックスとエラーメッセージ全体を出力する（スタックトレースではなく）
5. When エラーメッセージが複数行を含む場合, the generator shall そのまま保持する（改行文字を含む）
6. When 複数のfailureがある場合, the generator shall 複数形（"failures"）を使用する
7. When 複数のerrorがある場合, the generator shall 複数形（"errors"）を使用する

### Requirement 6: XML出力の可読性向上
**Objective:** As a 開発者, I want XML出力が読みやすくなるようにする機能, so that デバッグが容易になる

#### Acceptance Criteria
1. When failure要素を生成する場合, the generator shall 適切なインデントを使用してXMLを整形する
2. When error要素を生成する場合, the generator shall 適切なインデントを使用してXMLを整形する
3. When スタックトレースを出力する場合, the generator shall 読みやすい形式で出力する（改行とインデントを含む）
4. When XMLを出力する場合, the generator shall 既存のXMLフォーマッターの設定を尊重する

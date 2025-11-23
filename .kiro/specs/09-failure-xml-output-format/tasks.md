# Implementation Plan

## Task Breakdown

### 1. XMLジェネレーターの修正
- [x] 1.1 _buildFailureElementメソッドの修正
  - `type`属性を`TestFailure`から`AssertionError`に変更
  - `message`属性にfailure数を含むメッセージを設定（例: "1 failure, see stacktrace for details"）
  - 要素の内容として"Failure:\n"プレフィックスとエラーメッセージ全体を出力
  - `_buildTestCase`メソッドに`TestSuite`パラメータを追加
  - `_buildFailureElement`メソッドに`TestSuite`パラメータを追加してfailure数にアクセス
  - 複数のfailureがある場合、複数形（"failures"）を使用
  - _Requirements: 1.1, 1.2, 2.1, 2.2, 2.3, 2.4, 2.5, 5.1, 5.4, 5.5, 6.1, 6.3_

- [x] 1.2 _buildErrorElementメソッドの修正
  - `type`属性を`TestError`から`AssertionError`に変更
  - `message`属性にerror数を含むメッセージを設定（例: "1 error, see stacktrace for details"）
  - failure要素と同様のフォーマットを適用
  - 要素の内容として"Error:\n"プレフィックスとエラーメッセージ全体を出力
  - `_buildErrorElement`メソッドに`TestSuite`パラメータを追加してerror数にアクセス
  - 複数のerrorがある場合、複数形（"errors"）を使用
  - _Requirements: 1.3, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 5.1, 5.4, 5.5, 6.2, 6.3_

### 2. ユニットテストの実装
- [x] 2.1 failure要素のtype属性変更テスト
  - `type`属性が`AssertionError`に設定されることを確認
  - `message`属性がfailure数を含むメッセージに設定されることを確認（例: "1 failure, see stacktrace for details"）
  - `message`属性が出力されないことを確認（エラーメッセージがnullの場合）
  - エラーメッセージが正しく出力されることを確認
  - 複数のfailureがある場合、複数形が使用されることを確認
  - _Requirements: 1.1, 1.2, 2.1, 2.5, 5.1, 5.5_

- [x] 2.2 failure要素のフォーマット変更テスト
  - 要素の内容として"Failure:\n"プレフィックスとエラーメッセージ全体が出力されることを確認
  - エラーメッセージがnullの場合、要素の内容が出力されないことを確認
  - 複数行のエラーメッセージが正しく出力されることを確認
  - 複数のfailureがある場合、`message`属性に複数形が使用されることを確認
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 5.4, 5.5_

- [x] 2.3 error要素のtype属性変更テスト
  - `type`属性が`AssertionError`に設定されることを確認
  - `message`属性がerror数を含むメッセージに設定されることを確認（例: "1 error, see stacktrace for details"）
  - `message`属性が出力されないことを確認（エラーメッセージがnullの場合）
  - エラーメッセージが正しく出力されることを確認
  - 複数のerrorがある場合、複数形が使用されることを確認
  - _Requirements: 1.3, 3.1, 3.6, 5.1, 5.5_

- [x] 2.4 error要素のフォーマット変更テスト
  - failure要素と同様のフォーマットが適用されることを確認
  - 要素の内容として"Error:\n"プレフィックスとエラーメッセージ全体が出力されることを確認
  - エラーメッセージがnullの場合、要素の内容が出力されないことを確認
  - 複数行のエラーメッセージが正しく出力されることを確認
  - 複数のerrorがある場合、`message`属性に複数形が使用されることを確認
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 5.4, 5.5_

- [x] 2.5 後方互換性テスト
  - 既存のテストケースの動作に影響がないことを確認
  - XMLパーサーが正常に処理できることを確認
  - `type`属性の値が変更されても、XMLパーサーには影響しないことを確認
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 2.6 XML出力の可読性テスト
  - 適切なインデントが使用されることを確認
  - スタックトレースが読みやすい形式で出力されることを確認
  - XMLフォーマッターの設定が尊重されることを確認
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

### 3. 統合テストの実装
- [x] 3.1 エンドツーエンドテスト: XML出力フォーマット
  - 失敗したテストケースのXML出力が正しいフォーマットであることを確認
  - エラーが発生したテストケースのXML出力が正しいフォーマットであることを確認
  - 複数のテストケースがある場合、それぞれのフォーマットが正しいことを確認
  - `type`属性が`AssertionError`であることを確認
  - `message`属性がfailure/error数を含むメッセージであることを確認
  - 要素の内容として"Failure:\n"または"Error:\n"プレフィックスとエラーメッセージ全体が出力されることを確認
  - 複数のfailure/errorがある場合、複数形が使用されることを確認
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 4.1, 4.2, 5.4, 5.5, 6.1, 6.2, 6.3_

- [x] 3.2 CLI統合テスト: XML出力フォーマット
  - XML出力が正しいフォーマットであることを確認
  - 既存のCI/CDツールとの互換性を確認
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

## Implementation Notes

### 実装の優先順位
1. **高優先度**: タスク1.1-1.2（XMLジェネレーターの修正）
2. **中優先度**: タスク2.1-2.4（ユニットテストの実装）
3. **低優先度**: タスク2.5-2.6（後方互換性と可読性のテスト）、3.1-3.2（統合テスト）

### 実装の詳細
- `_buildTestCase`メソッドに`TestSuite`パラメータを追加して、failure/error数にアクセス可能にする
- `_buildFailureElement`と`_buildErrorElement`メソッドに`TestSuite`パラメータを追加
- `message`属性に`"${suite.totalFailures} failure${suite.totalFailures != 1 ? 's' : ''}, see stacktrace for details"`形式のメッセージを設定
- `message`属性に`"${suite.totalErrors} error${suite.totalErrors != 1 ? 's' : ''}, see stacktrace for details"`形式のメッセージを設定
- `builder.text()`メソッドを使用してテキストコンテンツを追加
- 要素の内容として`"Failure:\n${testCase.errorMessage!}"`または`"Error:\n${testCase.errorMessage!}"`を出力
- XMLフォーマッター（`toXmlString`）が自動的にインデントを追加するため、手動でのインデント制御は不要

### テストデータ
- 既存のテストデータを使用可能
- 必要に応じて、追加のテストデータを生成


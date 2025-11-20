# Implementation Plan

## Task Breakdown

### 1. Parserインターフェースの拡張
- [ ] 1.1 DartTestParserインターフェースにerrorReporterパラメータを追加
  - `parse`メソッドのシグネチャを更新（オプショナルな`errorReporter`パラメータを追加）
  - 既存の`parse(String jsonString)`メソッドとの後方互換性を維持
  - インターフェースのドキュメントコメントを更新
  - _Requirements: 5.5_

### 2. Parser実装の修正
- [ ] 2.1 DefaultDartTestParserの_processTestDoneEventメソッドにhiddenフラグチェックを追加
  - `testDone`イベントから`hidden`フラグを抽出（`event['hidden'] as bool? ?? false`）
  - hiddenフラグが`true`の場合、TestCaseを作成せず早期リターン
  - hiddenフラグが`false`、`null`、または未定義の場合は従来通り処理
  - hiddenフラグがboolean以外の型の場合は`false`として扱う
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 5.3_

- [ ] 2.2 DefaultDartTestParserのparseメソッドにerrorReporterパラメータを追加
  - `parse`メソッドのシグネチャを更新
  - `_parseEvents`メソッドにerrorReporterを渡す
  - `_processTestDoneEvent`メソッドにerrorReporterを渡す
  - _Requirements: 2.1, 5.5_

- [ ] 2.3 _processTestDoneEventメソッドにデバッグログ出力を追加
  - hiddenフラグが`true`の場合、ErrorReporterが提供されていればログを出力
  - ログメッセージ形式: `"Ignoring hidden test: ${testInfo.suiteName}::${testInfo.name}"`
  - ErrorReporterの`debug`メソッドを使用（デバッグモードが有効な場合のみ出力される）
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

### 3. CLI Runnerの修正
- [ ] 3.1 DefaultCliRunnerの_runConversionメソッドを修正
  - `parser.parse`呼び出し時に`errorReporter`を渡す
  - 既存の処理フローを維持しつつ、errorReporterを注入
  - _Requirements: 2.1, 5.5_

### 4. ユニットテストの実装
- [ ] 4.1 hiddenフラグが`true`の場合のテストケース除外テスト
  - `testDone`イベントで`hidden: true`のテストケースが除外されることを確認
  - TestCaseオブジェクトが作成されないことを確認
  - TestSuiteに追加されないことを確認
  - _Requirements: 1.1, 1.2_

- [ ] 4.2 hiddenフラグが`false`の場合の通常処理テスト
  - `hidden: false`のテストケースが通常通り処理されることを確認
  - TestCaseが正常に作成されることを確認
  - _Requirements: 1.3, 5.1_

- [ ] 4.3 hiddenフラグが未指定の場合の通常処理テスト
  - `hidden`フィールドが存在しない場合、通常通り処理されることを確認
  - 既存の動作に影響がないことを確認
  - _Requirements: 1.3, 5.2_

- [ ] 4.4 hiddenフラグがboolean以外の型の場合のテスト
  - `hidden`が文字列の場合、`false`として扱われることを確認
  - `hidden`が数値の場合、`false`として扱われることを確認
  - エラーが発生しないことを確認
  - _Requirements: 5.3_

- [ ] 4.5 hiddenとskippedの両方が`true`の場合のテスト
  - hiddenフラグが優先され、テストケースが除外されることを確認
  - skippedとして扱われないことを確認
  - _Requirements: 1.4_

- [ ] 4.6 デバッグログ出力のテスト
  - ErrorReporterが提供され、デバッグモードが有効な場合のみログが出力されることを確認
  - ログメッセージの形式が正しいことを確認（`"Ignoring hidden test: {suiteName}::{testName}"`）
  - デバッグモードが無効な場合、ログが出力されないことを確認
  - ErrorReporterが提供されていない場合、ログが出力されないことを確認
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [ ] 4.7 統計情報からの除外テスト
  - hiddenテストがtotalTestsから除外されることを確認
  - hiddenテストがfailuresから除外されることを確認
  - hiddenテストがerrorsから除外されることを確認
  - hiddenテストがskippedから除外されることを確認
  - hiddenテストの実行時間がtotalTimeから除外されることを確認
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 4.8 すべてのテストがhiddenの場合のテスト
  - 空のテストスイートとして扱われることを確認
  - エラーが発生しないことを確認
  - _Requirements: 3.5_

### 5. 統合テストの実装
- [ ] 5.1 エンドツーエンドテスト: hiddenテストの除外
  - JSON入力にhiddenテストが含まれる場合、XML出力に含まれないことを確認
  - 統計情報が正確に反映されることを確認（hiddenテストが除外された後の値）
  - JUnit XMLスキーマに準拠していることを確認
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 5.2 CLI統合テスト: デバッグモード
  - `--debug`フラグ付きで実行した場合、hiddenテストのログが標準エラー出力に出力されることを確認
  - デバッグモードなしの場合、ログが出力されないことを確認
  - XML出力に影響がないことを確認
  - _Requirements: 2.1, 2.3, 2.4_

### 6. 後方互換性の検証
- [ ] 6.1 既存のテストケースの動作確認
  - 既存のテストがすべて正常に動作することを確認
  - hiddenフラグが存在しないJSONでも正常に処理されることを確認
  - 既存のAPIインターフェースが変更されていないことを確認
  - _Requirements: 5.1, 5.2, 5.4, 5.5_


# Implementation Plan

## Task Breakdown

### 1. TestSuiteモデルの拡張
- [ ] 1.1 TestSuiteクラスにsystemOutフィールドを追加
  - `systemOut`フィールドを`String?`型で追加
  - コンストラクタにオプショナルパラメータ`systemOut`を追加
  - `equals`メソッドに`systemOut`を含める
  - `hashCode`メソッドに`systemOut`を含める
  - `toString`メソッドに`systemOut`を含める（オプショナル）
  - _Requirements: 1.1, 1.2, 1.3, 1.5_

### 2. Parser実装の修正
- [ ] 2.1 _SuiteBuilderクラスにsystemOutフィールドを追加
  - `systemOut`フィールドを`StringBuffer?`型で追加
  - 初期値は`null`
  - printイベントが来るたびに`StringBuffer`を作成または追加
  - _Requirements: 2.3, 2.4, 5.1_

- [ ] 2.2 DefaultDartTestParserの_parseEventsメソッドにprintイベント処理を追加
  - `case 'print':`の処理を実装
  - `_processPrintEvent`メソッドを呼び出す
  - _Requirements: 2.1, 2.2, 2.6_

- [ ] 2.3 _processPrintEventメソッドを新規作成
  - printイベントから`testID`を取得
  - `testID`から`_TestInfo`を取得（`tests`マップから）
  - `_TestInfo`が見つからない場合、イベントを無視（エラーを発生させない）
  - `_TestInfo`から`suiteName`を取得
  - `suiteName`から`_SuiteBuilder`を取得（`suites`マップから）
  - `_SuiteBuilder`が見つからない場合、イベントを無視（エラーを発生させない）
  - printイベントから`message`フィールドを取得（存在しない場合は空文字列）
  - `_SuiteBuilder.systemOut`が`null`の場合、新しい`StringBuffer`を作成
  - `_SuiteBuilder.systemOut`にメッセージを追加（改行区切り）
  - 空文字列のメッセージは改行として扱う
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.6_

- [ ] 2.4 _buildResultメソッドを修正してsystemOutを設定
  - `_SuiteBuilder`から`systemOut`を取得
  - `systemOut`が`null`でない場合、`toString()`で文字列に変換
  - `systemOut`が`null`の場合、`null`のまま
  - `TestSuite`コンストラクタに`systemOut`を渡す
  - _Requirements: 1.4, 2.5_

### 3. XMLジェネレーターの修正
- [ ] 3.1 DefaultJUnitXmlGeneratorの_buildTestSuiteメソッドを修正
  - `systemOut`が`null`でない場合、`<system-out>`タグを生成
  - `systemOut`が`null`または空文字列の場合、`<system-out>`タグを生成しない
  - `<system-out>`タグを`<testcase>`要素の前に配置
  - `builder.text()`メソッドを使用してテキストコンテンツを設定（XMLエスケープは自動処理）
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

### 4. ユニットテストの実装
- [ ] 4.1 TestSuiteモデルのsystemOutフィールドのテスト
  - `systemOut`が`null`の場合の動作を確認
  - `systemOut`が空文字列の場合の動作を確認
  - `systemOut`が有効な値の場合の動作を確認
  - `equals`メソッドで`systemOut`が正しく比較されることを確認
  - `hashCode`メソッドで`systemOut`が正しく含まれることを確認
  - _Requirements: 1.1, 1.2, 1.3_

- [ ] 4.2 パーサーでのprintイベント収集のテスト
  - `print`イベントが存在する場合、`systemOut`に含まれることを確認
  - 複数の`print`イベントが時系列順に改行区切りで連結されることを確認
  - `testID`が存在しない場合、イベントが無視されることを確認
  - `testID`に対応するテストケースが見つからない場合、イベントが無視されることを確認
  - `message`が空文字列の場合、改行として扱われることを確認
  - `message`フィールドが存在しない場合、空文字列として扱われることを確認
  - printイベントが存在しない場合、`systemOut`が`null`のままであることを確認
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [ ] 4.3 XMLジェネレーターでのsystem-outタグ生成のテスト
  - `systemOut`が`null`でない場合、`<system-out>`タグが生成されることを確認
  - `systemOut`が`null`の場合、`<system-out>`タグが生成されないことを確認
  - `systemOut`が空文字列の場合、`<system-out>`タグが生成されないことを確認
  - XMLエスケープが適切に処理されることを確認（&lt;, &gt;, &amp;等）
  - `<system-out>`タグが`<testcase>`要素の前に配置されることを確認
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [ ] 4.4 後方互換性のテスト
  - `print`イベントが存在しないJSONが正常に処理されることを確認
  - 既存のテストケースの動作に影響がないことを確認
  - `systemOut`が`null`の場合、XML出力が従来通りであることを確認
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 4.5 パフォーマンステスト
  - 大量のprintイベントが存在する場合の処理時間を測定
  - StringBufferを使用した効率的な文字列連結を確認
  - メモリ使用量が適切に管理されることを確認
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

### 5. 統合テストの実装
- [ ] 5.1 エンドツーエンドテスト: system-outタグの生成
  - JSON入力にprintイベントが含まれる場合、XML出力に`<system-out>`タグが含まれることを確認
  - 複数のテストスイートがある場合、それぞれのスイートに`<system-out>`タグが生成されることを確認
  - 複数のprintイベントが正しく連結されることを確認
  - JUnit XMLスキーマに準拠していることを確認
  - 既存のCI/CDツールとの互換性を確認
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [ ] 5.2 CLI統合テスト: printイベントの処理
  - printイベントを含むJSONを処理した場合、正常にXMLが生成されることを確認
  - 既存のCLI機能に影響がないことを確認
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

### 6. 後方互換性の検証
- [ ] 6.1 既存のテストケースの動作確認
  - 既存のテストがすべて正常に動作することを確認
  - printイベントが存在しないJSONでも正常に処理されることを確認
  - 既存のAPIインターフェースが変更されていないことを確認（オプショナルパラメータの追加のみ）
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_


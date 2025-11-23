# Implementation Plan

## Task Breakdown

### 1. Parser実装の修正
- [ ] 1.1 _SuiteBuilderクラスにsystemOutフィールドを追加
  - `systemOut`フィールドを`StringBuffer?`型で追加
  - 初期値は`null`
  - printイベントが来るたびに`StringBuffer`を作成または追加
  - _Requirements: 1.8, 4.1_

- [x] 1.2 _processPrintEventメソッドを修正してtestcaseに紐付かないprintイベントのみをテストスイートレベルで収集
  - 既存のテストケースレベルのprintイベント処理は維持
  - printイベントから`testID`を取得
  - `testID`が存在しない場合、テストスイートレベルで処理する（テストケースレベルには含めない）
  - `testID`が存在する場合、`tests`マップから`_TestInfo`を取得
  - `_TestInfo`が見つからない場合、テストスイートレベルで処理する（テストケースレベルには含めない）
  - `_TestInfo`が見つかる場合、テストケースレベルのみで処理し、テストスイートレベルには含めない
  - テストスイートレベルで処理する場合、`_TestInfo`から`suiteName`を取得（`_TestInfo`が存在する場合）または`suites`マップから適切なスイートを特定
  - `suiteName`から`_SuiteBuilder`を取得（`suites`マップから）
  - `_SuiteBuilder`が見つからない場合、イベントを無視（エラーを発生させない）
  - printイベントから`message`フィールドを取得（存在しない場合は空文字列）
  - `_SuiteBuilder.systemOut`が`null`の場合、新しい`StringBuffer`を作成
  - `_SuiteBuilder.systemOut`にメッセージを追加（改行区切り）
  - 空文字列のメッセージは改行として扱う
  - `messageType`が`stderr`または`error`の場合は無視（system-outのみ処理）
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.11, 3.1, 3.2, 3.3, 3.4, 5.5_

- [ ] 1.3 _buildResultメソッドを修正してsystemOutを設定
  - `_SuiteBuilder`から`systemOut`を取得
  - `systemOut`が`null`でない場合、`toString()`で文字列に変換
  - `systemOut`が`null`の場合、`null`のまま
  - `TestSuite`コンストラクタに`systemOut`を渡す
  - _Requirements: 1.10_

### 2. XMLジェネレーターの修正
- [ ] 2.1 DefaultJUnitXmlGeneratorの_buildTestSuiteメソッドを修正
  - `systemOut`が`null`でない場合、`<testsuite>`要素内に`<system-out>`子要素を生成
  - `systemOut`が`null`または空文字列の場合、`<system-out>`タグを生成しない
  - `<system-out>`タグを`<testcase>`要素の前に配置（JUnit XMLスキーマに準拠）
  - `builder.text()`メソッドを使用してテキストコンテンツを設定（XMLエスケープは自動処理）
  - 既存の`_buildTestCase`メソッドの`<system-out>`タグ生成処理は変更しない
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

### 3. ユニットテストの実装
- [ ] 3.1 パーサーでのTestSuiteレベルのprintイベント収集のテスト
  - `testID`が存在しないprintイベントが存在する場合、対応するテストスイートの`systemOut`に含まれることを確認
  - `testID`が存在するが、対応するテストケースが見つからないprintイベントが存在する場合、対応するテストスイートの`systemOut`に含まれることを確認
  - `testID`が存在し、対応するテストケースが見つかるprintイベントが存在する場合、テストケースレベルの`systemOut`にのみ含まれ、テストスイートレベルの`systemOut`には含まれないことを確認
  - 複数のtestcaseに紐付かないprintイベントが時系列順に改行区切りで連結されることを確認
  - `message`が空文字列の場合、改行として扱われることを確認
  - `message`フィールドが存在しない場合、空文字列として扱われることを確認
  - testcaseに紐付かないprintイベントが存在しない場合、`systemOut`が`null`のままであることを確認
  - testcaseに紐付くprintイベントのみが存在する場合、`systemOut`が`null`のままであることを確認
  - テストケースレベルのprintイベント処理が影響を受けないことを確認
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.11, 3.1, 3.2, 3.3, 3.4_

- [ ] 3.2 XMLジェネレーターでのtestsuiteレベルのsystem-outタグ生成のテスト
  - `systemOut`が`null`でない場合、`<testsuite>`要素内に`<system-out>`タグが生成されることを確認
  - `systemOut`が`null`の場合、`<system-out>`タグが生成されないことを確認
  - `systemOut`が空文字列の場合、`<system-out>`タグが生成されないことを確認
  - XMLエスケープが適切に処理されることを確認（&lt;, &gt;, &amp;等）
  - `<system-out>`タグが`<testcase>`要素の前に配置されることを確認
  - テストケースレベルの`<system-out>`タグの生成が影響を受けないことを確認
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

- [ ] 3.3 後方互換性のテスト
  - `print`イベントが存在しないJSONが正常に処理されることを確認
  - 既存のテストケースの動作に影響がないことを確認
  - テストケースレベルのsystem-out機能が変更されないことを確認
  - `systemOut`が`null`の場合、XML出力が従来通りであることを確認
  - 既存のAPIインターフェースが変更されていないことを確認
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [ ] 3.4 パフォーマンステスト
  - 大量のprintイベントが存在する場合の処理時間を測定
  - StringBufferを使用した効率的な文字列連結を確認
  - testcaseに紐付かないprintイベントのみをテストスイートレベルで処理する場合のオーバーヘッドを確認
  - メモリ使用量が適切に管理されることを確認
  - 10,000件のテストケースを10秒以内に処理できることを確認
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

### 4. 統合テストの実装
- [ ] 4.1 エンドツーエンドテスト: testsuiteレベルのsystem-outタグの生成
  - JSON入力にtestcaseに紐付かないprintイベントが含まれる場合、XML出力に`<testsuite>`要素内に`<system-out>`タグが含まれることを確認
  - JSON入力にtestcaseに紐付くprintイベントのみが含まれる場合、XML出力に`<testsuite>`要素内に`<system-out>`タグが含まれないことを確認
  - 複数のテストスイートがある場合、それぞれのスイートに`<system-out>`タグが生成されることを確認
  - テストケースレベルの`<system-out>`タグも同時に生成されることを確認
  - 複数のprintイベントが正しく連結されることを確認
  - JUnit XMLスキーマに準拠していることを確認
  - 既存のCI/CDツールとの互換性を確認
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 3.1, 3.2, 3.3, 3.4_

- [ ] 4.2 CLI統合テスト: printイベントの処理
  - printイベントを含むJSONを処理した場合、正常にXMLが生成されることを確認
  - 既存のCLI機能に影響がないことを確認
  - testcaseに紐付かないprintイベントがtestsuiteレベルのsystem-outに正しく出力されることを確認
  - testcaseに紐付くprintイベントがtestcaseレベルのsystem-outにのみ出力されることを確認
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_


# Implementation Plan

## Task Breakdown

### 1. TestCaseモデルの拡張
- [x] 1.1 TestCaseクラスにsystemOutフィールドを追加
  - `systemOut`フィールドを`String?`型で追加
  - コンストラクタにオプショナルパラメータ`systemOut`を追加
  - `equals`メソッドに`systemOut`を含める
  - `hashCode`メソッドに`systemOut`を含める
  - `toString`メソッドに`systemOut`を含める（オプショナル）
  - _Requirements: 1.1, 1.2, 1.3, 1.5, 1.6_

### 2. Parser実装の修正
- [x] 2.1 printイベントをテストケースIDでグループ化するデータ構造を追加
  - `_parseEvents`メソッド内に`Map<int, StringBuffer>`型のフィールドを追加
  - 各テストケースIDごとにprintメッセージを蓄積するためのデータ構造
  - メモリ効率のため、使用後はマップから削除する
  - _Requirements: 2.7, 2.8, 6.1, 6.5_

- [x] 2.2 _processPrintEventメソッドを修正してテストケースレベルで収集
  - printイベントから`testID`を取得
  - `testID`が存在しない場合、イベントを無視（エラーを発生させない）
  - `testID`に対応するprintメッセージバッファを取得または作成
  - printイベントから`message`フィールドを取得（存在しない場合は空文字列）
  - メッセージを時系列順に改行区切りで連結してバッファに追加
  - 空文字列のメッセージは改行として扱う
  - `messageType`が`stderr`または`error`の場合は無視（system-outのみ処理）
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.6, 6.1_

- [x] 2.3 _processTestDoneEventメソッドを修正してTestCaseにsystemOutを設定
  - `testDone`イベント処理時に、対応する`testID`のprintメッセージバッファを取得
  - バッファが存在する場合、`toString()`で文字列に変換
  - バッファが存在しない場合、`null`のまま
  - TestCaseコンストラクタに`systemOut`を渡す
  - 使用済みのバッファをマップから削除（メモリ効率のため）
  - _Requirements: 2.5, 2.7, 2.8, 6.2_

- [x] 2.4 _SuiteBuilderからsystemOut関連のコードを削除
  - `_SuiteBuilder`クラスから`systemOut`フィールドを削除
  - `_SuiteBuilder`クラスから`systemErr`フィールドを削除（本機能では対象外だが、一貫性のため）
  - `_buildResult`メソッドから`systemOut`、`systemErr`の処理を削除
  - TestSuiteコンストラクタへの`systemOut`、`systemErr`の渡しを削除
  - _Requirements: 4.3, 5.6_

### 3. XMLジェネレーターの修正
- [x] 3.1 DefaultJUnitXmlGeneratorの_buildTestCaseメソッドを修正
  - `systemOut`が`null`でない場合、`<testcase>`要素内に`<system-out>`子要素を生成
  - `systemOut`が`null`または空文字列の場合、`<system-out>`タグを生成しない
  - `<system-out>`タグをstatus-specific要素（failure、error、skipped）の前に配置
  - `builder.text()`メソッドを使用してテキストコンテンツを設定（XMLエスケープは自動処理）
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [x] 3.2 DefaultJUnitXmlGeneratorの_buildTestSuiteメソッドからtestsuiteレベルのsystem-outタグ生成を削除
  - `<testsuite>`要素内の`<system-out>`タグ生成コードを削除
  - `<testsuite>`要素内の`<system-err>`タグ生成コードを削除
  - `<testsuite>`要素内で`<testcase>`要素のみを直接子要素として生成することを確認
  - _Requirements: 4.1, 4.2, 4.3_

### 4. ユニットテストの実装
- [x] 4.1 TestCaseモデルのsystemOutフィールドのテスト
  - `systemOut`が`null`の場合の動作を確認
  - `systemOut`が空文字列の場合の動作を確認
  - `systemOut`が有効な値の場合の動作を確認
  - `equals`メソッドで`systemOut`が正しく比較されることを確認
  - `hashCode`メソッドで`systemOut`が正しく含まれることを確認
  - _Requirements: 1.1, 1.2, 1.3, 1.6_

- [x] 4.2 パーサーでのprintイベント収集（テストケースレベル）のテスト
  - `print`イベントが存在する場合、対応するテストケースの`systemOut`に含まれることを確認
  - 複数の`print`イベントが時系列順に改行区切りで連結されることを確認
  - `testID`が存在しない場合、イベントが無視されることを確認
  - `testID`に対応するテストケースが見つからない場合、イベントが無視されることを確認
  - `message`が空文字列の場合、改行として扱われることを確認
  - `message`フィールドが存在しない場合、空文字列として扱われることを確認
  - printイベントが`testDone`より前に発生する場合、正しく処理されることを確認
  - printイベントが存在しない場合、`systemOut`が`null`のままであることを確認
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

- [x] 4.3 XMLジェネレーターでのsystem-outタグ生成（テストケースレベル）のテスト
  - `systemOut`が`null`でない場合、`<testcase>`要素内に`<system-out>`タグが生成されることを確認
  - `systemOut`が`null`の場合、`<system-out>`タグが生成されないことを確認
  - `systemOut`が空文字列の場合、`<system-out>`タグが生成されないことを確認
  - XMLエスケープが適切に処理されることを確認（&lt;, &gt;, &amp;等）
  - `<system-out>`タグがstatus-specific要素の前に配置されることを確認
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [x] 4.4 testsuiteレベルのsystem-outタグ削除のテスト
  - TestSuiteの`systemOut`が`null`でない場合でも、`<testsuite>`要素内に`<system-out>`タグが生成されないことを確認
  - TestSuiteの`systemErr`が`null`でない場合でも、`<testsuite>`要素内に`<system-err>`タグが生成されないことを確認
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 4.5 後方互換性のテスト
  - `print`イベントが存在しないJSONが正常に処理されることを確認
  - 既存のテストケースの動作に影響がないことを確認
  - `systemOut`が`null`の場合、XML出力が従来通りであることを確認
  - TestSuiteの`systemOut`フィールドが存在する場合でも、それが無視されることを確認
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [x] 4.6 パフォーマンステスト
  - 大量のprintイベントが存在する場合の処理時間を測定
  - StringBufferを使用した効率的な文字列連結を確認
  - テストケースごとのprintイベントグループ化が効率的であることを確認
  - メモリ使用量が適切に管理されることを確認
  - 10,000件のテストケースを10秒以内に処理できることを確認
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

### 5. 統合テストの実装
- [x] 5.1 エンドツーエンドテスト: system-outタグの生成（テストケースレベル）
  - JSON入力にprintイベントが含まれる場合、XML出力に各テストケースの`<system-out>`タグが含まれることを確認
  - 複数のテストケースがある場合、それぞれのテストケースに`<system-out>`タグが生成されることを確認
  - testsuiteレベルの`<system-out>`タグが生成されないことを確認
  - 複数のprintイベントが正しく連結されることを確認
  - JUnit XMLスキーマに準拠していることを確認
  - 既存のCI/CDツールとの互換性を確認
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 4.1, 4.2, 4.3_

- [x] 5.2 CLI統合テスト: printイベントの処理
  - printイベントを含むJSONを処理した場合、正常にXMLが生成されることを確認
  - 既存のCLI機能に影響がないことを確認
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_


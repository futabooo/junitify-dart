# Implementation Plan

## Task Breakdown

### 1. TestSuiteモデルの拡張
- [ ] 1.1 TestSuiteクラスにsystemErrフィールドを追加
  - `systemErr`フィールドを`String?`型で追加
  - コンストラクタにオプショナルパラメータ`systemErr`を追加
  - `equals`メソッドに`systemErr`を含める
  - `hashCode`メソッドに`systemErr`を含める
  - `toString`メソッドに`systemErr`を含める（オプショナル）
  - _Requirements: 1.1, 1.2, 1.3, 1.5_

### 2. Parser実装の修正
- [ ] 2.1 _SuiteBuilderクラスにsystemErrフィールドを追加
  - `systemErr`フィールドを`StringBuffer?`型で追加
  - 初期値は`null`
  - エラー出力イベントが来るたびに`StringBuffer`を作成または追加
  - _Requirements: 2.3, 2.4, 5.1_

- [ ] 2.2 _processPrintEventメソッドを修正してmessageTypeをチェック
  - `print`イベントから`messageType`フィールドを取得
  - `messageType`が`"stderr"`または`"error"`の場合、エラー出力として処理
  - `messageType`が`"print"`またはnullの場合、既存の`systemOut`処理を実行
  - _Requirements: 2.1, 2.2, 2.7_

- [ ] 2.3 エラー出力イベント処理のロジックを実装
  - エラー出力イベントから`testID`を取得
  - `testID`から`_TestInfo`を取得（`tests`マップから）
  - `_TestInfo`が見つからない場合、イベントを無視（エラーを発生させない）
  - `_TestInfo`から`suiteName`を取得
  - `suiteName`から`_SuiteBuilder`を取得（`suites`マップから）
  - `_SuiteBuilder`が見つからない場合、イベントを無視（エラーを発生させない）
  - エラー出力イベントから`message`フィールドを取得（存在しない場合は空文字列）
  - `_SuiteBuilder.systemErr`が`null`の場合、新しい`StringBuffer`を作成
  - `_SuiteBuilder.systemErr`にメッセージを追加（改行区切り）
  - 空文字列のメッセージは改行として扱う
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.6, 2.7_

- [ ] 2.4 _buildResultメソッドを修正してsystemErrを設定
  - `_SuiteBuilder`から`systemErr`を取得
  - `systemErr`が`null`でない場合、`toString()`で文字列に変換
  - `systemErr`が`null`の場合、`null`のまま
  - `TestSuite`コンストラクタに`systemErr`を渡す
  - _Requirements: 1.4, 2.5_

### 3. XMLジェネレーターの修正
- [ ] 3.1 DefaultJUnitXmlGeneratorの_buildTestSuiteメソッドを修正
  - `systemErr`が`null`でない場合、`<system-err>`タグを生成
  - `systemErr`が`null`または空文字列の場合、`<system-err>`タグを生成しない
  - `<system-err>`タグを`<system-out>`タグの後に配置
  - `<system-err>`タグを`<testcase>`要素の前に配置
  - `builder.text()`メソッドを使用してテキストコンテンツを設定（XMLエスケープは自動処理）
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

### 4. ユニットテストの実装
- [ ] 4.1 TestSuiteモデルのsystemErrフィールドのテスト
  - `systemErr`が`null`の場合の動作を確認
  - `systemErr`が空文字列の場合の動作を確認
  - `systemErr`が有効な値の場合の動作を確認
  - `equals`メソッドで`systemErr`が正しく比較されることを確認
  - `hashCode`メソッドで`systemErr`が正しく含まれることを確認
  - `systemOut`と`systemErr`が同時に設定可能であることを確認
  - _Requirements: 1.1, 1.2, 1.3, 4.6_

- [ ] 4.2 パーサーでのエラー出力イベント収集のテスト
  - `print`イベントの`messageType`が`"stderr"`の場合、`systemErr`に含まれることを確認
  - `print`イベントの`messageType`が`"error"`の場合、`systemErr`に含まれることを確認
  - `print`イベントの`messageType`が`"print"`またはnullの場合、`systemOut`に含まれることを確認（既存の動作）
  - 複数のエラー出力イベントが時系列順に改行区切りで連結されることを確認
  - `testID`が存在しない場合、イベントが無視されることを確認
  - `testID`に対応するテストケースが見つからない場合、イベントが無視されることを確認
  - `message`が空文字列の場合、改行として扱われることを確認
  - `message`フィールドが存在しない場合、空文字列として扱われることを確認
  - エラー出力イベントが存在しない場合、`systemErr`が`null`のままであることを確認
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

- [ ] 4.3 XMLジェネレーターでのsystem-errタグ生成のテスト
  - `systemErr`が`null`でない場合、`<system-err>`タグが生成されることを確認
  - `systemErr`が`null`の場合、`<system-err>`タグが生成されないことを確認
  - `systemErr`が空文字列の場合、`<system-err>`タグが生成されないことを確認
  - XMLエスケープが適切に処理されることを確認（&lt;, &gt;, &amp;等）
  - `<system-err>`タグが`<system-out>`タグの後に配置されることを確認
  - `<system-err>`タグが`<testcase>`要素の前に配置されることを確認
  - `systemOut`と`systemErr`が両方存在する場合、両方のタグが正しい順序で生成されることを確認
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [ ] 4.4 後方互換性のテスト
  - エラー出力イベントが存在しないJSONが正常に処理されることを確認
  - 既存のテストケースの動作に影響がないことを確認
  - `systemErr`が`null`の場合、XML出力が従来通りであることを確認
  - `system-out`機能と独立して動作することを確認
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [ ] 4.5 パフォーマンステスト
  - 大量のエラー出力イベントが存在する場合の処理時間を測定
  - StringBufferを使用した効率的な文字列連結を確認
  - メモリ使用量が適切に管理されることを確認
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

### 5. 統合テストの実装
- [ ] 5.1 エンドツーエンドテスト: system-errタグの生成
  - JSON入力にエラー出力イベントが含まれる場合、XML出力に`<system-err>`タグが含まれることを確認
  - 複数のテストスイートがある場合、それぞれのスイートに`<system-err>`タグが生成されることを確認
  - 複数のエラー出力イベントが正しく連結されることを確認
  - `system-out`と`system-err`が両方存在する場合、両方のタグが正しい順序で生成されることを確認
  - JUnit XMLスキーマに準拠していることを確認
  - 既存のCI/CDツールとの互換性を確認
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [ ] 5.2 CLI統合テスト: エラー出力イベントの処理
  - エラー出力イベントを含むJSONを処理した場合、正常にXMLが生成されることを確認
  - 既存のCLI機能に影響がないことを確認
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

### 6. 後方互換性の検証
- [ ] 6.1 既存のテストケースの動作確認
  - 既存のテストがすべて正常に動作することを確認
  - エラー出力イベントが存在しないJSONでも正常に処理されることを確認
  - 既存のAPIインターフェースが変更されていないことを確認（オプショナルパラメータの追加のみ）
  - `system-out`機能と独立して動作することを確認
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_


# Implementation Plan

## Task Breakdown

### 1. TestSuiteモデルの拡張

#### 1.1 TestSuiteクラスにplatformフィールドを追加
- [x] `platform`フィールドを`String?`型で追加
  - コンストラクタにオプショナルパラメータ`platform`を追加
  - `equals`メソッドに`platform`を含める
  - `hashCode`メソッドに`platform`を含める
  - `toString`メソッドに`platform`を含める（オプショナル）
  - 空文字列も有効な値として扱う（nullと区別）
  - _Requirements: 1.1, 1.2, 1.3, 1.6_

### 1.2 パーサーでのplatform情報の取得
- [x] `_SuiteBuilder`クラスにplatformフィールドを追加
  - `platform`フィールドを`String?`型で追加
  - _Requirements: 3.1, 3.2_

- [x] `_processSuiteEvent`メソッドを修正
  - suiteイベントから`platform`フィールドを読み取る
  - `_SuiteBuilder`に`platform`を設定
  - _Requirements: 3.1, 3.2_

- [x] `_buildResult`メソッドを修正
  - TestSuite作成時に`platform`を設定
  - _Requirements: 3.1, 3.2_

### 2. XMLジェネレーターの修正

#### 2.1 DefaultJUnitXmlGeneratorにプラットフォーム情報取得メソッドを追加
- [x] `_getPlatformInfo`メソッドを新規作成
  - `TestSuite`の`platform`フィールドがnullでない場合、その値を返す
  - `platform`フィールドがnullの場合、`Platform.operatingSystem`を使用して動的に取得
  - `Platform.operatingSystem`が例外をスローする場合、try-catchで捕捉し、nullを返す
  - プラットフォーム情報が空文字列の場合、nullを返す
  - `dart:io`パッケージをインポートする
  - _Requirements: 3.3, 3.4, 3.5, 3.6_

#### 2.2 DefaultJUnitXmlGeneratorの_buildTestSuiteメソッドを修正
- [x] `<properties>`タグを生成するロジックを追加
  - `_getPlatformInfo`メソッドを呼び出してプラットフォーム情報を取得
  - プラットフォーム情報が取得可能な場合、`<properties>`タグを生成
  - `<properties>`タグ内に`<property>`タグを生成
  - `<property>`タグに`name="platform"`属性と`value`属性を設定
  - `<properties>`タグを`<testcase>`要素の前に配置（JUnit XMLスキーマ準拠）
  - XMLエスケープはxmlパッケージが自動的に処理
  - プラットフォーム情報が取得できない場合、`<properties>`タグを生成しない
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

### 3. ユニットテストの実装

#### 3.1 TestSuiteモデルのplatformフィールドのテスト
- [x] TestSuiteモデルのplatformフィールドのテストを追加
  - `platform`が`null`の場合の動作を確認
  - `platform`が空文字列の場合の動作を確認
  - `platform`が有効な値（"linux", "macos", "windows"等）の場合の動作を確認
  - `equals`メソッドで`platform`が正しく比較されることを確認
  - `hashCode`メソッドで`platform`が正しく含まれることを確認
  - `toString`メソッドに`platform`が含まれることを確認（オプショナル）
  - _Requirements: 1.1, 1.2, 1.3, 5.1_

#### 3.2 XMLジェネレーターでのpropertiesタグ生成のテスト
- [x] propertiesタグ生成のテストを追加
  - `platform`フィールドがnullでない場合、`<properties>`タグが生成されることを確認
  - `platform`フィールドがnullの場合、`Platform.operatingSystem`を使用して動的に取得することを確認
  - プラットフォーム情報が取得可能な場合、`<properties>`タグが生成されることを確認
  - プラットフォーム情報が取得できない場合、`<properties>`タグが生成されないことを確認
  - `platform`が空文字列の場合、`<properties>`タグが生成されないことを確認
  - XMLエスケープが適切に処理されることを確認（&lt;, &gt;, &amp;等）
  - `<properties>`タグが`<testcase>`要素の前に配置されることを確認
  - `<property>`タグが`name="platform"`属性と適切な`value`属性を持つことを確認
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 5.2_

#### 3.3 プラットフォーム情報取得のテスト
- [ ] プラットフォーム情報取得のテストを追加
  - `Platform.operatingSystem`が正常に取得できる場合の動作を確認
  - `Platform.operatingSystem`が例外をスローする場合の動作を確認（Web環境のシミュレーション）
  - プラットフォーム情報が空文字列の場合の動作を確認
  - `platform`フィールドが設定されている場合、その値が優先されることを確認
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 5.3_

#### 3.4 後方互換性のテスト
- [ ] 後方互換性のテストを追加
  - `platform`フィールドがnullの場合、既存の動作に影響がないことを確認
  - 既存のテストケースの動作に影響がないことを確認
  - 既存の`<testcase>`要素、`<system-out>`要素、`<system-err>`要素の生成に影響がないことを確認
  - 既存のXML出力との互換性を維持することを確認（`<properties>`タグが追加されるのみ）
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 5.5_

#### 3.5 パフォーマンステスト
- [ ] パフォーマンステストを追加
  - プラットフォーム情報の取得がパフォーマンスに大きな影響を与えないことを確認（既存の処理時間の5%以内の増加）
  - 大量のテストケースがある場合の処理時間を測定
  - メモリ使用量が適切に管理されることを確認
  - _Requirements: 3.5, 5.6_

### 4. 統合テストの実装

#### 4.1 エンドツーエンドテスト: propertiesタグの生成
- [ ] エンドツーエンドテストを追加
  - プラットフォーム情報が取得可能な場合、XML出力に`<properties>`タグが含まれることを確認
  - 複数のテストスイートがある場合、それぞれのスイートに`<properties>`タグが生成されることを確認
  - `<properties>`タグが`<testcase>`要素の前に配置されることを確認
  - JUnit XML標準スキーマに準拠していることを確認
  - 既存のCI/CDツールとの互換性を確認
  - _Requirements: 2.6, 2.8, 5.1, 5.2, 5.6, 5.7_

#### 4.2 CLI統合テスト: プラットフォーム情報の処理
- [ ] CLI統合テストを追加
  - プラットフォーム情報を含むXMLが正常に生成されることを確認
  - 既存のCLI機能に影響がないことを確認
  - プラットフォーム情報が取得できない環境でも正常に処理されることを確認
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

### 5. 後方互換性の検証

#### 5.1 既存のテストケースの動作確認
- [ ] 既存のテストケースの動作確認
  - 既存のテストがすべて正常に動作することを確認
  - `platform`フィールドがnullの場合でも正常に処理されることを確認
  - 既存のAPIインターフェースが変更されていないことを確認（オプショナルパラメータの追加のみ）
  - 既存のXML出力との互換性を維持することを確認
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 5.5_

### 6. ドキュメントの更新

#### 6.1 コードコメントの更新
- [x] コードコメントの更新
  - `_buildTestSuite`メソッドに`<properties>`タグ生成に関するコメントを追加
  - `_getPlatformInfo`メソッドにプラットフォーム情報取得に関するコメントを追加
  - `_processSuiteEvent`メソッドにplatform情報取得に関するコメントを追加
  - JUnit XML標準への準拠を明記
  - _Requirements: 2.6, 3.1_


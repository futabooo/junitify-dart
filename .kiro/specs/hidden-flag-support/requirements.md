# Requirements Document

## Project Description (Input)
junitifyは、Dartのテストフレームワークが出力するJSON形式のテスト結果を、CI/CDシステムやテストレポートツールで広く使用されているJUnit XML形式に変換するコマンドラインツールです。

## Requirements

### Requirement 1: Hiddenフラグの検出とフィルタリング
**Objective:** As a 開発者, I want JSONのhiddenフラグがtrueの場合にテストケースをパース段階で完全に無視する機能, so that hiddenテストがテスト結果に含まれないようにできる

#### Acceptance Criteria
1. When JSONのtestDoneイベントでhiddenフラグがtrueの場合, the parser shall テストケースをTestCaseオブジェクトとして作成せず、スイートに追加しない
2. When hiddenフラグがtrueのテストケースを検出した場合, the parser shall そのテストケースを完全にスキップし、後続の処理に影響を与えない
3. When hiddenフラグがfalseまたは未指定の場合, the parser shall 従来通りテストケースを処理する
4. When hiddenフラグとskippedフラグの両方がtrueの場合, the parser shall hiddenフラグを優先し、テストケースを無視する
5. When testStartイベントでテストが開始されたが、対応するtestDoneイベントでhiddenフラグがtrueの場合, the parser shall そのテストケースを無視する

### Requirement 2: ログ出力とデバッグ情報
**Objective:** As a 開発者, I want hiddenテストが無視された場合にデバッグログを出力する機能, so that 処理の可視性を確保できる

#### Acceptance Criteria
1. When hiddenフラグがtrueのテストケースを検出した場合, the parser shall デバッグモードが有効な場合のみログメッセージを出力する
2. When デバッグログを出力する場合, the system shall テストケース名とスイート名を含む情報を出力する
3. When デバッグモードが無効な場合, the system shall ログを出力せず、サイレントに無視する
4. The log message shall 標準エラー出力に出力され、XML出力に影響を与えない
5. The log message format shall `[DEBUG] Ignoring hidden test: {suiteName}::{testName}` の形式とする

### Requirement 3: 統計情報からの除外
**Objective:** As a 開発者, I want hiddenテストが統計情報に含まれないようにする機能, so that 正確なテスト結果を報告できる

#### Acceptance Criteria
1. When hiddenフラグがtrueのテストケースを無視する場合, the system shall テストスイートのtotalTestsカウントから除外する
2. When hiddenフラグがtrueのテストケースを無視する場合, the system shall テストスイートのfailures、errors、skippedカウントからも除外する
3. When hiddenフラグがtrueのテストケースを無視する場合, the system shall テストスイートの実行時間（time）からも除外する
4. When hiddenフラグがtrueのテストケースを無視する場合, the system shall DartTestResultの集計統計（totalTests、totalFailures等）からも除外する
5. When すべてのテストケースがhiddenフラグで無視された場合, the system shall 空のテストスイートとして扱い、エラーを発生させない

### Requirement 4: XML変換時の除外
**Objective:** As a 開発者, I want hiddenテストがJUnit XMLに含まれないようにする機能, so that CI/CDツールで不要なテストが表示されない

#### Acceptance Criteria
1. When hiddenフラグがtrueのテストケースがパース段階で除外された場合, the converter shall そのテストケースをXMLに含めない
2. When テストスイートにhiddenテストのみが含まれていた場合, the converter shall そのテストスイートをXMLに含めない
3. When テストスイートにhiddenテストと通常のテストが混在している場合, the converter shall 通常のテストのみを含むXMLを生成する
4. The XML output shall 統計情報が正確に反映される（hiddenテストが除外された後の値）
5. The XML output shall JUnit XMLスキーマに準拠し、既存のCI/CDツールと互換性を保つ

### Requirement 5: 後方互換性の維持
**Objective:** As a 開発者, I want hiddenフラグの処理が既存の動作に影響を与えないようにする機能, so that 既存のワークフローが壊れない

#### Acceptance Criteria
1. When hiddenフラグがfalseまたは未指定の場合, the system shall 従来通りテストケースを処理する
2. When hiddenフラグが存在しないJSONを処理する場合, the system shall エラーを発生させず、従来通り処理する
3. When hiddenフラグがboolean以外の型（文字列、数値等）の場合, the system shall falseとして扱い、エラーを発生させない
4. The system shall 既存のテストケースの動作（passed、failed、skipped）に影響を与えない
5. The system shall 既存のAPIインターフェースを変更しない


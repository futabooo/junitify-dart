# Implementation Plan

## Task Breakdown

### 1. プロジェクトセットアップとベース構造
- [x] 1.1 (P) プロジェクト初期化と依存関係設定
  - Dartプロジェクトの初期化（pubspec.yaml作成）
  - 必要な依存パッケージの追加（args ^2.4.0、xml ^6.5.0、test ^1.24.0）
  - プロジェクト構造のディレクトリ作成（lib、bin、test）
  - _Requirements: 5_

- [x] 1.2 (P) 共通型定義とエラー型の実装
  - Result型の実装（成功/失敗を表現）
  - エラー型階層の定義（AppError、ErrorPhase enum）
  - 各フェーズのエラー型（InputError、ParseError、OutputError）
  - _Requirements: 6_

### 2. データモデルの実装
- [x] 2.1 (P) Dartテスト結果のドメインモデル構築
  - TestStatusの列挙型定義（passed、failed、skipped、error）
  - TestCaseモデルの実装（name、className、status、time、errorMessage、stackTrace）
  - TestSuiteモデルの実装（name、testCases、time）
  - DartTestResultモデルの実装（suites、totalTests、totalFailures、totalSkipped、totalTime）
  - ビジネスルールの不変条件検証ロジック
  - _Requirements: 2_

### 3. エラーハンドリング機能の実装
- [x] 3.1 (P) エラー報告とログ機能の構築
  - ErrorReporterインターフェースの実装
  - 標準エラー出力へのエラーメッセージ出力機能
  - デバッグモードとログレベル制御
  - エラーフォーマット機能（フェーズ別メッセージ生成）
  - _Requirements: 6_

### 4. 入力処理機能の実装
- [x] 4.1 ファイル入力の読み込み機能
  - InputSourceインターフェースの定義
  - FileInputSourceの実装（ファイルからJSON文字列を読み込む）
  - UTF-8エンコーディングの保証
  - ファイル存在確認とエラーハンドリング（FileNotFoundError、FileReadError）
  - _Requirements: 1, 6_

- [x] 4.2 標準入力の読み込み機能
  - StdinInputSourceの実装（標準入力からJSON文字列を読み込む）
  - UTF-8エンコーディングの保証
  - エンコーディングエラーのハンドリング
  - _Requirements: 1, 6_

### 5. JSON解析機能の実装
- [x] 5.1 JSONパーサーの基本構造構築
  - DartTestParserインターフェースの定義
  - JSON構文検証とデコード機能
  - JSON構文エラーのハンドリング（JsonSyntaxError）
  - _Requirements: 2, 6_

- [x] 5.2 Dartテストフォーマットのパース実装
  - Dart test JSON構造のフィールド抽出ロジック
  - テストスイート情報の抽出（name、tests、time）
  - テストケース情報の抽出（status、errorMessage、stackTrace）
  - スキップされたテストの検出
  - フォーマット検証とエラー報告（InvalidFormatError、MissingFieldError）
  - _Requirements: 2, 6_

### 6. XML変換機能の実装
- [x] 6.1 JUnit XMLジェネレーターの構築
  - JUnitXmlGeneratorインターフェースの定義
  - DartTestResultからXmlDocumentへの変換ロジック
  - JUnit XMLスキーマ構造の生成（testsuites、testsuite要素）
  - testsuite要素の属性設定（name、tests、failures、errors、skipped、time）
  - _Requirements: 3_

- [x] 6.2 テストケースのXML変換実装
  - testcase要素の生成と属性設定（name、classname、time）
  - 失敗テストケースのfailure要素生成（message、stacktrace）
  - スキップテストケースのskipped要素生成
  - 特殊文字のエスケープ処理
  - XML宣言とUTF-8エンコーディング指定
  - _Requirements: 3_

### 7. 出力処理機能の実装
- [x] 7.1 ファイル出力の書き込み機能
  - OutputDestinationインターフェースの定義
  - FileOutputDestinationの実装（XMLをファイルに書き込む）
  - Pretty print形式でのXML文字列化（インデント付き）
  - 書き込みエラーのハンドリング（FileWriteError、PermissionError）
  - _Requirements: 4, 6_

- [x] 7.2 標準出力への書き込み機能
  - StdoutOutputDestinationの実装（XMLを標準出力に書き込む）
  - UTF-8エンコーディングの保証
  - Pretty print形式での出力
  - _Requirements: 4_

### 8. CLIエントリーポイントの実装
- [x] 8.1 コマンドライン引数の解析機能
  - CliConfigモデルの実装
  - argsパッケージを使用したオプション定義（--input、--output、--help、--version、--debug）
  - 短縮オプションの設定（-i、-o、-h、-v）
  - 引数パースとバリデーション
  - 相互排他的オプションの検証
  - _Requirements: 5, 6_

- [x] 8.2 メインフロー統合とエラーハンドリング
  - CliRunnerインターフェースの実装
  - 各コンポーネント（InputReader、Parser、Converter、OutputWriter）の統合
  - エラーハンドリングと適切な終了コード制御（0: 成功、1: エラー）
  - ヘルプメッセージとバージョン情報の表示
  - デバッグモードの制御
  - _Requirements: 5, 6_

### 9. ユニットテストの実装
- [ ] 9.1 (P) データモデルのテスト
  - DartTestResult、TestSuite、TestCaseのテスト
  - 不変条件の検証テスト
  - エッジケースのテスト
  - _Requirements: 2_

- [ ] 9.2 (P) 入力処理のテスト
  - FileInputSourceのテスト（正常系、ファイル不存在、権限エラー）
  - StdinInputSourceのテスト
  - エンコーディングエラーのテスト
  - _Requirements: 1, 6_

- [ ] 9.3 (P) JSON解析のテスト
  - 有効なDart test JSON形式のパーステスト
  - JSON構文エラーのテスト
  - 不正なフォーマット（欠落フィールド、不正な型）のテスト
  - 各テストステータス（passed、failed、skipped、error）の解析テスト
  - _Requirements: 2, 6_

- [ ] 9.4 (P) XML変換のテスト
  - 成功テストケースの変換テスト
  - 失敗テストケースの変換テスト（エラーメッセージ、スタックトレース含む）
  - スキップテストケースの変換テスト
  - 複数テストスイートの変換テスト
  - 特殊文字エスケープのテスト
  - JUnit XMLスキーマ準拠の検証
  - _Requirements: 3_

- [ ] 9.5 (P) 出力処理のテスト
  - FileOutputDestinationのテスト（正常系、書き込み失敗）
  - StdoutOutputDestinationのテスト
  - Pretty print形式の検証
  - _Requirements: 4, 6_

- [ ] 9.6 (P) エラーハンドリングのテスト
  - 各エラー型のメッセージフォーマットテスト
  - エラーフェーズ別の報告テスト
  - デバッグモードの動作テスト
  - _Requirements: 6_

### 10. 統合テストの実装
- [ ] 10.1 End-to-end変換フローのテスト
  - ファイル入力→変換→ファイル出力の完全フローテスト
  - 標準入力→変換→標準出力のパイプラインテスト
  - 複数テストスイート、大量テストケースの変換テスト
  - _Requirements: 1, 2, 3, 4_

- [ ] 10.2 エラーシナリオの統合テスト
  - 各フェーズ（入力、パース、変換、出力）でのエラー発生と報告テスト
  - エラーメッセージの明確性検証
  - 適切な終了コードの検証
  - _Requirements: 6_

- [ ] 10.3 CLIインターフェースの統合テスト
  - 各コマンドラインオプションの動作テスト
  - ヘルプとバージョン表示のテスト
  - 不正なオプション指定時のエラー処理テスト
  - オプション省略時のデフォルト動作（標準I/O）テスト
  - _Requirements: 5, 6_

### 11. パフォーマンステストの実装
- [ ] 11.1 大規模テストケース処理のテスト
  - 10,000テストケースを含むファイルの処理時間測定（10秒以内の検証）
  - メモリ使用量の測定（入力ファイルサイズの3倍以内の検証）
  - 大容量ファイル（100MB+）の処理テスト
  - _Requirements: 7_

### 12. 実行可能ファイルの作成
- [ ] 12.1 CLIコマンドとしてのパッケージング
  - binディレクトリにメインエントリーポイント作成
  - 実行権限の設定
  - dart compileを使用したネイティブバイナリのコンパイル（オプション）
  - _Requirements: 5_

## Requirements Coverage Matrix

| Requirement | Tasks |
|-------------|-------|
| 1 - JSON入力の処理 | 4.1, 4.2, 9.2, 10.1 |
| 2 - Dartテストフォーマットのパース | 2.1, 5.1, 5.2, 9.1, 9.3, 10.1 |
| 3 - JUnit XML形式への変換 | 6.1, 6.2, 9.4, 10.1 |
| 4 - XML出力の生成 | 7.1, 7.2, 9.5, 10.1 |
| 5 - コマンドラインインターフェース | 1.1, 8.1, 8.2, 10.3, 12.1 |
| 6 - エラーハンドリングとログ | 1.2, 3.1, 4.1, 4.2, 5.1, 5.2, 7.1, 8.1, 8.2, 9.2, 9.3, 9.5, 9.6, 10.2, 10.3 |
| 7 - パフォーマンスと制約 | 11.1 |

## Implementation Notes

### 並列実行可能なタスク
- タスク1.1とタスク1.2は独立して実行可能
- タスク2.1、3.1は他のタスクと並列実行可能
- ユニットテスト（9.1〜9.6）は相互に独立しており並列実行可能

### タスク実行順序の推奨
1. **フェーズ1**: プロジェクトセットアップ（1.1、1.2）
2. **フェーズ2**: 基盤実装（2.1、3.1）
3. **フェーズ3**: コア機能実装（4.1、4.2、5.1、5.2、6.1、6.2、7.1、7.2）- パイプラインの流れに沿って実装
4. **フェーズ4**: CLI統合（8.1、8.2）
5. **フェーズ5**: テスト（9.1〜9.6、10.1〜10.3、11.1）
6. **フェーズ6**: パッケージング（12.1）

### 注意事項
- タスク5.2は5.1に依存
- タスク6.2は6.1に依存
- タスク8.2は4.1、4.2、5.2、6.2、7.1、7.2に依存（統合タスク）
- 統合テスト（10.x）は対応する実装タスクの完了後に実行


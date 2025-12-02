# Implementation Plan

## Task Breakdown

### 1. CliConfigへの設定追加
- [x] 1.1 CliConfigクラスにfileRelativeToフィールドを追加
  - `fileRelativeTo`フィールド（`String?`型）を追加
  - コンストラクタにオプショナルパラメータ`fileRelativeTo`を追加（デフォルト値: `'.'`）
  - `toString`メソッドに`fileRelativeTo`を含める
  - 既存のフィールドとの後方互換性を維持
  - _Requirements: 2.1, 2.2, 2.5, 2.6_

### 2. CLIオプションの追加
- [x] 2.1 DefaultCliRunnerの_createArgParserメソッドを修正
  - `--file-relative-to`オプションを追加（文字列値を受け取る）
  - `-r`短縮形を追加
  - ヘルプテキストを設定: "the relative path to calculate the path defined in the 'file' element in the test from"
  - デフォルト値を`'.'`に設定
  - 既存のオプションとの互換性を維持
  - _Requirements: 1.1, 1.2, 1.6, 1.7, 1.8, 1.9, 1.10_

- [x] 2.2 DefaultCliRunnerの_buildConfigメソッドを修正
  - `results['file-relative-to']`から`fileRelativeTo`値を取得
  - `CliConfig`に`fileRelativeTo`を設定
  - _Requirements: 1.3, 2.3_

- [x] 2.3 DefaultCliRunnerの_runConversionメソッドを修正
  - パーサーの`parse`メソッドに`fileRelativeTo: config.fileRelativeTo`を渡す
  - 既存のパラメータ（`jsonString`、`errorReporter`）との互換性を維持
  - _Requirements: 1.3, 1.4, 1.5_

### 3. パーサーインターフェースの拡張
- [x] 3.1 DartTestParserインターフェースのparseメソッドを修正
  - `parse`メソッドに`fileRelativeTo`パラメータを追加（オプショナル、デフォルト: `null`）
  - 既存のパラメータ（`jsonString`、`errorReporter`）との互換性を維持
  - ドキュメントコメントを更新
  - _Requirements: 3.8, 3.9, 5.4, 5.7_

- [x] 3.2 DefaultDartTestParserのparseメソッドを修正
  - `fileRelativeTo`パラメータを受け取る
  - `_processTestStartEvent`メソッドに`fileRelativeTo`を渡す
  - 既存の処理フローを維持
  - _Requirements: 3.8, 3.9, 5.4, 5.7_

### 4. パス変換ロジックの実装
- [x] 4.1 _extractFilePathFromUrlメソッドのシグネチャを変更
  - `fileRelativeTo`パラメータ（`String?`型）を追加
  - 既存の処理（URI解析、ファイルパス抽出）を維持
  - _Requirements: 3.2, 3.3, 3.4_

- [x] 4.2 _extractFilePathFromUrlメソッドに相対パス変換ロジックを追加
  - `fileRelativeTo`が`null`または空文字列の場合、絶対パスをそのまま返す
  - `fileRelativeTo`が指定されている場合、`path.relative(absolutePath, from: fileRelativeTo)`を使用して相対パスに変換
  - `path`パッケージをインポート（`import 'package:path/path.dart' as p;`）
  - `path.relative`が例外を投げる場合、エラーをキャッチし、絶対パスをそのまま返す（フォールバック）
  - エッジケースの処理（異なるドライブ、ルートパス等）
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9, 4.10, 4.11, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 6.10_

- [x] 4.3 _processTestStartEventメソッドを修正
  - `_extractFilePathFromUrl`メソッドを呼び出す際に`fileRelativeTo`を渡す
  - 既存の処理（`url`と`line`の取得、`_TestInfo`への保存）を維持
  - _Requirements: 3.2, 3.3, 3.4, 3.7_

### 5. ユニットテストの実装
- [ ] 5.1 CliConfigのfileRelativeToフィールドのテスト
  - `fileRelativeTo`がデフォルト値（`'.'`）で設定されることを確認
  - `fileRelativeTo`が明示的に指定された場合、その値が設定されることを確認
  - `fileRelativeTo`が`null`の場合の動作を確認
  - `toString`メソッドに`fileRelativeTo`が含まれることを確認
  - 既存のフィールドとの互換性を確認
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [ ] 5.2 CLIオプション解析のテスト
  - `--file-relative-to`オプションが正しく解析されることを確認
  - `-r`短縮形が正しく解析されることを確認
  - デフォルト値（`'.'`）が設定されることを確認
  - ヘルプテキストが正しく表示されることを確認
  - 既存のオプションとの互換性を確認
  - _Requirements: 1.1, 1.2, 1.6, 1.7, 1.8, 1.9, 1.10_

- [ ] 5.3 パーサーのfileRelativeToパラメータのテスト
  - `fileRelativeTo`が`null`の場合、絶対パスが維持されることを確認
  - `fileRelativeTo`が`'.'`の場合、現在のワーキングディレクトリを基準とした相対パスが生成されることを確認
  - `fileRelativeTo`が指定された場合、相対パスが生成されることを確認
  - `fileRelativeTo`が空文字列の場合、絶対パスが維持されることを確認
  - 既存のAPIインターフェースとの互換性を確認（パラメータ未指定時）
  - _Requirements: 3.1, 3.2, 3.8, 3.9, 3.10, 5.4, 5.7_

- [ ] 5.4 _extractFilePathFromUrlメソッドの相対パス変換のテスト
  - `fileRelativeTo`が`null`の場合、絶対パスをそのまま返すことを確認
  - `fileRelativeTo`が空文字列の場合、絶対パスをそのまま返すことを確認
  - `fileRelativeTo`が指定されている場合、`path.relative`を使用して相対パスに変換されることを確認
  - `path.relative`が例外を投げる場合、エラーをキャッチし、絶対パスをそのまま返すことを確認
  - 異なるプラットフォーム（Windows、Unix/Linux）での動作を確認
  - エッジケースのテスト:
    - 異なるドライブのWindowsパス（絶対パスをそのまま返す）
    - ルートパス（`/`で始まるUnix/Linuxパス）
    - 存在しないディレクトリを参照する`fileRelativeTo`
    - 相対パスとして指定された`fileRelativeTo`（例：`../parent`）
    - `fileRelativeTo`が`..`や`.`を含む場合
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9, 4.10, 4.11, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 6.10_

- [ ] 5.5 後方互換性のテスト
  - `fileRelativeTo`パラメータが指定されない場合、絶対パスが維持されることを確認
  - 既存のテストケースの動作に影響がないことを確認
  - CLIで`--file-relative-to`オプションが指定されない場合、デフォルト値（`'.'`）が使用されることを確認
  - APIインターフェースで`fileRelativeTo`パラメータが指定されない場合、デフォルト値（`null`）が使用されることを確認
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_

### 6. 統合テストの実装
- [ ] 6.1 エンドツーエンドテスト: 相対パス変換
  - `--file-relative-to`オプションを指定した場合、XML出力の`file`属性が相対パスになることを確認
  - `--file-relative-to`オプションを指定しない場合、XML出力の`file`属性が相対パスになることを確認（デフォルト値: `'.'`）
  - `-r`短縮形を使用した場合、正しく動作することを確認
  - 複数のテストケースがある場合、それぞれのテストケースに正しい相対パスが設定されることを確認
  - 異なる`fileRelativeTo`値を指定した場合の動作を確認
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 6.2 CLI統合テスト: オプションの処理
  - `--file-relative-to`オプションを含むCLIコマンドが正常に実行されることを確認
  - 既存のCLI機能（`--input`、`--output`、`--help`、`--version`、`--debug`）との互換性を確認
  - エラーハンドリング（不正なオプション値等）を確認
  - _Requirements: 1.10, 5.1, 5.2, 5.3, 7.1, 7.2_

- [ ] 6.3 エッジケースの統合テスト
  - 異なるプラットフォーム（Windows、Unix/Linux）での動作を確認
  - 異なるドライブのWindowsパスの動作を確認
  - ルートパスの動作を確認
  - 存在しないディレクトリを参照する`fileRelativeTo`の動作を確認
  - 相対パスとして指定された`fileRelativeTo`の動作を確認
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 6.10, 7.7, 7.8_

## Requirements Coverage Matrix

| Requirement | Tasks |
|-------------|-------|
| 1.1-1.10 | CLIオプションの追加 | 2.1, 2.2, 2.3, 5.2, 6.1, 6.2 |
| 2.1-2.6 | CliConfigへの設定追加 | 1.1, 2.2, 5.1 |
| 3.1-3.10 | パーサーでの相対パス変換処理 | 3.1, 3.2, 4.1, 4.2, 4.3, 5.3, 5.4 |
| 4.1-4.11 | 相対パス変換ロジックの実装 | 4.1, 4.2, 4.3, 5.4 |
| 5.1-5.7 | 後方互換性の維持 | 1.1, 2.1, 2.2, 2.3, 3.1, 3.2, 4.1, 4.2, 4.3, 5.5 |
| 6.1-6.10 | エッジケースの処理 | 4.2, 4.3, 5.4, 6.3 |
| 7.1-7.10 | テストと検証 | 5.1, 5.2, 5.3, 5.4, 5.5, 6.1, 6.2, 6.3 |

## Implementation Notes

### 実装順序の推奨
1. **フェーズ1**: CliConfigへの設定追加（1.1）
2. **フェーズ2**: CLIオプションの追加（2.1, 2.2, 2.3）
3. **フェーズ3**: パーサーインターフェースの拡張（3.1, 3.2）
4. **フェーズ4**: パス変換ロジックの実装（4.1, 4.2, 4.3）
5. **フェーズ5**: ユニットテストの実装（5.1, 5.2, 5.3, 5.4, 5.5）
6. **フェーズ6**: 統合テストの実装（6.1, 6.2, 6.3）

### 実装上の注意事項
- `fileRelativeTo`はオプショナルパラメータとして実装し、後方互換性を維持する
- CLIで`--file-relative-to`オプションが指定されない場合、デフォルト値（`'.'`）が使用される
- APIインターフェースで`fileRelativeTo`パラメータが指定されない場合、デフォルト値（`null`）が使用され、絶対パスが維持される
- `path.relative`が例外を投げる場合、エラーをキャッチし、絶対パスをそのまま返す（フォールバック）
- エッジケースの処理を適切に行い、エラーを発生させない設計にする
- 既存のテストケースがすべて正常に動作することを確認

### テスト戦略
- ユニットテスト: 各コンポーネントの機能を個別にテスト
- 統合テスト: エンドツーエンドでの動作確認
- 回帰テスト: 既存のテストケースがすべて正常に動作することを確認
- エッジケーステスト: 様々なパス形式とエッジケースをテスト

### 依存関係
- タスク2.2はタスク1.1に依存
- タスク2.3はタスク1.1とタスク2.2に依存
- タスク3.2はタスク3.1に依存
- タスク4.2はタスク4.1に依存
- タスク4.3はタスク4.2に依存
- タスク5.1はタスク1.1に依存
- タスク5.2はタスク2.1に依存
- タスク5.3はタスク3.1とタスク3.2に依存
- タスク5.4はタスク4.1とタスク4.2に依存
- タスク6.1はタスク2.3とタスク4.3に依存
- タスク6.2はタスク2.1とタスク2.2に依存
- タスク6.3はタスク4.2とタスク4.3に依存


# Implementation Plan

## Task Breakdown

### 1. TestSuiteモデルの拡張

#### 1.1 TestSuiteクラスにtimestampフィールドを追加
- [x] `timestamp`フィールドを`DateTime?`型で追加
  - コンストラクタにオプショナルパラメータ`timestamp`を追加
  - `equals`メソッドに`timestamp`を含める
  - `hashCode`メソッドに`timestamp`を含める
  - `toString`メソッドに`timestamp`を含める（オプショナル）
  - _Requirements: 1.1, 1.2, 1.4_

### 2. パーサーでのtimestamp情報の取得

#### 2.1 パーサーでのtimestamp処理
- [x] TestSuiteのtimestampフィールドは常にnullのままにする
  - JSONのsuiteイベントからtimestamp情報を取得しない
  - timestamp情報はXML生成時に動的に取得される
  - _Requirements: 1.2, 1.4_

### 3. XMLジェネレーターの修正

#### 3.1 DateTimeフォーマット関数の実装
- [x] `_formatTimestamp`メソッドを新規作成
  - DateTimeをISO 8601形式（`YYYY-MM-DDTHH:mm:ss`、タイムゾーンなし）に変換
  - 年、月、日、時、分、秒を2桁または4桁にパディング
  - 秒単位まで正確に出力（ミリ秒は含めない）
  - _Requirements: 2.4, 2.5, 3.4_

#### 3.2 timestamp情報取得メソッドの実装
- [x] `_getTimestamp`メソッドを新規作成
  - `TestSuite`の`timestamp`フィールドがnullでない場合、その値を返す
  - `timestamp`フィールドがnullの場合、以下の優先順位でタイムスタンプを取得:
    - `timestampOption`が指定されている場合:
      - `now`が指定されている場合、`DateTime.now()`を使用
      - `none`が指定されている場合、nullを返す（timestamp属性を生成しない）
      - `yyyy-MM-ddTHH:mm:ss`形式の文字列が指定されている場合、`DateTime.parse()`を使用してDateTimeに変換
    - `timestampOption`が指定されていない場合:
      - `inputPath`が指定されている場合、そのファイルの変更日時を取得（`File.stat()`を使用）
      - それ以外の場合、`DateTime.now()`を使用して動的に取得
  - ファイルの変更日時取得が失敗した場合（例: ファイルが存在しない）、`DateTime.now()`にフォールバック
  - `DateTime.now()`が例外をスローする場合、try-catchで捕捉し、nullを返す
  - `DateTime.parse()`が失敗した場合、エラーをスロー（呼び出し側で処理）
  - _Requirements: 1.5, 2.3, 3.3, 3.5, 3.6, 6.2_

#### 3.3 JUnitXmlGeneratorのconvertメソッドを修正
- [x] `convert`メソッドに`inputPath`と`timestampOption`パラメータを追加
  - オプショナルパラメータ`inputPath`と`timestampOption`を追加
  - `_buildTestSuite`メソッドに`inputPath`と`timestampOption`を渡す
  - _Requirements: 1.5, 2.3, 3.3, 6.1_

#### 3.4 _buildTestSuiteメソッドを修正
- [x] `timestamp`属性を生成するロジックを追加
  - `_getTimestamp`メソッドを呼び出してtimestamp情報を取得（`inputPath`と`timestampOption`を渡す）
  - timestamp情報が取得可能で、`timestampOption`が`none`でない場合、`timestamp`属性を生成
  - `timestamp`属性を`time`属性の後に配置（JUnit XML標準スキーマに準拠）
  - `_formatTimestamp`メソッドを使用してISO 8601形式に変換
  - timestamp情報が取得できない場合、または`timestampOption`が`none`の場合、`timestamp`属性を生成しない
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 6.2_

#### 3.5 CliConfigの修正
- [x] `CliConfig`クラスに`timestampOption`フィールドを追加
  - `timestampOption`フィールドを`String?`型で追加
  - コンストラクタにオプショナルパラメータ`timestampOption`を追加
  - _Requirements: 6.1_

#### 3.6 CliRunnerの修正
- [x] `_createArgParser`メソッドに`--timestamp`オプションを追加
  - `--timestamp`オプションを追加（`-t`のショートカットも追加）
  - ヘルプメッセージに`now`、`none`、`yyyy-MM-ddTHH:mm:ss`形式の説明を追加
  - _Requirements: 6.1, 6.2_

- [x] `_buildConfig`メソッドを修正
  - `results['timestamp']`を取得して`CliConfig`に設定
  - _Requirements: 6.1_

- [x] `_runConversion`メソッドを修正
  - `generator.convert`呼び出し時に`inputPath`と`timestampOption`を渡す
  - `config.inputPath`と`config.timestampOption`を`generator.convert`に渡す
  - `timestampOption`が無効な値の場合、エラーメッセージを表示し、処理を終了する
  - _Requirements: 1.5, 2.3, 3.3, 3.6, 6.1, 6.2, 6.3_

### 4. ユニットテストの実装

#### 4.1 TestSuiteモデルのtimestampフィールドのテスト
- [ ] TestSuiteモデルのtimestampフィールドのテストを追加
  - `timestamp`が`null`の場合の動作を確認
  - `timestamp`が有効なDateTime値の場合の動作を確認
  - `equals`メソッドで`timestamp`が正しく比較されることを確認
  - `hashCode`メソッドで`timestamp`が正しく含まれることを確認
  - `toString`メソッドに`timestamp`が含まれることを確認（オプショナル）
  - _Requirements: 1.1, 1.2, 1.4, 5.5_

#### 4.2 パーサーでのtimestamp処理のテスト
- [ ] パーサーでのtimestamp処理のテストを追加
  - TestSuiteのtimestampフィールドが常にnullのままであることを確認
  - JSONのsuiteイベントからtimestamp情報を取得しないことを確認
  - _Requirements: 1.2, 1.4, 5.5_

#### 4.3 XMLジェネレーターでのtimestamp属性生成のテスト
- [ ] timestamp属性生成のテストを追加
  - `timestamp`フィールドがnullでない場合、`timestamp`属性が生成されることを確認
  - `timestampOption`が`now`の場合、現在時刻を使用することを確認
  - `timestampOption`が`none`の場合、`timestamp`属性が生成されないことを確認
  - `timestampOption`が`yyyy-MM-ddTHH:mm:ss`形式の場合、指定された時刻を使用することを確認
  - `timestampOption`が指定されず、`inputPath`が指定されている場合、ファイルの変更日時を使用することを確認
  - `timestampOption`も`inputPath`も指定されていない場合、`DateTime.now()`を使用して動的に取得することを確認
  - ファイルの変更日時取得が失敗した場合、`DateTime.now()`にフォールバックすることを確認
  - timestamp情報が取得可能な場合、`timestamp`属性が生成されることを確認
  - timestamp情報が取得できない場合、`timestamp`属性が生成されないことを確認
  - `timestamp`属性が`time`属性の後に配置されることを確認
  - `timestamp`属性のフォーマットが`YYYY-MM-DDTHH:mm:ss`形式（タイムゾーンなし）であることを確認
  - 秒単位まで正確に出力されることを確認（ミリ秒は含まれない）
  - _Requirements: 1.5, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.3, 5.1, 5.2, 5.3, 5.4, 6.1, 6.2_

#### 4.5 CLIオプションのテスト
- [ ] `--timestamp`オプションのテストを追加
  - `--timestamp now`が正しく動作することを確認
  - `--timestamp none`が正しく動作することを確認
  - `--timestamp yyyy-MM-ddTHH:mm:ss`形式が正しく動作することを確認
  - `--timestamp`に無効な値が指定された場合、エラーメッセージが表示されることを確認
  - `--timestamp`が指定されていない場合、従来の動作が維持されることを確認
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

#### 4.4 DateTimeフォーマット関数のテスト
- [ ] DateTimeフォーマット関数のテストを追加
  - 様々なDateTime値に対してISO 8601形式（`YYYY-MM-DDTHH:mm:ss`、タイムゾーンなし）で正しく変換されることを確認
  - 秒単位まで正確に出力されることを確認（ミリ秒は含まれない）
  - _Requirements: 2.4, 2.5, 3.4, 5.2_

### 5. 統合テストの実装

#### 5.1 エンドツーエンドフローのテスト
- [ ] JSONイベントからXML出力までのエンドツーエンドフローを検証
  - suiteイベントに`time`フィールドが含まれている場合のフローを検証
  - suiteイベントに`time`フィールドが含まれていない場合のフローを検証
  - 生成されたXMLに`timestamp`属性が含まれることを検証
  - `timestamp`属性が`time`属性の後に配置されることを検証
  - `timestamp`属性のフォーマットが正しいことを検証
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 5.1, 5.2, 5.3, 5.4_

#### 5.2 後方互換性のテスト
- [ ] 既存のテストケースが正常に通過することを確認
  - 既存のテストスイートを実行し、すべてのテストが正常に通過することを確認
  - timestampフィールドがnullの場合でも既存の動作が維持されることを確認
  - 既存のXML出力に影響がないことを確認（timestamp情報が取得可能な場合を除く）
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 5.5_

#### 5.3 CI/CDツールとの互換性テスト
- [ ] CI/CDツールでXMLファイルを処理するテストを追加
  - 生成されたXMLファイルがJenkins、GitLab CI、GitHub Actions等で正常に処理されることを確認
  - JUnit XML標準スキーマに準拠していることを確認
  - _Requirements: 2.6, 5.6, 5.7_


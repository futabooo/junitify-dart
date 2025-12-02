# Requirements Document

## Project Description (Input)
file属性を相対PATHで変換するかどうかのoptionをcliに追加

## Requirements

### Requirement 1: CLIオプションの追加
**Objective:** As a 開発者, I want CLIにfile属性を相対パスで変換する際の基準ディレクトリを指定するオプションを追加する機能, so that 出力されるXMLのfile属性を指定したディレクトリからの相対パスとして出力できる

#### Acceptance Criteria
1. The CLI shall `--file-relative-to` という名前のオプションを追加する
2. The CLI shall `-r` という短縮形を`--file-relative-to`オプションに追加する
3. When `--file-relative-to`オプションが指定された場合, the CLI shall 指定されたディレクトリを基準としてfile属性を相対パスに変換する
4. When `--file-relative-to`オプションが指定されていない場合（デフォルト値: `'.'`）, the CLI shall 現在のワーキングディレクトリを基準としてfile属性を相対パスに変換する
5. When `--file-relative-to`オプションが明示的に`null`または空文字列として指定された場合, the CLI shall 現在の動作（絶対パス）を維持する
6. The `--file-relative-to`オプション shall 文字列値を受け取るオプションとして実装される
7. The `--file-relative-to`オプションのヘルプテキスト shall "the relative path to calculate the path defined in the 'file' element in the test from" とする
8. The `--file-relative-to`オプションのデフォルト値 shall `'.'`（現在のワーキングディレクトリ）とする
9. The `--file-relative-to`オプション shall `--help`で表示される使用方法に含まれる
10. The CLI shall 既存のオプション（`--input`, `--output`, `--help`, `--version`, `--debug`）と互換性を保つ

### Requirement 2: CliConfigへの設定追加
**Objective:** As a 開発者, I want CliConfigクラスにfile属性の相対パス変換基準ディレクトリ設定を追加する機能, so that パーサーやコンバーターに設定を渡せる

#### Acceptance Criteria
1. The CliConfig class shall `fileRelativeTo` という名前の`String?`型フィールドを追加する
2. The CliConfig constructor shall `fileRelativeTo`パラメータをオプショナルとして受け入れる（デフォルト値: `'.'`）
3. When CliConfigが作成される場合, the CLI shall コマンドライン引数から`fileRelativeTo`値を設定する
4. When `fileRelativeTo`が`null`または空文字列の場合, the CliConfig shall 絶対パスを維持するモードとして扱う（後方互換性のため）
5. The CliConfig class shall `toString`メソッドに`fileRelativeTo`を含める（デバッグ用）
6. The CliConfig class shall 既存のフィールドとの後方互換性を維持する

### Requirement 3: パーサーでの相対パス変換処理
**Objective:** As a 開発者, I want パーサーが設定に基づいてfile属性を相対パスに変換する機能, so that XML出力で相対パスを使用できる

#### Acceptance Criteria
1. When `fileRelativeTo`設定が`null`または空文字列の場合, the parser shall 現在の動作（絶対パスをそのまま返す）を維持する
2. When `fileRelativeTo`設定が指定されている場合（デフォルト値: `'.'`を含む）, the parser shall `_extractFilePathFromUrl`メソッドで絶対パスを相対パスに変換する
3. When 絶対パスから相対パスへの変換を行う場合, the parser shall `p.relative(Uri.parse(test.url!).path, from: fileRelativeTo)`の形式で`path.relative`メソッドを使用する
4. When `path.relative`メソッドを使用する場合, the parser shall `from`パラメータに`fileRelativeTo`を指定する
5. When 絶対パスが`fileRelativeTo`ディレクトリの配下にない場合（例：異なるドライブのWindowsパス）, the parser shall 絶対パスをそのまま返す
6. When 相対パスへの変換に失敗した場合（例：`path.relative`が例外を投げる）, the parser shall エラーを発生させず、絶対パスをそのまま返す
7. When `fileRelativeTo`設定が指定されていて、既に相対パス形式のfile属性が存在する場合, the parser shall そのパスをそのまま使用する（二重変換を避ける）
8. The parser shall `parse`メソッドに`fileRelativeTo`パラメータを追加する（オプショナル、デフォルト: `null`）
9. When `fileRelativeTo`パラメータが`null`の場合, the parser shall 絶対パスをそのまま返し、後方互換性を保つ
10. When `fileRelativeTo`パラメータが`'.'`の場合, the parser shall 現在のワーキングディレクトリを基準として相対パスを生成する

### Requirement 4: 相対パス変換ロジックの実装
**Objective:** As a 開発者, I want 絶対パスから相対パスへの変換ロジックを実装する機能, so that 正確に相対パスを生成できる

#### Acceptance Criteria
1. When 絶対パスが`fileRelativeTo`ディレクトリの配下にある場合, the conversion logic shall `path.relative(targetPath, from: fileRelativeTo)`メソッドを使用して相対パスを生成する
2. When `path.relative`メソッドを使用する場合, the conversion logic shall `from`パラメータに`fileRelativeTo`を指定する
3. When Windows環境で異なるドライブのパスを変換する場合, the conversion logic shall 絶対パスをそのまま返す（相対パスに変換できない）
4. When Unix/Linux環境でパスを変換する場合, the conversion logic shall 正しく相対パスを生成する
5. When パスに`..`や`.`が含まれる場合, the conversion logic shall `path.relative`が正規化された相対パスを生成する
6. When パスが`fileRelativeTo`ディレクトリと同じ場合, the conversion logic shall `./`で始まる相対パスまたはファイル名のみを返す
7. When パス変換中にエラーが発生した場合（例：`path.relative`が例外を投げる）, the conversion logic shall 例外をキャッチし、絶対パスをそのまま返す
8. The conversion logic shall プラットフォーム固有のパス区切り文字（`/`または`\`）を適切に処理する
9. The conversion logic shall 空文字列やnullパスを適切に処理する（nullを返す）
10. When `fileRelativeTo`が相対パスとして指定された場合, the conversion logic shall 現在のワーキングディレクトリを基準に解決する
11. When `fileRelativeTo`が絶対パスとして指定された場合, the conversion logic shall その絶対パスを基準として使用する

### Requirement 5: 後方互換性の維持
**Objective:** As a 開発者, I want 新しいオプションの追加が既存の動作に影響を与えないようにする機能, so that 既存のワークフローが壊れない

#### Acceptance Criteria
1. When `--file-relative-to`オプションが指定されていない場合（デフォルト値: `'.'`が使用される）, the system shall 現在のワーキングディレクトリを基準として相対パスを生成する
2. When `--file-relative-to`オプションが明示的に`null`または空文字列として指定された場合, the system shall 従来通り絶対パスをfile属性として出力する
3. When 既存のCLIコマンドを実行する場合（オプション未指定）, the system shall デフォルト値（`'.'`）を使用して相対パスを生成する
4. When 既存のAPIインターフェースを使用する場合（`fileRelativeTo`パラメータ未指定）, the system shall デフォルト値（`null`）を使用し、絶対パスを維持する（後方互換性）
5. The system shall 既存のテストケースの動作（passed、failed、skipped）に影響を与えない
6. The system shall 既存のXML出力形式（file属性の有無、形式等）に影響を与えない（`fileRelativeTo`が`null`の場合）
7. When `fileRelativeTo`パラメータが`parse`メソッドに渡されない場合, the parser shall デフォルト値（`null`）を使用し、エラーを発生させない

### Requirement 6: エッジケースの処理
**Objective:** As a 開発者, I want 様々なパス形式に対して適切に処理できる, so that 予期しないエラーが発生しない

#### Acceptance Criteria
1. When 絶対パスが`/`（ルート）で始まるUnix/Linuxパスの場合, the conversion logic shall `fileRelativeTo`がルートの配下にある場合のみ相対パスに変換する
2. When 絶対パスが`C:\`で始まるWindowsパスの場合, the conversion logic shall `fileRelativeTo`が同じドライブにある場合のみ相対パスに変換する
3. When パスに特殊文字（スペース、日本語等）が含まれる場合, the conversion logic shall 正しく処理する
4. When パスがシンボリックリンクを参照している場合, the conversion logic shall シンボリックリンクを解決せず、元のパスをそのまま使用する
5. When パスが存在しないファイルを参照している場合, the conversion logic shall エラーを発生させず、パス変換を試みる
6. When `fileRelativeTo`が存在しないディレクトリを参照している場合, the conversion logic shall エラーを発生させず、パス変換を試みる
7. When `fileRelativeTo`が`null`または空文字列で、file属性がnullの場合, the system shall エラーを発生させず、nullのまま処理を続行する
8. When `fileRelativeTo`が指定されていて、file属性がnullの場合, the system shall エラーを発生させず、nullのまま処理を続行する
9. When `fileRelativeTo`が相対パスとして指定された場合（例：`../parent`）, the conversion logic shall 現在のワーキングディレクトリを基準に解決する
10. When `fileRelativeTo`が`..`や`.`を含む場合, the conversion logic shall `path.relative`が正規化されたパスを生成する

### Requirement 7: テストと検証
**Objective:** As a 開発者, I want 新しいオプションが正しく動作することを確認するテスト, so that 品質を保証できる

#### Acceptance Criteria
1. The system shall `--file-relative-to`オプションが正しく解析されることを確認するテストを含む
2. The system shall `-r`短縮形が正しく解析されることを確認するテストを含む
3. The system shall `fileRelativeTo`設定が指定されている場合に相対パスが生成されることを確認するテストを含む
4. The system shall `fileRelativeTo`設定が`null`の場合に絶対パスが維持されることを確認するテストを含む
5. The system shall `fileRelativeTo`設定が`'.'`の場合に現在のワーキングディレクトリを基準とした相対パスが生成されることを確認するテストを含む
6. The system shall `path.relative`メソッドが正しく使用されることを確認するテストを含む
7. The system shall 異なるプラットフォーム（Windows、Unix/Linux）での動作を確認するテストを含む
8. The system shall エッジケース（異なるドライブ、ルートパス、存在しないディレクトリ等）を確認するテストを含む
9. The system shall 後方互換性（オプション未指定時の動作、API未指定時の動作）を確認するテストを含む
10. The system shall `fileRelativeTo`が相対パスとして指定された場合の動作を確認するテストを含む

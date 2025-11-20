# Requirements Document

## Project Description (Input)
classnameの値はスラッシュをドットに変換最後の拡張子部分は削除する

## Requirements

### Requirement 1: classname属性の正規化処理
**Objective:** As a 開発者, I want JUnit XML出力のclassname属性を正規化できる機能, so that CI/CDツールでテスト結果を適切に分類・表示できる

#### Acceptance Criteria
1. When JUnit XMLを生成する際にclassname属性を設定する場合, the CLI shall スラッシュ（`/`）をドット（`.`）に変換する
2. When classname属性の値を正規化する場合, the CLI shall 最後の拡張子部分（例：`.dart`、`.js`、`.ts`）を削除する
3. When classnameが`test/example_test.dart`の場合, then the CLI shall `test.example_test`に変換する
4. When classnameが`lib/src/converter/junit_xml_generator.dart`の場合, then the CLI shall `lib.src.converter.junit_xml_generator`に変換する
5. When classnameが拡張子を持たない場合（例：`test/example_test`）, then the CLI shall スラッシュのみをドットに変換し、拡張子削除処理は行わない
6. When classnameが複数のドットを含む場合（例：`test/example.test.dart`）, then the CLI shall 最後のドット以降を拡張子として認識し、削除する
7. When classnameが空文字列の場合, then the CLI shall 空文字列のまま出力する（変換処理は行わない）
8. When classnameがスラッシュを含まない場合（例：`example_test`）, then the CLI shall 拡張子のみを削除し、スラッシュ変換処理は行わない
9. The CLI shall 変換処理をJUnit XML生成時に実行し、TestCaseモデルのclassNameフィールドは変更しない（変換は出力時のみ）

### Requirement 2: 既存機能への影響回避
**Objective:** As a 開発者, I want classname正規化機能が既存の機能に影響を与えない, so that 既存のテストやCI/CDパイプラインが正常に動作し続ける

#### Acceptance Criteria
1. When classname正規化機能を実装する場合, the CLI shall 既存のTestCaseモデルの構造を変更しない
2. When classname正規化機能を実装する場合, the CLI shall 既存のテストケースがすべて正常に動作する
3. When classname正規化機能を実装する場合, the CLI shall 他のJUnit XML属性（name、time、failure等）に影響を与えない
4. When classname正規化機能を実装する場合, the CLI shall パフォーマンスに大きな影響を与えない（変換処理はO(n)時間で完了する）

### Requirement 3: エッジケースの処理
**Objective:** As a 開発者, I want 様々な入力形式に対して適切に処理できる, so that 予期しないエラーが発生しない

#### Acceptance Criteria
1. When classnameが`/`のみで構成されている場合（例：`///`）, then the CLI shall すべてのスラッシュをドットに変換し、結果として`.`のみが残る場合は空文字列として扱う
2. When classnameが`.`のみで構成されている場合（例：`...`）, then the CLI shall 最後のドット以降を拡張子として削除する
3. When classnameが先頭にスラッシュを含む場合（例：`/test/example.dart`）, then the CLI shall 先頭のスラッシュもドットに変換する（結果：`.test.example`）
4. When classnameが末尾にスラッシュを含む場合（例：`test/example/`）, then the CLI shall 末尾のスラッシュをドットに変換し、拡張子がないためそのまま出力する（結果：`test.example.`）
5. When classnameが複数の連続するスラッシュを含む場合（例：`test//example.dart`）, then the CLI shall すべてのスラッシュをドットに変換し、連続するドットは1つのドットに正規化しない（結果：`test..example`）

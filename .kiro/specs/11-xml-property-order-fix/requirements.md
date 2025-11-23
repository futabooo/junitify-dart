# Requirements Document

## Project Description (Input)
XMLタグのプロパティの順番を修正 https://github.com/testmoapp/junitxml  を参考にして

## Requirements

### Requirement 1: testsuite要素の属性順序の修正
**Objective:** As a 開発者, I want JUnit XMLの`<testsuite>`要素の属性を標準的な順序で出力する機能, so that CI/CDツールやテスト管理ツールとの互換性を向上させ、可読性を向上させる

#### Acceptance Criteria
1. When `<testsuite>`要素を生成する場合, the converter shall 属性を以下の順序で出力する: `name`, `tests`, `failures`, `errors`, `skipped`, `time`, `timestamp`（オプション）
2. When `timestamp`属性が存在する場合, the converter shall `time`属性の後に配置する
3. When `timestamp`属性が存在しない場合, the converter shall `time`属性で終了する
4. The 属性の順序 shall testmoapp/junitxmlリポジトリで推奨される標準的なJUnit XML形式に準拠する
5. When 既存のXML出力と比較する場合, the converter shall 属性の値は変更せず、順序のみを修正する
6. The XML output shall 既存のCI/CDツール（Jenkins、GitLab CI、GitHub Actions等）と互換性を保つ

### Requirement 2: testcase要素の属性順序の修正
**Objective:** As a 開発者, I want JUnit XMLの`<testcase>`要素の属性を標準的な順序で出力する機能, so that CI/CDツールやテスト管理ツールとの互換性を向上させ、可読性を向上させる

#### Acceptance Criteria
1. When `<testcase>`要素を生成する場合, the converter shall 属性を以下の順序で出力する: `name`, `classname`, `time`, `file`（オプション）, `line`（オプション）
2. When `file`属性が存在する場合, the converter shall `time`属性の後に配置する
3. When `line`属性が存在する場合, the converter shall `file`属性の後に配置する（`file`が存在する場合）
4. When `file`属性が存在せず`line`属性が存在する場合, the converter shall `time`属性の後に`line`属性を配置する
5. The 属性の順序 shall testmoapp/junitxmlリポジトリで推奨される標準的なJUnit XML形式に準拠する
6. When 既存のXML出力と比較する場合, the converter shall 属性の値は変更せず、順序のみを修正する
7. The XML output shall 既存のCI/CDツール（Jenkins、GitLab CI、GitHub Actions等）と互換性を保つ

### Requirement 3: XML属性の順序制御の実装
**Objective:** As a 開発者, I want XML属性の順序を制御する機能, so that 標準的なJUnit XML形式に準拠した出力を生成できる

#### Acceptance Criteria
1. When Dartのxmlパッケージを使用する場合, the converter shall 属性を設定する順序がXML出力に反映されることを確認する
2. When xmlパッケージが属性の順序を保持しない場合, the converter shall 代替手段（カスタムXMLビルダー、属性の手動順序付け等）を実装する
3. When 属性を設定する場合, the converter shall 標準的な順序で属性を設定する
4. When XMLを生成する場合, the converter shall 属性の順序が一貫して維持されることを確認する
5. The 実装 shall パフォーマンスに大きな影響を与えない（既存の処理時間の10%以内の増加）

### Requirement 4: 後方互換性の維持
**Objective:** As a 開発者, I want XML属性の順序修正が既存の動作に影響を与えないようにする機能, so that 既存のワークフローが壊れない

#### Acceptance Criteria
1. When XML属性の順序を修正する場合, the system shall 属性の値は変更しない
2. When 既存のXMLファイルを処理する場合, the system shall エラーを発生させず、従来通り処理する
3. The system shall 既存のテストケースの動作（passed、failed、skipped）に影響を与えない
4. The system shall 既存のAPIインターフェースを変更しない
5. When XML属性の順序が異なるXMLファイルを読み込む場合, the system shall 正常に処理する（XML属性の順序は読み込みに影響しないため）

### Requirement 5: テストと検証
**Objective:** As a 開発者, I want XML属性の順序が正しく実装されていることを検証する機能, so that 標準的なJUnit XML形式に準拠していることを確認できる

#### Acceptance Criteria
1. When `<testsuite>`要素を生成する場合, the tests shall 属性の順序が`name`, `tests`, `failures`, `errors`, `skipped`, `time`, `timestamp`（オプション）であることを検証する
2. When `<testcase>`要素を生成する場合, the tests shall 属性の順序が`name`, `classname`, `time`, `file`（オプション）, `line`（オプション）であることを検証する
3. When 既存のテストを実行する場合, the tests shall すべてのテストが正常に通過することを確認する
4. When 生成されたXMLファイルを検証する場合, the tests shall testmoapp/junitxmlリポジトリの例と比較して順序が一致することを確認する
5. When CI/CDツールでXMLファイルを処理する場合, the tests shall 正常に処理されることを確認する


# Implementation Plan

## Task Breakdown

### 1. classname正規化関数の実装
- [ ] 1.1 (P) `normalizeClassName`関数の実装
  - `DefaultJUnitXmlGenerator`クラス内にプライベートメソッド`_normalizeClassName`を追加
  - スラッシュ（`/`）をドット（`.`）に変換する処理
  - 最後の拡張子部分（`.dart`など）を削除する処理
  - 空文字列の処理
  - エッジケースの処理（先頭スラッシュ、末尾スラッシュ、連続スラッシュ等）
  - _Requirements: 1, 3_

### 2. JUnit XML生成処理の統合
- [ ] 2.1 (P) `_buildTestCase`メソッドの修正
  - `_buildTestCase`メソッド内で`testCase.className`を正規化
  - `builder.attribute('classname', _normalizeClassName(testCase.className))`に変更
  - TestCaseモデルの`className`フィールドは変更しないことを確認
  - 他の属性（name、time等）に影響がないことを確認
  - _Requirements: 1, 2_

### 3. ユニットテストの実装
- [ ] 3.1 (P) `normalizeClassName`関数のユニットテスト
  - 基本的な変換ケースのテスト
    - `test/example_test.dart` → `test.example_test`
    - `lib/src/converter/junit_xml_generator.dart` → `lib.src.converter.junit_xml_generator`
    - `test/example_test` → `test.example_test`（拡張子なし）
    - `example_test.dart` → `example_test`（スラッシュなし）
    - `example_test` → `example_test`（変換不要）
  - 空文字列のテスト（`` → ``）
  - エッジケースのテスト:
    - `/`のみ（`///` → ``）
    - `.`のみ（`...` → ``）
    - 先頭スラッシュ（`/test/example.dart` → `.test.example`）
    - 末尾スラッシュ（`test/example/` → `test.example.`）
    - 連続スラッシュ（`test//example.dart` → `test..example`）
    - 複数ドット（`test/example.test.dart` → `test.example.test`）
  - _Requirements: 1, 3_

- [ ] 3.2 (P) `DefaultJUnitXmlGenerator`の統合テスト
  - classname正規化がXML出力に反映されることを確認
  - TestCaseモデルの`className`フィールドが変更されないことを確認
  - 他の属性（name、time、failure等）に影響がないことを確認
  - 既存のテストケースがすべて正常に動作することを確認
  - _Requirements: 1, 2_

### 4. 既存テストの更新
- [ ] 4.1 既存テストケースの期待値更新
  - `junit_xml_generator_test.dart`の既存テストを確認
  - classname属性の期待値を正規化後の形式に更新
  - すべてのテストが正常に動作することを確認
  - _Requirements: 2_

## Requirements Coverage Matrix

| Requirement | Tasks |
|-------------|-------|
| 1 - classname属性の正規化処理 | 1.1, 2.1, 3.1, 3.2 |
| 2 - 既存機能への影響回避 | 2.1, 3.2, 4.1 |
| 3 - エッジケースの処理 | 1.1, 3.1 |

## Implementation Notes

### 実装順序の推奨
1. **フェーズ1**: `normalizeClassName`関数の実装（1.1）
2. **フェーズ2**: `_buildTestCase`メソッドの修正（2.1）
3. **フェーズ3**: ユニットテストの実装（3.1、3.2）
4. **フェーズ4**: 既存テストの更新（4.1）

### 実装上の注意事項
- `normalizeClassName`関数は純粋関数として実装し、副作用を持たない
- TestCaseモデルの`className`フィールドは変更しない（出力時のみ変換）
- 既存のテストケースがすべて正常に動作することを確認
- パフォーマンスへの影響を最小限に抑える（O(n)時間で完了）

### テスト戦略
- ユニットテスト: `normalizeClassName`関数のすべてのケースをテスト
- 統合テスト: XML出力への反映を確認
- 回帰テスト: 既存のテストケースがすべて正常に動作することを確認

### 依存関係
- タスク2.1はタスク1.1に依存
- タスク3.1はタスク1.1に依存
- タスク3.2はタスク2.1に依存
- タスク4.1はタスク2.1に依存


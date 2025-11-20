# Design Document

## Overview
testcase-system-out-support機能は、DartテストJSON出力の`print`イベントを収集し、テストケースレベルでJUnit XMLの`<system-out>`タグとして出力する機能を追加します。これにより、CI/CDツールで各テストケースの標準出力を個別に確認できるようになります。また、既存のtestsuiteレベルの`<system-out>`タグは削除されます。

**Purpose**: テストケースの標準出力をJUnit XMLに含め、CI/CDツールでのデバッグと可視性を向上させる。各テストケースの出力を個別に追跡可能にする。
**Users**: Dart開発者がテストケースの標準出力をCI/CDレポートで確認したい場合に使用する。
**Impact**: パーサーでprintイベントをテストケースごとに収集し、TestCaseモデルに追加、XMLジェネレーターで`<testcase>`要素内に`<system-out>`タグを生成する。testsuiteレベルの`<system-out>`タグは生成しない。

### Goals
- TestCaseモデルに`systemOut`フィールドを追加する
- パーサーでprintイベントを収集し、テストケースに紐付ける
- JUnit XMLの`<testcase>`要素内に`<system-out>`タグを生成する
- testsuiteレベルの`<system-out>`タグを削除する
- 既存のAPIインターフェースとの後方互換性を維持する
- パフォーマンスへの影響を最小化する

### Non-Goals
- testsuiteレベルの`<system-out>`タグ（テストケースレベルのみ）
- printイベントのフィルタリング機能（すべてのprintイベントを収集）
- printイベントの順序変更機能（時系列順のみ）
- system-errタグのテストケースレベル対応（本機能では対象外）

## Architecture

### Existing Architecture Analysis
現在のアーキテクチャはレイヤードアーキテクチャを採用しており、以下の流れで処理が行われます：
1. **Input Layer**: JSON入力を読み込む
2. **Parser Layer**: JSONをDartTestResultに変換
3. **Converter Layer**: DartTestResultをJUnit XMLに変換
4. **Output Layer**: XMLを出力

現在、printイベントはテストスイートレベルで収集されています（`_SuiteBuilder.systemOut`）。本機能では、これをテストケースレベルに変更します。

### Architecture Pattern & Boundary Map
**Selected Pattern**: 既存のレイヤードアーキテクチャを維持し、Parser LayerとConverter Layerに機能を追加

```mermaid
graph LR
    CLI[CLI Runner] --> Parser[JSON Parser]
    Parser --> |Collect print events per testID| TestCase[TestCase with systemOut]
    Parser --> Converter[XML Converter]
    Converter --> |Generate system-out tag in testcase| Output[Output Writer]
```

**Architecture Integration**:
- パターン選択理由: 既存のアーキテクチャパターンを維持し、最小限の変更で機能を追加
- ドメイン境界: Parser Layerでprintイベントをテストケースごとに収集、Converter LayerでXML生成
- 既存パターンの維持: レイヤードアーキテクチャ、エラーハンドリング、Result型パターンを維持
- 新規コンポーネントの理由: printイベントをテストケースIDでグループ化して保持するデータ構造を追加
- Steering compliance: レイヤードアーキテクチャ、単一責任の原則、依存関係の一方向性を維持

### Technology Stack
既存の技術スタックを維持します。追加の依存関係は不要です。

| Layer | Choice / Version | Role in Feature | Notes |
|-------|------------------|-----------------|-------|
| Parser | Dart SDK 3.8+ | printイベントの収集とテストケースへの紐付け | 既存のParserを拡張 |
| Models | Dart SDK 3.8+ | TestCaseモデルにsystemOutフィールドを追加 | 既存のモデルを拡張 |
| Converter | xml package | system-outタグの生成とXMLエスケープ | 既存のConverterを拡張 |

## System Flows

### Print Event Processing Flow (Test Case Level)

```mermaid
sequenceDiagram
    participant CLI
    participant Parser
    participant TestBuilder
    participant Converter
    
    CLI->>Parser: parse(jsonString)
    Parser->>Parser: Process events
    Parser->>Parser: Process print event
    Parser->>Parser: Get testID from print event
    alt testID found
        Parser->>TestBuilder: Store print message for testID
        Note over TestBuilder: Group messages by testID
    else testID not found
        Parser->>Parser: Ignore print event
    end
    Parser->>Parser: Process testDone event
    Parser->>Parser: Get stored print messages for testID
    Parser->>Parser: Create TestCase with systemOut
    Parser->>CLI: Return DartTestResult
    CLI->>Converter: convert(testResult)
    alt systemOut is not null
        Converter->>Converter: Generate system-out tag in testcase
        Converter->>Converter: XML escape content
    end
    Converter->>CLI: Return XML document
```

**Flow-level decisions**:
- printイベントの処理は`_parseEvents`メソッド内で実施
- `testID`から対応するテストケースを特定し、printメッセージを一時保存
- printイベントは`testDone`イベントより前に発生する可能性があるため、`testID`でグループ化して保持
- `testDone`イベント時に、保存されたprintメッセージを時系列順に改行区切りで連結し、TestCaseに設定
- XML生成時、`systemOut`がnullでない場合のみ`<testcase>`要素内に`<system-out>`タグを生成
- `<system-out>`タグはstatus-specific要素（failure、error、skipped）の前に配置（JUnit XMLスキーマに準拠）
- testsuiteレベルの`<system-out>`タグは生成しない

## Requirements Traceability

| Requirement | Summary | Components | Interfaces | Flows |
|-------------|---------|------------|------------|-------|
| 1.1-1.6 | TestCaseにsystemOutフィールド追加 | TestCase | TestCase constructor | Print Event Processing Flow |
| 2.1-2.8 | printイベントの収集とテストケースへの紐付け | DefaultDartTestParser, _TestBuilder | - | Print Event Processing Flow |
| 3.1-3.6 | testcase要素内にsystem-outタグ生成 | DefaultJUnitXmlGenerator | - | Print Event Processing Flow |
| 4.1-4.3 | testsuiteレベルのsystem-outタグ削除 | DefaultJUnitXmlGenerator | - | Print Event Processing Flow |
| 5.1-5.6 | 後方互換性の維持 | DefaultDartTestParser, TestCase | - | Print Event Processing Flow |
| 6.1-6.5 | パフォーマンスへの影響最小化 | DefaultDartTestParser | - | Print Event Processing Flow |

## Components and Interfaces

### Models Layer

#### TestCase

| Field | Detail |
|-------|--------|
| Intent | テストケースを表現し、system-out情報を保持する |
| Requirements | 1.1, 1.2, 1.3, 1.4, 1.5, 1.6 |
| Owner / Reviewers | - |

**Responsibilities & Constraints**
- テストケースの基本情報（name、className、status、time）を保持する
- オプショナルな`systemOut`フィールドで標準出力を保持する
- `systemOut`がnullの場合、従来通り動作する

**Dependencies**
- Inbound: なし
- Outbound: TestStatus — テストステータス（P0）

**Contracts**: Data Model [ ]

##### Data Model Interface
```dart
class TestCase {
  const TestCase({
    required this.name,
    required this.className,
    required this.status,
    required this.time,
    this.errorMessage,
    this.stackTrace,
    this.systemOut,  // 新規追加: オプショナル
  });

  final String name;
  final String className;
  final TestStatus status;
  final Duration time;
  final String? errorMessage;
  final String? stackTrace;
  final String? systemOut;  // 新規追加
}
```

- Preconditions:
  - `name`、`className`、`status`、`time`は必須
  - `systemOut`はオプショナル（null可）
- Postconditions:
  - `systemOut`がnullでない場合、改行区切りで連結されたprint出力を含む
- Invariants:
  - 既存のAPIインターフェースとの後方互換性を維持（systemOutはオプショナル）

**Implementation Notes**
- `systemOut`フィールドをオプショナルパラメータとして追加
- `equals`、`hashCode`、`toString`メソッドに`systemOut`を含める必要がある
- 空文字列も有効な値として扱う（nullと区別）

### Parser Layer

#### DefaultDartTestParser

| Field | Detail |
|-------|--------|
| Intent | DartテストJSONをパースし、printイベントを収集してテストケースに紐付ける |
| Requirements | 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 6.1, 6.2, 6.3, 6.4, 6.5 |
| Owner / Reviewers | - |

**Responsibilities & Constraints**
- JSONイベントをパースし、DartTestResultを生成する
- `print`イベントを処理し、`testID`から対応するテストケースを特定する
- printイベントを`testID`でグループ化して一時保存する
- `testDone`イベント時に、保存されたprintメッセージを時系列順に改行区切りで連結し、TestCaseに設定する
- printイベントの`testID`が存在しない、または対応するテストケースが見つからない場合は無視する

**Dependencies**
- Inbound: ErrorReporter（オプショナル）— デバッグログの出力（P1）
- Outbound: DartTestResult, TestCase, TestSuite — テスト結果モデル（P0）
- External: dart:convert — JSONパース（P0）

**Contracts**: Service [ ]

##### Service Interface
```dart
abstract class DartTestParser {
  /// Parses a JSON string into a DartTestResult.
  Result<DartTestResult, ParseError> parse(
    String jsonString, {
    ErrorReporter? errorReporter,
  });
}
```

- Preconditions:
  - `jsonString`は有効なJSON文字列であること
- Postconditions:
  - printイベントが存在する場合、対応するテストケースの`systemOut`に含まれる
  - printイベントが存在しない場合、`systemOut`はnullのまま
- Invariants:
  - 既存のAPIインターフェースとの後方互換性を維持

**Implementation Notes**
- `_parseEvents`メソッド内で、printイベントを`testID`でグループ化して保持するマップを追加（`Map<int, List<String>>`または`Map<int, StringBuffer>`）
- `_processPrintEvent`メソッドを修正し、printイベントをテストケースIDでグループ化して保持
- `_processTestDoneEvent`メソッドを修正し、保存されたprintメッセージを取得してTestCaseに設定
- 効率的な文字列連結のため、`StringBuffer`を使用
- printイベントが`testDone`より前に発生する場合も処理できるように、一時保存する

#### _TestBuilder (新規内部クラスまたは既存構造の拡張)

| Field | Detail |
|-------|--------|
| Intent | テストケース構築中の情報を保持し、print出力を蓄積する |
| Requirements | 2.3, 2.4, 2.7, 2.8, 6.1, 6.5 |
| Owner / Reviewers | - |

**Responsibilities & Constraints**
- テストケースの構築中にprint出力を蓄積する
- 複数のprintイベントを時系列順に改行区切りで連結する

**Dependencies**
- Inbound: なし
- Outbound: TestCase — テストケース（P0）

**Implementation Notes**
- printイベントを`testID`でグループ化して保持するデータ構造を追加
- `Map<int, StringBuffer>`を使用して、各テストケースIDごとにprintメッセージを蓄積
- `testDone`イベント時に、対応する`testID`のprintメッセージを取得してTestCaseに設定
- 使用後はメモリ効率のため、マップから削除する

### Converter Layer

#### DefaultJUnitXmlGenerator

| Field | Detail |
|-------|--------|
| Intent | DartTestResultをJUnit XMLに変換し、testcase要素内にsystem-outタグを生成する |
| Requirements | 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 4.1, 4.2, 4.3 |
| Owner / Reviewers | - |

**Responsibilities & Constraints**
- TestCaseの`systemOut`フィールドがnullでない場合、`<testcase>`要素内に`<system-out>`タグを生成する
- XMLエスケープ（&lt;, &gt;, &amp;等）を適切に処理する
- `<system-out>`タグをstatus-specific要素（failure、error、skipped）の前に配置する
- testsuiteレベルの`<system-out>`タグは生成しない

**Dependencies**
- Inbound: DartTestResult, TestCase, TestSuite — テスト結果モデル（P0）
- Outbound: XmlDocument — XMLドキュメント（P0）
- External: xml package — XML生成（P0）

**Contracts**: Service [ ]

##### Service Interface
```dart
abstract class JUnitXmlGenerator {
  /// Converts a DartTestResult to a JUnit XML document.
  XmlDocument convert(DartTestResult testResult);
}
```

- Preconditions:
  - `testResult`は有効なDartTestResultであること
- Postconditions:
  - `systemOut`がnullでない場合、`<testcase>`要素内に`<system-out>`タグが生成される
  - XMLエスケープが適切に処理される
  - testsuiteレベルの`<system-out>`タグは生成されない
- Invariants:
  - 既存のAPIインターフェースとの後方互換性を維持

**Implementation Notes**
- `_buildTestCase`メソッド内で、status-specific要素の前に`system-out`タグを生成
- `systemOut`がnullでない場合のみ`<system-out>`タグを生成
- `xml`パッケージの`XmlBuilder`を使用してXMLエスケープを自動処理
- `builder.text()`メソッドを使用してテキストコンテンツを設定（自動エスケープ）
- `_buildTestSuite`メソッドから、testsuiteレベルの`<system-out>`タグ生成コードを削除

## Data Models

### Domain Model
TestCaseモデルに`systemOut`フィールド（String?型）を追加します。

### Logical Data Model
**変更内容**: TestCaseモデルに`systemOut`フィールドを追加

```dart
class TestCase {
  final String name;
  final String className;
  final TestStatus status;
  final Duration time;
  final String? errorMessage;
  final String? stackTrace;
  final String? systemOut;  // 新規追加
}
```

### Physical Data Model
**該当なし**: 永続化層は存在しません。

### Data Contracts & Integration
**JSONイベント構造**:
- `print`イベントの構造:
  ```json
  {
    "type": "print",
    "testID": 40,
    "message": "Usage: junitify [options]",
    "messageType": "print",
    "time": 585
  }
  ```
- `testID`フィールドから対応するテストケースを特定
- `message`フィールドがprint出力の内容
- `message`が空文字列の場合は改行として扱う

**後方互換性**:
- `print`イベントが存在しないJSONも正常に処理される
- `testID`が存在しない、または対応するテストケースが見つからない場合は無視される
- `systemOut`がnullの場合は従来通り動作する
- TestSuiteの`systemOut`フィールドは無視される（テストケースレベルのみ処理）

## Error Handling

### Error Strategy
printイベントの処理はエラーを発生させません。以下の場合でも正常に処理されます：
- `testID`フィールドが存在しない
- `testID`に対応する`_TestInfo`が見つからない
- `message`フィールドが存在しない（空文字列として扱う）
- printイベントの構造が不正（そのイベントを無視）

### Error Categories and Responses
**該当なし**: printイベントの処理はエラーを発生させない設計です。

### Monitoring
デバッグモードが有効な場合、printイベントの処理状況をログ出力することも可能ですが、現時点では実装しません（要件外）。

## Testing Strategy

### Unit Tests
1. **TestCaseモデルのsystemOutフィールド**
   - `systemOut`がnullの場合の動作を確認
   - `systemOut`が空文字列の場合の動作を確認
   - `systemOut`が有効な値の場合の動作を確認
   - `equals`、`hashCode`、`toString`に`systemOut`が含まれることを確認

2. **パーサーでのprintイベント収集（テストケースレベル）**
   - `print`イベントが存在する場合、対応するテストケースの`systemOut`に含まれることを確認
   - 複数の`print`イベントが時系列順に改行区切りで連結されることを確認
   - `testID`が存在しない場合、イベントが無視されることを確認
   - `testID`に対応するテストケースが見つからない場合、イベントが無視されることを確認
   - `message`が空文字列の場合、改行として扱われることを確認
   - printイベントが`testDone`より前に発生する場合、正しく処理されることを確認

3. **XMLジェネレーターでのsystem-outタグ生成（テストケースレベル）**
   - `systemOut`がnullでない場合、`<testcase>`要素内に`<system-out>`タグが生成されることを確認
   - `systemOut`がnullの場合、`<system-out>`タグが生成されないことを確認
   - `systemOut`が空文字列の場合、`<system-out>`タグが生成されないことを確認
   - XMLエスケープが適切に処理されることを確認（&lt;, &gt;, &amp;等）
   - `<system-out>`タグがstatus-specific要素の前に配置されることを確認

4. **testsuiteレベルのsystem-outタグ削除**
   - TestSuiteの`systemOut`がnullでない場合でも、`<testsuite>`要素内に`<system-out>`タグが生成されないことを確認
   - TestSuiteの`systemErr`がnullでない場合でも、`<testsuite>`要素内に`<system-err>`タグが生成されないことを確認

5. **後方互換性**
   - `print`イベントが存在しないJSONが正常に処理されることを確認
   - 既存のテストケースの動作に影響がないことを確認
   - `systemOut`がnullの場合、XML出力が従来通りであることを確認

6. **パフォーマンス**
   - 大量のprintイベントが存在する場合の処理時間を測定
   - StringBufferを使用した効率的な文字列連結を確認
   - テストケースごとのprintイベントグループ化が効率的であることを確認

### Integration Tests
1. **エンドツーエンドテスト: system-outタグの生成（テストケースレベル）**
   - JSON入力にprintイベントが含まれる場合、XML出力に各テストケースの`<system-out>`タグが含まれることを確認
   - 複数のテストケースがある場合、それぞれのテストケースに`<system-out>`タグが生成されることを確認
   - testsuiteレベルの`<system-out>`タグが生成されないことを確認

2. **CLI統合テスト: printイベントの処理**
   - printイベントを含むJSONを処理した場合、正常にXMLが生成されることを確認
   - 既存のCI/CDツールとの互換性を確認

### Performance Tests
1. **大規模テストスイートでのパフォーマンス**
   - 10,000件のテストケースに大量のprintイベントが含まれる場合の処理時間を測定
   - printイベントの処理によるオーバーヘッドが最小限であることを確認
   - メモリ使用量が適切に管理されることを確認

## Optional Sections

### Backward Compatibility
既存のAPIインターフェースを維持するため、`TestCase`コンストラクタにオプショナルパラメータ`systemOut`を追加します。これにより：
- 既存のコードは変更なしで動作する（`systemOut`はnullのまま）
- 新しいコードは`systemOut`を設定することで標準出力を保持できる
- デフォルトの動作（`systemOut`なし）では従来通り動作する
- TestSuiteの`systemOut`フィールドは無視されるが、既存のコードとの互換性のため削除しない

### Migration Strategy
**該当なし**: 既存のコードへの変更は不要です。新機能はオプショナルな動作として追加されます。ただし、testsuiteレベルの`<system-out>`タグは生成されなくなるため、既存のCI/CDツールがtestsuiteレベルの`<system-out>`タグに依存している場合は、テストケースレベルの`<system-out>`タグを使用するように移行する必要があります。


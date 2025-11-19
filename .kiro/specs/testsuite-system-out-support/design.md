# Design Document

## Overview
testsuite-system-out-support機能は、DartテストJSON出力の`print`イベントを収集し、テストスイートレベルでJUnit XMLの`<system-out>`タグとして出力する機能を追加します。これにより、CI/CDツールでテストスイートの標準出力を確認できるようになります。

**Purpose**: テストスイートの標準出力をJUnit XMLに含め、CI/CDツールでのデバッグと可視性を向上させる。
**Users**: Dart開発者がテストスイートの標準出力をCI/CDレポートで確認したい場合に使用する。
**Impact**: パーサーでprintイベントを収集し、TestSuiteモデルに追加、XMLジェネレーターで`<system-out>`タグを生成する。

### Goals
- TestSuiteモデルに`systemOut`フィールドを追加する
- パーサーでprintイベントを収集し、テストスイートに紐付ける
- JUnit XMLの`<testsuite>`要素内に`<system-out>`タグを生成する
- 既存のAPIインターフェースとの後方互換性を維持する
- パフォーマンスへの影響を最小化する

### Non-Goals
- テストケースレベルの`<system-out>`タグ（テストスイートレベルのみ）
- printイベントのフィルタリング機能（すべてのprintイベントを収集）
- printイベントの順序変更機能（時系列順のみ）

## Architecture

### Existing Architecture Analysis
現在のアーキテクチャはレイヤードアーキテクチャを採用しており、以下の流れで処理が行われます：
1. **Input Layer**: JSON入力を読み込む
2. **Parser Layer**: JSONをDartTestResultに変換
3. **Converter Layer**: DartTestResultをJUnit XMLに変換
4. **Output Layer**: XMLを出力

system-out機能の処理は**Parser Layer**と**Converter Layer**で実装します。Parser Layerでprintイベントを収集し、Converter LayerでXMLタグを生成します。

### Architecture Pattern & Boundary Map
**Selected Pattern**: 既存のレイヤードアーキテクチャを維持し、Parser LayerとConverter Layerに機能を追加

```mermaid
graph LR
    CLI[CLI Runner] --> Parser[JSON Parser]
    Parser --> |Collect print events| TestSuite[TestSuite with systemOut]
    Parser --> Converter[XML Converter]
    Converter --> |Generate system-out tag| Output[Output Writer]
```

**Architecture Integration**:
- パターン選択理由: 既存のアーキテクチャパターンを維持し、最小限の変更で機能を追加
- ドメイン境界: Parser Layerでprintイベントを収集、Converter LayerでXML生成
- 既存パターンの維持: レイヤードアーキテクチャ、エラーハンドリング、Result型パターンを維持
- 新規コンポーネントの理由: `_SuiteBuilder`にprint出力を蓄積する機能を追加
- Steering compliance: レイヤードアーキテクチャ、単一責任の原則、依存関係の一方向性を維持

### Technology Stack
既存の技術スタックを維持します。追加の依存関係は不要です。

| Layer | Choice / Version | Role in Feature | Notes |
|-------|------------------|-----------------|-------|
| Parser | Dart SDK 3.8+ | printイベントの収集とテストスイートへの紐付け | 既存のParserを拡張 |
| Models | Dart SDK 3.8+ | TestSuiteモデルにsystemOutフィールドを追加 | 既存のモデルを拡張 |
| Converter | xml package | system-outタグの生成とXMLエスケープ | 既存のConverterを拡張 |

## System Flows

### Print Event Processing Flow

```mermaid
sequenceDiagram
    participant CLI
    participant Parser
    participant SuiteBuilder
    participant Converter
    
    CLI->>Parser: parse(jsonString)
    Parser->>Parser: Process events
    Parser->>Parser: Process print event
    Parser->>Parser: Get testID from print event
    Parser->>Parser: Find TestInfo by testID
    alt TestInfo found
        Parser->>Parser: Get suiteName from TestInfo
        Parser->>SuiteBuilder: Append message to systemOut
    else TestInfo not found
        Parser->>Parser: Ignore print event
    end
    Parser->>Parser: Build TestSuite with systemOut
    Parser->>CLI: Return DartTestResult
    CLI->>Converter: convert(testResult)
    alt systemOut is not null
        Converter->>Converter: Generate system-out tag
        Converter->>Converter: XML escape content
    end
    Converter->>Converter: Generate testcase tags
    Converter->>CLI: Return XML document
```

**Flow-level decisions**:
- printイベントの処理は`_parseEvents`メソッド内で実施
- `testID`から`_TestInfo`を取得し、そこから`suiteName`を取得
- `_SuiteBuilder`に`systemOut`フィールドを追加し、print出力を蓄積
- 複数のprintイベントは時系列順に改行区切りで連結
- XML生成時、`systemOut`がnullでない場合のみ`<system-out>`タグを生成
- `<system-out>`タグは`<testcase>`要素の前に配置（JUnit XMLスキーマ準拠）

## Requirements Traceability

| Requirement | Summary | Components | Interfaces | Flows |
|-------------|---------|------------|------------|-------|
| 1.1 | TestSuiteにsystemOutフィールド追加 | TestSuite | TestSuite constructor | Print Event Processing Flow |
| 1.2-1.5 | systemOutフィールドの動作 | TestSuite | - | Print Event Processing Flow |
| 2.1 | printイベントのtestIDからスイート特定 | DefaultDartTestParser | - | Print Event Processing Flow |
| 2.2-2.6 | printイベントの収集と連結 | DefaultDartTestParser, _SuiteBuilder | - | Print Event Processing Flow |
| 3.1-3.6 | system-outタグの生成 | DefaultJUnitXmlGenerator | - | Print Event Processing Flow |
| 4.1-4.5 | 後方互換性の維持 | DefaultDartTestParser, TestSuite | - | Print Event Processing Flow |
| 5.1-5.4 | パフォーマンスへの影響最小化 | DefaultDartTestParser | - | Print Event Processing Flow |

## Components and Interfaces

### Models Layer

#### TestSuite

| Field | Detail |
|-------|--------|
| Intent | テストスイートを表現し、system-out情報を保持する |
| Requirements | 1.1, 1.2, 1.3, 1.4, 1.5 |
| Owner / Reviewers | - |

**Responsibilities & Constraints**
- テストスイートの基本情報（name、testCases、time）を保持する
- オプショナルな`systemOut`フィールドで標準出力を保持する
- `systemOut`がnullの場合、従来通り動作する

**Dependencies**
- Inbound: なし
- Outbound: TestCase — テストケースのリスト（P0）

**Contracts**: Data Model [ ]

##### Data Model Interface
```dart
class TestSuite {
  const TestSuite({
    required this.name,
    required this.testCases,
    required this.time,
    this.systemOut,  // 新規追加: オプショナル
  });

  final String name;
  final List<TestCase> testCases;
  final Duration time;
  final String? systemOut;  // 新規追加
}
```

- Preconditions:
  - `name`、`testCases`、`time`は必須
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
| Intent | DartテストJSONをパースし、printイベントを収集してテストスイートに紐付ける |
| Requirements | 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 4.1, 4.2, 4.3, 5.1, 5.2, 5.4 |
| Owner / Reviewers | - |

**Responsibilities & Constraints**
- JSONイベントをパースし、DartTestResultを生成する
- `print`イベントを処理し、`testID`から対応するテストスイートを特定する
- 同じテストスイートのprint出力を時系列順に改行区切りで連結する
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
  - printイベントが存在する場合、対応するテストスイートの`systemOut`に含まれる
  - printイベントが存在しない場合、`systemOut`はnullのまま
- Invariants:
  - 既存のAPIインターフェースとの後方互換性を維持

**Implementation Notes**
- `_parseEvents`メソッド内で`print`イベントを処理する新しいケースを追加
- `_processPrintEvent`メソッドを新規作成し、printイベントを処理
- `_SuiteBuilder`クラスに`systemOut`フィールド（StringBuffer型）を追加
- `testID`から`_TestInfo`を取得し、そこから`suiteName`を取得
- `_SuiteBuilder`の`systemOut`にprintメッセージを追加（改行区切り）
- `_buildResult`メソッドで`TestSuite`を作成する際、`systemOut`を設定
- 効率的な文字列連結のため、`StringBuffer`を使用

#### _SuiteBuilder

| Field | Detail |
|-------|--------|
| Intent | テストスイート構築中の情報を保持し、print出力を蓄積する |
| Requirements | 2.3, 2.4, 5.1 |
| Owner / Reviewers | - |

**Responsibilities & Constraints**
- テストスイートの構築中にprint出力を蓄積する
- 複数のprintイベントを時系列順に改行区切りで連結する

**Dependencies**
- Inbound: なし
- Outbound: TestCase — テストケースのリスト（P0）

**Implementation Notes**
- `systemOut`フィールドを`StringBuffer?`型で追加
- printイベントが来るたびに、`systemOut`にメッセージを追加（改行区切り）
- `_buildResult`で`TestSuite`を作成する際、`systemOut.toString()`を使用（nullの場合はnull）

### Converter Layer

#### DefaultJUnitXmlGenerator

| Field | Detail |
|-------|--------|
| Intent | DartTestResultをJUnit XMLに変換し、system-outタグを生成する |
| Requirements | 3.1, 3.2, 3.3, 3.4, 3.5, 3.6 |
| Owner / Reviewers | - |

**Responsibilities & Constraints**
- TestSuiteの`systemOut`フィールドがnullでない場合、`<system-out>`タグを生成する
- XMLエスケープ（&lt;, &gt;, &amp;等）を適切に処理する
- `<system-out>`タグを`<testcase>`要素の前に配置する

**Dependencies**
- Inbound: DartTestResult, TestSuite — テスト結果モデル（P0）
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
  - `systemOut`がnullでない場合、`<system-out>`タグが生成される
  - XMLエスケープが適切に処理される
- Invariants:
  - 既存のAPIインターフェースとの後方互換性を維持

**Implementation Notes**
- `_buildTestSuite`メソッド内で、`testcase`要素の前に`system-out`タグを生成
- `systemOut`がnullでない場合のみ`<system-out>`タグを生成
- `xml`パッケージの`XmlBuilder`を使用してXMLエスケープを自動処理
- `builder.text()`メソッドを使用してテキストコンテンツを設定（自動エスケープ）

## Data Models

### Domain Model
TestSuiteモデルに`systemOut`フィールド（String?型）を追加します。

### Logical Data Model
**変更内容**: TestSuiteモデルに`systemOut`フィールドを追加

```dart
class TestSuite {
  final String name;
  final List<TestCase> testCases;
  final Duration time;
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
1. **TestSuiteモデルのsystemOutフィールド**
   - `systemOut`がnullの場合の動作を確認
   - `systemOut`が空文字列の場合の動作を確認
   - `systemOut`が有効な値の場合の動作を確認
   - `equals`、`hashCode`、`toString`に`systemOut`が含まれることを確認

2. **パーサーでのprintイベント収集**
   - `print`イベントが存在する場合、`systemOut`に含まれることを確認
   - 複数の`print`イベントが時系列順に改行区切りで連結されることを確認
   - `testID`が存在しない場合、イベントが無視されることを確認
   - `testID`に対応するテストケースが見つからない場合、イベントが無視されることを確認
   - `message`が空文字列の場合、改行として扱われることを確認

3. **XMLジェネレーターでのsystem-outタグ生成**
   - `systemOut`がnullでない場合、`<system-out>`タグが生成されることを確認
   - `systemOut`がnullの場合、`<system-out>`タグが生成されないことを確認
   - `systemOut`が空文字列の場合、`<system-out>`タグが生成されないことを確認
   - XMLエスケープが適切に処理されることを確認（&lt;, &gt;, &amp;等）
   - `<system-out>`タグが`<testcase>`要素の前に配置されることを確認

4. **後方互換性**
   - `print`イベントが存在しないJSONが正常に処理されることを確認
   - 既存のテストケースの動作に影響がないことを確認

5. **パフォーマンス**
   - 大量のprintイベントが存在する場合の処理時間を測定
   - StringBufferを使用した効率的な文字列連結を確認

### Integration Tests
1. **エンドツーエンドテスト: system-outタグの生成**
   - JSON入力にprintイベントが含まれる場合、XML出力に`<system-out>`タグが含まれることを確認
   - 複数のテストスイートがある場合、それぞれのスイートに`<system-out>`タグが生成されることを確認

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
既存のAPIインターフェースを維持するため、`TestSuite`コンストラクタにオプショナルパラメータ`systemOut`を追加します。これにより：
- 既存のコードは変更なしで動作する（`systemOut`はnullのまま）
- 新しいコードは`systemOut`を設定することで標準出力を保持できる
- デフォルトの動作（`systemOut`なし）では従来通り動作する

### Migration Strategy
**該当なし**: 既存のコードへの変更は不要です。新機能はオプショナルな動作として追加されます。


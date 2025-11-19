# Project Structure

## Organization Philosophy

レイヤードアーキテクチャに基づく機能別ディレクトリ構造。各レイヤー（入力、解析、変換、出力）が明確に分離され、依存関係が一方向に流れるように設計されています。

## Directory Patterns

### CLI Layer
**Location**: `/lib/src/cli/`  
**Purpose**: コマンドラインインターフェースとエントリーポイントの実装  
**Example**: `cli_runner.dart`, `cli_config.dart`

### Input Layer
**Location**: `/lib/src/input/`  
**Purpose**: 入力ソースの抽象化と実装（ファイル、標準入力）  
**Example**: `input_source.dart`

### Parser Layer
**Location**: `/lib/src/parser/`  
**Purpose**: Dart テスト JSON の解析ロジック  
**Example**: `dart_test_parser.dart`

### Models Layer
**Location**: `/lib/src/models/`  
**Purpose**: ドメインモデルとデータ構造の定義  
**Example**: `dart_test_result.dart`, `test_suite.dart`, `test_case.dart`, `test_status.dart`

### Converter Layer
**Location**: `/lib/src/converter/`  
**Purpose**: JUnit XML 生成ロジック  
**Example**: `junit_xml_generator.dart`

### Output Layer
**Location**: `/lib/src/output/`  
**Purpose**: 出力先の抽象化と実装（ファイル、標準出力）  
**Example**: `output_destination.dart`

### Error Layer
**Location**: `/lib/src/error/`  
**Purpose**: エラー処理とレポート機能  
**Example**: `error_reporter.dart`

### Common Layer
**Location**: `/lib/src/common/`  
**Purpose**: 共通型定義とユーティリティ  
**Example**: `result.dart`, `error.dart`

### Entry Point
**Location**: `/bin/`  
**Purpose**: 実行可能なエントリーポイント  
**Example**: `junitify.dart`

### Library Export
**Location**: `/lib/junitify.dart`  
**Purpose**: パブリック API のエクスポート定義

### Tests
**Location**: `/test/`  
**Purpose**: テストコード（構造は `/lib/` と同様に組織化）  
**Example**: `/test/parser/`, `/test/converter/`, `/test/integration/`

## Naming Conventions

- **Files**: snake_case（例: `dart_test_parser.dart`）
- **Classes**: PascalCase（例: `DartTestParser`, `CliRunner`）
- **Functions/Methods**: camelCase（例: `parseJson`, `generateXml`）
- **Constants**: lowerCamelCase with `const`（例: `const defaultTimeout`）
- **Enums**: PascalCase（例: `TestStatus`, `ErrorPhase`）

## Import Organization

```dart
// 標準ライブラリ
import 'dart:io';

// 外部パッケージ
import 'package:args/args.dart';
import 'package:xml/xml.dart';

// 内部パッケージ（相対パス）
import '../models/dart_test_result.dart';
import '../common/result.dart';
```

**Import 順序**:
1. Dart 標準ライブラリ（`dart:*`）
2. 外部パッケージ（`package:*`）
3. 内部モジュール（相対パス `../` または `./`）

## Code Organization Principles

1. **依存関係の方向**: CLI → Input/Parser/Converter/Output → Models/Common
2. **インターフェース分離**: 各レイヤーは抽象インターフェースに依存し、実装は注入可能
3. **単一責任**: 各クラスは一つの明確な責任を持つ
4. **不変性**: モデルクラスは可能な限り不変（immutable）に設計
5. **テスト容易性**: 依存性注入により、各コンポーネントを独立してテスト可能

---
_Document patterns, not file trees. New files following patterns shouldn't require updates_


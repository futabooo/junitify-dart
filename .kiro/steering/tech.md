# Technology Stack

## Architecture

パイプライン/レイヤードアーキテクチャを採用。入力→解析→変換→出力の線形フローで、各レイヤーが明確に分離されています。

## Core Technologies

- **Language**: Dart 3.8+
- **Runtime**: Dart VM
- **Package Manager**: pub

## Key Libraries

- **args**: コマンドライン引数解析（^2.7.0）
- **xml**: JUnit XML 生成（^6.6.1）
- **test**: テストフレームワーク（^1.27.0、dev dependency）
- **lints**: コード品質チェック（^6.0.0、dev dependency）

## Development Standards

### Type Safety

- Dart の型システムを最大限に活用
- null 安全性を徹底
- 明示的な型注釈を推奨（特に public API）

### Code Quality

- `analysis_options.yaml` で lints ルールを定義
- 静的解析ツール（dart analyze）を活用
- コードフォーマット（dart format）を適用

### Testing

- ユニットテスト: 各コンポーネントの個別テスト
- 統合テスト: End-to-end フローのテスト
- パフォーマンステスト: 大規模データセットでの処理時間検証

## Development Environment

### Required Tools

- Dart SDK 3.8 以降
- pub パッケージマネージャー

### Common Commands

```bash
# Dev: 開発モードで実行
dart run bin/junitify.dart -i input.json -o output.xml

# Test: テスト実行
dart test

# Analyze: 静的解析
dart analyze

# Format: コードフォーマット
dart format .

# Build: パッケージ公開準備
dart pub publish --dry-run
```

## Key Technical Decisions

1. **Result 型パターン**: 型安全なエラーハンドリングのため、Result<T, E> 型を採用
2. **インターフェース分離**: InputSource、OutputDestination など、I/O を抽象化してテスト容易性を向上
3. **エラーフェーズ分類**: ErrorPhase enum でエラー発生箇所を明確化
4. **ストリーミング非対応**: シンプルさと信頼性を優先し、バッチ処理のみをサポート

---
_Document standards and patterns, not every dependency_


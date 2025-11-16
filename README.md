# junitify

A command-line tool to convert Dart test JSON output to JUnit XML format.

## Overview

junitify enables seamless integration of Dart test results with CI/CD pipelines and test reporting tools (Jenkins, GitLab CI, GitHub Actions, etc.) by converting Dart's JSON test output to the widely-supported JUnit XML format.

## Installation

```bash
dart pub global activate junitify
```

## Usage

```bash
# Convert from file to file
junitify -i test_output.json -o junit_output.xml

# Convert from stdin to stdout
dart test --reporter=json | junitify

# Show help
junitify --help

# Show version
junitify --version
```

## Options

- `-i, --input <path>` - Input JSON file path (default: stdin)
- `-o, --output <path>` - Output XML file path (default: stdout)
- `-h, --help` - Show usage information
- `-v, --version` - Show version information
- `--debug` - Enable debug mode with detailed error messages

## Requirements

- Dart SDK 3.8 or later

## License

MIT


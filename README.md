# transcribe

A small macOS command-line tool that transcribes audio files on-device using Apple's [Speech](https://developer.apple.com/documentation/speech) framework (`SpeechAnalyzer` / `SpeechTranscriber`).

## Requirements

- macOS 27 or later
- Swift 6.4 toolchain (Xcode 27)

## Installation

```sh
git clone https://github.com/cprecioso/swift-transcribe.git
cd swift-transcribe
swift build -c release
cp .build/release/transcribe /usr/local/bin/
```

## Usage

```
transcribe --language <language> [--format <format>] [--output <output>] <input-file>
```

| Option              | Description                                               | Default |
| ------------------- | --------------------------------------------------------- | ------- |
| `-l`, `--language`  | Audio language, as a locale identifier (e.g. `en_US`)     |         |
| `-f`, `--format`    | Output format: `plain` or `srt`                           | `plain` |
| `-o`, `--output`    | Output file path, or `-` for stdout                       | stdout  |
| `<input-file>`      | Audio file to transcribe                                  |         |

If the requested locale isn't supported, the closest supported one is used and a warning is printed. Speech models for the locale are downloaded automatically on first use.

### Examples

Print a plain-text transcript:

```sh
transcribe -l en_US interview.m4a
```

Generate SRT subtitles:

```sh
transcribe -l es_ES -f srt -o subtitles.srt video-audio.wav
```

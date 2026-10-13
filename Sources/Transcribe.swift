import ArgumentParser
import Foundation
import Logging
import Speech

let logger = Logger(label: "design.precioso.Transcribe")

@main
struct Transcribe: AsyncParsableCommand {
  @Option(
    name: "-l --language",
    help: "Audio language",
    transform: Locale.init(identifier:)
  )
  var inputLocale: Locale

  @Option(
    name: "-f --format",
    help: "Output file format"
  )
  var outputFormat: OutputFormat = .plain

  @Option(
    name: "-o --output",
    help: "Where to store the output",
    completion: .file(),
    transform: getOutputStream
  )
  var outputStream: FileHandle = .standardOutput

  @Argument(
    help: "The file to transcribe",
    completion: .file(),
    transform: URL.init(fileURLWithPath:)
  )
  var inputFile: URL

  mutating func run() async throws {

    guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: inputLocale) else {
      throw CLIError.argumentError("Locale is not supported")
    }
    if locale != inputLocale {
      logger.warning(
        "Locale \"\(inputLocale)\" is not supported, using closest supported locale: \"\(locale)\"")
    }

    let transcriber = SpeechTranscriber(
      locale: locale,
      transcriptionOptions: [],
      reportingOptions: [],
      attributeOptions: [.audioTimeRange]
    )

    if await !SpeechTranscriber.installedLocales.contains(locale) {
      logger.info("Starting download...")
      do {
        if let req =
          try await AssetInventory
          .assetInstallationRequest(supporting: [transcriber])
        {
          try await req.downloadAndInstall()
        }
      } catch {
        throw CLIError.genericError("Asset installation failed", error)
      }
      logger.info("Download finished")
    }

    let analyzer = SpeechAnalyzer(modules: [transcriber])
    defer { await analyzer.cancelAndFinishNow() }

    let file = try AVAudioFile(forReading: inputFile)

    let outputStream = self.outputStream
    defer { try? outputStream.close() }

    let outputFormatter = outputFormat.formatter

    let writeTask =
      Task {
        for try await outputData in outputFormatter(results: transcriber.results) {
          try outputStream.write(contentsOf: outputData)
        }
      }
    defer { writeTask.cancel() }

    logger.debug("Starting analysis")
    if let lastSampleTime =
      try await analyzer.analyzeSequence(from: file)
    {
      logger.debug("Finalizaing analysis")
      try await analyzer.finalizeAndFinish(through: lastSampleTime)
    }
    logger.debug("Analysis done")

    logger.debug("Waiting for result write")
    try await writeTask.value
    logger.debug("Result write finished")
  }
}

func getOutputStream(_ inputValue: String?) throws -> FileHandle {
  if let inputValue, inputValue != "-" {
    guard FileManager.default.createFile(atPath: inputValue, contents: nil) else {
      throw CLIError.fileError("Can't create output file")
    }
    guard let fh = FileHandle(forWritingAtPath: inputValue) else {
      throw CLIError.genericError("Can't open output file")
    }
    return fh
  } else {
    return .standardOutput
  }
}

enum CLIError: Swift.Error {
  case genericError(String, Error? = nil)
  case fileError(String)
  case argumentError(String)
}

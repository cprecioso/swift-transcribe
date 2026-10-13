import ArgumentParser
import Speech

enum OutputFormat: String, ExpressibleByArgument {
  case plain
  case srt

  var formatter: any OutputFormatter {
    switch self {
    case .plain: PlainFormatter()
    case .srt: SrtFormatter()
    }
  }
}

typealias OutputStream = AsyncSequence<Data, any Swift.Error>
protocol OutputFormatter {
  associatedtype Stream: OutputStream
  func callAsFunction(results: SpeechTranscriber.Results) -> Stream
}

internal struct PlainFormatter: OutputFormatter {
  func callAsFunction(results: SpeechTranscriber.Results) -> some OutputStream {
    results.map({ Data(String($0.text.characters).utf8) })
  }
}

internal struct SrtFormatter: OutputFormatter {
  func callAsFunction(results: SpeechTranscriber.Results) -> some OutputStream {
    AsyncThrowingStream { continuation in
      let task = Task {
        do {
          var i = 1
          for try await chunk in results {
            let block =
              """
              \(i)
              \(formatAsTimestamp(chunk.range.start)) --> \(formatAsTimestamp(chunk.range.end))
              \(String(chunk.text.characters).trimmingCharacters(in: .whitespacesAndNewlines))


              """

            continuation.yield(Data(block.utf8))

            i += 1
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  func formatAsTimestamp(_ time: CMTime) -> String {
    let totalMillis = Int((time.seconds * 1000).rounded())
    let hours = totalMillis / 3_600_000
    let minutes = totalMillis / 60_000 % 60
    let seconds = totalMillis / 1000 % 60
    let millis = totalMillis % 1000

    return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, millis)
  }
}

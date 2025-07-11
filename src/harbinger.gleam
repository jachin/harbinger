import file_streams/file_open_mode
import file_streams/file_stream
import file_streams/file_stream_error
import gleam/io
import gleam/string_tree

pub type LogLevel {
  EmergencyLevel
  AlertLevel
  CriticalLevel
  ErrorLevel
  WarningLevel
  NoticeLevel
  InfoLevel
  DebugLevel
}

pub type Transport {
  Console
  File(file_stream.FileStream)
  NullLogger
}

pub type Harbinger {
  Tape(log_level: LogLevel, transport: Transport)
}

fn level_to_string(level: LogLevel) -> String {
  case level {
    EmergencyLevel -> "EMERGENCY"
    AlertLevel -> "ALERT"
    CriticalLevel -> "CRITICAL"
    ErrorLevel -> "ERROR"
    WarningLevel -> "WARNING"
    NoticeLevel -> "NOTICE"
    InfoLevel -> "INFO"
    DebugLevel -> "DEBUG"
  }
}

pub fn new_file_logger(log_level: LogLevel, file_name: String) -> Harbinger {
  case file_stream.open(file_name, [file_open_mode.Append]) {
    Ok(file_stream) -> Tape(log_level, File(file_stream))
    Error(err) -> {
      let _ = io.print_error(file_stream_error.describe(err))
      Tape(log_level, NullLogger)
    }
  }
}

fn log(logger: Harbinger, level: LogLevel, message: String) -> Nil {
  let msg =
    string_tree.from_strings([level_to_string(level), ": ", message, "\n"])
    |> string_tree.to_string
  case logger.transport {
    Console -> io.print(msg)
    File(stream) -> {
      case file_stream.write_bytes(stream, <<msg:utf8>>) {
        Ok(_) -> Nil
        Error(err) -> {
          let _ = io.print_error(file_stream_error.describe(err))
          Nil
        }
      }
    }
    NullLogger -> Nil
  }
}

pub fn info(logger: Harbinger, message: String) -> Harbinger {
  log(logger, InfoLevel, message)
  logger
}

pub fn error(logger: Harbinger, message: String) -> Harbinger {
  log(logger, ErrorLevel, message)
  logger
}

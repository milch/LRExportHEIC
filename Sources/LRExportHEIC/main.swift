import ConsoleKit
import Foundation

let console: Console = Terminal()
var input = CommandInput(arguments: CommandLine.arguments)
var context = CommandContext(console: console, input: input)

do {
  try console.run(ExportHEICCommand(), input: input)
} catch {
  console.error("\(error)")
  exit(1)
}

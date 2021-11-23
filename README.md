# LRExportHEIC

A plugin to allow Lightroom to export HEIC files.

There are two components:

- The plugin itself, which is the component that interfaces with Lightroom using the Lightroom SDK, written in Lua.
- The CLI component, which takes an input file path and an output file path, and renders the HEIC image to the output file path. It is written in Swift.

## Compatibility

Because the CLI component is using macOS APIs to create the HEIC file, the only supported platform is macOS. Theoretically there should be nothing preventing it from working on earlier versions, but I have only personally tested it on macOS Monterey (v12+).

# LRExportHEIC

A plugin to allow Lightroom to export HEIC files.

There are two components:

- The plugin itself, which is the component that interfaces with Lightroom using the Lightroom SDK, written in Lua.
- The CLI component, which takes an input file path and an output file path, and renders the HEIC image to the output file path. It is written in Swift.

## Compatibility

Because the CLI component is using macOS APIs to create the HEIC file, the only supported platform is macOS. Theoretically there should be nothing preventing it from working on earlier versions, but I have only personally tested it on macOS Monterey (v12+). It definitely won't work on Windows.

I have only tested the plugin to work with the latest version of Lightroom (v11).

## Usage

This plugin is using Lightroom's SDK in a way that was probably not intended, so it may not work for your setup. It may mess up your files, corrupt your library, and kick your dog in the process. Proceed with caution, and always make sure you have a backup.

### Installation

- Download the [latest release](https://github.com/milch/LRExportHEIC/releases/latest) from the sidebar
- Open Lightroom, and open the Plug-In Manager from the Menu
- Press the `add` button, and select the plugin wherever you saved it. Make sure that it is enabled.

### Exporting HEIC files

- Select images and start the export like normal (e.g. Right click + Export)
- You will see a new "Post-Process Action" in the lower left corner of the export dialog, which you will need to highlight and then press `Insert` 
- You will see a new panel named "HEIC settings" at the bottom. Note that the regular File Settings panel is unused at this point, and settings made in that panel will be overridden by any setting you choose in the "HEIC settings" panel
- Press `Export`. Your export should proceed like normal, and you will find your files at the location you selected
- The files will have a `.jpg` extension. This is expected. You can rename them to use a `.heic` extension or leave them with the `.jpg` extension. Most applications won't care about the extension, and will be able to use the file like normal. 

The plugin also adds a new item under "Export To" named "Export HEIC". This does nothing more than hide the original File Settings panel so you don't accidentally make changes there instead of the "HEIC settings" panel. However, this is entirely optional and only a cosmetic change.

## How does it work? 

The plugin creates what the Lightroom SDK calls an "Export post-process action" or an "Export Filter Provider". As the name suggests, it allows the plugin to run some code after Lightroom has completed the initial processing of the image. Here is roughly what happens:

- Lightroom renders the image according to the user's settings
- This plugin (ExportHEIC) starts executing and is provided with a list of images and their export settings
- ExportHEIC requests a different version of the image to be rendered into a temporary location. According to the Lightroom SDK guide, now it becomes the plugin's responsibility to place the final image in the originally requested location
  - The rendering that ExportHEIC requests will be either an 8-bit or a 16-bit TIFF depending on the bit-depth selected in the HEIC settings panel
 - ExportHEIC uses a helper executable to render the temporary TIFF file created in the previous step into an HEIC file 
 - The HEIC file is placed at the originally requested location 
   - This is why it has to have a .jpg extension. If the file had a .heic extension instead, Lightroom would say that the export failed because it couldn't find the final rendered file

## Why HEIC?

HEIC is a more modern file format than the standard JPEG, which is frequently used to render photos after they have been edited, and to share them with friends or online. HEIC is well-supported by most viewers and has been used by Apple in one form or another since 2017. Camera manufacturers are also starting to adopt it, with flagship cameras like the Sony A1 or Canon R3 adding support. There are two main benefits to HEIC:

- A better compression algorithm, meaning either a lower file size for the same perceived quality or a higher quality image at the same file size
- 10-bit encoding support, allowing for a wider dynamic range and giving more latitude for further edits than the 8-bit JPEG

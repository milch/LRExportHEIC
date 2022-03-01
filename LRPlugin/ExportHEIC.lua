local LrBinding = import 'LrBinding'
local LrLogger = import 'LrLogger'
local LrPathUtils = import 'LrPathUtils'
local LrTasks = import 'LrTasks'
local LrView = import 'LrView'

local logger = LrLogger('ExportHEIC')
logger:enable('print')

function formatPercentage(num, fromModel)
  return tostring(math.floor(num)) .. ' %'
end

return {
  exportPresetFields = {
    { key = 'HEICQuality', default = 75 },
    { key = 'HEICUseSizeLimit', default = false },
    { key = 'HEICSizeLimit', default = 3000 },
    { key = 'HEICMinQuality', default = 10 },
    { key = 'HEICMaxQuality', default = 90 },
    { key = 'HEICColorSpace', default = 'SRGB' },
    { key = 'HEICBitDepth', default = 10 },
  },
  hideSections = { 'video', 'fileSettings' },
  -- sectionsForTopOfDialog = function( viewFactory, propertyTable )
  sectionForFilterInDialog = function( viewFactory, propertyTable )
    local f = viewFactory
    local bind = LrView.bind
    local negbind = LrBinding.negativeOfKey

    return {
      title = 'HEIC Settings',

      f:row {  -- root row
        margin_top = 8,
        margin_bottom = 8,
        spacing = 18,

        f:column {  -- left-column
          spacing = 12,

          f:row {  -- control 1: quality
            f:static_text {
              title = 'Quality:', enabled = negbind 'HEICUseSizeLimit',
              width_in_chars = 8, alignment = 'right',
            },
            f:spacer { width = 2 },
            f:slider {
              value = bind 'HEICQuality',
              enabled = negbind 'HEICUseSizeLimit',
              min = 0, max = 100, integral = true,
            },
            f:static_text {
              title = bind({ key = 'HEICQuality', transform = formatPercentage }),
              enabled = negbind 'HEICUseSizeLimit',
            },
          },  -- control 1: quality

          f:row {  -- control 2: color space
            f:static_text { width_in_chars = 8, alignment = 'right', title = 'Color Space:' },
            f:spacer { width = 2 },
            f:popup_menu {
              width_in_chars = 8,
              items = {
                { title = 'sRGB', value = 'SRGB' },
                { title = 'Display P3', value = 'DisplayP3' },
                { title = 'AdobeRGB', value = 'AdobeRGB1998' },
              },
              value = bind 'HEICColorSpace'
            },
          },  -- control 2: color space

          f:row {  -- control 3: bit depth
            f:static_text { width_in_chars = 8, alignment = 'right', title = 'Bit Depth:' },
            f:spacer { width = 2 },
            f:radio_button { value = bind 'HEICBitDepth', title = '8', checked_value = 8 },
            f:radio_button { value = bind 'HEICBitDepth', title = '10', checked_value = 10 },
          },  -- control 3: bit depth

        },  -- left-column

        f:column {  -- right column
          spacing = 12,

          f:row {  -- control 1: file size
            f:checkbox { value = bind 'HEICUseSizeLimit', title = 'Limit File Size To:' },
            f:edit_field {
              value = bind 'HEICSizeLimit',
              enabled = bind 'HEICUseSizeLimit',
              increment = 100, large_increment = 1000,
              min = 1, max = 1000000,
              width_in_digits = 7,
            },
            f:static_text { title = 'K' },
          },  -- control 1: file size

          f:view {  -- control 2: min quality
            visible = bind 'HEICUseSizeLimit',
            place = 'horizontal',
            f:static_text { width_in_chars = 9, title = 'Minimal Quality:' },
            f:slider {
              value = bind 'HEICMinQuality',
              min = 0, max = 100, integral = true,
            },
            f:static_text {
              title = bind({ key = 'HEICMinQuality', transform = formatPercentage })
            },
          },

          f:view {  -- control 3: max quality
            visible = bind 'HEICUseSizeLimit',
            place = 'horizontal',
            f:static_text { width_in_chars = 9, title = 'Maximal Quality:' },
            f:slider {
              value = bind 'HEICMaxQuality',
              min = 0, max = 100, integral = true,
            },
            f:static_text {
              title = bind({ key = 'HEICMaxQuality', transform = formatPercentage })
            },
          },
        },  -- right column

      }  -- root row
    }
  end,
  postProcessRenderedPhotos = function(functionContext, filterContext)
    local p = filterContext.propertyTable

    local renditionOptions = {
      filterSettings = function( renditionToSatisfy, exportSettings )
        exportSettings.LR_format = 'TIFF'
        if p.HEICBitDepth > 8 then
          exportSettings.LR_export_bitDepth = 16
        else
          exportSettings.LR_export_bitDepth = 8
        end

        if p.HEICColorSpace == "SRGB" then
          exportSettings.LR_export_colorSpace = "sRGB"
        elseif p.HEICColorSpace == "AdobeRGB1998" then
          exportSettings.LR_export_colorSpace = "AdobeRGB"
        elseif p.HEICColorSpace == "DisplayP3" then
          exportSettings.LR_export_colorSpace = "DisplayP3"
        end
        return os.tmpname()
      end,
    }

    local converterPath = LrPathUtils.child(_PLUGIN.path, 'LRExportHEIC')
    local cmd = '"' .. converterPath .. '"'
    if p.HEICUseSizeLimit then
      cmd = (cmd .. ' --size-limit ' .. (p.HEICSizeLimit * 1000)
             .. ' --min-quality ' .. (p.HEICMinQuality / 100)
             .. ' --max-quality ' .. (p.HEICMaxQuality / 100))
    else
      cmd = cmd .. ' --quality ' .. (p.HEICQuality / 100)
    end

    logger:info('Starting rendering of TIFF originals')
    for sourceRendition, renditionToSatisfy in  filterContext:renditions(renditionOptions) do
      logger:info('Processing rendition')
      local success, pathOrMessage = sourceRendition:waitForRender()
      if success then
        local actualCmd = (cmd .. ' --input-file "' .. pathOrMessage .. '" "'
                           .. renditionToSatisfy.destinationPath .. '"')
        local status = LrTasks.execute(actualCmd)
        logger:info('Command status: ' .. status)
        if status ~= 0 then
          logger:info('Failure')
          renditionToSatisfy:renditionIsDone(false, pathOrMessage)
          break
        end
        logger:info('Success')
        renditionToSatisfy:renditionIsDone(true, 'Success')
      else
        logger:info('Source rendition did not finish rendering: ' .. pathOrMessage)
      end
    end
  end,
  -- processRenderedPhotos = function(functionContext, exportContext)
  -- end
}

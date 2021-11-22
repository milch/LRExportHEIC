local LrView = import 'LrView'
local LrTasks = import 'LrTasks'
local LrPathUtils = import 'LrPathUtils'
local LrLogger = import 'LrLogger'

local logger = LrLogger('ExportHEIC')
logger:enable('print')

function formatPercentage(num, fromModel)
  return tostring(math.floor(num)) .. ' %'
end

return {
  exportPresetFields = {
    { key = 'HEICQuality', default = 75 },
    { key = 'HEICColorSpace', default = 'SRGB' },
    { key = 'HEICBitDepth', default = 10 },
  },
  hideSections = { 'video', 'fileSettings' },
  -- sectionsForTopOfDialog = function( viewFactory, propertyTable )
  sectionForFilterInDialog = function( viewFactory, propertyTable )
    return 
      {
        title = 'HEIC Settings',
        viewFactory:row {
          viewFactory:column {
            viewFactory:row {
              viewFactory:static_text { title = 'Quality' },
              viewFactory:slider {
                value = LrView.bind('HEICQuality'),
                min = 0,
                max = 100,
                integral = true
              },
              viewFactory:static_text {
                title = LrView.bind({ key = 'HEICQuality', transform = formatPercentage })
              },
            },
          },
          viewFactory:spacer { width = 16 },
          viewFactory:column {
            viewFactory:row {
              viewFactory:static_text { title = 'Color Space:' },
              viewFactory:spacer { width = 4 },
              viewFactory:popup_menu {
                items = {
                  { title = 'sRGB', value = 'SRGB' },
                  { title = 'Display P3', value = 'DisplayP3' },
                  { title = 'AdobeRGB', value = 'AdobeRGB1998' },
                },
                value = LrView.bind('HEICColorSpace')
              },
            },
          }
        },
        viewFactory:row {
          viewFactory:static_text { title = 'Bit Depth' },
          viewFactory:spacer { width = 4 },
          viewFactory:popup_menu {
            items = {
              { title = '8', value = 8 },
              { title = '10', value = 10 },
            },
            value = LrView.bind('HEICBitDepth')
          },
        },
      }
  end,
  postProcessRenderedPhotos = function(functionContext, filterContext)
    local converterPath = LrPathUtils.child(_PLUGIN.path, 'LRExportHEIC')
    local qualityPercent = filterContext.propertyTable.HEICQuality / 100

    local renditionOptions = {
      filterSettings = function( renditionToSatisfy, exportSettings )
        exportSettings.LR_format = 'TIFF'
        if filterContext.propertyTable.HEICBitDepth > 8 then
          exportSettings.LR_export_bitDepth = 16
        else
          exportSettings.LR_export_bitDepth = 8
        end

        if filterContext.propertyTable.HEICColorSpace == "SRGB" then
          exportSettings.LR_export_colorSpace = "sRGB"
        elseif filterContext.propertyTable.HEICColorSpace == "AdobeRGB1998" then
          exportSettings.LR_export_colorSpace = "AdobeRGB"
        elseif filterContext.propertyTable.HEICColorSpace == "DisplayP3" then
          exportSettings.LR_export_colorSpace = "DisplayP3"
        end
        return os.tmpname()
      end,
    }

    logger:info('Starting rendering of TIFF originals')
    for sourceRendition, renditionToSatisfy in  filterContext:renditions(renditionOptions) do
      logger:info('Processing rendition')
      local success, pathOrMessage = sourceRendition:waitForRender()
      if success then
        local status = LrTasks.execute(converterPath .. ' --input-file "' .. pathOrMessage .. '" --quality ' .. qualityPercent .. ' "' .. renditionToSatisfy.destinationPath .. '"')
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

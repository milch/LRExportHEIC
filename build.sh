swift build --configuration release --arch x86_64 --arch arm64

rm -rf ExportHEIC.lrplugin
rsync -a ./LRPlugin/ ExportHEIC.lrplugin
cp ./.build/apple/Products/Release/LRExportHEIC ExportHEIC.lrplugin/LRExportHEIC

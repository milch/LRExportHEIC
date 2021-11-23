swift build --configuration release --arch x86_64 --arch arm64

rm -rf plugin
mkdir -p plugin

rsync -a ./LRPlugin/ plugin/ExportHEIC.lrplugin
cp ./.build/apple/Products/Release/LRExportHEIC plugin/ExportHEIC.lrplugin/LRExportHEIC

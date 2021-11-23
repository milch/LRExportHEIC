set -eux
set -o pipefail

swift build --configuration release --arch x86_64 --arch arm64

rm -rf plugin
mkdir -p plugin

rsync -a ./LRPlugin/ plugin/ExportHEIC.lrplugin
cp ./.build/apple/Products/Release/LRExportHEIC plugin/ExportHEIC.lrplugin/LRExportHEIC

# Update version with latest git tag
git fetch --tags
GIT_VERSION=$(git describe --tags $(git rev-list --tags --max-count=1))
MAJOR_VERSION=$(echo $GIT_VERSION | cut -f 1 -d . | tr -d 'v')
MINOR_VERSION=$(echo $GIT_VERSION | cut -f 2 -d .)
PATCH_VERSION=$(echo $GIT_VERSION | cut -f 3 -d .)
BUILD_NUMBER=$(git rev-list --all --count)

VERSION_SPEC="VERSION = { major=${MAJOR_VERSION}, minor=${MINOR_VERSION}, revision=${PATCH_VERSION}, build=${BUILD_NUMBER} },"

sed -I '' "s/VERSION = .*/$VERSION_SPEC/" plugin/ExportHEIC.lrplugin/Info.lua

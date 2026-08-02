#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_PATH="$SCRIPT_DIR/DayGlyph.xcodeproj"
readonly SCHEME="DayGlyph"
readonly BUNDLE_ID="dev.chinyen.DayGlyph"
readonly DERIVED_DATA_PATH="$SCRIPT_DIR/build/DayGlyphDemo"

device_name="iPhone 17 Pro"
mode="demo"

usage() {
    echo "用法：./run-demo.sh [--device \"设备名\"] [--mode demo|clean|onboarding]"
    echo
    echo "  demo        清空旧沙盒、填充演示月、跳过新手引导（默认，适合录屏）"
    echo "  clean       清空旧沙盒、跳过新手引导、不填充演示数据"
    echo "  onboarding  清空旧沙盒、从新手引导开始"
}

while (($# > 0)); do
    case "$1" in
        --device)
            [[ $# -ge 2 ]] || { echo "错误：--device 缺少设备名" >&2; exit 2; }
            device_name="$2"
            shift 2
            ;;
        --mode)
            [[ $# -ge 2 ]] || { echo "错误：--mode 缺少模式" >&2; exit 2; }
            mode="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "错误：未知参数 $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

case "$mode" in
    demo|clean|onboarding) ;;
    *)
        echo "错误：--mode 只能是 demo、clean 或 onboarding" >&2
        exit 2
        ;;
esac

command -v xcodebuild >/dev/null || {
    echo "错误：未找到 xcodebuild，请先安装并选择 Xcode Command Line Tools。" >&2
    exit 1
}

simulator_id="$(
    xcrun simctl list devices available |
        awk -v target="$device_name" '
            index($0, target " (") {
                if (match($0, /\([0-9A-F-]+\)/)) {
                    print substr($0, RSTART + 1, RLENGTH - 2)
                    exit
                }
            }
        '
)"

if [[ -z "$simulator_id" ]]; then
    echo "错误：找不到可用模拟器“$device_name”。" >&2
    echo "可用设备：" >&2
    xcrun simctl list devices available >&2
    exit 1
fi

echo "→ 启动模拟器：$device_name"
xcrun simctl boot "$simulator_id" 2>/dev/null || true
xcrun simctl bootstatus "$simulator_id" -b
open -a Simulator

echo "→ 初始化录屏环境"
xcrun simctl terminate "$simulator_id" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl uninstall "$simulator_id" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl ui "$simulator_id" appearance light
xcrun simctl status_bar "$simulator_id" override \
    --time "9:41" \
    --batteryState charged \
    --batteryLevel 100 \
    --wifiBars 3 \
    --cellularBars 4 2>/dev/null || true

echo "→ 构建 DayGlyph"
xcodebuild build \
    -quiet \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$simulator_id" \
    -derivedDataPath "$DERIVED_DATA_PATH"

readonly APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/DayGlyph.app"
if [[ ! -d "$APP_PATH" ]]; then
    echo "错误：构建完成，但没有找到 $APP_PATH" >&2
    exit 1
fi

echo "→ 安装并启动"
xcrun simctl install "$simulator_id" "$APP_PATH"

launch_arguments=()
case "$mode" in
    demo)
        launch_arguments+=("--dayglyph-demo-seed" "--dayglyph-skip-onboarding")
        ;;
    clean)
        launch_arguments+=("--dayglyph-skip-onboarding")
        ;;
    onboarding)
        ;;
esac

xcrun simctl launch "$simulator_id" "$BUNDLE_ID" "${launch_arguments[@]}"

echo
echo "✓ DayGlyph 已以 $mode 模式启动，可以开始录制演示视频。"

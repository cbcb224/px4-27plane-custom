# PX4 1.16.2 自制飞控板：GitHub 云编译资料

本目录用于 **PX4 1.16.2 自制飞控板的纯 GitHub Actions 云编译**。

- Windows 源码目录：`C:\Users\Administrator\Desktop\27plane\px4`
- PX4 基线：精确标签 `v1.16.2`
- 当前开发分支：`codex/px4-1.16.2-custom`
- Windows 只负责：编辑源码、Git 提交与推送、下载构建产物、使用 QGroundControl 烧录
- 固件构建全部在 GitHub Actions 的 Ubuntu 运行器和官方 NuttX 容器中完成
- **不需要安装或配置 WSL、Ubuntu、Docker Desktop、CMake、ARM 交叉编译器或本地 `make`**
- 首次 bootloader 烧录仍需 SWD/JTAG、芯片 DFU 或板载调试器

> GitHub Actions 会在每次运行时自动检出你的 GitHub 仓库和子模块。你不需要手动把源码“上传到云端构建机”，只需推送 Git 提交。

## 文件说明

| 文件 | 用途 |
| --- | --- |
| [PX4-1.16.2-GitHub云编译教程.md](./PX4-1.16.2-GitHub云编译教程.md) | 从 GitHub 仓库配置、自制板移植、board ID、云编译到烧录与首板调试的完整教程 |
| [github-actions/px4-custom-board.yml](./github-actions/px4-custom-board.yml) | GitHub Actions 工作流模板，复制到仓库的 `.github/workflows/` 后使用 |
| [scripts/check-cloud-build-setup.ps1](./scripts/check-cloud-build-setup.ps1) | 只读检查 PX4 基线、子模块、board 目标、工作流目标、remote 和磁盘空间；不检查本地编译工具链 |

## 当前源码结论

当前目录已经是一份完整的 PX4 `v1.16.2` 工作树，**不要删除后重新下载**。

本次检查结果：

- Git 分支：`codex/px4-1.16.2-custom`
- 精确标签：`v1.16.2`
- Git 子模块：35 个，未发现缺失或版本不匹配
- `.px4board` 目标文件：196 个
- `firmware.prototype`：84 个
- 仓库内唯一 board ID：69 个
- 当前最大 board ID：41777
- `origin`：官方 `PX4/PX4-Autopilot`
- C 盘可用空间：约 90 GiB

删除整个目录不会让云编译更可靠，反而会丢失板卡代码和 Git 历史。只有工作树已损坏、子模块无法修复或有可靠备份时，才考虑重新检出。

## 最快上手

1. 阅读完整教程的前 3 节，确认 GitHub 仓库、云工作流和构建产物流程。
2. 运行只读准备检查：

   ```powershell
   powershell -ExecutionPolicy Bypass -File "C:\Users\Administrator\Desktop\27plane\px4\.codex\scripts\check-cloud-build-setup.ps1"
   ```

3. 在自己的 GitHub 账号中创建仓库，把当前源码推送到该仓库；保留 `origin` 为官方 PX4，另加一个自己的 remote。
4. 把工作流模板复制到 `.github/workflows/px4-custom-board.yml`。
5. 第一次先保留 `PX4_BOARD_TARGET: px4_fmu-v6x_default`，在云端做官方目标烟雾测试，排除仓库、子模块和 Actions 配置问题。
6. 选择最接近的 donor board，复制到 `boards/<vendor>/<model>/`，再改 board ID、Flash 布局、引脚、总线、驱动和启动脚本。
7. 把工作流目标改成自己的完整目标名，例如 `acme_mypilot-v1_default`，重新推送并运行。
8. 从 Actions 下载 artifact，使用 Windows QGroundControl 烧录 `.px4`。首次 bootloader 用 SWD/JTAG 或芯片 DFU 烧录。

## 云编译边界

云编译成功只表示 **源码和板卡配置能够生成固件**。它不能验证：

- PCB 走线、电源轨、时钟和复位是否正确；
- 引脚复用、总线片选、I2C 地址和中断是否正确；
- IMU 安装方向、坐标系和校准是否合理；
- PWM/DShot 通道、电调协议和电机顺序是否正确；
- 电源监控、USB、SD 卡、CAN、RC 和日志功能是否真实可用；
- 电磁兼容、温升、振动和飞行安全。

## 必须牢记

- 不要未经查重直接使用官方 board ID；自定义板 ID 必须同时写入 bootloader 和应用程序并保持一致。
- bootloader 与应用程序的 Flash 地址不能重叠，`image_maxsize` 和链接脚本必须匹配实际 MCU。
- 首次上电使用限流电源，拆除螺旋桨和外部执行器负载。
- QGC 只用于已经能进入 bootloader 的应用程序烧录；空白 MCU 的首次 bootloader 必须使用调试器或 DFU。
- 私有仓库的 GitHub Actions 会消耗账户额度；公开仓库通常不产生分钟费用，但仍受平台规则和资源限制。
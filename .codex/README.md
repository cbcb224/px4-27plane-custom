# PX4 1.16.2 自制飞控板：GitHub 云编译资料

本目录用于 **PX4 1.16.2 自制飞控板的纯 GitHub Actions 云编译**。

- Windows 源码目录：`C:\Users\Administrator\Desktop\27plane\px4`
- PX4 基线：精确标签 `v1.16.2`
- 当前开发分支：`codex/px4-1.16.2-custom`
- GitHub 云编译仓库：[cbcb224/px4-27plane-custom](https://github.com/cbcb224/px4-27plane-custom)
- Windows 只负责：编辑源码、Git 提交与推送、下载构建产物、使用 QGroundControl 烧录
- 固件构建全部在 GitHub Actions 的 Ubuntu 运行器和官方 NuttX 容器中完成
- **不需要安装或配置 WSL、Ubuntu、Docker Desktop、CMake、ARM 交叉编译器或本地 `make`**
- 首次 bootloader 烧录仍需 SWD/JTAG、芯片 DFU 或板载调试器

> GitHub Actions 会在每次运行时自动检出你的 GitHub 仓库和子模块。你不需要手动把源码“上传到云端构建机”，只需推送 Git 提交。

## 当前云编译状态

- 仓库类型：官方 PX4 的公开 fork
- 默认分支：`codex/px4-1.16.2-custom`
- 个人 remote 名称：`myrepo`
- 首次烟雾构建：成功（目标 `px4_fmu-v6x_default`）
- 首次烟雾运行：[40840194077](https://github.com/cbcb224/px4-27plane-custom/actions/runs/40840194077)
- 当前自制板目标：`p224_p224-aio-v1_default`
- 当前成功运行：#7 [40860950848](https://github.com/cbcb224/px4-27plane-custom/actions/runs/40860950848)
- 对应提交：`4996c86`（`Group P224 AIO PWM channels by timer`）
- 本机 artifact：`C:\Users\Administrator\Desktop\27plane\px4-artifacts\px4-custom-p224_p224-aio-v1_default-7.zip`
- ZIP SHA-256：`ad2c88a0da51c538a3023b17db414c118bcd93795b1fa94334861885c492c8db`
- 本机固件：`C:\Users\Administrator\Desktop\27plane\px4-artifacts\px4-custom-p224_p224-aio-v1_default-7\p224_p224-aio-v1_default\p224_p224-aio-v1_default.px4`
- 固件 SHA-256：`54d2f2138ceced141a644d6fd95271acbc9af7cd1573beb3a2461dd0e423b372`
- 固件大小：`1,706,930` 字节

> 当前自制板目标已经能在云端生成固件，但尚未证明 PCB、传感器、PWM/DShot、电源和电机顺序真实正确。云编译成功不等于可以飞行。

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

3. **[已完成]** 已创建公开 fork，并保留 `origin` 为官方 PX4，使用 `myrepo` 推送自制分支。
4. **[已完成]** 工作流已安装到 `.github/workflows/px4-custom-board.yml`。
5. **[已完成]** `px4_fmu-v6x_default` 官方目标已在云端构建成功并上传 artifact。
6. **[已完成]** 已创建 `boards/p224/p224-aio-v1/`，并把工作流目标改为 `p224_p224-aio-v1_default`。
7. **[已完成]** 九个 PWM 输出已按 TIM1、TIM3、TIM4、TIM2 分组，Run #7 云编译成功。
8. **下一步：** 使用限流电源并拆除螺旋桨，先核对 bootloader、串口输出、IMU、电源监控和九路 PWM/DShot 波形；首次 bootloader 仍用 SWD/JTAG 或芯片 DFU 烧录。
9. 从 Actions 下载最新 artifact，台架检查通过后再使用 Windows QGroundControl 烧录 `.px4`，不要直接把“编译成功”当作可以飞行。

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
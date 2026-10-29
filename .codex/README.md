# PX4 1.16.2 自制飞控板：GitHub 云编译资料

本目录用于 **PX4 1.16.2 自制飞控板的纯 GitHub Actions 云编译**。

- Windows 源码目录：`C:\Users\Administrator\Desktop\27plane\px4`
- PX4 基线：`v1.16.2`
- 当前开发分支：`codex/px4-1.16.2-custom`
- 当前正式固件提交：`aaa6eaae3ee8eeb8ff66380d0338d2470e0ac07b`
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
- 首次烟雾构建：成功（目标 `px4_fmu-v6x_default`，Run #1）
- 首次烟雾运行：[40840194077](https://github.com/cbcb224/px4-27plane-custom/actions/runs/40840194077)
- 当前自制板目标：`p224_p224-aio-v1_default`
- bootloader 目标：`p224_p224-aio-v1_bootloader`
- 当前成功运行：Run #9 [40862991259](https://github.com/cbcb224/px4-27plane-custom/actions/runs/40862991259)
- 对应提交：`aaa6eaa`（`Enable P224 AIO bootloader cloud build`）
- 本次同时生成：应用程序 + bootloader

本机 artifact：

```text
C:\Users\Administrator\Desktop\27plane\px4-artifacts\px4-custom-p224_p224-aio-v1_default-9.zip
```

- ZIP 大小：`21,514,117` 字节
- ZIP SHA-256：`1dacdf915fc5c057fd17d397831370f149eb5c7ecf7c9205b65163e20c745581`

bootloader：

```text
C:\Users\Administrator\Desktop\27plane\px4-artifacts\px4-custom-p224_p224-aio-v1_default-9\p224_p224-aio-v1_bootloader\p224_p224-aio-v1_bootloader.bin
```

- 大小：`41,176` 字节
- SHA-256：`4a81ae92f9b7c53b148458ee1b53c59fc15e8fa81a177d2a7044d8076e5bc5ba`
- 烧录起始地址：`0x08000000`

应用程序：

```text
C:\Users\Administrator\Desktop\27plane\px4-artifacts\px4-custom-p224_p224-aio-v1_default-9\p224_p224-aio-v1_default\p224_p224-aio-v1_default.px4
```

- 大小：`1,707,002` 字节
- SHA-256：`386c2c7498f1cbdc7cdac727bba8cf8e194b3e59f9fc6fa1c9ced1af4d088235`
- `image_maxsize`：`1,835,008` 字节
- 剩余余量：`128,006` 字节

> 当前自制板目标已经能在云端生成应用程序和 bootloader，但尚未证明 PCB、传感器、PWM/DShot、电源和电机顺序真实正确。云编译成功不等于可以飞行。

## 文件说明

| 文件 | 用途 |
| --- | --- |
| [P224-AIO-V1.0-PX4完整工作流程报告.md](./P224-AIO-V1.0-PX4完整工作流程报告.md) | 从方案选择、Git 流程、板级移植、云编译到烧录与台架验证的完整报告 |
| [代码修改记录.md](./代码修改记录.md) | 按时间顺序记录所有代码、配置、脚本、工作流和文档修改；后续修改必须持续更新 |
| [PX4-1.16.2-GitHub云编译教程.md](./PX4-1.16.2-GitHub云编译教程.md) | GitHub 仓库配置、自制板移植、board ID、云编译和首板调试教程 |
| [27赛季无人机-AIO-V1.0-PX4引脚映射.md](./27赛季无人机-AIO-V1.0-PX4引脚映射.md) | AIO V1.0 的 MCU 球位、网络、传感器、串口、PWM 和编译决策 |
| [github-actions/px4-custom-board.yml](./github-actions/px4-custom-board.yml) | GitHub Actions 工作流模板 |
| [scripts/check-cloud-build-setup.ps1](./scripts/check-cloud-build-setup.ps1) | 只读检查 PX4 基线、子模块、board 目标、工作流目标、remote 和磁盘空间 |

## 当前源码结论

当前目录是一份基于 PX4 `v1.16.2` 的完整工作树。截至正式固件提交 `aaa6eaa` 已有 18 个提交；之后还有文档和规则提交，**不要删除后重新下载**。

本次检查结果：

- Git 分支：`codex/px4-1.16.2-custom`
- 当前正式固件提交：`aaa6eaae3ee8eeb8ff66380d0338d2470e0ac07b`
- 正式固件提交 `git describe`：`v1.16.2-18-gaaa6eaae3e`
- Git 子模块：35 个
- `origin`：官方 `PX4/PX4-Autopilot`
- `myrepo`：个人 `cbcb224/px4-27plane-custom`
- 当前未跟踪目录：`.workbuddy/`、`boards/p224/p224-aio-v1/extras/`

删除整个目录不会让云编译更可靠，反而会丢失板卡代码和 Git 历史。只有工作树已损坏、子模块无法修复或有可靠备份时，才考虑重新检出。

## 最快上手

1. 先阅读完整工作流程报告的“当前完成状态”“下一步建议”和“硬件台架验证清单”。
2. 运行只读准备检查：

   ```powershell
   powershell -ExecutionPolicy Bypass -File "C:\Users\Administrator\Desktop\27plane\px4\.codex\scripts\check-cloud-build-setup.ps1"
   ```

3. **[已完成]** 创建公开 fork，并保留 `origin` 为官方 PX4，使用 `myrepo` 推送自制分支。
4. **[已完成]** 工作流已安装到 `.github/workflows/px4-custom-board.yml`。
5. **[已完成]** `px4_fmu-v6x_default` 官方目标已在 Run #1 构建成功。
6. **[已完成]** 已创建 `boards/p224/p224-aio-v1/`，并配置 board ID、时钟、传感器、串口、PWM、ADC、LED 和蜂鸣器。
7. **[已完成]** 已修复 PWM 定时器分组问题，Run #7 应用构建成功。
8. **[已完成]** 已启用 bootloader 云构建，Run #9 同时成功生成应用程序和 bootloader。
9. **下一步：** 使用限流电源并拆除螺旋桨，先用 SWD/JTAG 或芯片 DFU 烧录 `p224_p224-aio-v1_bootloader.bin`，再通过 QGC 烧录 `.px4`。
10. 完成启动、串口、传感器、电池采样和九路 PWM/DShot 台架验证后，才进入电机和整机测试。

## 当前板级要点

- MCU：STM32H743VIH6，TFBGA-100
- HSE：16 MHz
- Board ID：`41778`
- 应用地址：`0x08020000`
- BMI088：SPI1
- ICM-42688P：SPI2
- IST8310、DPS310：内部 I2C4
- 外部 I2C1：PB8/PB9，有焊盘
- GPS1：`/dev/ttyS2`
- TEL1/TEL2/TEL3：`/dev/ttyS0`、`/dev/ttyS1`、`/dev/ttyS3`
- PWM1～PWM4：TIM1，M1～M4
- PWM5～PWM6：TIM3，M5/M8
- PWM7～PWM8：TIM4，M7/M6
- PWM9：TIM2_CH3，PB10/J7，预留
- 当前四旋翼只使用 Motor1～Motor4

## 必须注意

- **不要烧录** `boards/p224/p224-aio-v1/extras/micoair_h743-aio_bootloader.bin`；它只是 donor 参考文件。
- `CBRK_SUPPLY_CHK=894281` 会绕过电源检查，只能用于受控台架验证。
- 所有传感器中断脚目前未接 MCU，必须验证轮询方式的采样、超时和数据连续性。
- PWM/DShot、电池采样、IMU 方向和电机顺序均未做硬件验证。
- 云编译成功只表示源码和板卡配置能够生成固件，不代表 PCB 或飞行安全已经验证。

## 日常 Git 流程

```powershell
Set-Location 'C:\Users\Administrator\Desktop\27plane\px4'
git status --short --branch
git diff --check
git add -- "要提交的文件"
git commit -m "清晰的小提交说明"
git push myrepo codex/px4-1.16.2-custom
```

推送会自动触发 `Build custom PX4 firmware`。不要使用 `git add .`，以免把 `.workbuddy/` 或 donor `extras/` 误提交。

## 云编译边界

云编译成功不能验证：

- PCB 走线、电源轨、时钟和复位是否正确；
- 引脚复用、总线片选、I2C 地址和中断是否正确；
- IMU 安装方向、坐标系和校准是否合理；
- PWM/DShot 通道、电调协议和电机顺序是否正确；
- 电源监控、USB、SD 卡、CAN、RC 和日志功能是否真实可用；
- 电磁兼容、温升、振动和飞行安全。

## 必须牢记

- 不要未经查重直接使用官方 board ID；自定义 board ID 必须同时写入 bootloader 和应用程序并保持一致。
- bootloader 与应用程序的 Flash 地址不能重叠，链接脚本、`image_maxsize` 和实际 MCU 容量必须匹配。
- 首次上电使用限流电源，拆除螺旋桨和外部执行器负载。
- QGC 只用于已经能进入 bootloader 的应用程序烧录；空白 MCU 的首次 bootloader 必须使用调试器或 DFU。
- 公开仓库通常不产生 Actions 分钟费用，但仍受 GitHub 平台规则、存储、并发和 artifact 保留期限约束。

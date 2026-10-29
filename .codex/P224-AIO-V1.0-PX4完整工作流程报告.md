# P224 AIO V1.0 PX4 1.16.2 完整工作流程报告

> - 报告日期：2026-10-29
> - 项目：嘉立创 EDA《27赛季无人机》— AIO V1.0
> - PX4 基线：`v1.16.2`
> - 本地源码：`C:\Users\Administrator\Desktop\27plane\px4`
> - 开发分支：`codex/px4-1.16.2-custom`
> - 当前提交：`aaa6eaae3ee8eeb8ff66380d0338d2470e0ac07b`
> - 公开仓库：[cbcb224/px4-27plane-custom](https://github.com/cbcb224/px4-27plane-custom)
> - 最终成功云构建：Run #9，[40862991259](https://github.com/cbcb224/px4-27plane-custom/actions/runs/40862991259)
> - 构建策略：Windows 编辑源码 → Git 推送 → GitHub Actions 云编译 → 下载 artifact
> - 明确约束：本方案不安装 WSL、Ubuntu、Docker Desktop、CMake 或 ARM 工具链，不执行本地固件编译

---

## 目录

1. 报告结论
2. 项目目标、范围与边界
3. 最终方案和工作架构
4. 当前完成状态
5. Git 和 GitHub 基础知识
6. 从零到当前状态的每一步工作流程
7. Git 提交与云构建时间线
8. 板级配置汇总
9. 九路 PWM 映射
10. GitHub Actions 云编译工作流
11. Run #6 失败与修复复盘
12. Run #9 成功产物和校验值
13. bootloader 与应用程序烧录流程
14. 硬件台架验证清单
15. 当前风险与未验证项
16. 日常修改和提交命令
17. 常见问题处理
18. 下一步建议
19. 证据文件索引

---

## 1. 报告结论

目前已经完成一条可重复的 PX4 自制飞控板纯云端构建链：

```text
AIO V1.0 原理图/PCB
        ↓
整理 MCU 球位、网络和 PX4 引脚决策
        ↓
建立 boards/p224/p224-aio-v1/
        ↓
适配 board ID、时钟、Flash、SPI、I2C、UART、PWM、ADC、LED、蜂鸣器
        ↓
Git 提交并推送到公开 GitHub 仓库
        ↓
GitHub Actions 自动检出源码和 35 个子模块
        ↓
在固定官方 NuttX 容器中执行 make
        ↓
成功生成 .px4 应用程序和 bootloader .bin
        ↓
下载 artifact，进入硬件烧录与台架验证阶段
```

当前云编译状态为：

- 应用程序目标 `p224_p224-aio-v1_default`：构建成功。
- bootloader 目标 `p224_p224-aio-v1_bootloader`：构建成功。
- 两者都在 Run #9 中生成并上传。
- 应用镜像为 `1,707,002` 字节，小于 `1,835,008` 字节上限。
- 已记录 ZIP、应用程序和 bootloader 的 SHA-256，可追溯和查重。

但这只说明“源码可以编译成固件”，不等于硬件已经验证，更不等于可以飞行。

PCBA 仍必须依次验证：

- 电源轨、时钟、复位、SWD 和 USB；
- bootloader 启动、进入 DFU/串口下载模式和参数保存；
- IMU、气压计、磁力计、SD 卡和串口；
- 电池电压/电流采样；
- 九路 PWM/DShot 波形、通道映射、电调协议和电机顺序；
- 振动、温升、失效保护和整机飞行安全。

---

## 2. 项目目标、范围与边界

### 2.1 项目目标

为嘉立创 EDA《27赛季无人机》AIO V1.0 自制飞控板建立可维护的 PX4 固件目标，并只依靠 GitHub Actions 完成固件编译。

### 2.2 已选择的技术路线

- 使用 PX4 官方 `v1.16.2` 作为基线。
- 在自己的公开 fork 中维护板级代码。
- 保留官方 `origin`，另设个人远端 `myrepo`。
- 使用独立分支 `codex/px4-1.16.2-custom`，不在只读标签上开发。
- 使用 `.px4board` 明确选择驱动、模块和功能。
- 使用 GitHub Actions 的 Ubuntu 运行器。
- 固件编译在固定镜像 `px4io/px4-dev-nuttx-focal:2022-08-12` 中执行。
- 首次 bootloader 用 SWD/JTAG 或 STM32 芯片 DFU 烧录。
- 后续应用程序用 QGroundControl 或 bootloader 支持的方式烧录。

### 2.3 明确不做的事情

- 不安装本地 PX4 NuttX 编译环境。
- 不在 Windows 上执行 `make`。
- 不把本地未提交的修改当作云端已构建内容。
- 不把 donor 的 `extras/micoair_h743-aio_bootloader.bin` 烧进 P224 板。
- 不因云编译成功而跳过台架测试。

### 2.4 “云编译成功”能证明和不能证明什么

能够证明：

- 工作流成功检出指定 commit 和子模块；
- 目标名能在 `.px4board` 中找到；
- CMake、Kconfig、链接脚本和源码在当前容器中可完成构建；
- 输出镜像没有超过当前配置的 `image_maxsize`。

不能证明：

- PCB 网表、器件封装和实际焊接正确；
- 晶振频率、负载电容和时钟树在实物上稳定；
- 传感器总线、片选、地址、方向和中断方式正确；
- 电源采样比例和电流检测极性正确；
- PWM 定时器、DShot、电调协议和电机顺序正确；
- USB、SD 卡、CAN、RC、日志和 failsafe 真实可用；
- 飞机可以安全飞行。

---

## 3. 最终方案和工作架构

### 3.1 为什么使用云端编译

PX4 NuttX 固件依赖 Linux、CMake、Python 工具、NuttX 配置和 ARM 交叉编译器。把这些依赖放进 GitHub Actions 后，Windows 只负责源码和烧录，可以减少本机环境差异。

### 3.2 本机与云端的分工

| 位置 | 负责内容 |
| --- | --- |
| Windows 本地 | 阅读原理图、编辑板级源码、Git 提交、下载 artifact、QGC 烧录、硬件测试 |
| GitHub 仓库 | 保存源码历史、分支和 Actions 工作流 |
| GitHub Actions | 检出源码、校验目标、拉取容器、编译应用和 bootloader、上传产物 |
| 飞控板 | 烧录 bootloader、烧录应用、运行 PX4、台架和飞行验证 |

### 3.3 自动与手动的边界

云编译不是“在网页里逐行敲命令”。

配置完成后，常规流程是：

1. 在 Windows 修改文件；
2. 本地 `git commit`；
3. `git push` 到个人 GitHub 仓库；
4. 工作流按 `on.push` 自动开始；
5. 在 Actions 页面查看日志和下载 artifact。

也可以使用 `workflow_dispatch` 在 GitHub 网页手动点击 `Run workflow`。无论哪种方式，真正编译命令仍是工作流中的 `make "$PX4_BOARD_TARGET"`，只是由云端自动执行。

### 3.4 GitHub Actions 工作流示意

```text
git push
   |
   v
actions/checkout@v4
  submodules: recursive
  fetch-depth: 0
   |
   v
校验 default.px4board / bootloader.px4board 目标名
   |
   v
写入 build/build-info.txt
   |
   v
docker pull px4io/px4-dev-nuttx-focal:2022-08-12
   |
   v
make p224_p224-aio-v1_default
make p224_p224-aio-v1_bootloader
   |
   v
actions/upload-artifact@v4
```

---

## 4. 当前完成状态

### 4.1 已完成

- [x] 下载并保留 PX4 `v1.16.2` 完整源码。
- [x] 核对 35 个 Git 子模块。
- [x] 建立个人公开 fork 和独立开发分支。
- [x] 保留 `origin` 为官方 PX4，新增 `myrepo` 为个人仓库。
- [x] 建立 `.github/workflows/px4-custom-board.yml`。
- [x] 先用官方 `px4_fmu-v6x_default` 做烟雾构建。
- [x] 从 AIO V1.0 工程整理 MCU 球位和板级网络。
- [x] 建立 `boards/p224/p224-aio-v1/`。
- [x] 配置 board ID `41778`。
- [x] 配置 16 MHz HSE、480 MHz CPU 时钟和 2 MiB Flash 布局。
- [x] 配置 BMI088、ICM-42688P、IST8310 和 DPS310。
- [x] 配置 SPI1、SPI2、I2C1、I2C4 和四路串口。
- [x] 配置九路直接 PWM 输出。
- [x] 配置电池电压/电流 ADC。
- [x] 配置共阳 RGB LED、蜂鸣器和 HRT。
- [x] 修复 TIM3/TIM4 通道交叉导致的构建失败。
- [x] 开启 bootloader 云构建并成功生成 bootloader。
- [x] 记录 Run #9 的 commit、产物路径、大小和 SHA-256。

### 4.2 尚未完成

- [ ] 用 SWD/JTAG 或芯片 DFU 给实物烧录 bootloader。
- [ ] 用 QGC 给实物烧录应用程序。
- [ ] 验证正常启动和 USB/串口连接。
- [ ] 校准并验证所有传感器。
- [ ] 用示波器或逻辑分析仪验证九路 PWM/DShot。
- [ ] 校准电池电压和电流比例。
- [ ] 验证电机顺序、转向和失控保护。
- [ ] 完成日志、温升、振动和台架测试。
- [ ] 完成首飞前评审。

---

## 5. Git 和 GitHub 基础知识

### 5.1 本项目中几个关键概念

| 概念 | 通俗解释 | 本项目实例 |
| --- | --- | --- |
| 仓库 repository | 保存源码和全部历史的目录 | `C:\Users\Administrator\Desktop\27plane\px4` |
| commit | 一次有说明的版本快照 | `aaa6eaa` |
| branch | 一条独立开发线 | `codex/px4-1.16.2-custom` |
| tag | 固定版本标记 | `v1.16.2` |
| remote | 远端仓库地址 | `origin`、`myrepo` |
| push | 把本地提交上传到远端 | `git push myrepo ...` |
| pull | 拉取远端更新 | 当前单人维护时较少使用 |
| fork | GitHub 上复制一份仓库 | `cbcb224/px4-27plane-custom` |
| Actions | GitHub 提供的工作流/云构建服务 | `px4-custom-board.yml` |
| artifact | Actions 运行后上传的文件包 | Run #9 ZIP |

### 5.2 两个 remote 的含义

```text
origin  https://github.com/PX4/PX4-Autopilot.git
myrepo  https://github.com/cbcb224/px4-27plane-custom.git
```

- `origin` 用于对照和获取官方 PX4。
- `myrepo` 用于推送自己的分支和触发云编译。

不要把自制板代码直接推到官方 `PX4/PX4-Autopilot`，也没有该权限。

### 5.3 为什么不在 `v1.16.2` 标签上直接开发

标签应当固定在官方发布点。直接修改标签会导致版本含义混乱。本项目从 `v1.16.2` 建立开发分支，之后所有板级改动都成为独立 commit，才能准确定位“哪个提交生成了哪个固件”。

### 5.4 当前工作树说明

当前只应保留以下未跟踪目录，且不要提交：

```text
.workbuddy/
boards/p224/p224-aio-v1/extras/
```

其中 `extras/micoair_h743-aio_bootloader.bin` 只是外部参考文件，不能作为 P224 AIO V1.0 的正式 bootloader 烧录。

---

## 6. 从零到当前状态的每一步工作流程

下面的“每一步”同时对应实际操作、代码变化和可追溯提交。早期有些操作在同一天连续完成，所以并非每个动作都单独形成一个 commit。

### 第 0 步：确定硬件事实和编译决策

输入来自 AIO V1.0 原理图/PCB：

- 主控为 STM32H743VIH6，TFBGA-100；
- HSE 晶振为 16 MHz；
- BMI088 在 SPI1；
- ICM-42688P 在 SPI2；
- IST8310 和 DPS310 在内部 I2C4；
- I2C1 外部总线有焊盘；
- USART2 TX/RX 有焊盘；
- 九路 PWM 网络及其定时器约束；
- 电池电压/电流、RGB LED、蜂鸣器和 SDIO/USB 连接。

同时记录以下“不编译”决定：

- PA3/U28.6 `IO1` 不编译为 PX4 GPIO；
- J7/PB10 不单独编译为普通 GPIO，只使用 TIM2_CH3 PWM9；
- 所有传感器中断脚未接 MCU，驱动启动方式需重点验证。

产物：

- `boards/p224/p224-aio-v1/src/board_config.h`
- `boards/p224/p224-aio-v1/src/timer_config.cpp`
- `.codex/27赛季无人机-AIO-V1.0-PX4引脚映射.md`

### 第 1 步：保留并核对 PX4 1.16.2 源码

本地源码已经有完整工作树，因此没有删除重下。核对命令：

```powershell
Set-Location 'C:\Users\Administrator\Desktop\27plane\px4'
git status --short --branch
git log --oneline -5
git submodule status --recursive
```

结果：

- 基线为 PX4 `v1.16.2`；
- 子模块共 35 个；
- 分支为 `codex/px4-1.16.2-custom`；
- 不因为云编译而删除本地源码。

### 第 2 步：配置 GitHub 个人仓库和两个 remote

- 建立公开 fork：`cbcb224/px4-27plane-custom`。
- 保留 `origin` 指向官方 PX4。
- 新增 `myrepo` 指向个人 fork。
- 推送分支 `codex/px4-1.16.2-custom`。

对应提交起点：

- `b7310ce Add PX4 GitHub cloud build workflow and guide`

### 第 3 步：建立云编译工作流

新增：

```text
.github/workflows/px4-custom-board.yml
.codex/github-actions/px4-custom-board.yml
```

工作流配置的核心变量：

```yaml
PX4_BOARD_TARGET: p224_p224-aio-v1_default
PX4_BOOTLOADER_TARGET: p224_p224-aio-v1_bootloader
PX4_BUILD_BOOTLOADER: "true"
PX4_DOCKER_IMAGE: px4io/px4-dev-nuttx-focal:2022-08-12
```

工作流会：

1. 递归检出源码和子模块；
2. 从 `boards/**/*.px4board` 生成合法目标列表；
3. 校验完整目标名；
4. 生成 `build-info.txt`；
5. 拉取固定官方 NuttX 容器；
6. 构建应用程序；
7. 根据开关构建 bootloader；
8. 上传 `.px4`、`.elf`、`.bin`、`.hex`、`.map` 和 `build-info.txt`。

### 第 4 步：用官方目标做烟雾构建

在修改自制板之前，先用官方 `px4_fmu-v6x_default` 验证 GitHub 仓库、容器、子模块和 artifact 上传链路。

结果：

- Run #1 `40840194077` 成功；
- 证明云构建基础设施可用；
- 避免把 GitHub/工具链问题误判为自制板源码问题。

对应提交：

- `1b7fdde Document successful PX4 cloud build [skip ci]`

### 第 5 步：把原理图信息整理成 PX4 引脚决策

不仅记录“某个 MCU 引脚连到哪里”，还把硬件事实转换成 PX4 配置：

- MCU 球位与网络；
- 传感器所在总线及片选；
- 串口映射；
- PWM 定时器和通道；
- ADC 引脚与采样通道；
- LED、蜂鸣器、USB、SDIO；
- 不进入当前固件的连接。

对应提交：

- `18d8537 Document P224 AIO V1.0 pin mapping`

### 第 6 步：建立自制板目录和目标名

目录：

```text
boards/p224/p224-aio-v1/
```

完整目标命名规则：

```text
<VENDOR>_<MODEL>_<LABEL>
```

因此：

```text
boards/p224/p224-aio-v1/default.px4board
  -> p224_p224-aio-v1_default

boards/p224/p224-aio-v1/bootloader.px4board
  -> p224_p224-aio-v1_bootloader
```

不能用 `p224_p224` 这类会被下划线错误拆分的旧写法；工作流现在直接根据目录和 `.px4board` 文件名校验唯一目标。

对应提交：

- `978347f Add P224 AIO V1.0 board target`

### 第 7 步：把云工作流切换到自制板目标

把 YAML 中的目标从官方板切换到：

```text
p224_p224-aio-v1_default
```

并在后续启用：

```text
p224_p224-aio-v1_bootloader
```

对应提交：

- `4a76f3d Build P224 AIO V1.0 target in cloud`
- `aaa6eaa Enable P224 AIO bootloader cloud build`

### 第 8 步：修复目标预检脚本

预检脚本最初对带下划线的目标存在标签识别问题。修复后，预检直接镜像 PX4 Makefile 的目标发现逻辑：

```bash
find boards -maxdepth 3 -mindepth 3 -name '*.px4board'
```

再去掉路径和扩展名，把目录分隔符替换为下划线，得到准确目标名。

对应提交：

- `331bfec Fix cloud build preflight tag detection`

### 第 9 步：配置 board ID 和 Flash 布局

自制板不能随意复用官方 board ID，否则 bootloader 和应用程序可能识别错误。

当前配置：

```text
BOARD_TYPE=41778
board_id=41778
BOOTLOADER_FLASH_START=0x08000000
APP_LOAD_ADDRESS=0x08020000
应用 Flash 区起始=0x08020000
应用 Flash 区长度=1792 KiB
image_maxsize=1835008 字节
```

重要文件：

```text
boards/p224/p224-aio-v1/firmware.prototype
boards/p224/p224-aio-v1/src/hw_config.h
boards/p224/p224-aio-v1/nuttx-config/scripts/script.ld
boards/p224/p224-aio-v1/nuttx-config/scripts/bootloader_script.ld
```

校验原则：

- bootloader 与应用程序地址不能重叠；
- board ID 必须同时匹配 bootloader 和 `.px4` 固件；
- Flash 长度、扇区数量和实际 MCU 容量必须一致；
- `image_maxsize` 不能大于链接脚本允许的区域。

### 第 10 步：适配 16 MHz HSE

AIO V1.0 使用 16 MHz HSE。板级文件把 HSE、PLL 和系统时钟按 16 MHz 重新计算。

关键配置：

```text
STM32_BOARD_XTAL=16000000
PLL1: 16 MHz / 1 × 60 = 960 MHz VCO
PLL1P: 960 MHz / 2 = 480 MHz SYSCLK
CPUCLK=480 MHz
HCLK=240 MHz
```

对应提交：

- `82b007e Configure P224 AIO for 16 MHz HSE`

### 第 11 步：配置 SPI 传感器

当前 SPI 映射：

| 总线 | 器件 | 片选/引脚 | 启动参数 |
| --- | --- | --- | --- |
| SPI1 | BMI088 加速度计 | PA2 | `bmi088 -s -b 1 -A -R 6 start` |
| SPI1 | BMI088 陀螺仪 | PA10 | `bmi088 -s -b 1 -G -R 6 start` |
| SPI2 | ICM-42688P | PD15 | `icm42688p -s -b 2 -R 6 start` |

总线引脚：

```text
SPI1: SCK=PA5, MISO=PA6, MOSI=PA7
SPI2: SCK=PB13, MISO=PB14, MOSI=PB15
```

注意：BMI088 的 SDO1 和 SDO2 同时连接 SPI1 MISO。必须依靠两个独立片选避免总线冲突。

对应提交：

- `07f3f2c Map P224 AIO SPI sensors`

### 第 12 步：配置 I2C 总线和内部传感器

当前 I2C 映射：

| PX4 总线 | MCU 引脚 | 用途 |
| --- | --- | --- |
| 外部 I2C1 | SCL=PB8，SDA=PB9 | 板级焊盘引出，供外部设备 |
| 内部 I2C4 | SCL=PD12，SDA=PD13 | IST8310 磁力计、DPS310 气压计 |

传感器启动：

```text
ist8310 -I -R 2 start
dps310 -I start -a 118
```

其中 DPS310 地址为 `118`（十进制，即 `0x76`）。

对应提交：

- `2ed49b4 Map P224 AIO I2C buses`
- `3717b09 Enable P224 AIO I2C sensors`

### 第 13 步：配置串口

当前 `.px4board` 串口映射：

| PX4 端口 | NuttX 设备 |
| --- | --- |
| GPS1 | `/dev/ttyS2` |
| TEL1 | `/dev/ttyS0` |
| TEL2 | `/dev/ttyS1` |
| TEL3 | `/dev/ttyS3` |

硬件侧对应的 UART 配置包括：

- USART2：TX=PD5，RX=PD6，有板级焊盘；
- UART4：TX=PD1，RX=PD0；
- UART7：TX=PA15，RX=PB3；
- UART8：TX=PE1，RX=PE0。

注意：`.px4board` 的 `/dev/ttySx` 编号与 UART 外设编号不是简单一一对应，必须结合 NuttX defconfig、板级串口注册顺序和实际启动日志验证。

对应提交：

- `284918d Map P224 AIO serial ports`

### 第 14 步：配置九路 PWM

`timer_config.cpp` 中九路直接输出按定时器分组：

```cpp
Timer1 Channel1 -> PE9
Timer1 Channel3 -> PE13
Timer1 Channel2 -> PE11
Timer1 Channel4 -> PE14
Timer3 Channel1 -> PB4
Timer3 Channel2 -> PB5
Timer4 Channel1 -> PB6
Timer4 Channel2 -> PB7
Timer2 Channel3 -> PB10
```

PX4 要求同一 TIM 的通道在数组中连续，否则构建会报：

```text
Timers are not grouped together
```

同时，数组顺序决定 PWM1～PWM9 的逻辑编号，所以分组后必须用 `PWM_MAIN_FUNC*` 把逻辑编号重新对应到板上 M1～M8。

对应提交：

- `39e289e Map P224 AIO PWM outputs`
- `4996c86 Group P224 AIO PWM channels by timer`

### 第 15 步：配置电池 ADC

硬件：

| 测量项 | MCU 引脚 | ADC 通道 |
| --- | --- | --- |
| 电池电压 | PA4 | ADC1_INP18 |
| 电池电流 | PC4 | ADC1_INP4 |

默认参数：

```text
BAT1_A_PER_V=14.14
BAT1_N_CELLS=4
BAT1_V_CHARGED=4.2
BAT1_V_DIV=21.12
BAT1_V_EMPTY=3.2
```

这些数值来自当前硬件设计计算，但必须用可调电源和电子负载实测校准。

对应提交：

- `4dc1f0d Map P224 AIO ADC battery inputs`

### 第 16 步：配置 RGB LED、蜂鸣器和 HRT

RGB LED 为共阳、低电平点亮：

```text
红色 = PC1
绿色 = PA0
蓝色 = PC0
```

蜂鸣器为有源高电平/定时器驱动：

```text
TONE_ALARM_TIMER=8
TONE_ALARM_CHANNEL=2
GPIO_TONE_ALARM=PC7
```

高分辨率定时器：

```text
HRT_TIMER=5
HRT_TIMER_CHANNEL=1
```

对应提交：

- `870ce1d Map P224 AIO RGB LED`
- `a6bde18 Add P224 AIO tone alarm and HRT`

### 第 17 步：整理启动脚本和默认参数

关键启动文件：

```text
init/rc.board_defaults
init/rc.board_sensors
init/rc.board_extras
```

当前行为：

- 启动板级 ADC；
- 启动 BMI088 加速度计和陀螺仪；
- 启动 ICM-42688P；
- 启动 IST8310 和 DPS310；
- 设置电池参数；
- 设置 PWM 输出功能映射；
- 设置四旋翼控制分配；
- 设置 `RC_INPUT_PROTO=-1`；
- 设置 `CBRK_SUPPLY_CHK=894281`，暂时绕过电源检查；
- 设置 `SYS_AUTOSTART=4001`。

`CBRK_SUPPLY_CHK` 只能用于已采取外部限流和保护措施的台架调试，正式使用前必须重新评估并恢复合理电源检查。

### 第 18 步：修复 PWM 分组导致的云构建失败

首次包含九路 PWM 的 Run #6 失败，错误为：

```text
Timers are not grouped together
```

根因：

```text
TIM3_CH1 -> TIM4_CH2 -> TIM4_CH1 -> TIM3_CH2
```

同一 TIM 的通道被其他 TIM 隔开。

修复：

```text
TIM3_CH1 -> TIM3_CH2 -> TIM4_CH1 -> TIM4_CH2
```

但修复顺序后：

```text
PWM6 = PB5 = M8
PWM8 = PB7 = M6
```

因此增加：

```text
PWM_MAIN_FUNC6=108
PWM_MAIN_FUNC7=107
PWM_MAIN_FUNC8=106
```

修复后 Run #7 成功。

### 第 19 步：记录构建结果并完善映射文档

对应提交：

- `7dd0494 Document P224 PWM timer grouping and build result`

该提交补充了 PWM 分组原因、运行成功记录和后续调试验收说明。

### 第 20 步：启用 bootloader 云构建

工作流新增：

```yaml
PX4_BOOTLOADER_TARGET: p224_p224-aio-v1_bootloader
PX4_BUILD_BOOTLOADER: "true"
```

构建容器内执行：

```bash
make p224_p224-aio-v1_default
make p224_p224-aio-v1_bootloader
```

对应提交：

- `aaa6eaa Enable P224 AIO bootloader cloud build`

结果：

- Run #9 同时生成应用和 bootloader；
- 两个目标均通过；
- 产物已下载并校验。

### 第 21 步：下载并校验 artifact

下载后应核对：

- 工作流名称是否为 `Build custom PX4 firmware`；
- run number 和 commit 是否为预期值；
- `build-info.txt` 中的 `board_target`；
- 是否同时存在应用和 bootloader；
- 文件大小和 SHA-256；
- `.px4` 是否小于 `image_maxsize`。

不只看“绿色对勾”，还要追溯具体 commit 和文件哈希。

### 第 22 步：首次烧录 bootloader

前置条件：

- 已确认 SWD/JTAG 或芯片 DFU 连接；
- 已确认 BOOT0、NRST、3.3 V、GND 和调试口；
- 使用限流电源；
- 拆除螺旋桨和电机负载；
- 不烧录 `extras/micoair_h743-aio_bootloader.bin`。

首次烧录只能使用 Run #9 生成的：

```text
p224_p224-aio-v1_bootloader.bin
```

或对应的官方构建输出。

### 第 23 步：烧录应用程序

bootloader 正常启动且 USB/串口可用后，再通过 QGC 或 bootloader 工具烧录：

```text
p224_p224-aio-v1_default.px4
```

烧录后先看启动日志和基础外设，不直接装桨试飞。

### 第 24 步：硬件台架验证

按以下顺序逐项验证：

1. 电源轨、限流和温升；
2. SWD、USB、串口启动日志；
3. 参数保存和重启；
4. SPI/I2C 传感器识别；
5. ADC 电压/电流；
6. RGB LED 和蜂鸣器；
7. 九路 PWM/DShot 波形；
8. 电机顺序、转向和 failsafe；
9. SD 卡、日志、RC、GPS/CAN；
10. 振动、安装方向和飞行前评审。

---

## 7. Git 提交与云构建时间线

| 顺序 | 提交 | 内容 | 对应结果 |
| --- | --- | --- | --- |
| 1 | `b7310ce` | 建立 GitHub 云编译工作流和教程 | 云构建基础设施 |
| 2 | `1b7fdde` | 记录首次官方目标烟雾构建 | Run #1 成功 |
| 3 | `18d8537` | 整理 AIO V1.0 引脚映射 | 硬件事实基线 |
| 4 | `978347f` | 创建 P224 自制板目标 | 板级目录 |
| 5 | `4a76f3d` | 云端切换到自制板目标 | 开始构建自制板 |
| 6 | `331bfec` | 修复云编译目标预检 | 目标名校验 |
| 7 | `82b007e` | 配置 16 MHz HSE | 正确时钟输入 |
| 8 | `07f3f2c` | 映射 SPI 传感器 | BMI088/ICM42688 |
| 9 | `2ed49b4` | 映射 I2C 总线 | I2C1/I2C4 |
| 10 | `3717b09` | 启用 I2C 传感器 | IST8310/DPS310 |
| 11 | `284918d` | 映射串口 | GPS/TEL |
| 12 | `39e289e` | 映射 PWM | 九路输出 |
| 13 | `4dc1f0d` | 映射电池 ADC | 电压/电流 |
| 14 | `870ce1d` | 映射 RGB LED | 状态灯 |
| 15 | `a6bde18` | 增加蜂鸣器和 HRT | 声光告警/时基 |
| 16 | `4996c86` | 修复 PWM 定时器分组 | Run #7 成功 |
| 17 | `7dd0494` | 补充 PWM 映射和构建文档 | 文档同步 |
| 18 | `aaa6eaa` | 启用 bootloader 云编译 | Run #9 成功 |

时间线说明：

- 这些提交是“可追溯的主要阶段”，不是把所有终端操作都机械拆成一个 commit。
- 每个 commit 应只表达一个清晰目的；出现新问题应单独修复并保留原因。
- 不要把 `.workbuddy/`、`extras/`、临时日志或构建缓存提交到仓库。

---

## 8. 板级配置汇总

### 8.1 目标与硬件

| 项目 | 当前值 |
| --- | --- |
| 板卡厂商目录 | `p224` |
| 板卡型号目录 | `p224-aio-v1` |
| 应用目标 | `p224_p224-aio-v1_default` |
| bootloader 目标 | `p224_p224-aio-v1_bootloader` |
| board ID | `41778` |
| MCU（PCB） | STM32H743VIH6，TFBGA-100 |
| 架构 | Cortex-M7 |
| HSE | 16 MHz |
| CPUCLK | 480 MHz |
| 主 Flash | 2 MiB |
| 应用起始地址 | `0x08020000` |
| 应用可用长度 | 1,792 KiB |
| `image_maxsize` | 1,835,008 字节 |
| PX4 基线 | `v1.16.2` |

> 板级部分文件沿用了 H7 模板中的说明性注释，个别注释仍写有 `STM32H743II` 或旧 donor 名称。实际硬件识别应以 AIO V1.0 原理图和 BOM 中的 **STM32H743VIH6** 为准；后续可清理注释，但不得仅凭注释修改 Flash/引脚逻辑。

### 8.2 功能启用概览

`.px4board` 当前启用的主要内容：

- ADC 板级驱动；
- BMI088、ICM-42688P；
- IST8310 磁力计、DPS310 气压计；
- PWM_OUT、DShot、TAP_ESC；
- TONE_ALARM；
- GPS、RC_INPUT、Telemetry；
- UAVCAN；
- battery_status、commander、EKF2、logger；
- 多旋翼姿态/位置/速率控制；
- 固定翼和 VTOL 控制模块；
- uXRCE-DDS client；
- actutor_test、i2cdetect、param、top、uorb 等调试命令。

### 8.3 PX4 Kconfig 与 `.px4board` 的关系

PX4 使用 Kconfig 管理驱动、模块和功能开关。`default.px4board` 本质上是保存下来的 Kconfig 结果，例如：

```text
CONFIG_DRIVERS_IMU_BOSCH_BMI088=y
CONFIG_DRIVERS_MAGNETOMETER_ISENTEK_IST8310=y
CONFIG_MODULES_EKF2=y
```

在完整本地开发环境中，可以使用 PX4 的 Kconfig 图形界面选择或裁剪驱动、模块和功能。但本项目已经明确不做本地编译，因此当前做法是直接、显式地维护 `.px4board`：

1. 编辑 `boards/p224/p224-aio-v1/default.px4board`；
2. 同时检查启动脚本是否引用了对应驱动；
3. 提交并推送；
4. 让云端构建验证结果。

直接在 `.px4board` 编辑并不等于绕开 Kconfig；它仍由 PX4 构建系统解析。风险是手工写错符号名，所以每次增删功能都应以构建日志为准。

### 8.4 关键源码文件

| 文件 | 作用 |
| --- | --- |
| `default.px4board` | 应用目标驱动和模块开关 |
| `bootloader.px4board` | bootloader 目标开关 |
| `firmware.prototype` | board ID、镜像描述和大小限制 |
| `src/hw_config.h` | bootloader 地址、board type、Flash 参数、USB 描述 |
| `src/board_config.h` | LED、ADC、PWM、蜂鸣器、HRT、USB、SDIO |
| `src/timer_config.cpp` | 九路 PWM 定时器和引脚 |
| `src/spi.cpp` | SPI 总线和片选 |
| `src/i2c.cpp` | 外部 I2C1、内部 I2C4 |
| `init/rc.board_sensors` | 传感器启动命令 |
| `init/rc.board_defaults` | 板级参数默认值 |
| `nuttx-config/include/board.h` | 时钟、UART、SPI、I2C 引脚复用 |
| `nuttx-config/scripts/script.ld` | 应用链接地址和 Flash 长度 |
| `nuttx-config/scripts/bootloader_script.ld` | bootloader 链接布局 |

---

## 9. 九路 PWM 映射

### 9.1 定时器、引脚和板上网络

| PX4 输出 | 定时器通道 | MCU 引脚 | 板上网络 | 当前用途 |
| --- | --- | --- | --- | --- |
| PWM1 | TIM1_CH1 | PE9 | M1 | 四旋翼 Motor1 |
| PWM2 | TIM1_CH3 | PE13 | M2 | 四旋翼 Motor2 |
| PWM3 | TIM1_CH2 | PE11 | M3 | 四旋翼 Motor3 |
| PWM4 | TIM1_CH4 | PE14 | M4 | 四旋翼 Motor4 |
| PWM5 | TIM3_CH1 | PB4 | M5 | 已映射，未参与当前四旋翼 |
| PWM6 | TIM3_CH2 | PB5 | M8 | 已映射，未参与当前四旋翼 |
| PWM7 | TIM4_CH1 | PB6 | M7 | 已映射，未参与当前四旋翼 |
| PWM8 | TIM4_CH2 | PB7 | M6 | 已映射，未参与当前四旋翼 |
| PWM9 | TIM2_CH3 | PB10/J7 | TIM2-CH3 | 已映射，预留 |

### 9.2 输出功能补偿

```text
PWM_MAIN_FUNC1=101
PWM_MAIN_FUNC2=102
PWM_MAIN_FUNC3=103
PWM_MAIN_FUNC4=104
PWM_MAIN_FUNC5=105
PWM_MAIN_FUNC6=108
PWM_MAIN_FUNC7=107
PWM_MAIN_FUNC8=106
```

作用：数组因定时器分组改变了 PWM6/PWM8 的物理网络顺序，通过功能参数仍让逻辑输出对应板上 M6、M7、M8。

### 9.3 当前控制分配

```text
CA_AIRFRAME=0
CA_ROTOR_COUNT=4
PWM_MAIN_TIM0=-4
```

含义：

- 当前按四旋翼控制分配；
- 只使用 Motor1～Motor4；
- `PWM_MAIN_TIM0=-4` 使第一组 TIM1 使用 DShot300；
- TIM3、TIM4、TIM2 的最终协议、频率、极性和空闲状态仍需实测确认。

### 9.4 验证方法

必须在装桨前完成：

1. 用示波器或逻辑分析仪测量每一路；
2. 确认 PWM1～PWM9 与 M1～M8/TIM2-CH3 的实际对应；
3. 逐路发送小占空比并检查对应电调输入；
4. 确认 DShot 帧和电调响应；
5. 确认上电、复位和飞控重启时不会误输出；
6. 最后才检查电机顺序和转向。

---

## 10. GitHub Actions 云编译工作流

### 10.1 触发方式

`.github/workflows/px4-custom-board.yml` 当前在以下事件触发：

- `push`；
- `pull_request`；
- `workflow_dispatch`（网页手动触发）。

因此文档提交也会触发一次云构建。文档改动不会使旧固件失效，正式烧录仍应追溯到明确的源码 commit。

### 10.2 目标校验

工作流会找出所有 `.px4board`，把目录和文件名转换成目标名：

```text
boards/p224/p224-aio-v1/default.px4board
  -> p224_p224-aio-v1_default
```

然后要求 `PX4_BOARD_TARGET` 和 `PX4_BOOTLOADER_TARGET` 与列表完全一致。这样可以避免旧脚本把 `p224_p224-aio-v1_default` 错误截断为其他标签。

### 10.3 构建元数据

每次构建写入：

```text
repository
workflow_ref
commit
branch
px4_description
board_target
bootloader_target
build_bootloader
docker_image
github_run_id
github_run_number
built_utc
```

这些字段是把本地源码、GitHub 运行记录、下载文件和烧录固件对应起来的关键证据。

### 10.4 容器和命令

```yaml
PX4_DOCKER_IMAGE: px4io/px4-dev-nuttx-focal:2022-08-12
```

容器内核心命令：

```bash
make p224_p224-aio-v1_default
make p224_p224-aio-v1_bootloader
```

工作流固定容器 tag，而不是跟随 `latest`，便于复现。若未来升级镜像，需要重新做完整构建和硬件回归。

### 10.5 上传内容

- 应用 `.px4`；
- 应用 `.elf`；
- 应用 `.bin`；
- 应用 `.hex`；
- 应用 `.map`；
- bootloader `.elf`；
- bootloader `.bin`；
- bootloader `.hex`；
- bootloader `.map`；
- `build-info.txt`。

artifact 保留 14 天。重要版本应及时下载到本地并保存哈希，不能只依赖 GitHub 的临时 artifact。

---

## 11. Run #6 失败与修复复盘

### 11.1 问题现象

运行：

- Run #6 `40859263169`
- 状态：失败
- 日志错误：`Timers are not grouped together`

### 11.2 根因

九路通道最初按板上网络或逻辑编号排列，造成同一 TIM 的通道被其他 TIM 隔开：

```text
TIM3_CH1
TIM4_CH2
TIM4_CH1
TIM3_CH2
```

PX4 的 `timer_io_channels[]` 要求同一定时器所有通道连续出现。

### 11.3 修复方法

数组改为：

```text
TIM3_CH1
TIM3_CH2
TIM4_CH1
TIM4_CH2
```

但数组索引决定 PWM 编号，所以又出现：

```text
PWM6 -> PB5 -> M8
PWM8 -> PB7 -> M6
```

通过 `PWM_MAIN_FUNC6=108` 和 `PWM_MAIN_FUNC8=106` 补偿逻辑映射。

### 11.4 修复结果

- Run #7 `40860950848` 成功；
- 后续 Run #8 文档构建成功；
- Run #9 `40862991259` 同时成功构建应用与 bootloader。

### 11.5 可复用的排查原则

遇到云构建失败时：

1. 先确认 Actions 检出的 commit 是否等于本地预期；
2. 确认子模块完整；
3. 确认目标名与 `.px4board` 文件名一致；
4. 找到日志中第一个真实 `error:`，不要只看最后一个错误；
5. 区分“目标校验失败”“Docker 失败”“CMake/Kconfig 失败”“C++ 编译失败”和“链接/尺寸失败”；
6. 每次只做一个明确修复，再进行下一次云构建。

---

## 12. Run #9 成功产物和校验值

### 12.1 运行信息

| 项目 | 值 |
| --- | --- |
| Run | #9 |
| Run ID | `40862991259` |
| 状态 | 成功 |
| 提交 | `aaa6eaae3ee8eeb8ff66380d0338d2470e0ac07b` |
| 分支 | `codex/px4-1.16.2-custom` |
| 应用目标 | `p224_p224-aio-v1_default` |
| bootloader 目标 | `p224_p224-aio-v1_bootloader` |
| 构建开关 | `build_bootloader=true` |
| 容器 | `px4io/px4-dev-nuttx-focal:2022-08-12` |
| 构建 UTC 时间 | `2026-10-29T11:09:25Z` |

链接：

- [Run #9](https://github.com/cbcb224/px4-27plane-custom/actions/runs/40862991259)
- [公开仓库](https://github.com/cbcb224/px4-27plane-custom)

### 12.2 artifact ZIP

```text
C:\Users\Administrator\Desktop\27plane\px4-artifacts\px4-custom-p224_p224-aio-v1_default-9.zip
```

- 大小：`21,514,117` 字节
- SHA-256：

```text
1dacdf915fc5c057fd17d397831370f149eb5c7ecf7c9205b65163e20c745581
```

### 12.3 bootloader

```text
C:\Users\Administrator\Desktop\27plane\px4-artifacts\px4-custom-p224_p224-aio-v1_default-9\p224_p224-aio-v1_bootloader\p224_p224-aio-v1_bootloader.bin
```

- 大小：`41,176` 字节
- SHA-256：

```text
4a81ae92f9b7c53b148458ee1b53c59fc15e8fa81a177d2a7044d8076e5bc5ba
```

### 12.4 应用程序

```text
C:\Users\Administrator\Desktop\27plane\px4-artifacts\px4-custom-p224_p224-aio-v1_default-9\p224_p224-aio-v1_default\p224_p224-aio-v1_default.px4
```

- 大小：`1,707,002` 字节
- SHA-256：

```text
386c2c7498f1cbdc7cdac727bba8cf8e194b3e59f9fc6fa1c9ced1af4d088235
```

### 12.5 应用大小余量

```text
image_maxsize = 1,835,008 字节
应用大小       = 1,707,002 字节
剩余余量       =   128,006 字节
```

当前未超出 Flash 限制。以后新增模块、调试符号或驱动时，应持续关注 mirror 大小和链接结果。

### 12.6 `build-info.txt`

```text
commit=aaa6eaae3ee8eeb8ff66380d0338d2470e0ac07b
branch=codex/px4-1.16.2-custom
board_target=p224_p224-aio-v1_default
bootloader_target=p224_p224-aio-v1_bootloader
build_bootloader=true
docker_image=px4io/px4-dev-nuttx-focal:2022-08-12
github_run_id=40862991259
github_run_number=9
built_utc=2026-10-29T11:09:25Z
```

### 12.7 云构建历史摘要

| Run | 状态 | 说明 |
| --- | --- | --- |
| #1 `40840194077` | 成功 | 官方 `px4_fmu-v6x_default` 烟雾构建 |
| #6 `40859263169` | 失败 | TIM3/TIM4 通道交叉，报 `Timers are not grouped together` |
| #7 `40860950848` | 成功 | 修复 PWM 分组，应用构建成功 |
| #8 `40861976281` | 成功 | 文档更新构建 |
| #9 `40862991259` | 成功 | 应用与 bootloader 同时构建 |

如果后续查询 Actions 历史，应限定工作流文件：

```text
.github/workflows/px4-custom-board.yml
```

避免把同一仓库内其他工作流（例如 EKF 相关工作流）混入统计。

---

## 13. bootloader 与应用程序烧录流程

### 13.1 为什么需要两次烧录

PX4 的典型部署流程是：

```text
空白 MCU
  -> 调试器/芯片 DFU 写入 bootloader
  -> bootloader 建立 USB/串口下载能力
  -> QGC 写入 .px4 应用程序
  -> PX4 启动
```

如果板子还是空白 MCU，QGC 无法替代首次 bootloader 烧录。

### 13.2 首次 bootloader 烧录

使用 Run #9 文件：

```text
C:\Users\Administrator\Desktop\27plane\px4-artifacts\px4-custom-p224_p224-aio-v1_default-9\p224_p224-aio-v1_bootloader\p224_p224-aio-v1_bootloader.bin
```

烧录地址：

```text
0x08000000
```

可用方式：

- ST-Link/J-Link + SWD；
- OpenOCD；
- STM32CubeProgrammer；
- MCU 内置 ROM DFU（需要正确进入 BOOT0/DFU 模式）。

烧录前的电气检查：

- 3.3 V 在允许范围；
- GND、SWDIO、SWCLK、NRST、BOOT0 定义正确；
- 限流电源已设置；
- 电机和螺旋桨未连接；
- 不会误把 donor bootloader 烧入。

### 13.3 应用程序烧录

文件：

```text
C:\Users\Administrator\Desktop\27plane\px4-artifacts\px4-custom-p224_p224-aio-v1_default-9\p224_p224-aio-v1_default\p224_p224-aio-v1_default.px4
```

对于 PX4 自定义板，优先使用 `.px4` 包，而不是直接把应用 `.bin` 当普通文件烧到 Flash 起始地址。`.px4` 包含 PX4 固件封装信息，QGC/bootloader 会按 board ID 和地址校验。

建议顺序：

1. 只焊最小电源和 MCU，检查电流；
2. 烧录 bootloader；
3. 检查能否通过 USB/串口进入 bootloader；
4. 烧录 `.px4`；
5. 查看启动日志；
6. 再逐项接入传感器、SD、电调和外设；
7. 所有台架测试通过后才进入整机测试。

### 13.4 不要烧录 donor 文件

当前存在：

```text
boards/p224/p224-aio-v1/extras/micoair_h743-aio_bootloader.bin
```

这是外部参考/兼容性文件，不是本次针对 P224 AIO V1.0 生成的 bootloader。直接烧录可能导致 board ID、Flash 布局、USB 描述或启动行为不匹配。

正式文件应使用：

```text
p224_p224-aio-v1_bootloader.bin
```

并通过 SHA-256 或 `build-info.txt` 确认来自预期运行。

### 13.5 烧录后再验证

- USB 设备名称和 PID；
- bootloader 进入等待时间；
- 应用 board ID 是否匹配；
- 参数保存；
- 重启后仍能进入应用；
- SWD 重新连接；
- NRST/BOOT0 行为；
- 串口日志是否稳定。

---

## 14. 硬件台架验证清单

### 14.1 电源和 MCU 最小系统

- [ ] 输入电源限流，防反接；
- [ ] 3.3 V、5 V、传感器电源和参考电压在规格内；
- [ ] MCU 供电和 VCAP 正确；
- [ ] 16 MHz 晶振频率、起振和负载电容正确；
- [ ] NRST 和 BOOT0 按键/电平正确；
- [ ] SWD 可连接；
- [ ] USB D+/D- 和 ESD 器件正常；
- [ ] 空闲电流和温升正常。

### 14.2 bootloader 和 PX4 启动

- [ ] 可烧录并校验 bootloader；
- [ ] bootloader 能被 QGC 识别；
- [ ] `.px4` 的 board ID 与 bootloader 一致；
- [ ] 应用地址 `0x08020000` 正确；
- [ ] `dmesg` 无 hardfault、watchdog 或持续错误；
- [ ] 参数重启后保留；
- [ ] 应用镜像未超过 `image_maxsize`。

### 14.3 传感器

- [ ] BMI088 加速度计识别；
- [ ] BMI088 陀螺仪识别；
- [ ] ICM-42688P 识别；
- [ ] IST8310 识别；
- [ ] DPS310 在 I2C4 地址 `0x76` 识别；
- [ ] 各传感器采样率和数据连续；
- [ ] IMU 安装方向与 board frame 一致；
- [ ] 加速度计、陀螺仪和磁力计校准通过；
- [ ] 没有因中断脚未连接而出现无数据或超时。

可用 NSH/MAVLink 控制台检查：

```text
dmesg
i2cdetect -b 4
listener sensor_accel
listener sensor_gyro
listener sensor_mag
listener sensor_baro
uorb top
```

具体命令是否可用取决于当前镜像启用的 system command，应以实际帮助信息为准。

### 14.4 ADC、声光和外设

- [ ] PA4 电池电压比例正确；
- [ ] PC4 电流采样方向和零点正确；
- [ ] `BAT1_V_DIV=21.12`、`BAT1_A_PER_V=14.14` 实测校准；
- [ ] 4S 电池的充满/空载参数合理；
- [ ] RGB LED 三种颜色和亮度正确；
- [ ] PC7 蜂鸣器可正常发声；
- [ ] USB、SDIO、串口有实际读写；
- [ ] RC、GPS、CAN/UAVCAN 按需求验证。

### 14.5 九路 PWM/DShot

- [ ] PWM1～PWM9 每一路都有正确波形；
- [ ] M1～M8 网络对应正确；
- [ ] PWM6/PWM8 的顺序补偿有效；
- [ ] TIM1 DShot300 频率和帧正确；
- [ ] TIM2/TIM3/TIM4 输出协议已确认；
- [ ] 上电、复位、解锁前输出状态安全；
- [ ] 电调能识别信号；
- [ ] 电机顺序和转向正确；
- [ ] 失控保护和紧急停机能切断输出；
- [ ] 全程拆除螺旋桨。

### 14.6 首飞前

- [ ] 台架振动、温升和日志测试完成；
- [ ] 电源、传感器和电机全部通过；
- [ ] failsafe、return、land 和 emergency 已评审；
- [ ] 飞行区域安全；
- [ ] 有紧急断电方案；
- [ ] 使用低风险模式逐步扩大包线。

---

## 15. 当前风险与未验证项

### 15.1 高优先级风险

| 风险 | 说明 | 处理 |
| --- | --- | --- |
| 云构建成功被误解为可飞 | 构建只验证源码，不验证硬件 | 完成全部台架测试前不装桨 |
| `CBRK_SUPPLY_CHK=894281` | 绕过 PX4 电源检查 | 只用于受控台架，正式前恢复/评估 |
| donor bootloader | 外部 `.bin` 与 P224 目标不匹配 | 绝不烧录 `extras/` 文件 |
| PWM 未实测 | TIM1 DShot300 之外的定时器和协议未验证 | 逐路示波器/逻辑分析仪测试 |
| 传感器中断未接 | 多个 IMU/磁力计中断脚无 MCU 网络 | 验证轮询模式采样和超时 |
| 电机顺序未验证 | 逻辑映射正确不等于实物顺序正确 | 单路电调/电机测试 |
| 电池比例未校准 | 参数来自设计计算 | 可调电源 + 电子负载校准 |

### 15.2 中优先级风险

- 板级模板注释和实际 MCU 名称存在历史遗留差异；
- `.px4board` 手工增删模块可能引用错误 Kconfig 符号；
- `/dev/ttySx` 与实际 UART 外设需要通过启动日志核实；
- 内部 I2C4 上拉、总线电容和地址冲突需要实测；
- SPI1 的 BMI088 SDO1/SDO2 共 MISO，片选时序需要验证；
- SD 卡、USB 和日志功能尚未在实物验证；
- 未验证 EMC、振动、热设计和供电瞬态。

### 15.3 已知设计决策

- PA3/U28.6 `IO1` 当前不编译为 PX4 GPIO；
- J7/PB10 不单独编译普通 GPIO，只作为 TIM2_CH3 PWM9；
- TX2/RX2 和 I2C1 都有板级焊盘，可以保留为外部接口；
- HSE 按 16 MHz 固定，不按旧 BOM 文本中的 24 MHz 处理。

---

## 16. 日常修改和提交命令

### 16.1 修改前检查

```powershell
Set-Location 'C:\Users\Administrator\Desktop\27plane\px4'
git status --short --branch
git log --oneline -5
```

看到 `.workbuddy/` 和 `extras/` 未跟踪是正常的，不要用 `git add .` 把它们误提交。

### 16.2 修改后检查空白和错误

```powershell
git diff --check
git diff --stat
```

### 16.3 精确暂存

```powershell
git add -- "boards/p224/p224-aio-v1/src/board_config.h"
git add -- ".codex/P224-AIO-V1.0-PX4完整工作流程报告.md"
```

一次只暂存与当前目的相关的文件。

### 16.4 提交

```powershell
git commit -m "Describe one clear change"
```

提交说明建议：

- 英文短句即可；
- 一个提交只做一件事；
- 修复构建错误时写清模块或根因；
- 文档和代码尽量分开。

### 16.5 推送并触发云构建

```powershell
git push myrepo codex/px4-1.16.2-custom
```

推送后：

1. 打开 GitHub 仓库的 Actions；
2. 选择 `Build custom PX4 firmware`；
3. 确认运行的 commit；
4. 检查应用和 bootloader 两个构建步骤；
5. 下载 artifact 并记录哈希。

### 16.6 查询本地和远端是否一致

```powershell
git status --short --branch
git rev-parse HEAD
git log --oneline -1 myrepo/codex/px4-1.16.2-custom
```

如果本地 HEAD 与远端提交不一致，不要根据旧 artifact 判断新源码。

---

## 17. 常见问题处理

### 17.1 Actions 变红，但本地没有编译过

先看失败步骤：

- `Validate PX4 build targets`：目标名或 `.px4board` 路径错误；
- `Build PX4 firmware in official NuttX container`：源码、Kconfig、C++ 或链接错误；
- `docker pull`：网络或镜像仓库问题；
- `upload-artifact`：产物路径或文件不存在。

不要只重复点击重跑；先定位日志中的第一个真实错误。

### 17.2 修改没有出现在云端

检查：

```powershell
git status --short
git log --oneline -1
git log --oneline -1 myrepo/codex/px4-1.16.2-custom
```

确认是否已 `commit` 和 `push`，以及 Actions 运行的 commit 是否一致。

### 17.3 目标找不到

检查目录和文件名：

```text
boards/p224/p224-aio-v1/default.px4board
```

对应目标必须是：

```text
p224_p224-aio-v1_default
```

不要凭记忆少写下划线或 `_default`。

### 17.4 本地源码是否应该删除重下

不建议。当前目录已有完整源码、子模块和 Git 历史。只有在工作树严重损坏、子模块无法恢复且已有可靠备份时，才考虑重新检出。删除目录会丢失未推送提交和本地板级工作。

### 17.5 artifact 过期怎么办

artifact 默认保留 14 天。若已过期：

- 在 GitHub Actions 对同一 commit 手动运行 `workflow_dispatch`；
- 确认工作流仍使用该 commit 对应的配置；
- 重新下载并核对哈希；
- 重要发布版本应另外保存到本地或 Release。

### 17.6 什么时候需要重新做硬件验证

以下任一变化后都应重新验证：

- 修改时钟、Flash、链接脚本或 bootloader；
- 修改 SPI/I2C/UART/PWM/ADC 引脚；
- 修改 Kconfig 驱动或模块；
- 升级 PX4 版本、容器镜像或工具链；
- 修改电调协议、电机映射或控制分配；
- 修改 PCB、器件型号、晶振或电源网络。

---

## 18. 下一步建议

### 阶段 A：准备实物烧录

1. 确认板卡已到货并完成基础供电检查；
2. 确认 SWD/DFU 进入方式；
3. 使用限流电源，不接电机和桨；
4. 备份芯片读保护和 option bytes 信息；
5. 只烧录 Run #9 的 P224 bootloader。

### 阶段 B：最小系统启动

1. 烧录应用程序 `.px4`；
2. 连接 USB/串口；
3. 查看启动日志；
4. 检查 board ID、Flash 和参数保存；
5. 处理 hardfault、watchdog、USB 或启动异常。

### 阶段 C：外设逐项点亮

顺序建议：

```text
电源 ADC
  -> RGB LED / 蜂鸣器
  -> SPI IMU
  -> I2C 磁力计/气压计
  -> SD 卡/日志
  -> 串口/GPS/RC
  -> 九路 PWM/DShot
  -> 电机和电调
```

每次只接入一个子系统，出现问题时容易定位。

### 阶段 D：固件和文档固化

- 把通过硬件验证的 commit 打标签；
- 把对应 artifact 和 SHA-256 固定在发布说明；
- 更新本报告中的“未验证”状态；
- 记录台架日志、波形和电源测量结果；
- 在完成首飞前审查后，再生成正式试飞固件。

---

## 19. 证据文件索引

### 19.1 项目中已有文档

- [README](./README.md)
- [PX4 1.16.2 GitHub 云编译教程](./PX4-1.16.2-GitHub云编译教程.md)
- [AIO V1.0 PX4 引脚映射](./27赛季无人机-AIO-V1.0-PX4引脚映射.md)
- [本报告](./P224-AIO-V1.0-PX4完整工作流程报告.md)

### 19.2 关键源码

- `boards/p224/p224-aio-v1/default.px4board`
- `boards/p224/p224-aio-v1/bootloader.px4board`
- `boards/p224/p224-aio-v1/firmware.prototype`
- `boards/p224/p224-aio-v1/src/hw_config.h`
- `boards/p224/p224-aio-v1/src/board_config.h`
- `boards/p224/p224-aio-v1/src/timer_config.cpp`
- `boards/p224/p224-aio-v1/src/spi.cpp`
- `boards/p224/p224-aio-v1/src/i2c.cpp`
- `boards/p224/p224-aio-v1/init/rc.board_defaults`
- `boards/p224/p224-aio-v1/init/rc.board_sensors`
- `boards/p224/p224-aio-v1/nuttx-config/include/board.h`
- `boards/p224/p224-aio-v1/nuttx-config/scripts/script.ld`
- `boards/p224/p224-aio-v1/nuttx-config/scripts/bootloader_script.ld`

### 19.3 云构建

- `.github/workflows/px4-custom-board.yml`
- `.codex/github-actions/px4-custom-board.yml`
- `.codex/scripts/check-cloud-build-setup.ps1`
- Run #9：`40862991259`
- `px4-artifacts\px4-custom-p224_p224-aio-v1_default-9\build-info.txt`

### 19.4 最终判断

当前已经完成“自制板 PX4 源码适配 + GitHub 云端应用/bootloader 构建 + 产物追溯”。

当前尚未完成“实物启动、传感器、电源、PWM/DShot、电机、整机安全验证”。

因此，下一阶段的正确目标不是继续盲目增加功能，而是：

```text
用 Run #9 产物完成最小系统烧录
-> 验证启动和基础外设
-> 逐项做硬件台架测试
-> 只有全部通过后才考虑飞行
```

---

*本报告依据本地源码、Git 提交、GitHub Actions Run #9 和本机已下载 artifact 整理。若后续源码或工作流发生变化，应以新的 commit、run number、`build-info.txt` 和 SHA-256 为准。*

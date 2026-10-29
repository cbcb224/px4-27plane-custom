# 27赛季无人机 AIO V1.0 PX4 引脚映射

> 整理日期：2026-10-29  
> 设计对象：嘉立创 EDA《27赛季无人机》— **AIO V1.0**  
> 主控：**STM32H743VIH6，TFBGA-100**  
> 用途：自制 PX4 飞控板的硬件引脚与 PX4 编译配置对照

## 0. 记录口径与已确认修订

本文区分以下三个概念：

- **PCB 有网络**：原理图/PCB 网表中存在连接。
- **焊盘已引出**：该网络在板级焊盘或连接器上可供外部使用。
- **PX4 已编译/未编译**：是否进入当前 PX4 板级配置。

已按用户确认修订：

| 项目 | 最终记录 |
|---|---|
| USART2 TX/RX | `TX2/RX2` **有板级焊盘引出** |
| I2C1 | `PB8/PB9` **有板级焊盘引出**，同时存在上拉 |
| PA3 通用 IO | U19.K2/PA3 → `IO1` → U28.6；**不编译** |
| U28.6 IO1 | 硬件网络存在，但**不编译为 PX4 通用 IO** |
| PB10 TIM2_CH3 | 定时器功能**编译为 PX4 PWM9**； |
| HSE 晶振 | 按设计确认：**16 MHz** |
| BMI088 MISO | U32.10 `SDO2` 与 U32.15 `SDO1` 同时连接 `SPI1-MISO` |

> “不编译”表示保留 PCB 硬件事实，但不把它作为当前 PX4 配置中的功能使用。

---

# 1. 核心器件

| 位号 | 器件 | 封装/作用 |
|---|---|---|
| U19 | STM32H743VIH6 | TFBGA-100 主控 MCU |
| U31 | ICM-42688-P | SPI2 六轴 IMU |
| U32 | BMI088 | SPI1 加速度计/陀螺仪 |
| U33 | IST8310 | I2C4 磁力计 |
| U34 | DPS310 | I2C4 气压计 |
| U21/U23/U25/U27 | QF32MTF4AK8U7 | 四路电机预驱/功率驱动 |
| U16 | TS2306A | BOOT0 按键 |
| U17 | TS2306A | NRST 按键 |
| D14 | PRTR5V0U2F,115 | USB ESD 保护 |
| CARD1 | TF-021B-H265 | microSD 卡座 |
| USB1 | Type-C 16P | USB 接口 |
| X1 | SMD2016-4P | 16 MHz HSE 晶振 |

---

# 2. U19 STM32H743VIH6 完整球位映射

> “无网络”仅表示 PCB 网络表为空，不等于芯片内部功能为 NC。

| 球位 | MCU 引脚 | 网络 | PX4/硬件备注 |
|---|---|---|---|
| A1 | PC14 | 无网络 |  |
| A2 | PC13 | 无网络 |  |
| A3 | PE2 | 无网络 |  |
| A4 | PB9 | `I2C1-SDA` | I2C1 已引出焊盘 |
| A5 | PB7 | `M6` |  |
| A6 | PB4 | `M5` |  |
| A7 | PB3 | `RX7` |  |
| A8 | PA15 | `TX7` |  |
| A9 | PA14 | `SWCLK` | SWD 测试点 |
| A10 | PA13 | `SWDIO` | SWD 测试点 |
| B1 | PC15 | 无网络 |  |
| B2 | VBAT | `3V3` |  |
| B3 | PE3 | 无网络 |  |
| B4 | PB8 | `I2C1-SCL` | I2C1 已引出焊盘 |
| B5 | PB6 | `M7` |  |
| B6 | PD5 | `TX2` | USART2 TX，有焊盘引出 |
| B7 | PD2 | `SDIO_CMD` |  |
| B8 | PC11 | `SDIO_D3` |  |
| B9 | PC10 | `SDIO_D2` |  |
| B10 | PA12 | `USB_DP` |  |
| C1 | PH0 | `OSC_IN` | 16 MHz HSE |
| C2 | VSS | `GND` |  |
| C3 | PE4 | 无网络 |  |
| C4 | PE1 | `TX8` |  |
| C5 | PB5 | `M8` |  |
| C6 | PD6 | `RX2` | USART2 RX，有焊盘引出 |
| C7 | PD3 | 无网络 |  |
| C8 | PC12 | `SDIO_CK` |  |
| C9 | PA9 | 无网络 |  |
| C10 | PA11 | `USB_DM` |  |
| D1 | PH1 | `OSC_OUT` | 16 MHz HSE |
| D2 | VDD | `3V3` |  |
| D3 | PE5 | 无网络 |  |
| D4 | PE0 | `RX8` |  |
| D5 | BOOT0 | `BOOT0` | U16 按键，R33 下拉 |
| D6 | PD7 | 无网络 |  |
| D7 | PD4 | 无网络 |  |
| D8 | PD0 | `RX4` |  |
| D9 | PA8 | 无网络 |  |
| D10 | PA10 | `CSB_GYRO` | BMI088 陀螺仪片选 |
| E1 | NRST | `NRST` | U17 按键 |
| E2 | PC2 | 无网络 |  |
| E3 | PE6 | 无网络 |  |
| E4 | VSS | `GND` |  |
| E5 | VSS | `GND` |  |
| E6 | VSS | `GND` |  |
| E7 | VCAP | `VCAP` | 与 F8 相连 |
| E8 | PD1 | `TX4` |  |
| E9 | PC9 | `SDIO_D1` |  |
| E10 | PC7 | `BEEP` | 经 R38 驱动 Q3 |
| F1 | PC0 | `LED-B` |  |
| F2 | PC1 | `LED-R` |  |
| F3 | PC3 | 无网络 |  |
| F4 | VDDLDO | `3V3` |  |
| F5 | VDD | `3V3` |  |
| F6 | 33USB | `3V3` |  |
| F7 | PDR_ON | `3V3` |  |
| F8 | VCAP | `VCAP` | 与 E7 相连 |
| F9 | PC8 | `SDIO_D0` |  |
| F10 | PC6 | 无网络 |  |
| G1 | VSSA | `GND` |  |
| G2 | PA0 | `LED-G` |  |
| G3 | PA4 | `ADC_V` | 经 R28/R29 分压测 VIN |
| G4 | PC4 | `ADC_C` | U15.1 电流检测输出 |
| G5 | PB2 | 无网络 |  |
| G6 | PE10 | 无网络 |  |
| G7 | PE14 | `M4` |  |
| G8 | PD15 | `CS-42688` | ICM-42688 片选 |
| G9 | PD11 | 无网络 |  |
| G10 | PB15 | `SPI2-MOSI` |  |
| H1 | VDDA | `3V3` |  |
| H2 | PA1 | 无网络 |  |
| H3 | PA5 | `SPI1-SCK` | BMI088 |
| H4 | PC5 | 无网络 |  |
| H5 | PE7 | 无网络 |  |
| H6 | PE11 | `M3` |  |
| H7 | PE15 | 无网络 |  |
| H8 | PD14 | 无网络 |  |
| H9 | PD10 | 无网络 |  |
| H10 | PB14 | `SPI2-MISO` | ICM-42688 |
| J1 | VSS | `GND` |  |
| J2 | PA2 | `CSB_ACCEL` | BMI088 加速度计片选 |
| J3 | PA6 | `SPI1-MISO` | 同时连接 BMI088 SDO1/SDO2 |
| J4 | PB0 | 无网络 |  |
| J5 | PE8 | 无网络 |  |
| J6 | PE12 | 无网络 |  |
| J7 | PB10 | `TIM2-CH3` | 编译为 PX4 PWM9；不单独编译为普通 GPIO |
| J8 | PB13 | `SPI2-SCK` | ICM-42688 |
| J9 | PD9 | 无网络 |  |
| J10 | PD13 | `I2C4-SDA` |  |
| K1 | VDD | `3V3` |  |
| K2 | PA3 | `IO1` | 连接 U28.6；不编译 |
| K3 | PA7 | `SPI1-MOSI` | BMI088 |
| K4 | PB1 | 无网络 |  |
| K5 | PE9 | `M1` |  |
| K6 | PE13 | `M2` |  |
| K7 | PB11 | 无网络 |  |
| K8 | PB12 | 无网络 |  |
| K9 | PD8 | 无网络 |  |
| K10 | PD12 | `I2C4-SCL` |  |

---

# 3. 通信接口

## 3.1 串口

| PX4 信号 | MCU 球位/引脚 | 网络 | 端点 |
|---|---|---|---|
| UART8_TX | C4/PE1 | `TX8` | CN6.2 |
| UART8_RX | D4/PE0 | `RX8` | CN6.3 |
| UART7_TX | A8/PA15 | `TX7` | U30.2 |
| UART7_RX | A7/PB3 | `RX7` | U30.1 |
| USART2_TX | B6/PD5 | `TX2` | **板级焊盘已引出** |
| USART2_RX | C6/PD6 | `RX2` | **板级焊盘已引出** |
| UART4_TX | E8/PD1 | `TX4` | U29.3 |
| UART4_RX | D8/PD0 | `RX4` | U29.4 |

## 3.2 SPI

| 接口 | SCK | MISO | MOSI | CS |
|---|---|---|---|---|
| SPI1/BMI088 | H3/PA5 | J3/PA6 | K3/PA7 | J2/PA2=`CSB_ACCEL`；D10/PA10=`CSB_GYRO` |
| SPI2/ICM-42688-P | J8/PB13 | H10/PB14 | G10/PB15 | G8/PD15=`CS-42688` |

### BMI088 共用 MISO 说明

```text
BMI088 U32.10 SDO2 ─┐
                    ├─ SPI1-MISO ─ U19.J3/PA6
BMI088 U32.15 SDO1 ─┘
```

BMI088 的加速度计和陀螺仪共用 SPI1 的 MISO，但使用独立片选：

- `CSB_ACCEL` 选中加速度计时，由 `SDO1` 驱动 MISO。
- `CSB_GYRO` 选中陀螺仪时，由 `SDO2` 驱动 MISO。
- 同一时刻只能选中一个器件，避免两个输出同时驱动总线。

## 3.3 I2C

| 接口 | SCL | SDA | 端点 |
|---|---|---|---|
| I2C4 | K10/PD12 | J10/PD13 | IST8310、DPS310 |
| I2C1 | B4/PB8 | A4/PB9 | 有焊盘引出，并有 R35/R36 上拉到 `3V3` |

## 3.4 SDIO/microSD

| SDIO 信号 | MCU | CARD1 |
|---|---|---|
| CMD | B7/PD2 | CARD1.3 |
| CK | C8/PC12 | CARD1.5 |
| D0 | F9/PC8 | CARD1.7 |
| D1 | E9/PC9 | CARD1.8 |
| D2 | B9/PC10 | CARD1.1 |
| D3 | B8/PC11 | CARD1.2 |

## 3.5 USB

```text
USB_DP：U19.B10/PA12 → D14.3
D14.4 → USB1.A6/B6

USB_DM：U19.C10/PA11 → D14.1
D14.6 → USB1.A7/B7
```

USB ESD：D14 `PRTR5V0U2F,115`。

## 3.6 SWD

```text
SWCLK：U19.A9/PA14 → TP9.1
SWDIO：U19.A10/PA13 → TP10.1
```

当前为测试点形式，未发现标准 SWD 排针。

---

# 4. PWM、GPIO、ADC 与指示功能

## 4.1 电机 PWM

| 通道 | MCU 球位/引脚 | 网络 | 驱动 |
|---|---|---|---|
| M1 | K5/PE9 | `M1` | U21.6 |
| M2 | K6/PE13 | `M2` | U23.6 |
| M3 | H6/PE11 | `M3` | U25.6 |
| M4 | G7/PE14 | `M4` | U27.6 |
| PWM9 | J7/PB10 | `TIM2-CH3` | PX4 定时器 PWM 输出 |

PB10 的当前编译规则：

- 定时器功能：**TIM2_CH3 → PX4 PWM9，编译启用**。
- 普通 GPIO/J7 功能：**不单独编译**。

## 4.2 其他 GPIO 与 ADC

| 功能 | MCU 球位/引脚 | 网络 | 编译状态 |
|---|---|---|---|
| RGB 绿灯 | G2/PA0 | `LED-G` | 按板级 LED 配置 |
| RGB 红灯 | F2/PC1 | `LED-R` | 按板级 LED 配置 |
| RGB 蓝灯 | F1/PC0 | `LED-B` | 按板级 LED 配置 |
| 电压检测 | G3/PA4 | `ADC_V` | ADC |
| 电流检测 | G4/PC4 | `ADC_C` | ADC |
| 蜂鸣器 | E10/PC7 | `BEEP` | 经 R38 驱动 Q3 |
| 通用 IO 1 | K2/PA3 | `IO1` | **不编译** |
| U28.6 | K2/PA3 | `IO1` | **不编译为通用 IO** |
| BOOT0 | D5/BOOT0 | `BOOT0` | U16 按下接 `3V3`，R33 下拉 |
| 复位 | E1/NRST | `NRST` | U17 按下接 `GND` |

---

# 5. 板载连接器

| 位号 | 型号/封装 | 引脚映射 |
|---|---|---|
| U29 | HC-PZ254-13.8L-1x4PWA | 1=`5V_P`，2=`GND`，3=`TX4`，4=`RX4` |
| U30 | WAFER-GH1.25-4PWB | 1=`RX7`，2=`TX7`，3=`GND`，4=`5V_P`；5=`GND`，6=空 |
| U28 | WAFER-GH1.25-6PWB | 1=`M5`，2=`M6`，3=`M7`，4=`M8`，5=`GND`，6=`IO1`（不编译）；7=`GND`，8=空 |
| CN6 | WAFER-GH1.25-3PWB | 1=`GND`，2=`TX8`，3=`RX8`；4=`5V_P`，5=`GND` |
| CARD1 | TF-021B-H265 | 1=DAT2，2=DAT3，3=CMD，4=`3V3`，5=CK，6=GND，7=DAT0，8=DAT1，9/10=GND |
| USB1 | Type-C 16P | VBUS、GND、CC1、CC2、D+、D−；SBU 未连接 |
| X1 | SMD2016-4P | 1=`OSC_OUT`，2=GND，3=`OSC_IN`，4=GND，16 MHz |

---

# 6. 传感器接口

## 6.1 U31 ICM-42688-P

| 引脚 | 名称 | 网络/说明 |
|---|---|---|
| 1 | AP_SDO/AP_AD0 | `SPI2-MISO` → U19.H10 |
| 2、3 | RESV | GND |
| 4 | INT1/INT | PCB 无网络 |
| 5 | VDDIO | `3V3_SENS` |
| 6 | GND | GND |
| 7 | RESV | GND |
| 8 | VDD | `3V3_SENS` |
| 9 | INT2/FSYNC/CLKIN | GND |
| 10、11 | RESV | GND |
| 12 | AP_CS | `CS-42688` → U19.G8 |
| 13 | AP_SCLK | `SPI2-SCK` → U19.J8 |
| 14 | AP_SDI | `SPI2-MOSI` → U19.G10 |

## 6.2 U32 BMI088

| 引脚 | 名称 | 网络 |
|---|---|---|
| 1 | INT2 | 无网络 |
| 2 | NC | GND |
| 3 | VDD | `3V3_SENS` |
| 4 | GNDA | GND |
| 5 | CSB2/陀螺仪 | `CSB_GYRO` → U19.D10 |
| 6 | GNDIO | GND |
| 7 | PS | GND，SPI 模式 |
| 8 | SCL/SCK | `SPI1-SCK` → U19.H3 |
| 9 | SDA/SDI | `SPI1-MOSI` → U19.K3 |
| 10 | SDO2 | `SPI1-MISO` → U19.J3 |
| 11 | VDDIO | `3V3_SENS` |
| 12、13 | INT3/INT4 | 无网络 |
| 14 | CSB1/加速度计 | `CSB_ACCEL` → U19.J2 |
| 15 | SDO1 | `SPI1-MISO` → U19.J3 |
| 16 | INT1 | 无网络 |

## 6.3 U33 IST8310

| 引脚 | 名称 | 网络/说明 |
|---|---|---|
| 1 | SCL | `I2C4-SCL` → U19.K10 |
| 2 | AVDD | `3V3_SENS` |
| 3、4 | NC | NC |
| 5 | CAD0 | PCB 无网络 |
| 6 | CAD1 | PCB 无网络 |
| 7 | VPP | PCB 无网络 |
| 8 | NC | NC |
| 9 | VSS | GND |
| 10 | C1 | C118.1 |
| 11 | VSS | GND |
| 12 | NC | NC |
| 13 | DVDD | `3V3_SENS` |
| 14 | RSTN | PCB 无网络 |
| 15 | DRDY | PCB 无网络 |
| 16 | SDA | `I2C4-SDA` → U19.J10 |

## 6.4 U34 DPS310

| 引脚 | 名称 | 网络/说明 |
|---|---|---|
| 1 | GND | GND |
| 2 | CSB | 经 `$8N139`、R105 连 `3V3_SENS` |
| 3 | SDI | `I2C4-SDA` |
| 4 | SCK | `I2C4-SCL` |
| 5 | SDO | GND，确定 I2C 地址 |
| 6 | VDDIO | `3V3_SENS` |
| 7 | GND | GND |
| 8 | VDD | `3V3_SENS` |

---

# 7. 四路电机驱动 QF32MTF4AK8U7

| 驱动 | PWM 网络 | 网络后缀 |
|---|---|---|
| U21 | `M1` | `_1` |
| U23 | `M2` | `_2` |
| U25 | `M3` | `_3` |
| U27 | `M4` | `_4` |

下表中 `n` 为 1～4：

| 引脚 | 名称 | 网络/功能 |
|---|---|---|
| 1 | VB1 | `VBOOTU_n` |
| 2 | Driver_VCC | `10V` |
| 3 | NC | PCB 无网络 |
| 4 | SWD/PA13 | `DIO_n` |
| 5 | SWC/PA14 | `CLK_n` |
| 6 | PB4/PWM | `M1`～`M4`，连接 MCU |
| 7 | PB7 | 无网络 |
| 8 | PB6 | 无网络 |
| 9 | VCCIO | `3V3` |
| 10 | PB15 | 无网络 |
| 11 | PF0 | 无网络 |
| 12 | PF1 | 无网络 |
| 13 | NRST | 私有复位网络 `$nN172`，经电阻/电容 |
| 14 | VCCA | `3V3` |
| 15 | PA0 | `FU_n` |
| 16 | PA1 | `C_n` |
| 17 | PA2 | 无网络 |
| 18 | PA3 | 无网络 |
| 19 | PA4 | `FV_n` |
| 20 | PA5 | `FW_n` |
| 21 | PA6 | 无网络 |
| 22 | LO1 | `LU_n`，经电阻网络 |
| 23 | LO2 | `LV_n`，经电阻网络 |
| 24 | LO3 | `LW_n`，经电阻网络 |
| 25 | VS3 | `OUTW_n` |
| 26 | HO3 | `HW_n`，经电阻网络 |
| 27 | VB3 | `VBOOTW_n` |
| 28 | VS2 | `OUTV_n` |
| 29 | HO2 | `HV_n`，经电阻 |
| 30 | VB2 | `VBOOTV_n` |
| 31 | VS1 | `OUTU_n` |
| 32 | HO1 | `HU_n`，经电阻 |
| 33 | EP | GND |

三相功率网络：`OUTU_n`、`OUTV_n`、`OUTW_n`，连接对应功率 MOSFET。

---

# 8. 当前没有 PCB 网络的 33 个 MCU 球位

```text
A1 PC14   A2 PC13   A3 PE2
B1 PC15   B3 PE3
C3 PE4    C7 PD3    C9 PA9
D3 PE5    D6 PD7    D7 PD4
D9 PA8
E2 PC2    E3 PE6
F3 PC3    F10 PC6
G5 PB2    G6 PE10   G9 PD11
H2 PA1    H4 PC5    H5 PE7
H7 PE15   H8 PD14   H9 PD10
J4 PB0    J5 PE8    J6 PE12
J9 PD9
K4 PB1    K7 PB11   K8 PB12
K9 PD8
```

这些仅表示 PCB 网络为空，不能直接断言芯片功能为 NC。

---

# 9. 电源、地与晶振

```text
MCU 3V3：
B2 VBAT、D2 VDD、F4 VDDLDO、F5 VDD、
F6 33USB、F7 PDR_ON、H1 VDDA、K1 VDD

MCU GND：
C2、E4、E5、E6、G1、J1

VCAP：
E7 ↔ F8

HSE：
X1.3 OSC_IN  ↔ U19.C1/PH0
X1.1 OSC_OUT ↔ U19.D1/PH1
X1.2、X1.4 → GND
频率：16 MHz
```

> 工程器件记录中曾出现 `XL7EL89CKI-111YLC-24M` 料号文本；当前 PX4 配置以用户确认的 **16 MHz** 为准。正式备料时仍建议复核 BOM 料号，避免贴错晶振。

---

# 10. 当前需要保留的硬件注意事项

1. **TX2/RX2、I2C1 都有板级焊盘引出。**
   - 不能再用“PCB 上只有 MCU 端”描述这些网络。

2. **PA3/IO1 不进入当前 PX4 编译配置。**
   - 对应的物理网络是 `U19.K2/PA3 → IO1 → U28.6`。
   - 硬件仍存在，后续可以改配置重新启用。

3. **PB10 只按定时器 PWM9 使用。**
   - 定时器功能编译为 PWM9。
   - 不额外编译 J7/PB10 的普通 GPIO 功能。

4. **BMI088 的 SDO1/SDO2 共用 SPI1 MISO。**
   - 通过独立片选避免同时驱动。
   - 板级配置中应保持两个 CS 独立。

5. **所有传感器中断脚目前未连接到 MCU。**
   - ICM-42688 INT1 无网络，INT2 接 GND。
   - BMI088 INT1～INT4 未连接 MCU。
   - IST8310 DRDY 无网络。
   - 如果 PX4 驱动需要数据就绪中断，应改板或采用轮询配置。

## 11. PX4 编译决策速查

| 功能 | 硬件网络 | 当前 PX4 处理 |
|---|---|---|
| USART2 TX/RX | `TX2/RX2` | 保留，焊盘已引出 |
| I2C1 SCL/SDA | `I2C1-SCL/SDA` | 保留，焊盘已引出 |
| IO1 / U28.6 | `IO1` | 不编译 |
| PA3 通用 IO | `IO1` | 不编译 |
| TIM2_CH3 | `TIM2-CH3` | 编译为 PWM9 |
| J7/PB10 普通 GPIO | `TIM2-CH3` | 不单独编译 |
| HSE | X1 | 16 MHz |

---

*本文件根据 AIO V1.0 工程只读引脚信息及用户确认的 PX4 编译决策整理。*

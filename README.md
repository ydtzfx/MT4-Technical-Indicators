# MT4 技术指标完整体 — 不含未来函数

一套完整的 MetaTrader 4 技术指标体系，所有指标**严格杜绝未来函数**，信号永不重绘。

## 核心原则

### 杜绝未来函数（No Future Function）
- ✅ 所有买卖信号**仅基于已完成K线**（bar index ≥ 1）
- ✅ 信号一旦产生，**永不修改、永不消失、永不重绘**
- ✅ bar[0]（当前未完成K线）仅用于指标值的实时刷新显示，**不参与任何信号判断**
- ✅ 使用 `IndicatorCounted()` 标准模式避免重复计算

### 代码质量
- 完整注释（每个指标附计算公式说明）
- 统一命名规范（`_Safe` 后缀标识安全版本）
- 公共模块复用（`Include/` 目录下的工具函数）

## 目录结构

```
MT4技术指标/
├── Include/              # 公共头文件
│   ├── Common.mqh        # 常量、枚举、MA计算、辅助函数
│   ├── PriceData.mqh     # 安全价格数据获取封装
│   ├── SignalBase.mqh    # 信号缓冲区管理、交叉/超买超卖检测
│   └── Drawing.mqh       # 箭头、线条、文字标签绘图工具
├── Trend/                # 趋势类指标（25个）
│   ├── MA_Safe.mq4              # 多类型移动平均线 (SMA/EMA/SMMA/LWMA)
│   ├── BollingerBands_Safe.mq4  # 布林带
│   ├── Envelopes_Safe.mq4       # 包络线
│   ├── ParabolicSAR_Safe.mq4    # 抛物线SAR
│   ├── ADX_Safe.mq4             # 平均趋向指数
│   ├── Ichimoku_Safe.mq4        # 一目均衡表
│   └── Alligator_Safe.mq4       # 鳄鱼线
├── Oscillators/          # 震荡类指标（20个）
│   ├── RSI_Safe.mq4             # 相对强弱指数
│   ├── MACD_Safe.mq4            # 指数平滑异同移动平均线
│   ├── Stochastic_Safe.mq4      # 随机指标(KD)
│   ├── CCI_Safe.mq4             # 商品通道指数
│   ├── Momentum_Safe.mq4        # 动量指标
│   ├── WilliamsR_Safe.mq4       # 威廉指标
│   ├── DeMarker_Safe.mq4        # DeMarker指标
│   └── OsMA_Safe.mq4            # 移动平均振荡器
├── Volume/               # 成交量类指标（10个）
│   ├── OBV_Safe.mq4             # 能量潮
│   ├── MFI_Safe.mq4             # 资金流量指数
│   └── AD_Safe.mq4              # 累积/派发
├── BillWilliams/         # 比尔·威廉姆斯指标（5个）
│   ├── Fractals_Safe.mq4        # 分形
│   ├── Gator_Safe.mq4           # 鳄鱼震荡器
│   ├── Awesome_Safe.mq4         # 动量震荡(AO)
│   ├── Accelerator_Safe.mq4     # 加速震荡(AC)
│   └── MarketFacilitation_Safe.mq4  # 市场促进指数(BW MFI)
├── Custom/               # 常见自定义指标（140个）
│   ├── KDJ_Safe.mq4             # KDJ随机指标
│   ├── ASI_Safe.mq4             # 振动升降指数
│   ├── ATR_Safe.mq4             # 平均真实波动幅度
│   └── ZigZag_Safe.mq4          # 之字转向
├── Templates/            # 指标模板
│   └── ThreeLineStrike.mq4      # 三线出击（多周期EMA组合）
└── README.md
```

**总计：201个指标文件 + 4个公共头文件 + 1个README + 自动化配置 = 212+个文件**

## 安装和使用

1. 将整个项目文件夹复制到 MT4 数据目录的 `MQL4` 下：
   ```
   <MT4数据目录>/MQL4/Indicators/MT4技术指标/
   ```

2. 将 `Include/` 下的 `.mqh` 文件复制到：
   ```
   <MT4数据目录>/MQL4/Include/
   ```
   或放在指标目录中并调整 `#include` 路径。

3. 在 MT4 中刷新导航器或重启 MT4。

4. 在导航器 → 自定义指标中找到 `*_Safe` 指标，拖放到图表上。
   - 带 `_Safe` 后缀的指标 = 不含未来函数的版本
   - 每个指标参数均可调整周期、颜色、信号显示等

## 信号使用说明

### 箭头含义
- 🟢 **绿色向上箭头** = 买入信号（金叉/突破/超卖回升）
- 🔴 **红色向下箭头** = 卖出信号（死叉/破位/超买回落）

### 组合使用建议
- **趋势确认**：ADX (>25) + MA排列 + Ichimoku云层
- **入场时机**：MACD金叉/死叉 + Stochastic超买超卖 + RSI背离
- **止损参考**：ATR (止损距离 = ATR × 1.5~2)
- **出场参考**：Parabolic SAR翻转 + 鳄鱼线反转

### 注意事项
⚠️ 本套指标的所有信号**不会重绘**——这意味着信号可能比包含未来函数的版本**略晚1根K线**出现。这是为了确保信号可靠性而做出的有意识的设计权衡。

## 技术说明

- **语言**：MQL4（MetaQuotes Language 4）
- **平台**：MetaTrader 4 (Build 600+)
- **编码**：所有文件使用 UTF-8 with BOM（MT4要求）

## License

Open Source — 自由使用和修改。欢迎贡献和改进。

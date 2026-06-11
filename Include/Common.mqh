//+------------------------------------------------------------------+
//|                                                  Common.mqh       |
//|  通用常量、枚举、辅助函数                                          |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"

#ifndef _COMMON_MQH_
#define _COMMON_MQH_

//+------------------------------------------------------------------+
//| 版本信息                                                          |
//+------------------------------------------------------------------+
#define PROJECT_NAME       "MT4 Safe Indicators"
#define PROJECT_VERSION    "1.00"

//+------------------------------------------------------------------+
//| 操作模式枚举                                                      |
//+------------------------------------------------------------------+
// 信号模式：严格模式禁止使用 bar[0] 做信号判断
enum ENUM_SIGNAL_MODE
{
   SIGNAL_MODE_STRICT = 0,   // 严格模式：信号仅在 bar[1]+ 产生，绝不重绘
   SIGNAL_MODE_DISPLAY = 1   // 显示模式：允许 bar[0] 仅用于当前值刷新
};

//+------------------------------------------------------------------+
//| 移动平均类型枚举                                                  |
//+------------------------------------------------------------------+
enum ENUM_MA_METHOD_SAFE
{
   MA_SMA = 0,  // Simple Moving Average
   MA_EMA = 1,  // Exponential Moving Average
   MA_SMMA = 2, // Smoothed Moving Average
   MA_LWMA = 3  // Linear Weighted Moving Average
};

//+------------------------------------------------------------------+
//| 价格类型枚举                                                      |
//+------------------------------------------------------------------+
enum ENUM_PRICE_SAFE
{
   PRICE_CLOSE = 0,
   PRICE_OPEN  = 1,
   PRICE_HIGH  = 2,
   PRICE_LOW   = 3,
   PRICE_MEDIAN = 4,      // (High + Low) / 2
   PRICE_TYPICAL = 5,     // (High + Low + Close) / 3
   PRICE_WEIGHTED = 6     // (High + Low + Close + Close) / 4
};

//+------------------------------------------------------------------+
//| 信号方向枚举                                                      |
//+------------------------------------------------------------------+
enum ENUM_TRADE_SIGNAL
{
   SIGNAL_NONE = 0,     // 无信号
   SIGNAL_BUY = 1,      // 买入信号
   SIGNAL_SELL = -1     // 卖出信号
};

//+------------------------------------------------------------------+
//| 趋势方向枚举                                                      |
//+------------------------------------------------------------------+
enum ENUM_TREND_DIRECTION
{
   TREND_NONE = 0,
   TREND_UP = 1,
   TREND_DOWN = -1,
   TREND_SIDEWAYS = 2
};

//+------------------------------------------------------------------+
//| 颜色常量                                                          |
//+------------------------------------------------------------------+
#define CLR_BUY_SIGNAL      clrLime          // 买入信号颜色
#define CLR_SELL_SIGNAL     clrRed           // 卖出信号颜色
#define CLR_UP_TREND        clrDodgerBlue    // 上升趋势颜色
#define CLR_DOWN_TREND      clrOrangeRed     // 下降趋势颜色
#define CLR_NEUTRAL_LINE    clrGray          // 中性线颜色
#define CLR_BULLISH_BAR     clrLimeGreen     // 多头K线
#define CLR_BEARISH_BAR     clrTomato        // 空头K线
#define CLR_UPPER_BAND      clrRoyalBlue     // 上轨颜色
#define CLR_LOWER_BAND      clrRoyalBlue     // 下轨颜色
#define CLR_MIDDLE_BAND     clrOrange        // 中轨颜色

//+------------------------------------------------------------------+
//| 绘图常量                                                          |
//+------------------------------------------------------------------+
#define ARROW_BUY           233              // 向上箭头 Wingdings 码
#define ARROW_SELL          234              // 向下箭头 Wingdings 码
#define ARROW_UP            241              // 上箭头
#define ARROW_DOWN          242              // 下箭头
#define ARROW_DOT           159              // 圆点
#define ARROW_STOP           251              // 方块

#define OBJ_PREFIX          "SAFE_"           // 图形对象名前缀，避免冲突

//+------------------------------------------------------------------+
//| 辅助函数：检查是否为新的K线                                       |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, _Period, 0);

   if(currentBarTime != lastBarTime)
   {
      lastBarTime = currentBarTime;
      return(true);
   }
   return(false);
}

//+------------------------------------------------------------------+
//| 辅助函数：获取价格（根据价格类型枚举）                              |
//+------------------------------------------------------------------+
double GetPriceByType(int shift, ENUM_PRICE_SAFE priceType)
{
   switch(priceType)
   {
      case PRICE_CLOSE:    return(iClose(_Symbol, _Period, shift));
      case PRICE_OPEN:     return(iOpen(_Symbol, _Period, shift));
      case PRICE_HIGH:     return(iHigh(_Symbol, _Period, shift));
      case PRICE_LOW:      return(iLow(_Symbol, _Period, shift));
      case PRICE_MEDIAN:   return((iHigh(_Symbol, _Period, shift) + iLow(_Symbol, _Period, shift)) / 2.0);
      case PRICE_TYPICAL:  return((iHigh(_Symbol, _Period, shift) + iLow(_Symbol, _Period, shift) + iClose(_Symbol, _Period, shift)) / 3.0);
      case PRICE_WEIGHTED: return((iHigh(_Symbol, _Period, shift) + iLow(_Symbol, _Period, shift) + iClose(_Symbol, _Period, shift) * 2.0) / 4.0);
      default:             return(iClose(_Symbol, _Period, shift));
   }
}

//+------------------------------------------------------------------+
//| 辅助函数：计算MA值（手动实现，避免依赖iMA）                        |
//+------------------------------------------------------------------+
double CalculateMA(double &prices[], int period, ENUM_MA_METHOD_SAFE method, int shift)
{
   if(period <= 0) return(0.0);

   double result = 0.0;

   switch(method)
   {
      case MA_SMA:
      {
         double sum = 0.0;
         for(int i = shift; i < shift + period; i++)
            sum += prices[i];
         result = sum / period;
         break;
      }
      case MA_EMA:
      {
         // EMA 从当前 shift 往前递推
         // 初始 SMA 作为种子
         double ema = 0.0;
         int startIdx = shift + period;
         for(int i = startIdx; i >= shift; i--)
         {
            if(i == startIdx)
            {
               // 计算初始SMA
               double initSum = 0.0;
               for(int j = i; j < i + period; j++)
                  initSum += prices[j];
               ema = initSum / period;
            }
            else
            {
               double alpha = 2.0 / (period + 1.0);
               ema = prices[i] * alpha + ema * (1.0 - alpha);
            }
         }
         result = ema;
         break;
      }
      case MA_SMMA:
      {
         // SMMA = 对EMA进行再次平滑
         double smma = 0.0;
         int startIdx = shift + period;
         for(int i = startIdx; i >= shift; i--)
         {
            if(i == startIdx)
            {
               double initSum = 0.0;
               for(int j = i; j < i + period; j++)
                  initSum += prices[j];
               smma = initSum / period;
            }
            else
            {
               // SMMA: 新值 * (1/period) + 前值 * ((period-1)/period)
               smma = (prices[i] + smma * (period - 1.0)) / period;
            }
         }
         result = smma;
         break;
      }
      case MA_LWMA:
      {
         double lwmaSum = 0.0;
         double weightSum = 0.0;
         int weight = 1;
         for(int i = shift + period - 1; i >= shift; i--)
         {
            lwmaSum += prices[i] * weight;
            weightSum += weight;
            weight++;
         }
         result = (weightSum != 0) ? lwmaSum / weightSum : 0.0;
         break;
      }
      default:
         result = 0.0;
   }

   return(result);
}

//+------------------------------------------------------------------+
//| 辅助函数：安全除法（避免除以零）                                    |
//+------------------------------------------------------------------+
double SafeDivide(double numerator, double denominator, double defaultValue = 0.0)
{
   if(MathAbs(denominator) < 0.00000001)
      return(defaultValue);
   return(numerator / denominator);
}

//+------------------------------------------------------------------+
//| 信号强度枚举                                                      |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_STRENGTH
{
   SIGNAL_WEAK   = 0,  // 弱信号：单一条件触发
   SIGNAL_MEDIUM = 1,  // 中等信号：2个条件同时触发
   SIGNAL_STRONG = 2   // 强信号：3+条件同时触发，或关键交叉+排列确认
};

//+------------------------------------------------------------------+
//| 警报类型枚举                                                      |
//+------------------------------------------------------------------+
enum ENUM_ALERT_TYPE
{
   ALERT_NONE    = 0,  // 无警报
   ALERT_ON_BAR  = 1,  // K线完成时警报
   ALERT_REALTIME = 2  // 实时警报（谨慎使用，bar[1]确认）
};

//+------------------------------------------------------------------+
//| K线形态枚举                                                        |
//+------------------------------------------------------------------+
enum ENUM_CANDLE_PATTERN
{
   PATTERN_NONE       = 0,
   PATTERN_DOJI       = 1,   // 十字星
   PATTERN_HAMMER     = 2,   // 锤子线
   PATTERN_SHOOTING   = 3,   // 射击之星
   PATTERN_ENGULFING_BULL = 4, // 看涨吞没
   PATTERN_ENGULFING_BEAR = 5, // 看跌吞没
   PATTERN_MORNING_STAR  = 6, // 晨星
   PATTERN_EVENING_STAR  = 7, // 暮星
   PATTERN_THREE_WHITE   = 8, // 三白兵
   PATTERN_THREE_BLACK   = 9  // 三黑鸦
};

//+------------------------------------------------------------------+
//| 调试日志宏（编译时可通过 #define DEBUG_MODE 开启）                  |
//+------------------------------------------------------------------+
#ifdef DEBUG_MODE
   #define DEBUG_LOG(msg) Print("[DEBUG] ", msg)
   #define DEBUG_LOG2(msg, val) Print("[DEBUG] ", msg, " = ", val)
#else
   #define DEBUG_LOG(msg)      // 空操作
   #define DEBUG_LOG2(msg, val) // 空操作
#endif

//+------------------------------------------------------------------+
//| 辅助函数：计算ATR止损参考                                          |
//+------------------------------------------------------------------+
double CalcATRStopLoss(int period, double multiplier = 1.5)
{
   double trSum = 0.0;
   for(int i = 1; i <= period; i++)
   {
      double h = iHigh(_Symbol, _Period, i);
      double l = iLow(_Symbol, _Period, i);
      double pc = iClose(_Symbol, _Period, i + 1);
      double tr = MathMax(h - l, MathMax(MathAbs(h - pc), MathAbs(l - pc)));
      trSum += tr;
   }
   return(trSum / period * multiplier);
}

//+------------------------------------------------------------------+
//| 辅助函数：判断K线形态                                              |
//+------------------------------------------------------------------+
ENUM_CANDLE_PATTERN DetectCandlePattern(int shift)
{
   int s = (shift < 1) ? 1 : shift;

   double open  = iOpen(_Symbol, _Period, s);
   double close = iClose(_Symbol, _Period, s);
   double high  = iHigh(_Symbol, _Period, s);
   double low   = iLow(_Symbol, _Period, s);
   double body  = MathAbs(close - open);
   double range = high - low;
   double upperWick = high - MathMax(open, close);
   double lowerWick = MathMin(open, close) - low;

   // 前一根K线数据
   double prevOpen  = iOpen(_Symbol, _Period, s + 1);
   double prevClose = iClose(_Symbol, _Period, s + 1);
   double prevHigh  = iHigh(_Symbol, _Period, s + 1);
   double prevLow   = iLow(_Symbol, _Period, s + 1);
   double prevBody  = MathAbs(prevClose - prevOpen);

   if(range < _Point) return(PATTERN_NONE);

   // 十字星：实体极小
   if(body < range * 0.1)
      return(PATTERN_DOJI);

   // 锤子线：下影线长，实体在顶部，处于下跌趋势中
   if(lowerWick > body * 2 && upperWick < body * 0.5 &&
      close < iClose(_Symbol, _Period, s + 3))
      return(PATTERN_HAMMER);

   // 射击之星：上影线长，实体在底部，处于上涨趋势中
   if(upperWick > body * 2 && lowerWick < body * 0.5 &&
      close > iClose(_Symbol, _Period, s + 3))
      return(PATTERN_SHOOTING);

   // 看涨吞没
   if(close > open && prevClose < prevOpen &&
      close > prevOpen && open < prevClose)
      return(PATTERN_ENGULFING_BULL);

   // 看跌吞没
   if(close < open && prevClose > prevOpen &&
      close < prevOpen && open > prevClose)
      return(PATTERN_ENGULFING_BEAR);

   return(PATTERN_NONE);
}

//+------------------------------------------------------------------+
//| 辅助函数：获取信号强度的文字描述                                    |
//+------------------------------------------------------------------+
string SignalStrengthToString(ENUM_SIGNAL_STRENGTH strength)
{
   switch(strength)
   {
      case SIGNAL_WEAK:   return("WEAK");
      case SIGNAL_MEDIUM: return("MEDIUM");
      case SIGNAL_STRONG: return("STRONG");
      default:            return("NONE");
   }
}

//+------------------------------------------------------------------+
//| 报警模块 — Alert Module                                           |
//+------------------------------------------------------------------+
datetime g_lastAlertTime = 0; // 全局上次报警时间，避免重复

// 发送报警（支持声音+推送+邮件）
void SendAlertMessage(string indicatorName, string signalType, string message, ENUM_ALERT_TYPE alertType=ALERT_ON_BAR)
{
   if(alertType == ALERT_NONE) return;
   if(alertType == ALERT_ON_BAR && !IsNewBar()) return;
   if(alertType == ALERT_REALTIME && TimeCurrent() - g_lastAlertTime < 10) return; // 10秒内不重复

   string fullMsg = indicatorName + ": " + signalType + " — " + message + " @ " + TimeToStr(TimeCurrent());

   // 终端报警
   Alert(fullMsg);

   // 声音报警（需要sound文件在MT4目录下）
   if(signalType == "BUY") PlaySound("news.wav");
   else if(signalType == "SELL") PlaySound("alert2.wav");
   else PlaySound("tick.wav");

   // 推送通知（需要MT4设置中开启推送）
   SendNotification(fullMsg);

   g_lastAlertTime = TimeCurrent();
}

// 简化报警：买入
void AlertBuy(string indicator, double price, string reason="") {
   SendAlertMessage(indicator, "BUY", Symbol() + " BUY@" + DoubleToStr(price,Digits) + (reason!=""?" ["+reason+"]":""), ALERT_ON_BAR);
}
// 简化报警：卖出
void AlertSell(string indicator, double price, string reason="") {
   SendAlertMessage(indicator, "SELL", Symbol() + " SELL@" + DoubleToStr(price,Digits) + (reason!=""?" ["+reason+"]":""), ALERT_ON_BAR);
}

// 仅在首次触发时报警（使用静态变量跟踪）
bool IsFirstTrigger(string &triggerId, int barIndex) {
   static string lastTriggers[20];static int lastBars[20];
   for(int i=0;i<20;i++) {
      if(lastTriggers[i]==triggerId&&lastBars[i]==barIndex) return false;
   }
   for(int i=18;i>=0;i--) {lastTriggers[i+1]=lastTriggers[i];lastBars[i+1]=lastBars[i];}
   lastTriggers[0]=triggerId;lastBars[0]=barIndex;
   return true;
}

#endif // _COMMON_MQH_

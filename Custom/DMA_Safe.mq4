//+------------------------------------------------------------------+
//|                                                   DMA_Safe.mq4    |
//|  均线差（DMA）— 不含未来函数                                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  DIF = MA(Short) - MA(Long)                                        |
//|  AMA = MA(DIF, M)                                                  |
//|  类似MACD但使用SMA而非EMA，更平滑                                  |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：DIF上穿AMA（金叉, bar[1]确认）                           |
//|  - 卖出：DIF下穿AMA（死叉, bar[1]确认）                           |
//|  - DIF上穿/下穿零轴为辅助确认信号                                 |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 6

input int    InpShort = 10;          // 短周期
input int    InpLong  = 50;          // 长周期
input int    InpM     = 10;          // AMA周期
input ENUM_MA_METHOD_SAFE InpMAMethod = MA_SMA; // 均线类型

double difBuffer[];     // DIF线
double amaBuffer[];     // AMA线
double buySignal[];     // 买入信号
double sellSignal[];    // 卖出信号
double strongBuyBuffer[];   // 强烈买入
double strongSellBuffer[];  // 强烈卖出

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,clrWhite);SetIndexBuffer(0,difBuffer);SetIndexLabel(0,"DIF");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrYellow);SetIndexBuffer(1,amaBuffer);SetIndexLabel(1,"AMA");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(4,strongBuyBuffer);SetIndexArrow(4,ARROW_BUY);SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(5,strongSellBuffer);SetIndexArrow(5,ARROW_SELL);SetIndexEmptyValue(5,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("DMA_Safe("+IntegerToString(InpShort)+","+IntegerToString(InpLong)+")");return(0);
}
int deinit() { return(0); }

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpLong*2;if(limit<0)limit=0;

   // 步骤1: 计算DIF和AMA
   for(int i=limit;i>=1;i--) {
      double prices[200];for(int j=0;j<200&&(i+j<Bars);j++)prices[j]=iClose(_Symbol,_Period,i+j);
      double maS=CalculateMA(prices,InpShort,InpMAMethod,0);
      double maL=CalculateMA(prices,InpLong,InpMAMethod,0);
      difBuffer[i]=maS-maL;amaBuffer[i]=0;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuyBuffer[i]=EMPTY_VALUE;strongSellBuffer[i]=EMPTY_VALUE;
   }
   // AMA = MA of DIF
   for(int i=limit;i>=1;i--) {
      double d[60];int c=0;for(int j=0;j<InpM*2&&(i+j<Bars);j++)d[c++]=difBuffer[i+j];
      if(c>=InpM)amaBuffer[i]=CalculateMA(d,InpM,InpMAMethod,0);
   }
   // 步骤2: 信号（bar[1]+确认）
   for(int i=limit;i>=1;i--) {
      // 强烈买入：DIF上穿AMA + DIF在零轴下方（深度反转确认）
      if(difBuffer[i+1]<=amaBuffer[i+1]&&difBuffer[i]>amaBuffer[i]&&difBuffer[i+1]<0)
         strongBuyBuffer[i]=difBuffer[i]-MathAbs(difBuffer[i]*0.25);
      // 强烈卖出：DIF下穿AMA + DIF在零轴上方（深度反转确认）
      if(difBuffer[i+1]>=amaBuffer[i+1]&&difBuffer[i]<amaBuffer[i]&&difBuffer[i+1]>0)
         strongSellBuffer[i]=difBuffer[i]+MathAbs(difBuffer[i]*0.25);
      // DIF上穿AMA -> 金叉买入
      if(difBuffer[i+1]<=amaBuffer[i+1]&&difBuffer[i]>amaBuffer[i])buySignal[i]=difBuffer[i]-MathAbs(difBuffer[i]*0.2);
      // DIF下穿AMA → 死叉卖出
      if(difBuffer[i+1]>=amaBuffer[i+1]&&difBuffer[i]<amaBuffer[i])sellSignal[i]=difBuffer[i]+MathAbs(difBuffer[i]*0.2);
      // 零轴穿越辅助信号
      if(difBuffer[i+1]<0&&difBuffer[i]>0)buySignal[i]=difBuffer[i]-MathAbs(difBuffer[i]*0.2);
      if(difBuffer[i+1]>0&&difBuffer[i]<0)sellSignal[i]=difBuffer[i]+MathAbs(difBuffer[i]*0.2);
   }
   // 步骤3: 刷新bar[0]
   if(Bars>0){
      double p0[200];for(int j=0;j<200;j++)p0[j]=iClose(_Symbol,_Period,j);
      difBuffer[0]=CalculateMA(p0,InpShort,InpMAMethod,0)-CalculateMA(p0,InpLong,InpMAMethod,0);
      amaBuffer[0]=amaBuffer[1];buySignal[0]=EMPTY_VALUE;sellSignal[0]=EMPTY_VALUE;strongBuyBuffer[0]=EMPTY_VALUE;strongSellBuffer[0]=EMPTY_VALUE;
   }
   return(0);
}

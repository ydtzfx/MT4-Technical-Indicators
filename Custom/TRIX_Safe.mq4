//+------------------------------------------------------------------+
//|                                                   TRIX_Safe.mq4   |
//|  三重指数平滑平均线（TRIX）— 不含未来函数                          |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：EMA1=EMA(Close,N), EMA2=EMA(EMA1,N), EMA3=EMA(EMA2,N)       |
//|  TRIX = 100 * (EMA3_today - EMA3_yesterday) / EMA3_yesterday       |
//|  信号线 = MA(TRIX, SignalPeriod)                                   |
//|                                                                   |
//|  三重EMA过滤了短期噪音，直接反映中长期趋势的加速度                 |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 4

input int InpTRIXPeriod   = 12;     // TRIX周期
input int InpSignalPeriod = 9;      // 信号线周期

double trixBuffer[];    // TRIX主线
double signalBuffer[];  // 信号线
double buySignal[];     // 买入信号
double sellSignal[];    // 卖出信号

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,clrDodgerBlue);SetIndexBuffer(0,trixBuffer);SetIndexLabel(0,"TRIX");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrRed);SetIndexBuffer(1,signalBuffer);SetIndexLabel(1,"Signal");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("TRIX_Safe("+IntegerToString(InpTRIXPeriod)+")");return(0);
}
int deinit() { return(0); }

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpTRIXPeriod*5;if(limit<0)limit=0;

   // 三重EMA计算
   double ema1[],ema2[],ema3[];
   ArrayResize(ema1,Bars);ArrayResize(ema2,Bars);ArrayResize(ema3,Bars);
   double alpha=2.0/(InpTRIXPeriod+1.0);

   for(int i=Bars-2;i>=0;i--) {
      if(i>=Bars-InpTRIXPeriod*2)ema1[i]=iClose(_Symbol,_Period,i);
      else ema1[i]=iClose(_Symbol,_Period,i)*alpha+ema1[i+1]*(1-alpha);
   }
   for(int i=Bars-2;i>=0;i--) {
      if(i>=Bars-InpTRIXPeriod*3)ema2[i]=ema1[i];
      else ema2[i]=ema1[i]*alpha+ema2[i+1]*(1-alpha);
   }
   for(int i=Bars-2;i>=0;i--) {
      if(i>=Bars-InpTRIXPeriod*4)ema3[i]=ema2[i];
      else ema3[i]=ema2[i]*alpha+ema3[i+1]*(1-alpha);
   }
   // TRIX = 变化率 * 100
   for(int i=limit;i>=1;i--) {
      if(ema3[i+1]!=0)trixBuffer[i]=100.0*(ema3[i]-ema3[i+1])/MathAbs(ema3[i+1]);else trixBuffer[i]=0;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   // Signal = SMA of TRIX
   for(int i=limit;i>=1;i--) {
      double s=0;int c=0;for(int j=0;j<InpSignalPeriod&&(i+j<Bars);j++){s+=trixBuffer[i+j];c++;}
      signalBuffer[i]=c>0?s/c:0;
   }
   // 信号（bar[1]+确认）
   for(int i=limit;i>=1;i--) {
      // TRIX上穿信号线 → 金叉
      if(trixBuffer[i+1]<=signalBuffer[i+1]&&trixBuffer[i]>signalBuffer[i])buySignal[i]=trixBuffer[i]-0.01;
      // TRIX下穿信号线 → 死叉
      if(trixBuffer[i+1]>=signalBuffer[i+1]&&trixBuffer[i]<signalBuffer[i])sellSignal[i]=trixBuffer[i]+0.01;
      // TRIX上穿零轴
      if(trixBuffer[i+1]<0&&trixBuffer[i]>0)buySignal[i]=trixBuffer[i]-0.01;
   }
   // 刷新bar[0]
   if(Bars>0){
      double e10=ema1[1]*alpha+iClose(_Symbol,_Period,0)*(1-alpha);
      double e20=ema2[1]*alpha+e10*(1-alpha);
      double e30=ema3[1]*alpha+e20*(1-alpha);
      trixBuffer[0]=ema3[1]!=0?100.0*(e30-ema3[1])/MathAbs(ema3[1]):0;
      signalBuffer[0]=signalBuffer[1];buySignal[0]=EMPTY_VALUE;sellSignal[0]=EMPTY_VALUE;
   }
   return(0);
}

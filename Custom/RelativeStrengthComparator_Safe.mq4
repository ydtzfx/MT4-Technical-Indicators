//+------------------------------------------------------------------+
//|                                     RelativeStrengthComparator_Safe|
//|  相对强度比较器 — 原创指标                                         |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  概念：计算当前品种相对于基准品种的相对强弱                         |
//|  RS = Price_Symbol / Price_Base（归一化后）                         |
//|  正值且上升=当前品种强于基准，适合做多                              |
//|  负值且下降=当前品种弱于基准，适合做空                              |
//|  常用于跨品种分析和配对交易                                        |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_level1 0

input string InpBase="EURUSD";input int InpPeriod=20;

double rs[],signal[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,rs);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"RS vs "+InpBase);
   SetIndexStyle(1,DRAW_LINE,STYLE_DOT,1,clrYellow);SetIndexBuffer(1,signal);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Signal");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(2);IndicatorShortName("RelStrength_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      // 计算两个品种的相对回报率
      double ret1=SafeDivide(iClose(_Symbol,_Period,i)-iClose(_Symbol,_Period,i+InpPeriod),iClose(_Symbol,_Period,i+InpPeriod),0);
      double ret2=0;
      int bar2=iBarShift(InpBase,_Period,iTime(_Symbol,_Period,i));
      if(bar2>=0&&bar2+InpPeriod<Bars)ret2=SafeDivide(iClose(InpBase,_Period,bar2)-iClose(InpBase,_Period,bar2+InpPeriod),iClose(InpBase,_Period,bar2+InpPeriod),0);
      rs[i]=100*(ret1-ret2); // 超额收益
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i++){double s=0;for(int j=0;j<5;j++)s+=rs[i+j];signal[i]=s/5;}
   for(int i=limit;i>=2;i--){
      if(rs[i+1]<0&&rs[i]>0)buySignal[i]=rs[i]-1;      // 超额收益转正
      if(rs[i+1]>0&&rs[i]<0)sellSignal[i]=rs[i]+1;
      if(rs[i+1]<=signal[i+1]&&rs[i]>signal[i])buySignal[i]=rs[i]-1;
   }
   if(Bars>0){rs[0]=rs[1];signal[0]=signal[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}

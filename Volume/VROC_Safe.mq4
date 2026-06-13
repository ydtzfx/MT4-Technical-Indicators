//+------------------------------------------------------------------+
//|                                                   VROC_Safe.mq4   |
//|  量变化率（Volume Rate of Change）— 不含未来函数                   |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：VROC = 100 * (Volume - Volume[N]) / Volume[N]               |
//|  衡量成交量相对变化，正值=放量，负值=缩量                         |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_level1 0

input int InpPeriod=14;

double vroc[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,2);SetIndexBuffer(0,vroc);SetIndexLabel(0,"VROC");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,4,Cyan);SetIndexBuffer(3,strongBuy);SetIndexArrow(3,233);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,DeepPink);SetIndexBuffer(4,strongSell);SetIndexArrow(4,234);SetIndexEmptyValue(4,EMPTY_VALUE);
   IndicatorDigits(1);IndicatorShortName("VROC_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpPeriod*2;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      long v=iVolume(_Symbol,_Period,i),vp=iVolume(_Symbol,_Period,i+InpPeriod);
      vroc[i]=vp>0?100.0*(v-vp)/vp:0;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i--){
      // 强烈多头：极端放量(>120) + 价格上涨 + 成交量加速
      if(vroc[i]>120&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1)&&vroc[i]>vroc[i+1])strongBuy[i]=vroc[i]*0.35;
      // 强烈空头：极端放量(>120) + 价格下跌 + 成交量加速
      if(vroc[i]>120&&iClose(_Symbol,_Period,i)<iClose(_Symbol,_Period,i+1)&&vroc[i]>vroc[i+1])strongSell[i]=vroc[i]*1.15;
      // 放量+价格上涨 = 多头确认
      if(vroc[i]>50&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1))buySignal[i]=vroc[i]*0.5;
      // 放量+价格下跌 = 空头确认
      if(vroc[i]>50&&iClose(_Symbol,_Period,i)<iClose(_Symbol,_Period,i+1))sellSignal[i]=vroc[i]*1.5;
   }
   if(Bars>0){vroc[0]=vroc[1];buySignal[0]=sellSignal[0]=strongBuy[0]=strongSell[0]=EMPTY_VALUE;}
   return(0);
}

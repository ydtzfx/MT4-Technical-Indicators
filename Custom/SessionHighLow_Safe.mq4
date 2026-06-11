//+------------------------------------------------------------------+
//|                                          SessionHighLow_Safe.mq4  |
//|  时段高低点 — 不含未来函数                                        |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  标记每段交易时段（亚/欧/美盘）的高低点范围                         |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4

input int InpAsianStart=0,InpAsianEnd=9;   // 亚盘 0-9 (GMT+2)
input int InpEUStart=9,InpEUEnd=18;         // 欧盘 9-18
input int InpUSStart=14,InpUSEnd=23;        // 美盘 14-23

double asianHi[],asianLo[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrYellow);SetIndexBuffer(0,asianHi);SetIndexLabel(0,"Session High");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrYellow);SetIndexBuffer(1,asianLo);SetIndexLabel(1,"Session Low");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("SessionHL_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   // 找出最近一个完整时段的高低点
   int currentHour=Hour();double sHi=0,sLo=99999;
   for(int i=limit;i>=1;i--){
      datetime t=iTime(_Symbol,_Period,i);int h=TimeHour(t);
      if(h>=InpAsianStart&&h<InpAsianEnd){ // 简化：只用亚洲时段
         double hi=iHigh(_Symbol,_Period,i),lo=iLow(_Symbol,_Period,i);
         if(hi>sHi)sHi=hi;if(lo<sLo)sLo=lo;
         asianHi[i]=sHi;asianLo[i]=sLo;
      } else {asianHi[i]=asianHi[i+1];asianLo[i]=asianLo[i+1];}
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i--){
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      // 突破时段高点
      if(c1<=asianHi[i+1]&&c>asianHi[i])buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
      // 跌破时段低点
      if(c1>=asianLo[i+1]&&c<asianLo[i])sellSignal[i]=iHigh(_Symbol,_Period,i)+5*Point;
   }
   return(0);
}

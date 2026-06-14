#include "../Include/Common.mqh"
#include "../Include/PriceData.mqh"
//+------------------------------------------------------------------+
//|                                             TimeAtLevel_Safe.mq4  |
//|  价位停留时间 — 原创指标（吸收/拒绝分析）                           |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  概念：统计价格在每个水平上的停留bar数                              |
//|  长时间停留后突破=强方向（吸收后释放）                              |
//|  短时间停留后突破=弱方向（可能假突破）                              |
//|  输出：当前价格在当前水平已停留的bar数+突破概率评估                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 4

input double InpLevelWidth=0.3; // 水平宽度(%ATR)

double timeAtLevel[],breakProb[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3,clrDodgerBlue);SetIndexBuffer(0,timeAtLevel);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Bars at Level");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrOrange);SetIndexBuffer(1,breakProb);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Breakout Prob %");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(0);IndicatorShortName("TimeAtLevel_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;

   double atr=0;for(int j=0;j<14;j++)atr+=GetTrueRange(_Symbol,_Period,limit+10+j);atr/=14;
   double zoneWidth=InpLevelWidth*atr/100;

   for(int i=limit;i>=1;i--){
      double c=iClose(_Symbol,_Period,i);
      // 统计之前有多少连续bar在这个窄幅区间内
      int barsInZone=0;double zoneMid=c;
      for(int jj=i+1;j<Bars;j++){
         double cj=iClose(_Symbol,_Period,j);
         if(MathAbs(cj-zoneMid)<zoneWidth)barsInZone++;
         else break;
      }
      timeAtLevel[i]=barsInZone;
      // 停留越久→突破概率越高（吸收充分）
      breakProb[i]=MathMin(100,barsInZone*5.0);
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=2;i--){
      // 长时间盘整后突破
      if(timeAtLevel[i+1]>10&&timeAtLevel[i]==0&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1))buySignal[i]=5;
      if(timeAtLevel[i+1]>10&&timeAtLevel[i]==0&&iClose(_Symbol,_Period,i)<iClose(_Symbol,_Period,i+1))sellSignal[i]=5;
   }
   if(Bars>0){timeAtLevel[0]=timeAtLevel[1];breakProb[0]=breakProb[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}

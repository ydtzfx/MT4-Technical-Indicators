#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                   DynamicSupportResistance_Safe   |
//|  动态支撑阻力 — 原创指标                                           |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  创新：不是固定水平线，而是随着新数据动态调整的S/R区域              |
//|  - 基于成交量分布（Volume Profile）找到高成交量价格区               |
//|  - 基于价格行为（多次触碰未突破=S/R确认）                          |
//|  - 每次新bar完成后重新评估并调整S/R位置                            |
//+------------------------------------------------------------------+
#property copyright "Original Composite - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4

input int InpLookback=50;input int InpTouchCount=3;

double resistance[],support[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrTomato);SetIndexBuffer(0,resistance);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Dynamic Res");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrLimeGreen);SetIndexBuffer(1,support);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Dynamic Sup");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("DynSR_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      // 找回顾窗口内的高低点
      double hh=iHigh(_Symbol,_Period,i),ll=iLow(_Symbol,_Period,i);
      for(int j=1;j<InpLookback;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>hh)hh=h;if(l<ll)ll=l;}

      // 统计触碰次数确认S/R强度
      int touchRes=0,touchSup=0;double resZone=0,supZone=0;
      for(int jj=1;j<InpLookback;j++){
         h=iHigh(_Symbol,_Period,i+j);
         if(MathAbs(h-hh)<(hh*0.002)){touchRes++;resZone+=h;}
         l=iLow(_Symbol,_Period,i+j);
         if(MathAbs(l-ll)<(ll*0.002)){touchSup++;supZone+=l;}
      }
      // 触碰>=阈值才视为有效S/R（动态调整）
      resistance[i]=(touchRes>=InpTouchCount&&resZone>0)?resZone/touchRes:0;
      support[i]=(touchSup>=InpTouchCount&&supZone>0)?supZone/touchSup:0;
      if(resistance[i]==0)resistance[i]=resistance[i+1];
      if(support[i]==0)support[i]=support[i+1];

      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=2;i--){
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      // 突破动态阻力 → 强势买入
      if(resistance[i]>0&&c1<=resistance[i+1]&&c>resistance[i])buySignal[i]=support[i]>0?support[i]:iLow(_Symbol,_Period,i)-10*Point;
      // 跌破动态支撑 → 强势卖出
      if(support[i]>0&&c1>=support[i+1]&&c<support[i])sellSignal[i]=resistance[i]>0?resistance[i]:iHigh(_Symbol,_Period,i)+10*Point;
      // 价格从支撑反弹
      if(support[i]>0&&c1<=support[i+1]&&c>support[i])buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
   }
   if(Bars>0){resistance[0]=resistance[1];support[0]=support[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}

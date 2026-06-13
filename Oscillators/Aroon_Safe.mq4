//+------------------------------------------------------------------+
//|                                                Aroon_Safe.mq4     |
//|  阿隆指标（Aroon）— 不含未来函数                                  |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：AroonUp=100*(N-高点距今天数)/N, AroonDown同理               |
//|  Aroon>70=强趋势, Aroon<30=弱趋势, Up/Down交叉=趋势转换          |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_minimum 0
#property indicator_maximum 100

input int InpPeriod=14;

double aroonUp[],aroonDown[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrLimeGreen);SetIndexBuffer(0,aroonUp);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Aroon Up");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrTomato);SetIndexBuffer(1,aroonDown);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Aroon Down");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(4,strongBuy);SetIndexArrow(4,233);SetIndexLabel(4,"Strong Buy");SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(5,strongSell);SetIndexArrow(5,234);SetIndexLabel(5,"Strong Sell");SetIndexEmptyValue(5,EMPTY_VALUE);
   IndicatorDigits(1);IndicatorShortName("Aroon_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpPeriod*2;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--) {
      int highBars=0,lowBars=0;double hh=iHigh(_Symbol,_Period,i),ll=iLow(_Symbol,_Period,i);
      for(int j=0;j<=InpPeriod;j++) {
         double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);
         if(h>hh){hh=h;highBars=j;}if(l<ll){ll=l;lowBars=j;}
      }
      aroonUp[i]=100.0*(InpPeriod-highBars)/InpPeriod;aroonDown[i]=100.0*(InpPeriod-lowBars)/InpPeriod;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i--) {
      // Aroon Up 上穿 Aroon Down → 多头趋势启动
      if(aroonUp[i+1]<=aroonDown[i+1]&&aroonUp[i]>aroonDown[i]&&aroonUp[i]>70&&aroonDown[i]<30)strongBuy[i]=45;
      else if(aroonUp[i+1]<=aroonDown[i+1]&&aroonUp[i]>aroonDown[i]&&aroonUp[i]>50)buySignal[i]=45;
      // Aroon Down 上穿 Aroon Up → 空头趋势启动
      if(aroonDown[i+1]<=aroonUp[i+1]&&aroonDown[i]>aroonUp[i]&&aroonDown[i]>70&&aroonUp[i]<30)strongSell[i]=55;
      else if(aroonDown[i+1]<=aroonUp[i+1]&&aroonDown[i]>aroonUp[i]&&aroonDown[i]>50)sellSignal[i]=55;
   }
   if(Bars>0){aroonUp[0]=aroonUp[1];aroonDown[0]=aroonDown[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}

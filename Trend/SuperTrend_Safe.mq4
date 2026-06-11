//+------------------------------------------------------------------+
//|                                          SuperTrend_Safe.mq4      |
//|  超级趋势指标 — 不含未来函数                                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：UpperBand=(H+L)/2+K*ATR, LowerBand=(H+L)/2-K*ATR           |
//|  价格在上轨上方=多头趋势(绿线)，在下轨下方=空头趋势(红线)          |
//|  信号不重绘：趋势转换确认后才发出信号(bar[1]+)                    |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 7

input int InpATRPeriod=10;input double InpMultiplier=3.0;

double upTrend[],downTrend[],trendLine[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrLimeGreen);SetIndexBuffer(0,upTrend);SetIndexLabel(0,"Up Trend");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrTomato);SetIndexBuffer(1,downTrend);SetIndexLabel(1,"Down Trend");
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,clrYellow);SetIndexBuffer(2,trendLine);SetIndexLabel(2,"Trend Line");
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(5,strongBuy);SetIndexArrow(5,ARROW_BUY);SetIndexLabel(5,"Strong Buy");SetIndexEmptyValue(5,EMPTY_VALUE);
   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(6,strongSell);SetIndexArrow(6,ARROW_SELL);SetIndexLabel(6,"Strong Sell");SetIndexEmptyValue(6,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("SuperTrend_Safe("+IntegerToString(InpATRPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;

   // 从远到近递推SuperTrend
   double prevClose=iClose(_Symbol,_Period,Bars-2),prevUpper=0,prevLower=0;
   bool isUpTrend=true;double prevTrendLine=0;

   for(int i=Bars-2;i>=1;i--) {
      double hl2=(iHigh(_Symbol,_Period,i)+iLow(_Symbol,_Period,i))/2;
      double trSum=0;for(int j=0;j<InpATRPeriod;j++)trSum+=GetTrueRange(_Symbol,_Period,i+j);
      double atr=trSum/InpATRPeriod;
      double upperBand=hl2+InpMultiplier*atr,lowerBand=hl2-InpMultiplier*atr;

      if(i==Bars-2){isUpTrend=true;trendLine[i]=lowerBand;prevTrendLine=lowerBand;prevUpper=upperBand;prevLower=lowerBand;}
      else {
         if(isUpTrend) {
            if(prevClose<prevTrendLine){isUpTrend=false;trendLine[i]=upperBand;}
            else{trendLine[i]=MathMax(lowerBand,prevTrendLine);}
         } else {
            if(prevClose>prevTrendLine){isUpTrend=true;trendLine[i]=lowerBand;}
            else{trendLine[i]=MathMin(upperBand,prevTrendLine);}
         }
         prevTrendLine=trendLine[i];
      }
      prevClose=iClose(_Symbol,_Period,i);prevUpper=upperBand;prevLower=lowerBand;
      upTrend[i]=isUpTrend?trendLine[i]:EMPTY_VALUE;downTrend[i]=!isUpTrend?trendLine[i]:EMPTY_VALUE;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   // 信号：趋势转换确认(bar[1]+) — 增强分级
   for(int i=limit;i>=1;i--) {
      double atr=0;for(int j=0;j<InpATRPeriod;j++)atr+=GetTrueRange(_Symbol,_Period,i+j);atr/=InpATRPeriod;
      double dist=MathAbs((upTrend[i]!=EMPTY_VALUE?upTrend[i]:downTrend[i])-iClose(_Symbol,_Period,i));
      bool strongBreak = (dist > atr * InpMultiplier * 0.8); // 价格远离趋势线=趋势强劲
      // 强买：趋势转多 + 大幅突破
      if(upTrend[i+1]==EMPTY_VALUE&&upTrend[i]!=EMPTY_VALUE&&strongBreak)strongBuy[i]=iLow(_Symbol,_Period,i)-15*Point;
      else if(upTrend[i+1]==EMPTY_VALUE&&upTrend[i]!=EMPTY_VALUE)buySignal[i]=iLow(_Symbol,_Period,i)-10*Point;
      // 强卖：趋势转空 + 大幅突破
      if(downTrend[i+1]==EMPTY_VALUE&&downTrend[i]!=EMPTY_VALUE&&strongBreak)strongSell[i]=iHigh(_Symbol,_Period,i)+15*Point;
      else if(downTrend[i+1]==EMPTY_VALUE&&downTrend[i]!=EMPTY_VALUE)sellSignal[i]=iHigh(_Symbol,_Period,i)+10*Point;
   }
   if(Bars>0){upTrend[0]=upTrend[1];downTrend[0]=downTrend[1];buySignal[0]=sellSignal[0]=strongBuy[0]=strongSell[0]=EMPTY_VALUE;}
   return(0);
}

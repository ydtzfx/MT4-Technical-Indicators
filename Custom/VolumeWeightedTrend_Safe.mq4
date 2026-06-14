#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                       VolumeWeightedTrend_Safe    |
//|  成交量加权趋势线 — 原创指标                                       |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  创新：用成交量对价格进行加权后计算趋势线                          |
//|  高量K线的价格权重 > 低量K线的价格权重                             |
//|  VWMA = Σ(Price_i * Volume_i) / ΣVolume_i                          |
//|  信号线 = EMA(VWMA, Signal)                                         |
//|  与普通MA相比，VWT更不容易被缩量假突破欺骗                         |
//+------------------------------------------------------------------+
#property copyright "Original Composite - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5

input int InpPeriod=20;input int InpSignal=9;
input ENUM_PRICE_SAFE InpPrice=SAFE_PRICE_TYPICAL;

double vwt[],signal[],buySignal[],sellSignal[],confidence[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,vwt);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"VW Trend");
   SetIndexStyle(1,DRAW_LINE,STYLE_DOT,1,clrYellow);SetIndexBuffer(1,signal);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Signal");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_HISTOGRAM,STYLE_SOLID,1,clrGray);SetIndexBuffer(4,confidence);SetIndexEmptyValue(4,EMPTY_VALUE);SetIndexLabel(4,"Confidence");
   IndicatorDigits(4);IndicatorShortName("VWT_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpPeriod*2;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      // VWMA = sum(price * vol) / sum(vol)
      double sumPV=0,sumV=0;
      for(int j=0;j<InpPeriod;j++){
         double price=GetPriceByType(i+j,InpPrice);
         long vol=iVolume(_Symbol,_Period,i+j);
         sumPV+=price*vol;sumV+=vol;
      }
      vwt[i]=SafeDivide(sumPV,sumV,iClose(_Symbol,_Period,i));

      // 信号线
      double s=0;for(int jj=0;j<InpSignal;j++)s+=vwt[i+j];signal[i]=s/InpSignal;

      // 置信度 = 近期成交量 / 均量（高量=趋势更可靠）
      double curV=0,avgV=0;for(int jjj=0;j<5;j++)curV+=iVolume(_Symbol,_Period,i+j);curV/=5;
      for(int jjjj=0;j<20;j++)avgV+=iVolume(_Symbol,_Period,i+j);avgV/=20;
      confidence[i]=MathMin(100,SafeDivide(curV,avgV,1)*50);

      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=2;i--){
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      bool crossUp=(vwt[i+1]<=signal[i+1]&&vwt[i]>signal[i]);
      bool crossDn=(vwt[i+1]>=signal[i+1]&&vwt[i]<signal[i]);
      // 金叉 + 高置信度 = 强买入
      if(crossUp&&confidence[i]>50)buySignal[i]=iLow(_Symbol,_Period,i)-8*Point;
      else if(crossUp)buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
      // 死叉
      if(crossDn&&confidence[i]>50)sellSignal[i]=iHigh(_Symbol,_Period,i)+8*Point;
      else if(crossDn)sellSignal[i]=iHigh(_Symbol,_Period,i)+5*Point;
   }
   if(Bars>0){vwt[0]=vwt[1];signal[0]=signal[1];confidence[0]=confidence[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}

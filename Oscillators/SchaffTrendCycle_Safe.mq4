//+------------------------------------------------------------------+
//|                                    SchaffTrendCycle_Safe.mq4      |
//|  沙夫趋势周期（Schaff Trend Cycle）— 不含未来函数                 |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：MACD→Stochastic(MACD)→EMA(Stoch)→循环                      |
//|  结合了MACD的趋势跟踪和Stochastic的敏感度                        |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 75
#property indicator_level2 25

input int InpMACDFast=23,InpMACDSlow=50,InpCycle=10;

double stcBuffer[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,stcBuffer);SetIndexLabel(0,"STC");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   int idx=3;SetIndexBuffer(idx,strongBuy);SetIndexStyle(idx,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexArrow(idx,233);SetIndexEmptyValue(idx,EMPTY_VALUE);
   idx++;SetIndexBuffer(idx,strongSell);SetIndexStyle(idx,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexArrow(idx,234);SetIndexEmptyValue(idx,EMPTY_VALUE);
   IndicatorDigits(2);IndicatorShortName("STC_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   int hist=InpMACDSlow*3;if(limit>Bars-2)limit=Bars-hist;if(limit<0)limit=0;

   double macd[],stoch[],ll[],hh[];
   ArrayResize(macd,Bars);ArrayResize(stoch,Bars);ArrayResize(ll,Bars);ArrayResize(hh,Bars);

   // MACD Line
   for(int i=hist;i>=1;i--) {
      double prices[200];for(int j=0;j<hist;j++)prices[j]=iClose(_Symbol,_Period,i+j);
      double emaF=0;for(int j=hist-1;j>=hist-InpMACDFast;j--)emaF+=prices[j];emaF/=InpMACDFast;
      double aF=2.0/(InpMACDFast+1);for(int j=hist-InpMACDFast-1;j>=0;j--)emaF=prices[j]*aF+emaF*(1-aF);
      double emaS=0;for(int j=hist-1;j>=hist-InpMACDSlow;j--)emaS+=prices[j];emaS/=InpMACDSlow;
      double aS=2.0/(InpMACDSlow+1);for(int j=hist-InpMACDSlow-1;j>=0;j--)emaS=prices[j]*aS+emaS*(1-aS);
      macd[i]=emaF-emaS;
   }
   // Stochastic of MACD
   for(int i=hist;i>=1;i--) {
      double mn=macd[i],mx=macd[i];for(int j=0;j<InpCycle;j++){if(macd[i+j]<mn)mn=macd[i+j];if(macd[i+j]>mx)mx=macd[i+j];}
      double rng=mx-mn;stoch[i]=MathAbs(rng)>0?100*(macd[i]-mn)/rng:50;
   }
   // EMA of Stochastic
   double aC=2.0/(InpCycle+1);
   for(int i=hist;i>=1;i--) {
      double e=stoch[i+InpCycle];for(int j=InpCycle-1;j>=0;j--)e=stoch[i+j]*aC+e*(1-aC);
      stcBuffer[i]=e;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i--) {
      if(stcBuffer[i+1]<=15&&stcBuffer[i]>25)strongBuy[i]=20;
      else if(stcBuffer[i+1]<=25&&stcBuffer[i]>25)buySignal[i]=20;
      if(stcBuffer[i+1]>=85&&stcBuffer[i]<75)strongSell[i]=80;
      else if(stcBuffer[i+1]>=75&&stcBuffer[i]<75)sellSignal[i]=80;
   }
   if(Bars>0){stcBuffer[0]=stcBuffer[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}

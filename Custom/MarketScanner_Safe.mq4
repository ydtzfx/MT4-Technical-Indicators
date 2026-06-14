#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                          MarketScanner_Safe.mq4   |
//|  市场扫描仪表盘 — 不含未来函数                                    |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  综合多个指标信号给出当前市场状态评分                               |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum -100
#property indicator_maximum 100
#property indicator_level1 50
#property indicator_level2 -50

input int InpRSIPeriod=14;input int InpMACDFast=12;input int InpMACDSlow=26;input int InpADXPeriod=14;

double score[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,score);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Market Score");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   IndicatorDigits(0);IndicatorShortName("MarketScanner_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-150;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      int totalScore=0;

      // RSI信号
      double aG=0,aL=0;for(int j=0;j<InpRSIPeriod;j++){double ch=iClose(_Symbol,_Period,i+j)-iClose(_Symbol,_Period,i+j+1);if(ch>0)aG+=ch;else aL-=ch;}
      aG/=InpRSIPeriod;aL/=InpRSIPeriod;double rsi=aL<0.00000001?100:100-100/(1+aG/aL);
      if(rsi>60)totalScore+=20;else if(rsi>50)totalScore+=10;else if(rsi<40)totalScore-=20;else if(rsi<50)totalScore-=10;

      // MACD信号
      double prices[100];for(int jj=0;j<100;j++)prices[j]=iClose(_Symbol,_Period,i+j);
      double aF=2.0/(InpMACDFast+1),aS=2.0/(InpMACDSlow+1);
      double eF=prices[99],eS=prices[99];
      for(int jjj=98;j>=0;j--){eF=prices[j]*aF+eF*(1-aF);eS=prices[j]*aS+eS*(1-aS);}
      double macdLine=eF-eS;
      if(macdLine>0)totalScore+=(macdLine>0.0001?30:15);else totalScore-=(macdLine<-0.0001?30:15);

      // 均线排列
      double ma10=0,ma20=0,ma60=0;for(int jjjj=0;j<10;j++)ma10+=iClose(_Symbol,_Period,i+j);ma10/=10;
      for(int jjjjj=0;j<20;j++)ma20+=iClose(_Symbol,_Period,i+j);ma20/=20;
      for(int jjjjjj=0;j<60;j++)ma60+=iClose(_Symbol,_Period,i+j);ma60/=60;
      if(ma10>ma20&&ma20>ma60)totalScore+=30;else if(ma10<ma20&&ma20<ma60)totalScore-=30;

      // 趋势强度（连续上涨天数）
      int upDays=0;for(int jjjjjjj=0;j<5;j++)if(iClose(_Symbol,_Period,i+j)>iClose(_Symbol,_Period,i+j+1))upDays++;
      totalScore+=(upDays-2)*10;

      score[i]=MathMax(-100,MathMin(100,totalScore));
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=1;i--){
      if(score[i+1]<-50&&score[i]>-50)buySignal[i]=-55;
      if(score[i+1]>50&&score[i]<50)sellSignal[i]=55;
   }
   if(Bars>0){score[0]=score[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}

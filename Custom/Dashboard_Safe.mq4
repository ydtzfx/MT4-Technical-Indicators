//+------------------------------------------------------------------+
//|                                              Dashboard_Safe.mq4   |
//|  综合仪表盘 — 多指标信号一览                                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  同时显示8个核心指标的方向信号：                                     |
//|  RSI/MACD/Stoch/ADX/MA/Bollinger/AO/Fusion                        |
//|  多头得分-空头得分=净方向，>2=强多,<-2=强空                        |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_minimum -8
#property indicator_maximum 8
#property indicator_level1 2
#property indicator_level2 -2

input int InpRSIPeriod=14;

double netScore[],scoreDetail[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,netScore);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Net Score");
   SetIndexStyle(1,DRAW_NONE);SetIndexBuffer(1,scoreDetail);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Detail");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(0);IndicatorShortName("Dashboard_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      int score=0;

      // 1. RSI (>50=+1, >60=+2, <50=-1, <40=-2)
      double aG=0,aL=0;for(int j=0;j<InpRSIPeriod;j++){double ch=iClose(_Symbol,_Period,i+j)-iClose(_Symbol,_Period,i+j+1);if(ch>0)aG+=ch;else aL-=ch;}
      double rsi=SafeDivide(100*aG,aG+aL,50);score+=(rsi>60?2:rsi>50?1:rsi<40?-2:rsi<50?-1:0);

      // 2. MACD (>0=+1, 金叉=+2)
      double p[100];for(int j=0;j<100;j++)p[j]=iClose(_Symbol,_Period,i+j);
      double fE=0,sE=0;for(int j=99;j>=0;j--){if(j==99){fE=p[j];sE=p[j];}else{double aF=2.0/13,aS=2.0/27;fE=p[j]*aF+fE*(1-aF);sE=p[j]*aS+sE*(1-aS);}}
      double macd=fE-sE;if(macd>0)score+=macd>0.0001?2:1;else score-=macd<-0.0001?2:1;

      // 3. Stochastic (<20=+2, >80=-2)
      double stH=iHigh(_Symbol,_Period,i),stL=iLow(_Symbol,_Period,i);for(int j=0;j<5;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>stH)stH=h;if(l<stL)stL=l;}
      double stoch=SafeDivide(100*(iClose(_Symbol,_Period,i)-stL),stH-stL,50);score+=(stoch<20?2:stoch<30?1:stoch>80?-2:stoch>70?-1:0);

      // 4. ADX (>30且+DI>-DI=+1)
      double tS=0,ps=0,ms=0;for(int j=0;j<14;j++){int s=i+j;double hi=iHigh(_Symbol,_Period,s),lo=iLow(_Symbol,_Period,s),pc=iClose(_Symbol,_Period,s+1);tS+=MathMax(hi-lo,MathMax(MathAbs(hi-pc),MathAbs(lo-pc)));double up=hi-iHigh(_Symbol,_Period,s+1),dn=iLow(_Symbol,_Period,s+1)-lo;if(up>dn&&up>0)ps+=up;if(dn>up&&dn>0)ms+=dn;}
      double adx=SafeDivide(100*MathAbs(ps-ms),ps+ms,0);if(adx>25)score+=(ps>ms?1:-1);

      // 5. MA排列 (MA10>MA20>MA50=+2)
      double ma10=0,ma20=0,ma50=0;for(int j=0;j<10;j++)ma10+=iClose(_Symbol,_Period,i+j);ma10/=10;
      for(int j=0;j<20;j++)ma20+=iClose(_Symbol,_Period,i+j);ma20/=20;
      for(int j=0;j<50;j++)ma50+=iClose(_Symbol,_Period,i+j);ma50/=50;
      score+=(ma10>ma20&&ma20>ma50?2:ma10>ma20?1:ma10<ma20&&ma20<ma50?-2:ma10<ma20?-1:0);

      // 6. BB位置 (<下轨=+1, >上轨=-1)
      double sum=0;for(int j=0;j<20;j++)sum+=iClose(_Symbol,_Period,i+j);double sma=sum/20;
      double sd=0;for(int j=0;j<20;j++){double d=iClose(_Symbol,_Period,i+j)-sma;sd+=d*d;}sd=MathSqrt(sd/20);
      double bbU=sma+2*sd,bbL=sma-2*sd;double c=iClose(_Symbol,_Period,i);
      score+=(c<bbL?1:c>bbU?-1:0);

      netScore[i]=score;scoreDetail[i]=score;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i--){
      if(netScore[i+1]<=-2&&netScore[i]>-2)buySignal[i]=netScore[i]-0.5;
      if(netScore[i+1]>=2&&netScore[i]<2)sellSignal[i]=netScore[i]+0.5;
      if(netScore[i+1]<=-5&&netScore[i]>-5)buySignal[i]=netScore[i]-1;
   }
   if(Bars>0){netScore[0]=netScore[1];scoreDetail[0]=scoreDetail[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}

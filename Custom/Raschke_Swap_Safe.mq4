//+------------------------------------------------------------------+
//|                                           Raschke_Swap_Safe.mq4   |
//|  Raschke摆动交易 — Linda Bradford Raschke的策略                    |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  双时间框架+ADX+Stochastic三重确认                                  |
//|  主TF: 4H(趋势), 执行TF: 15M(入场)                                 |
//|  规则：4H ADX>20+Stoch超卖→15M RSI<30后回升=买入                   |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum -100
#property indicator_maximum 100
#property indicator_level1 50
#property indicator_level2 -50

input ENUM_TIMEFRAMES InpTrendTF=PERIOD_H4;input int InpRSIPeriod=5;

double raschkeSignal[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,raschkeSignal);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Raschke Signal");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   IndicatorDigits(0);IndicatorShortName("RaschkeSwap_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-500;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      datetime now=iTime(_Symbol,_Period,i);
      int trendBar=iBarShift(_Symbol,InpTrendTF,now);

      // 大周期：ADX趋势强度 + Stochastic方向
      double trS=0,ps=0,ms=0;
      for(int j=0;j<14;j++){int s=trendBar+j;double hi=iHigh(_Symbol,InpTrendTF,s),lo=iLow(_Symbol,InpTrendTF,s),pc=iClose(_Symbol,InpTrendTF,s+1);trS+=MathMax(hi-lo,MathMax(MathAbs(hi-pc),MathAbs(lo-pc)));double up=hi-iHigh(_Symbol,InpTrendTF,s+1),dn=iLow(_Symbol,InpTrendTF,s+1)-lo;if(up>dn&&up>0)ps+=up;if(dn>up&&dn>0)ms+=dn;}
      double adx=SafeDivide(100*MathAbs(ps-ms),ps+ms,0);

      double stH=iHigh(_Symbol,InpTrendTF,trendBar),stL=iLow(_Symbol,InpTrendTF,trendBar);
      for(int j=0;j<5;j++){int s=trendBar+j;double h=iHigh(_Symbol,InpTrendTF,s),l=iLow(_Symbol,InpTrendTF,s);if(h>stH)stH=h;if(l<stL)stL=l;}
      double stoch=SafeDivide(100*(iClose(_Symbol,InpTrendTF,trendBar)-stL),stH-stL,50);

      // 小周期：RSI
      double aG=0,aL=0;for(int j=0;j<InpRSIPeriod;j++){double ch=iClose(_Symbol,_Period,i+j)-iClose(_Symbol,_Period,i+j+1);if(ch>0)aG+=ch;else aL-=ch;}
      double rsi=SafeDivide(100*aG,aG+aL,50);

      // Raschke信号：大趋势+回调+RSI反转
      double sig=0;
      if(adx>20){
         if(stoch<30&&rsi<35)sig=70;     // 超卖准备反转买入
         else if(stoch>70&&rsi>65)sig=-70; // 超买准备反转卖出
         else if(rsi<30)sig=50;
         else if(rsi>70)sig=-50;
      }
      raschkeSignal[i]=sig;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i--){
      if(raschkeSignal[i+1]<-50&&raschkeSignal[i]>-50)buySignal[i]=-55;
      if(raschkeSignal[i+1]>50&&raschkeSignal[i]<50)sellSignal[i]=55;
   }
   if(Bars>0){raschkeSignal[0]=raschkeSignal[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}

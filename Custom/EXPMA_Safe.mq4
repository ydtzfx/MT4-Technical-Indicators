//+------------------------------------------------------------------+
//|                                                  EXPMA_Safe.mq4   |
//|  鎸囨暟骞冲潎绾匡紙EXPMA锛夆€?涓嶅惈鏈潵鍑芥暟                                |
//|  Part of: MT4 鎶€鏈寚鏍囧畬鏁翠綋 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  鍚屾椂鏄剧ず5鏉MA绾匡紝鏋勬垚澶氬懆鏈熷潎绾跨郴缁?                             |
//|  榛樿鍙傛暟锛?/10/20/60/120                                          |
//|                                                                   |
//|  淇″彿閫昏緫锛堟棤鏈潵鍑芥暟锛夛細                                          |
//|  - 涔板叆锛氱煭绾夸笂绌块暱绾?+ 鍧囩嚎澶氬ご鎺掑垪(bar[1]纭)                  |
//|  - 鍗栧嚭锛氱煭绾夸笅绌块暱绾?+ 鍧囩嚎绌哄ご鎺掑垪(bar[1]纭)                  |
//|  - 鍧囩嚎瀵嗛泦鍚庡彂鏁?鈫?瓒嬪娍鍚姩淇″彿                                 |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 9

input int  InpEMA1=5, InpEMA2=10, InpEMA3=20, InpEMA4=60, InpEMA5=120;
input bool InpShowSignals=true;
input color InpC1=clrLimeGreen, InpC2=clrYellow, InpC3=clrOrange, InpC4=clrDodgerBlue, InpC5=clrMagenta;

double e1[],e2[],e3[],e4[],e5[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,InpC1);SetIndexBuffer(0,e1);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"EMA"+IntegerToString(InpEMA1));
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,InpC2);SetIndexBuffer(1,e2);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"EMA"+IntegerToString(InpEMA2));
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,InpC3);SetIndexBuffer(2,e3);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexLabel(2,"EMA"+IntegerToString(InpEMA3));
   SetIndexStyle(3,DRAW_LINE,STYLE_SOLID,2,InpC4);SetIndexBuffer(3,e4);SetIndexEmptyValue(3,EMPTY_VALUE);SetIndexLabel(3,"EMA"+IntegerToString(InpEMA4));
   SetIndexStyle(4,DRAW_LINE,STYLE_SOLID,2,InpC5);SetIndexBuffer(4,e5);SetIndexEmptyValue(4,EMPTY_VALUE);SetIndexLabel(4,"EMA"+IntegerToString(InpEMA5));
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(5,buySignal);SetIndexArrow(5,ARROW_BUY);SetIndexEmptyValue(5,EMPTY_VALUE);
   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(6,sellSignal);SetIndexArrow(6,ARROW_SELL);SetIndexEmptyValue(6,EMPTY_VALUE);
   SetIndexStyle(7,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(7,strongBuy);SetIndexArrow(7,ARROW_BUY);SetIndexEmptyValue(7,EMPTY_VALUE);
   SetIndexStyle(8,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(8,strongSell);SetIndexArrow(8,ARROW_SELL);SetIndexEmptyValue(8,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("EXPMA_Safe");return(0);
}
int deinit(){return(0);}

double CalcEMA(double &p[],int period,int idx){
   double e=0;for(int i=idx+period;i<idx+period*2;i++)e+=p[i];e/=period;
   double a=2.0/(period+1);for(int i=idx+period-1;i>=idx;i--)e=p[i]*a+e*(1-a);return e;
}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   int maxP=InpEMA5;if(limit>Bars-2)limit=Bars-maxP*3;if(limit<0)limit=0;
   int hist=maxP*3;

   // 璁＄畻5鏉MA
   for(int i=limit;i>=1;i--) {
      double p[360];for(int j=0;j<hist&&(i+j<Bars);j++)p[j]=iClose(_Symbol,_Period,i+j);
      e1[i]=CalcEMA(p,InpEMA1,0);e2[i]=CalcEMA(p,InpEMA2,0);e3[i]=CalcEMA(p,InpEMA3,0);
      e4[i]=CalcEMA(p,InpEMA4,0);e5[i]=CalcEMA(p,InpEMA5,0);
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }

   // 淇″彿锛坆ar[1]+纭锛?
   if(InpShowSignals) for(int i=limit;i>=1;i--) {
      bool alignUp=(e1[i]>e2[i]&&e2[i]>e3[i]&&e3[i]>e4[i]);    // 多头排列
      bool alignDn=(e1[i]<e2[i]&&e2[i]<e3[i]&&e3[i]<e4[i]);    // 空头排列
      bool fullAlignUp=(e1[i]>e2[i]&&e2[i]>e3[i]&&e3[i]>e4[i]&&e4[i]>e5[i]);  // 全排列多头
      bool fullAlignDn=(e1[i]<e2[i]&&e2[i]<e3[i]&&e3[i]<e4[i]&&e4[i]<e5[i]);  // 全排列空头
      double close=iClose(_Symbol,_Period,i);
      // === 强信号（多条件确认）===
      int buyScore=0,sellScore=0;
      if(e1[i+1]<=e2[i+1]&&e1[i]>e2[i])buyScore++;  // C1: e1上穿e2
      if(e1[i+1]<=e3[i+1]&&e1[i]>e3[i])buyScore++;  // C2: e1上穿e3
      if(fullAlignUp)buyScore++;                       // C3: 全多头排列
      if(close>e5[i])buyScore++;                       // C4: 价格在最长均线上方
      if(e1[i+1]>=e2[i+1]&&e1[i]<e2[i])sellScore++;  // C1: e1下穿e2
      if(e1[i+1]>=e3[i+1]&&e1[i]<e3[i])sellScore++;  // C2: e1下穿e3
      if(fullAlignDn)sellScore++;                      // C3: 全空头排列
      if(close<e5[i])sellScore++;                       // C4: 价格在最长均线下方
      // 强买入：3+条件
      if(buyScore>=3)strongBuy[i]=iLow(_Symbol,_Period,i)-14*Point;
      // 强卖出：3+条件
      if(sellScore>=3)strongSell[i]=iHigh(_Symbol,_Period,i)+14*Point;
      // === 常规信号 ===
      // 短线上穿长线+多头排列 -> 买入
      if(e1[i+1]<=e2[i+1]&&e1[i]>e2[i]&&alignUp)buySignal[i]=iLow(_Symbol,_Period,i)-10*Point;
      // 短线下穿长线+空头排列 -> 卖出
      if(e1[i+1]>=e2[i+1]&&e1[i]<e2[i]&&alignDn)sellSignal[i]=iHigh(_Symbol,_Period,i)+10*Point;
      // 短线同时上穿中线和长线+多头排列 -> 强买入（常规信号补充）
      if(e1[i+1]<=e3[i+1]&&e1[i]>e3[i]&&alignUp)buySignal[i]=iLow(_Symbol,_Period,i)-12*Point;
   }

   // 鍒锋柊bar[0]
   if(Bars>0){
      double p0[360];for(int j=0;j<hist;j++)p0[j]=iClose(_Symbol,_Period,j);
      e1[0]=CalcEMA(p0,InpEMA1,0);e2[0]=e2[1];e3[0]=e3[1];e4[0]=e4[1];e5[0]=e5[1];
      buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=strongSell[0]=EMPTY_VALUE;
   }
   return(0);
}

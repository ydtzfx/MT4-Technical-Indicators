//+------------------------------------------------------------------+
//|                                                  EXPMA_Safe.mq4   |
//|  指数平均线（EXPMA）— 不含未来函数                                |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  同时显示5条EMA线，构成多周期均线系统                              |
//|  默认参数：5/10/20/60/120                                          |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：短线上穿长线 + 均线多头排列(bar[1]确认)                  |
//|  - 卖出：短线下穿长线 + 均线空头排列(bar[1]确认)                  |
//|  - 均线密集后发散 → 趋势启动信号                                 |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 7

input int  InpEMA1=5, InpEMA2=10, InpEMA3=20, InpEMA4=60, InpEMA5=120;
input bool InpShowSignals=true;
input color InpC1=clrLimeGreen, InpC2=clrYellow, InpC3=clrOrange, InpC4=clrDodgerBlue, InpC5=clrMagenta;

double e1[],e2[],e3[],e4[],e5[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,InpC1);SetIndexBuffer(0,e1);SetIndexLabel(0,"EMA"+IntegerToString(InpEMA1));
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,InpC2);SetIndexBuffer(1,e2);SetIndexLabel(1,"EMA"+IntegerToString(InpEMA2));
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,InpC3);SetIndexBuffer(2,e3);SetIndexLabel(2,"EMA"+IntegerToString(InpEMA3));
   SetIndexStyle(3,DRAW_LINE,STYLE_SOLID,2,InpC4);SetIndexBuffer(3,e4);SetIndexLabel(3,"EMA"+IntegerToString(InpEMA4));
   SetIndexStyle(4,DRAW_LINE,STYLE_SOLID,2,InpC5);SetIndexBuffer(4,e5);SetIndexLabel(4,"EMA"+IntegerToString(InpEMA5));
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(5,buySignal);SetIndexArrow(5,ARROW_BUY);SetIndexEmptyValue(5,EMPTY_VALUE);
   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(6,sellSignal);SetIndexArrow(6,ARROW_SELL);SetIndexEmptyValue(6,EMPTY_VALUE);
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

   // 计算5条EMA
   for(int i=limit;i>=1;i--) {
      double p[360];for(int j=0;j<hist&&(i+j<Bars);j++)p[j]=iClose(_Symbol,_Period,i+j);
      e1[i]=CalcEMA(p,InpEMA1,0);e2[i]=CalcEMA(p,InpEMA2,0);e3[i]=CalcEMA(p,InpEMA3,0);
      e4[i]=CalcEMA(p,InpEMA4,0);e5[i]=CalcEMA(p,InpEMA5,0);
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }

   // 信号（bar[1]+确认）
   if(InpShowSignals) for(int i=limit;i>=1;i--) {
      bool alignUp=(e1[i]>e2[i]&&e2[i]>e3[i]&&e3[i]>e4[i]);    // 多头排列
      bool alignDn=(e1[i]<e2[i]&&e2[i]<e3[i]&&e3[i]<e4[i]);    // 空头排列
      // 短线上穿长线+多头排列 → 买入
      if(e1[i+1]<=e2[i+1]&&e1[i]>e2[i]&&alignUp)buySignal[i]=iLow(_Symbol,_Period,i)-10*Point;
      // 短线下穿长线+空头排列 → 卖出
      if(e1[i+1]>=e2[i+1]&&e1[i]<e2[i]&&alignDn)sellSignal[i]=iHigh(_Symbol,_Period,i)+10*Point;
      // 短线同时上穿中线和长线 → 强买入
      if(e1[i+1]<=e3[i+1]&&e1[i]>e3[i]&&alignUp)buySignal[i]=iLow(_Symbol,_Period,i)-12*Point;
   }

   // 刷新bar[0]
   if(Bars>0){
      double p0[360];for(int j=0;j<hist;j++)p0[j]=iClose(_Symbol,_Period,j);
      e1[0]=CalcEMA(p0,InpEMA1,0);e2[0]=e2[1];e3[0]=e3[1];e4[0]=e4[1];e5[0]=e5[1];
      buySignal[0]=sellSignal[0]=EMPTY_VALUE;
   }
   return(0);
}

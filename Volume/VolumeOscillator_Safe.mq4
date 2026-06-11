//+------------------------------------------------------------------+
//|                                      VolumeOscillator_Safe.mq4    |
//|  成交量振荡器 — 不含未来函数                                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：VO=100*(EMA(V,Fast)-EMA(V,Slow))/EMA(V,Slow)                |
//|  正值=放量(短期超长期)，负值=缩量                                  |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_level1 0

input int InpFast=5,InpSlow=10;

double vo[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,2);SetIndexBuffer(0,vo);SetIndexLabel(0,"Vol Osc");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   IndicatorDigits(1);IndicatorShortName("VolOsc_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpSlow*3;if(limit<0)limit=0;

   double aF=2.0/(InpFast+1),aS=2.0/(InpSlow+1);
   for(int i=limit+InpSlow;i>=1;i--){ // 预计算EMA
      double eF=0,eS=0;for(int j=0;j<InpSlow*2;j++){double v=iVolume(_Symbol,_Period,i+j);eF+=v;eS+=v;}
      eF/=InpSlow*2;eS/=InpSlow*2;
      for(int j=InpSlow*2-1;j>=0;j--){double v=iVolume(_Symbol,_Period,i+j);eF=v*aF+eF*(1-aF);eS=v*aS+eS*(1-aS);}
      if(i<=limit){vo[i]=SafeDivide(100*(eF-eS),eS,0);buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;}
   }
   for(int i=limit;i>=1;i--){
      // 放量+价格涨=多头确认
      if(vo[i]>20&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1))buySignal[i]=vo[i]*0.5;
      // 放量+价格跌=空头确认
      if(vo[i]>20&&iClose(_Symbol,_Period,i)<iClose(_Symbol,_Period,i+1))sellSignal[i]=vo[i]*1.5;
   }
   if(Bars>0){vo[0]=vo[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}

//+------------------------------------------------------------------+
//|                                              PairsRatio_Safe.mq4  |
//|  配对交易比率 — 统计套利指标                                       |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  概念：计算当前品种与配对品种的价格比率                             |
//|  Ratio = Price1 / Price2, 归一化到ZScore                           |
//|  比率偏离均值>2σ→做空比率（买弱卖强），<-2σ→做多比率（买强卖弱）  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_minimum -4
#property indicator_maximum 4
#property indicator_level1 2
#property indicator_level2 -2

input string InpPairSymbol="EURUSD";input int InpPeriod=20;input int InpRatioPeriod=50;

double ratioZ[],ratioRaw[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,ratioZ);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Ratio Z-Score");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrYellow);SetIndexBuffer(1,ratioRaw);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Raw Ratio");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(2);IndicatorShortName("PairsRatio_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      double p1=iClose(_Symbol,_Period,i);
      int b2=iBarShift(InpPairSymbol,_Period,iTime(_Symbol,_Period,i));
      double p2=b2>=0?iClose(InpPairSymbol,_Period,b2):p1;
      double ratio=p2>0?p1/p2:1;
      ratioRaw[i]=ratio;

      // 计算比率的ZScore
      if(i+InpPeriod<Bars){
         double sum=0;for(int j=0;j<InpPeriod;j++)sum+=ratioRaw[i+j];double mean=sum/InpPeriod;
         double sd=0;for(int j=0;j<InpPeriod;j++){double d=ratioRaw[i+j]-mean;sd+=d*d;}
         sd=MathSqrt(sd/InpPeriod);ratioZ[i]=sd>0?(ratio-mean)/sd:0;
      }
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=3;i--){
      // 比率Z<-2 = 当前品种相对被低估 → 做多当前品种
      if(ratioZ[i+1]<-2&&ratioZ[i]>-2)buySignal[i]=-2.5;
      // 比率Z>2 = 当前品种相对被高估 → 做空当前品种
      if(ratioZ[i+1]>2&&ratioZ[i]<2)sellSignal[i]=2.5;
   }
   if(Bars>0){ratioZ[0]=ratioZ[1];ratioRaw[0]=ratioRaw[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}

//+------------------------------------------------------------------+
//|                                                   ZScore_Safe.mq4 |
//|  Z分数指标 — 统计偏离度指标                                        |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：Z = (Price - SMA) / StdDev                                   |
//|  |Z|>2 = 价格显著偏离均值（95%置信区间外）                           |
//|  |Z|>3 = 极端偏离（99.7%外，高概率回归）                             |
//|  是Bollinger %B的更严格统计版本                                    |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_minimum -4
#property indicator_maximum 4
#property indicator_level1 2
#property indicator_level2 -2

input int InpPeriod=20;

double zScore[],signal[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,zScore);SetIndexLabel(0,"Z-Score");
   SetIndexStyle(1,DRAW_LINE,STYLE_DOT,1,clrYellow);SetIndexBuffer(1,signal);SetIndexLabel(1,"Signal");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(2);IndicatorShortName("ZScore_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpPeriod*2;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      double sum=0;for(int j=0;j<InpPeriod;j++)sum+=iClose(_Symbol,_Period,i+j);double sma=sum/InpPeriod;
      double sd=0;for(int j=0;j<InpPeriod;j++){double d=iClose(_Symbol,_Period,i+j)-sma;sd+=d*d;}
      sd=MathSqrt(sd/InpPeriod);
      zScore[i]=sd>0?(iClose(_Symbol,_Period,i)-sma)/sd:0;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i++){double s=0;for(int j=0;j<5;j++)s+=zScore[i+j];signal[i]=s/5;}

   for(int i=limit;i>=3;i--){
      // Z从<-2回升 → 超卖回归买入
      if(zScore[i+1]<-2&&zScore[i]>-2)buySignal[i]=-2.5;
      // Z从>2回落 → 超买回归卖出
      if(zScore[i+1]>2&&zScore[i]<2)sellSignal[i]=2.5;
      // Z从<-3回升 → 极端超卖强买入
      if(zScore[i+1]<-3&&zScore[i]>-3)buySignal[i]=-3.5;
      // Z从>3回落 → 极端超买强卖出
      if(zScore[i+1]>3&&zScore[i]<3)sellSignal[i]=3.5;
      // ZScore上穿Signal（趋势启动）
      if(zScore[i+1]<=signal[i+1]&&zScore[i]>signal[i]&&zScore[i]<0)buySignal[i]=zScore[i]-0.5;
   }
   if(Bars>0){zScore[0]=zScore[1];signal[0]=signal[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}

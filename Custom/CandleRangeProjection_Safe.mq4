//+------------------------------------------------------------------+
//|                                   CandleRangeProjection_Safe.mq4  |
//|  K线范围预测 — 基于近期K线统计估算下一根K线的高概率范围             |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input int InpPeriod=20;
double projHi[],projLo[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_LINE,STYLE_DOT,1,clrLimeGreen);SetIndexBuffer(0,projHi);SetIndexLabel(0,"Proj Hi");SetIndexStyle(1,DRAW_LINE,STYLE_DOT,1,clrTomato);SetIndexBuffer(1,projLo);SetIndexLabel(1,"Proj Lo");SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(4);IndicatorShortName("RangeProj_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=1;i--){
      double sumR=0,sumDir=0;int n=0;
      for(int j=1;j<=InpPeriod;j++){double r=iHigh(_Symbol,_Period,i+j)-iLow(_Symbol,_Period,i+j);sumR+=r;double dir=iClose(_Symbol,_Period,i+j)-iClose(_Symbol,_Period,i+j+1);sumDir+=dir;n++;}
      double avgR=sumR/n;double avgDir=sumDir/n;double c=iClose(_Symbol,_Period,i);
      // 预测范围 = 当前收盘 + 平均方向 ± 平均范围/2
      projHi[i]=c+avgDir+avgR/2;projLo[i]=c+avgDir-avgR/2;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=3;i++){
      // 实际K线超越预测高=超强→买入
      if(iClose(_Symbol,_Period,i-1)>projHi[i])buySignal[i-1]=iLow(_Symbol,_Period,i-1)-5*Point;
      // 实际K线低于预测低=超弱→卖出
      if(iClose(_Symbol,_Period,i-1)<projLo[i])sellSignal[i-1]=iHigh(_Symbol,_Period,i-1)+5*Point;
   }
   return(0);}

//+------------------------------------------------------------------+
//|                                          CandleOverlap_Safe.mq4   |
//|  K线重叠度 — 当前K线与前一根的重叠百分比                            |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum 0
#property indicator_maximum 100
input int InpSmooth=5;
double overlap[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,overlap);SetIndexLabel(0,"Overlap%");SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("Overlap_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=1;i--){
      double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i);
      double ph=iHigh(_Symbol,_Period,i+1),pl=iLow(_Symbol,_Period,i+1),pRange=ph-pl;
      // 重叠区域 = min(h,ph)-max(l,pl)，负值=有缺口
      double ov=MathMin(h,ph)-MathMax(l,pl);overlap[i]=pRange>0?MathMax(0,100*ov/pRange):0;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=3;i++){
      // 重叠率从极低(缺口/突破)回到正常水平=趋势确认后回踩
      if(overlap[i+1]<20&&overlap[i]>50)buySignal[i]=overlap[i]-5;
      // 重叠率持续>90=压缩盘整，突破后信号
      if(overlap[i+2]>90&&overlap[i+1]>90&&overlap[i]<50&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1))buySignal[i]=overlap[i]-10;
   }
   if(Bars>0){overlap[0]=overlap[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}

//+------------------------------------------------------------------+
//|                                  CandleCloseVsPrevRange_Safe.mq4  |
//|  收盘vs前范围 — 当前收盘在前一根K线范围内的位置                    |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum -100
#property indicator_maximum 100
double cvp[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,cvp);SetIndexLabel(0,"Close vs Prev");SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("CvsP_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=1;i++){
      double c=iClose(_Symbol,_Period,i),ph=iHigh(_Symbol,_Period,i+1),pl=iLow(_Symbol,_Period,i+1),pRange=ph-pl;
      // 收盘vs前范围：>100=突破前高，<0=跌破前低，0-100=在前范围内
      cvp[i]=pRange>0?100*(c-pl)/pRange:50;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=3;i++){
      // 连续在上半区(>60)→强势整理后突破
      if(cvp[i+2]>60&&cvp[i+1]>60&&cvp[i]>100)buySignal[i]=100;
      // 从>100回落到<80=假突破确认
      if(cvp[i+1]>100&&cvp[i]<80)sellSignal[i]=80;
      // 从<0回升到>20=假跌破反弹
      if(cvp[i+1]<0&&cvp[i]>20)buySignal[i]=20;
   }
   if(Bars>0){cvp[0]=cvp[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}return(0);}

//+------------------------------------------------------------------+
//|                                           ColorChange_Safe.mq4    |
//|  K线变色 — 连续同色后第一根异色K线的意义                           |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input int InpStreakMin=3; // 至少连续N根后变色
double colorBull[],colorBear[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(0,colorBull);SetIndexArrow(0,ARROW_BUY);SetIndexLabel(0,"Turn Bull");SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(1,colorBear);SetIndexArrow(1,ARROW_SELL);SetIndexLabel(1,"Turn Bear");SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("ColorChg_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){colorBull[i]=colorBear[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   for(int i=limit;i>=3;i++){
      bool isBull=iClose(_Symbol,_Period,i)>iOpen(_Symbol,_Period,i);
      bool prevBull=iClose(_Symbol,_Period,i+1)>iOpen(_Symbol,_Period,i+1);
      if(isBull!=prevBull){
         int streak=1;for(int j=2;j<=10;j++){if(iClose(_Symbol,_Period,i+j)>iOpen(_Symbol,_Period,i+j)==prevBull)streak++;else break;}
         if(streak>=InpStreakMin){
            double body=MathAbs(iClose(_Symbol,_Period,i)-iOpen(_Symbol,_Period,i)),r=iHigh(_Symbol,_Period,i)-iLow(_Symbol,_Period,i);
            if(isBull&&body>r*0.4){colorBull[i]=iLow(_Symbol,_Period,i)-5*Point;if(streak>=5)buySignal[i]=iLow(_Symbol,_Period,i)-12*Point;}
            if(!isBull&&body>r*0.4){colorBear[i]=iHigh(_Symbol,_Period,i)+5*Point;if(streak>=5)sellSignal[i]=iHigh(_Symbol,_Period,i)+12*Point;}
         }
      }
   }
   return(0);}

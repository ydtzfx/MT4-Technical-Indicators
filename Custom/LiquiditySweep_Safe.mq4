//+------------------------------------------------------------------+
//|                                          LiquiditySweep_Safe.mq4  |
//|  流动性清扫（Liquidity Sweep / Stop Hunt）— ICT/SMC                |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  概念：价格故意突破前期高点/低点制造假突破，扫掉止损后立即反转      |
//|  Bullish Sweep：价格跌破前期低点后迅速拉回（扫多头止损→反转上涨）   |
//|  Bearish Sweep：价格突破前期高点后迅速回落（扫空头止损→反转下跌）   |
//|  确认：突破后需在3根bar内回归突破位                                |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4

input int InpSwingPeriod=10; // 找摆动高/低点的周期
input int InpReturnBars=3;   // 回归确认bar数

double bullSweep[],bearSweep[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(0,bullSweep);SetIndexArrow(0,ARROW_BUY);SetIndexLabel(0,"Bullish Sweep");SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(1,bearSweep);SetIndexArrow(1,ARROW_SELL);SetIndexLabel(1,"Bearish Sweep");SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexLabel(2,"Sweep Confirmed");SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexLabel(3,"Sweep Confirmed");SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("LiquiditySweep_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){bullSweep[i]=EMPTY_VALUE;bearSweep[i]=EMPTY_VALUE;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;}

   for(int i=limit;i>=InpSwingPeriod+InpReturnBars;i--){
      // 找近期摆动高点（潜在流动性池）
      double swingHigh=iHigh(_Symbol,_Period,i+1),swingLow=iLow(_Symbol,_Period,i+1);
      for(int j=2;j<=InpSwingPeriod;j++){
         double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);
         if(h>swingHigh)swingHigh=h;if(l<swingLow)swingLow=l;
      }

      // === 看涨Sweep：价格跌破摆动低点后迅速回归 ===
      for(int j=1;j<=InpReturnBars;j++){
         if(iLow(_Symbol,_Period,i+j-1)<swingLow-2*Point){ // 跌破
            bool recovered=true;
            for(int k=0;k<j;k++)if(iClose(_Symbol,_Period,i+k)<=swingLow)recovered=false;
            if(recovered&&iClose(_Symbol,_Period,i)>swingLow){ // 拉回
               bullSweep[i+j-1]=swingLow-5*Point;
               buySignal[i]=iLow(_Symbol,_Period,i)-10*Point;
            }
            break;
         }
      }

      // === 看跌Sweep：价格突破摆动高点后迅速回落 ===
      for(int j=1;j<=InpReturnBars;j++){
         if(iHigh(_Symbol,_Period,i+j-1)>swingHigh+2*Point){
            bool recovered=true;
            for(int k=0;k<j;k++)if(iClose(_Symbol,_Period,i+k)>=swingHigh)recovered=false;
            if(recovered&&iClose(_Symbol,_Period,i)<swingHigh){
               bearSweep[i+j-1]=swingHigh+5*Point;
               sellSignal[i]=iHigh(_Symbol,_Period,i)+10*Point;
            }
            break;
         }
      }
   }
   return(0);
}

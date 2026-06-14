#include "../Include/Common.mqh"
#include "../Include/Drawing.mqh"
//+------------------------------------------------------------------+
//|                                            MurreyMath_Safe.mq4    |
//|  莫里数学线（Murrey Math Lines）— 不含未来函数                    |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  基于Gann理论，将价格范围分成8等份（+4等份超限区）                |
//|  关键线：0/8,1/8,2/8,3/8,4/8,5/8,6/8,7/8,8/8                     |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2

input int InpPeriod=64;input double InpStepBack=0;

double buySig[],sellSig[];

int init() {
   SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(0,buySig);SetIndexArrow(0,ARROW_BUY);SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(1,sellSig);SetIndexArrow(1,ARROW_SELL);SetIndexEmptyValue(1,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("MurreyMath_Safe");return(0);
}
int deinit(){RemoveAllObjects();return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   RemoveAllObjects();
   for(int i=limit;i>=InpPeriod;i--){
      double hh=iHigh(_Symbol,_Period,i),ll=iLow(_Symbol,_Period,i);
      for(int j=1;j<InpPeriod;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>hh)hh=h;if(l<ll)ll=l;}
      double range=hh-ll,octave=range/8;
      if(octave<Point)continue;
      string levelNames[]={"0/8","1/8","2/8","3/8","4/8","5/8","6/8","7/8","8/8","+1/8","+2/8"};
      color lvlColors[]={clrGray,clrYellow,clrOrange,clrTomato,clrDodgerBlue,clrTomato,clrOrange,clrYellow,clrGray,clrMagenta,clrMagenta};
      for(int idx=0;idx<11;idx++){
         double price=ll+octave*(idx-1);
         string nm=OBJ_PREFIX+"MM_"+IntegerToString(i)+"_"+IntegerToString(idx);
         if(ObjectFind(nm)<0){
            ObjectCreate(nm,OBJ_HLINE,0,0,price);ObjectSet(nm,OBJPROP_COLOR,lvlColors[idx]);
            ObjectSet(nm,OBJPROP_STYLE,(idx==0||idx==8)?STYLE_SOLID:STYLE_DOT);ObjectSet(nm,OBJPROP_BACK,true);
         }
      }
      double c=iClose(_Symbol,_Period,i);
      if(c<ll+octave*2)buySig[i]=ll-5*Point;      // 接近0/8支撑
      if(c>ll+octave*6)sellSig[i]=hh+5*Point;     // 接近8/8阻力
      break; // 每根bar只画最近一组
   }
   return(0);
}

#include "../Include/Common.mqh"
#include "../Include/Drawing.mqh"
//+------------------------------------------------------------------+
//|                                             Fibonacci_Safe.mq4    |
//|  斐波那契回撤线 — 不含未来函数（基于已完成的高低点）               |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  基于N根bar内的最高点和最低点绘制Fibonacci回撤/扩展线               |
//|  关键水平：0, 23.6, 38.2, 50, 61.8, 78.6, 100, 161.8, 261.8     |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2

input int InpLookback=100;     // 回溯bar数
input int InpConfirmation=5;   // 确认bar数（高低点右侧有N根不突破才确认）
input bool InpShowExtension=true; // 显示扩展线

double highPoint[],lowPoint[];

int init() {
   SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,1,clrTomato);SetIndexBuffer(0,highPoint);SetIndexArrow(0,ARROW_SELL);SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,1,clrLimeGreen);SetIndexBuffer(1,lowPoint);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("Fibonacci_Safe");return(0);
}
int deinit(){RemoveAllObjects();return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   RemoveAllObjects();
   double fibLevels[]={0,0.236,0.382,0.5,0.618,0.786,1.0,1.618,2.618};
   color fibColors[]={clrGray,clrYellow,clrOrange,clrRed,clrGreen,clrBlue,clrGray,clrMagenta,clrMagenta};

   // 找已确认的高低点
   for(int i=Bars-InpConfirmation-1;i>=InpLookback+InpConfirmation;i--){
      double hh=iHigh(_Symbol,_Period,i),ll=iLow(_Symbol,_Period,i);
      for(int j=1;j<=InpLookback;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>hh)hh=h;if(l<ll)ll=l;}
      bool isHigh=true,isLow=true;
      for(int jj=1;j<=InpConfirmation;j++){
         if(iHigh(_Symbol,_Period,i-j)>=hh)isHigh=false;
         if(iLow(_Symbol,_Period,i-j)<=ll)isLow=false;
      }
      if(isHigh)highPoint[i]=hh+5*Point;
      if(isLow)lowPoint[i]=ll-5*Point;
      if(isHigh&&isLow){ // 找到完整的波段
         double range=hh-ll;
         for(int f=0;f<(InpShowExtension?9:7);f++){
            double level=ll+range*fibLevels[f];
            string nm=OBJ_PREFIX+"FIB_"+IntegerToString(i)+"_"+IntegerToString(f);
            if(ObjectFind(nm)<0){
               ObjectCreate(nm,OBJ_HLINE,0,0,level);
               ObjectSet(nm,OBJPROP_COLOR,fibColors[f]);ObjectSet(nm,OBJPROP_STYLE,f>6?STYLE_DOT:STYLE_DASH);
               ObjectSet(nm,OBJPROP_WIDTH,f==3||f==4?2:1);ObjectSet(nm,OBJPROP_BACK,true);
            }
         }
      }
   }
   return(0);
}

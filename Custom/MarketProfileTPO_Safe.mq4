#include "../Include/Common.mqh"
#include "../Include/Drawing.mqh"
//+------------------------------------------------------------------+
//|                                        MarketProfileTPO_Safe.mq4  |
//|  市场轮廓TPO — 原创指标                                            |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  概念：统计每个价格水平出现的TPO（Time Price Opportunity）次数       |
//|  价格被交易的时间越长=该价位越重要（价值区域）                       |
//|  POC(Point of Control)=TPO最多的价格                                |
//|  Value Area=覆盖70%TPO的价格区间                                    |
//|  用于判断日内/波段交易的关键支撑阻力                                |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2

input int InpTPOBars=100;   // TPO统计bar数
input int InpLevels=40;     // 价格分段数
input double InpValueArea=0.7; // 价值区域比例

double buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(0,buySignal);SetIndexArrow(0,ARROW_BUY);SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(1,sellSignal);SetIndexArrow(1,ARROW_SELL);SetIndexEmptyValue(1,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("MarketProfile_Safe");return(0);
}
int deinit(){RemoveAllObjects();return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-300;if(limit<0)limit=0;
   RemoveAllObjects();

   for(int i=limit;i>=InpTPOBars;i--){
      // 确定价格范围
      double hh=iHigh(_Symbol,_Period,i),ll=iLow(_Symbol,_Period,i);
      for(int j=1;j<InpTPOBars;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>hh)hh=h;if(l<ll)ll=l;}
      double step=(hh-ll)/InpLevels;if(step<Point)continue;

      // 统计每个价格水平的TPO
      int tpo[];ArrayResize(tpo,InpLevels);ArrayInitialize(tpo,0);
      for(int jj=0;j<InpTPOBars;j++){
         h=iHigh(_Symbol,_Period,i+j);l=iLow(_Symbol,_Period,i+j);
         int hi=(int)((h-ll)/step),li=(int)((l-ll)/step);
         hi=MathMax(0,MathMin(InpLevels-1,hi));li=MathMax(0,MathMin(InpLevels-1,li));
         for(int k=li;k<=hi;k++)tpo[k]++;
      }

      // 找POC（最大TPO）
      int maxTPO=0,pocIdx=0,totalTPO=0;
      for(int p=0;p<InpLevels;p++){totalTPO+=tpo[p];if(tpo[p]>maxTPO){maxTPO=tpo[p];pocIdx=p;}}
      double poc=ll+pocIdx*step+step/2;

      // 价值区域（覆盖ValueArea比例的TPO）
      int vaTarget=(int)(totalTPO*InpValueArea);int vaSum=tpo[pocIdx];
      int vaHigh=pocIdx,vaLow=pocIdx;
      while(vaSum<vaTarget&&(vaHigh<InpLevels-1||vaLow>0)){
         if(vaHigh<InpLevels-1&&(vaLow<=0||tpo[vaHigh+1]>=tpo[vaLow-1])){vaHigh++;vaSum+=tpo[vaHigh];}
         else{vaLow--;vaSum+=tpo[vaLow];}
      }
      double vah=ll+vaHigh*step+step/2,val=ll+vaLow*step+step/2;

      // 绘制POC和VA边界
      string nm=OBJ_PREFIX+"POC_"+IntegerToString(i);
      if(ObjectFind(nm)<0){ObjectCreate(nm,OBJ_HLINE,0,0,poc);ObjectSet(nm,OBJPROP_COLOR,clrYellow);ObjectSet(nm,OBJPROP_WIDTH,2);}
      nm=OBJ_PREFIX+"VAH_"+IntegerToString(i);
      if(ObjectFind(nm)<0){ObjectCreate(nm,OBJ_HLINE,0,0,vah);ObjectSet(nm,OBJPROP_COLOR,clrDodgerBlue);ObjectSet(nm,OBJPROP_STYLE,STYLE_DOT);}
      nm=OBJ_PREFIX+"VAL_"+IntegerToString(i);
      if(ObjectFind(nm)<0){ObjectCreate(nm,OBJ_HLINE,0,0,val);ObjectSet(nm,OBJPROP_COLOR,clrDodgerBlue);ObjectSet(nm,OBJPROP_STYLE,STYLE_DOT);}

      // 信号：价格在VA之外=极端位置
      double c=iClose(_Symbol,_Period,i);
      if(c<val)buySignal[i]=val-5*Point;   // 低于价值区=超卖
      if(c>vah)sellSignal[i]=vah+5*Point;  // 高于价值区=超买
      break;
   }
   return(0);
}

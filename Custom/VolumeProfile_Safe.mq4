//+------------------------------------------------------------------+
//|                                          VolumeProfile_Safe.mq4   |
//|  成交量分布（Volume Profile）— 不含未来函数                       |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  统计N根bar内每个价格水平的成交量分布                               |
//|  POC(Point of Control)=成交量最大的价格，VAH/VAL=价值区域上下界    |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2

input int InpProfileBars=100;input int InpPriceLevels=50;

double buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(0,buySignal);SetIndexArrow(0,ARROW_BUY);SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(1,sellSignal);SetIndexArrow(1,ARROW_SELL);SetIndexEmptyValue(1,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("VolProfile_Safe");return(0);
}
int deinit(){RemoveAllObjects();return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   RemoveAllObjects();
   for(int i=limit;i>=InpProfileBars;i--){
      double hh=iHigh(_Symbol,_Period,i),ll=iLow(_Symbol,_Period,i);
      for(int j=1;j<InpProfileBars;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>hh)hh=h;if(l<ll)ll=l;}
      double step=(hh-ll)/InpPriceLevels;if(step<Point)continue;
      double volByPrice[];ArrayResize(volByPrice,InpPriceLevels);ArrayInitialize(volByPrice,0);
      for(int j=0;j<InpProfileBars;j++){
         double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);long v=iVolume(_Symbol,_Period,i+j);
         int bidx=(int)((h-ll)/step);int sidx=(int)((l-ll)/step);
         bidx=MathMax(0,MathMin(InpPriceLevels-1,bidx));sidx=MathMax(0,MathMin(InpPriceLevels-1,sidx));
         if(bidx==sidx)volByPrice[bidx]+=v;else for(int k=sidx;k<=bidx;k++)volByPrice[k]+=v/(bidx-sidx+1);
      }
      // 找POC
      double maxV=0;int pocIdx=0;
      for(int p=0;p<InpPriceLevels;p++)if(volByPrice[p]>maxV){maxV=volByPrice[p];pocIdx=p;}
      double poc=ll+pocIdx*step+step/2;
      string nm=OBJ_PREFIX+"POC_"+IntegerToString(i);
      if(ObjectFind(nm)<0){ObjectCreate(nm,OBJ_HLINE,0,0,poc);ObjectSet(nm,OBJPROP_COLOR,clrYellow);ObjectSet(nm,OBJPROP_STYLE,STYLE_DOT);}
      double c=iClose(_Symbol,_Period,i);
      if(c<poc&&c>ll+step*2)buySignal[i]=ll-5*Point;    // 价格在POC下方
      if(c>poc&&c<hh-step*2)sellSignal[i]=hh+5*Point;   // 价格在POC上方
      break;
   }
   return(0);
}

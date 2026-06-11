//+------------------------------------------------------------------+
//|                                           GridTrading_Safe.mq4    |
//|  网格交易指标 — 自动显示网格层级                                  |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  基于最近高低点自动生成等距/等比网格                                |
//|  标注当前价格所在的网格层级+到达上下层级的距离                      |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 2

input int InpGrids=10;input double InpGridSpacing=50; // 网格间距(点数)
input bool InpPercentGrid=false; // true=百分比间距

double buySignal[],sellSignal[];

int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(0,buySignal);SetIndexArrow(0,ARROW_BUY);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(1,sellSignal);SetIndexArrow(1,ARROW_SELL);SetIndexEmptyValue(1,EMPTY_VALUE);IndicatorDigits(4);IndicatorShortName("Grid_Safe");return(0);}
int deinit(){RemoveAllObjects();return(0);}

int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   RemoveAllObjects();
   for(int i=limit;i>=50;i--){
      double gridHi=iHigh(_Symbol,_Period,i+1),gridLo=iLow(_Symbol,_Period,i+1);
      for(int j=2;j<=50;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>gridHi)gridHi=h;if(l<gridLo)gridLo=l;}
      double step=InpPercentGrid?gridLo*InpGridSpacing/100:InpGridSpacing*Point;
      double c=iClose(_Symbol,_Period,i);
      for(int g=-InpGrids;g<=InpGrids;g++){
         double level=gridLo+(gridHi-gridLo)/2+g*step;
         string nm=OBJ_PREFIX+"GRID_"+IntegerToString(i)+"_"+IntegerToString(g);
         color clr=(g==0?clrWhite:clrGray);
         if(ObjectFind(nm)<0){ObjectCreate(nm,OBJ_HLINE,0,0,level);ObjectSet(nm,OBJPROP_COLOR,clr);ObjectSet(nm,OBJPROP_STYLE,g==0?STYLE_SOLID:STYLE_DOT);}
      }
      // 信号：到达网格下边界=买入，到达上边界=卖出
      int nearestLo=0,nearestHi=0;
      for(int g=-InpGrids;g<=0;g++){double lvl=gridLo+(gridHi-gridLo)/2+g*step;if(c>lvl&&c-lvl<step*0.3)nearestLo++;}
      for(int g=0;g<=InpGrids;g++){double lvl=gridLo+(gridHi-gridLo)/2+g*step;if(c<lvl&&lvl-c<step*0.3)nearestHi++;}
      if(nearestLo>0)buySignal[i]=gridLo;if(nearestHi>0)sellSignal[i]=gridHi;
      break;
   }
   return(0);}

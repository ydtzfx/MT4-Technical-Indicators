//+------------------------------------------------------------------+
//|                                      SwingMeasuredMove_Safe.mq4   |
//|  摆幅测量 — 基于已完成波段的等幅/扩展目标投影                      |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
double targetUp[],targetDn[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_LINE,STYLE_DOT,1,clrLimeGreen);SetIndexBuffer(0,targetUp);SetIndexLabel(0,"Target Up");SetIndexStyle(1,DRAW_LINE,STYLE_DOT,1,clrTomato);SetIndexBuffer(1,targetDn);SetIndexLabel(1,"Target Dn");SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(4);IndicatorShortName("SwingMM_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){targetUp[i]=targetDn[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   for(int i=limit;i>=5;i--){
      double hh=iHigh(_Symbol,_Period,i+1),ll=iLow(_Symbol,_Period,i+1);
      int hiBar=i+1,loBar=i+1;
      for(int j=2;j<10;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>hh){hh=h;hiBar=i+j;}if(l<ll){ll=l;loBar=i+j;}}
      double swing=hh-ll;if(swing<10*Point)continue;
      double c=iClose(_Symbol,_Period,i);
      // 等幅目标：从反转点加/减前一波幅度
      if(hiBar<loBar){targetUp[i]=c+swing;targetDn[i]=c-swing*0.618;if(c>hh)buySignal[i]=ll-5*Point;}
      else{targetDn[i]=c-swing;targetUp[i]=c+swing*0.618;if(c<ll)sellSignal[i]=hh+5*Point;}
   }return(0);}

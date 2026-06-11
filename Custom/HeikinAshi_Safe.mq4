//+------------------------------------------------------------------+
//|                                            HeikinAshi_Safe.mq4    |
//|  平均K线图（Heikin Ashi）— 不含未来函数                           |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：HA_Close=(O+H+L+C)/4, HA_Open=(HA_Open_prev+HA_Close_prev)/2|
//|  HA_High=Max(H,HA_Open,HA_Close), HA_Low=Min(L,HA_Open,HA_Close)  |
//|  平滑趋势显示，阳线连续=上升趋势，阴线连续=下降趋势                |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4

double haOpen[],haHigh[],haLow[],haClose[];

int init() {
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3,clrTomato);SetIndexBuffer(0,haOpen);SetIndexLabel(0,"HA Open");
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,3,clrTomato);SetIndexBuffer(1,haHigh);SetIndexLabel(1,"HA High");
   SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID,3,clrLimeGreen);SetIndexBuffer(2,haLow);SetIndexLabel(2,"HA Low");
   SetIndexStyle(3,DRAW_HISTOGRAM,STYLE_SOLID,3,clrLimeGreen);SetIndexBuffer(3,haClose);SetIndexLabel(3,"HA Close");
   IndicatorDigits(4);IndicatorShortName("HeikinAshi_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;

   for(int i=limit+50;i>=1;i--) {
      double o=iOpen(_Symbol,_Period,i),h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i);
      double hac=(o+h+l+c)/4;
      double hao;if(i>=Bars-2)hao=(o+c)/2;else hao=(haOpen[i+1]+haClose[i+1])/2;
      double hah=MathMax(h,MathMax(hao,hac)),hal=MathMin(l,MathMin(hao,hac));
      // 阴阳柱分别存放在不同缓冲区实现着色
      if(hac>=hao){haOpen[i]=hal;haHigh[i]=hah;haLow[i]=0;haClose[i]=0;}
      else{haLow[i]=hal;haClose[i]=hah;haOpen[i]=0;haHigh[i]=0;}
   }
   if(Bars>0){haOpen[0]=haOpen[1];haHigh[0]=haHigh[1];haLow[0]=haLow[1];haClose[0]=haClose[1];}
   return(0);
}

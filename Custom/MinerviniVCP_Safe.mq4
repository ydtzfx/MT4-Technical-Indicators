#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                         MinerviniVCP_Safe.mq4     |
//|  VCP形态（波动率收缩形态）— Mark Minervini's SEPA策略             |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  概念：每次回调的幅度递减（波动率收缩），最终突破时爆发              |
//|  检测：连续2-4次收缩+成交量萎缩+最终放量突破                       |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum 0
#property indicator_maximum 100

input int InpSwingBars=10; // 摆动点检测窗口

double vcpScore[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3,clrDodgerBlue);SetIndexBuffer(0,vcpScore);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"VCP Score");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   IndicatorDigits(0);IndicatorShortName("VCP_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   for(int i=limit;i>=InpSwingBars*3;i--){
      // 找最近的3-4个回调幅度
      double pullbacks[];ArrayResize(pullbacks,5);int pbCount=0;
      double prevHigh=iHigh(_Symbol,_Period,i+1);
      for(int j=2;j<InpSwingBars*4;j++){
         if(i+j>=Bars)break;
         double h=iHigh(_Symbol,_Period,i+j);bool isHigh=true;
         for(int k=1;k<=InpSwingBars/2;k++){if(i+j+k<Bars&&iHigh(_Symbol,_Period,i+j+k)>=h)isHigh=false;if(i+j-k>=0&&iHigh(_Symbol,_Period,i+j-k)>=h)isHigh=false;}
         if(isHigh&&pbCount<5){double pullback=h-iLow(_Symbol,_Period,i+j);for(int kk=0;k<InpSwingBars;k++){if(i+j+k<Bars){double l=iLow(_Symbol,_Period,i+j+k);if(l<iLow(_Symbol,_Period,i+j))pullback=h-l;}}pullbacks[pbCount++]=pullback;}
      }

      // 检测收缩：每轮回调幅度递减
      double vcpVal=0;
      if(pbCount>=3){
         int contractionCnt=0;
         for(int p=0;p<pbCount-1;p++)if(pullbacks[p+1]<pullbacks[p]*0.8)contractionCnt++;
         // 成交量也检查是否在收缩
         double volNow=iVolume(_Symbol,_Period,i),volAvg=0;for(int jj=0;j<20;j++)volAvg+=iVolume(_Symbol,_Period,i+j);volAvg/=20;
         double volRatio=volAvg>0?volNow/volAvg:1;

         vcpVal=contractionCnt*25; // 每次收缩25分
         if(volRatio<0.7)vcpVal+=25; // 缩量加分
         // 放量突破=触发
         if(volRatio>1.5&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1))vcpVal=MathMin(100,vcpVal+30);
      }
      vcpScore[i]=vcpVal;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=2;i--){
      if(vcpScore[i+1]<60&&vcpScore[i]>75)buySignal[i]=vcpScore[i]-10;
   }
   if(Bars>0){vcpScore[0]=vcpScore[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}

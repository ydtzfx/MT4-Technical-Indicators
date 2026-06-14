#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                         CandleVelocity_Safe.mq4   |
//|  K线速度 — 单位时间内的价格变动速率                                 |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 4
input int InpPeriod=5;
double velocity[],accel[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,velocity);SetIndexLabel(0,"Velocity");SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrYellow);SetIndexBuffer(1,accel);SetIndexLabel(1,"Acceleration");SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(1);IndicatorShortName("Velocity_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-50;if(limit<0)limit=0;
   for(int i=limit;i>=1;i--){
      double c=iClose(_Symbol,_Period,i),pc=iClose(_Symbol,_Period,i+1);
      double range=iHigh(_Symbol,_Period,i)-iLow(_Symbol,_Period,i);
      // 速度 = 价格变动/范围(标准化)
      velocity[i]=SafeDivide((c-pc),range,0)*100;
      accel[i]=velocity[i]-velocity[i+1];
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=3;i++){
      // 速度从负转正=方向改变
      if(velocity[i+1]<-20&&velocity[i]>20)buySignal[i]=-30;
      // 加速度持续放大=趋势加强
      if(accel[i+1]>0&&accel[i]>accel[i+1]&&velocity[i]>30)buySignal[i]=velocity[i]-10;
      // 减速=趋势衰竭
      if(velocity[i+1]>50&&velocity[i]<20&&velocity[i+2]>50)sellSignal[i]=velocity[i]+10;
   }
   if(Bars>0){velocity[0]=velocity[1];accel[0]=accel[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}

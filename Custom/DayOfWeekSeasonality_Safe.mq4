#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                      DayOfWeekSeasonality_Safe    |
//|  周日历效应 — 原创统计指标                                        |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  概念：统计每个星期几的历史平均涨跌和胜率                           |
//|  输出：当前星期几的统计期望值+置信度                                |
//|  正值=该日历史上倾向于上涨，负值=倾向于下跌                         |
//|  基于过去N周的同一天数据计算                                        |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_minimum -100
#property indicator_maximum 100
#property indicator_level1 0

input int InpWeeks=20; // 回溯周数

double seasonal[],confidence[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,seasonal);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Seasonality");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrYellow);SetIndexBuffer(1,confidence);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Confidence");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(0);IndicatorShortName("DoW_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-500;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      datetime t=iTime(_Symbol,_Period,i);int dow=TimeDayOfWeek(t); // 0=Sun..6=Sat
      // 收集过去N周同一天的数据
      double sumRet=0;int winCnt=0,total=0;
      for(int w=1;w<=InpWeeks;w++){
         for(int j=i;j<Bars;j++){
            datetime tj=iTime(_Symbol,_Period,j);
            if(TimeDayOfWeek(tj)==dow&&(j-i)>=(w-1)*7*24*60/Period()){
               double ret=iClose(_Symbol,_Period,j)-iClose(_Symbol,_Period,j+1);
               sumRet+=ret;if(ret>0)winCnt++;total++;break;
            }
         }
      }
      double avgRet=total>0?sumRet/total:0;
      double winRate=total>0?100.0*winCnt/total:50;
      seasonal[i]=avgRet/Point; // 以点数为单位
      confidence[i]=winRate;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=2;i--){
      // 季节性强正期望+高胜率
      if(seasonal[i]>5&&confidence[i]>65)buySignal[i]=seasonal[i]-2;
      // 季节性强负期望+高胜率
      if(seasonal[i]<-5&&confidence[i]>65)sellSignal[i]=seasonal[i]+2;
   }
   if(Bars>0){seasonal[0]=seasonal[1];confidence[0]=confidence[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}

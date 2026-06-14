#include "../Include/Common.mqh"
#include "../Include/PriceData.mqh"
//+------------------------------------------------------------------+
//|                                       GreeksSimulator_Safe.mq4    |
//|  期权希腊值模拟 — Delta/Gamma/Theta/Vega估算                       |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 4
input double InpStrike=0; // 0=自动使用当前价格
input int InpExpiryBars=20;
double delta[],gamma[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,delta);SetIndexLabel(0,"Delta");SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,2);SetIndexBuffer(1,gamma);SetIndexLabel(1,"Gamma");SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(3);IndicatorShortName("Greeks_Safe");return(0);}
int deinit(){return(0);}
double normCDF(double x){return 0.5*(1+CalcErf(x/MathSqrt(2)));}
double normPDF(double x){return MathExp(-x*x/2)/MathSqrt(2*3.14159);}
double CalcErf(double x){double t=1.0/(1.0+0.5*MathAbs(x)),tau=t*MathExp(-x*x-1.26551223+t*(1.00002368+t*(0.37409196+t*(0.09678418+t*(-0.18628806+t*(0.27886807+t*(-1.13520398+t*(1.48851587+t*(-0.82215223+t*0.17087277)))))))));return(x>=0?1-tau:tau-1);}
int start(){
   int i,cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(i=limit;i>=1;i--){
      double S=iClose(_Symbol,_Period,i);double K=InpStrike>0?InpStrike:S;
      double atr=0;for(int j=0;j<14;j++)atr+=GetTrueRange(_Symbol,_Period,i+j);atr/=14;
      double sigma=SafeDivide(atr,S,0.01); // 波动率代理
      double T=InpExpiryBars/260.0; // 年化到期时间
      double r=0.02; // 无风险利率(简化)
      if(sigma*MathSqrt(T)>0){
         double d1=(MathLog(S/K)+(r+sigma*sigma/2)*T)/(sigma*MathSqrt(T));
         delta[i]=normCDF(d1); // Call Delta
         gamma[i]=normPDF(d1)/(S*sigma*MathSqrt(T));
      }
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=2;i++){
      if(delta[i+1]<0.3&&delta[i]>0.3)buySignal[i]=0.25;     // Delta突破=方向确认
      if(delta[i+1]>0.7&&delta[i]<0.7)sellSignal[i]=0.75;    // Delta回落=方向减弱
   }
   if(Bars>0){delta[0]=delta[1];gamma[0]=gamma[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}

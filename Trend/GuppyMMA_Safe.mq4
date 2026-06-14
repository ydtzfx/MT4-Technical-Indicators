#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                                GuppyMMA_Safe.mq4  |
//|  顾比均线（Guppy MMA）— 不含未来函数                              |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  6条短期EMA(3,5,8,10,12,15)+6条长期EMA(30,35,40,45,50,60)         |
//|  短期组上穿长期组=趋势转多，短期组发散=趋势加速                    |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 16

input bool InpShowSignals=true;

// 12条EMA线 + 4个信号缓冲区
double s3[],s5[],s8[],s10[],s12[],s15[];
double l30[],l35[],l40[],l45[],l50[],l60[];
double buySignal[],sellSignal[];
double strongBuy[],strongSell[];

// 计算单个EMA值
double CalcE(double &p[],int per,int idx){
   int i;
   double e=0;
   for(i=idx+per;i<idx+per*2;i++)e+=p[i];
   e/=per;
   double a=2.0/(per+1);
   for(i=idx+per-1;i>=idx;i--)e=p[i]*a+e*(1-a);
   return e;
}

int init() {
   color sc[6]={clrLimeGreen,clrLimeGreen,clrLime,clrLime,clrYellowGreen,clrYellowGreen};
   color lc[6]={clrTomato,clrTomato,clrOrangeRed,clrOrangeRed,clrOrange,clrOrange};

   // 短期组 (0-5)
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,sc[0]);SetIndexBuffer(0,s3);SetIndexLabel(0,"S3");SetIndexEmptyValue(0,0);
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,sc[1]);SetIndexBuffer(1,s5);SetIndexLabel(1,"S5");SetIndexEmptyValue(1,0);
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,sc[2]);SetIndexBuffer(2,s8);SetIndexLabel(2,"S8");SetIndexEmptyValue(2,0);
   SetIndexStyle(3,DRAW_LINE,STYLE_SOLID,1,sc[3]);SetIndexBuffer(3,s10);SetIndexLabel(3,"S10");SetIndexEmptyValue(3,0);
   SetIndexStyle(4,DRAW_LINE,STYLE_SOLID,1,sc[4]);SetIndexBuffer(4,s12);SetIndexLabel(4,"S12");SetIndexEmptyValue(4,0);
   SetIndexStyle(5,DRAW_LINE,STYLE_SOLID,1,sc[5]);SetIndexBuffer(5,s15);SetIndexLabel(5,"S15");SetIndexEmptyValue(5,0);

   // 长期组 (6-11)
   SetIndexStyle(6,DRAW_LINE,STYLE_SOLID,1,lc[0]);SetIndexBuffer(6,l30);SetIndexLabel(6,"L30");SetIndexEmptyValue(6,0);
   SetIndexStyle(7,DRAW_LINE,STYLE_SOLID,1,lc[1]);SetIndexBuffer(7,l35);SetIndexLabel(7,"L35");SetIndexEmptyValue(7,0);
   SetIndexStyle(8,DRAW_LINE,STYLE_SOLID,1,lc[2]);SetIndexBuffer(8,l40);SetIndexLabel(8,"L40");SetIndexEmptyValue(8,0);
   SetIndexStyle(9,DRAW_LINE,STYLE_SOLID,1,lc[3]);SetIndexBuffer(9,l45);SetIndexLabel(9,"L45");SetIndexEmptyValue(9,0);
   SetIndexStyle(10,DRAW_LINE,STYLE_SOLID,1,lc[4]);SetIndexBuffer(10,l50);SetIndexLabel(10,"L50");SetIndexEmptyValue(10,0);
   SetIndexStyle(11,DRAW_LINE,STYLE_SOLID,1,lc[5]);SetIndexBuffer(11,l60);SetIndexLabel(11,"L60");SetIndexEmptyValue(11,0);

   // 信号缓冲区 (12-15)
   SetIndexStyle(12,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(12,buySignal);SetIndexArrow(12,ARROW_BUY);SetIndexEmptyValue(12,EMPTY_VALUE);
   SetIndexStyle(13,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(13,sellSignal);SetIndexArrow(13,ARROW_SELL);SetIndexEmptyValue(13,EMPTY_VALUE);
   SetIndexBuffer(14,strongBuy);SetIndexStyle(14,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexArrow(14,233);SetIndexEmptyValue(14,EMPTY_VALUE);
   SetIndexBuffer(15,strongSell);SetIndexStyle(15,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexArrow(15,234);SetIndexEmptyValue(15,EMPTY_VALUE);

   IndicatorDigits(4);IndicatorShortName("GuppyMMA_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int i, j, k;
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   // 历史计算
   for(i=limit;i>=1;i--) {
      double p[200];
      for(j=0;j<200&&(i+j<Bars);j++)p[j]=iClose(_Symbol,_Period,i+j);

      // 逐条计算12条EMA（MQL4不支持指针数组，必须展开）
      s3[i]  = CalcE(p,3,0);  s5[i]  = CalcE(p,5,0);
      s8[i]  = CalcE(p,8,0);  s10[i] = CalcE(p,10,0);
      s12[i] = CalcE(p,12,0); s15[i] = CalcE(p,15,0);

      l30[i] = CalcE(p,30,0); l35[i] = CalcE(p,35,0);
      l40[i] = CalcE(p,40,0); l45[i] = CalcE(p,45,0);
      l50[i] = CalcE(p,50,0); l60[i] = CalcE(p,60,0);

      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }

   // 信号判断
   if(InpShowSignals) for(i=limit;i>=1;i--) {
      strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
      // 强信号：交叉 + 中期确认(s5>l35) + 短期组发散
      if(s3[i+1]<=l60[i+1]&&s3[i]>l60[i]&&s5[i]>l35[i]&&s3[i]-s15[i]>s3[i+1]-s15[i+1])
         strongBuy[i]=iLow(_Symbol,_Period,i)-15*Point;
      if(s3[i+1]>=l60[i+1]&&s3[i]<l60[i]&&s5[i]<l35[i]&&s15[i]-s3[i]>s15[i+1]-s3[i+1])
         strongSell[i]=iHigh(_Symbol,_Period,i)+15*Point;
      // 标准信号：最短短期组上穿最长长期组
      if(s3[i+1]<=l60[i+1]&&s3[i]>l60[i])buySignal[i]=iLow(_Symbol,_Period,i)-15*Point;
      if(s3[i+1]>=l60[i+1]&&s3[i]<l60[i])sellSignal[i]=iHigh(_Symbol,_Period,i)+15*Point;
   }

   // bar[0] 显示刷新
   if(Bars>0){
      s3[0]=s3[1];  s5[0]=s5[1];    s8[0]=s8[1];
      s10[0]=s10[1];s12[0]=s12[1];  s15[0]=s15[1];
      l30[0]=l30[1];l35[0]=l35[1];  l40[0]=l40[1];
      l45[0]=l45[1];l50[0]=l50[1];  l60[0]=l60[1];
      buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=strongSell[0]=EMPTY_VALUE;
   }
   return(0);
}

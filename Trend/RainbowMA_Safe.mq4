#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                               RainbowMA_Safe.mq4  |
//|  彩虹均线（Rainbow MA）— 不含未来函数                              |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  20条EMA(2,4,6,...,40)用渐变色显示，均线束发散/收缩判断趋势       |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 24

input bool InpShowSignals=true;

double m0[],m1[],m2[],m3[],m4[],m5[],m6[],m7[],m8[],m9[];
double m10[],m11[],m12[],m13[],m14[],m15[],m16[],m17[],m18[],m19[];
double buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   for(int i=0;i<20;i++) {
      int r=(i<10)?(i*25):(255-(i-10)*25);int g=(i<10)?(255-i*25):(i-10)*25;int b=128-i*6;
      string clr=IntegerToString(r)+","+IntegerToString(g)+","+IntegerToString(b);
      switch(i){
         case 0:SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(0,m0);SetIndexLabel(0,"MA2");SetIndexEmptyValue(0,0);break;
         case 1:SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(1,m1);SetIndexLabel(1,"MA4");SetIndexEmptyValue(1,0);break;
         case 2:SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(2,m2);SetIndexLabel(2,"MA6");SetIndexEmptyValue(2,0);break;
         case 3:SetIndexStyle(3,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(3,m3);SetIndexLabel(3,"MA8");SetIndexEmptyValue(3,0);break;
         case 4:SetIndexStyle(4,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(4,m4);SetIndexLabel(4,"MA10");SetIndexEmptyValue(4,0);break;
         case 5:SetIndexStyle(5,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(5,m5);SetIndexLabel(5,"MA12");SetIndexEmptyValue(5,0);break;
         case 6:SetIndexStyle(6,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(6,m6);SetIndexLabel(6,"MA14");SetIndexEmptyValue(6,0);break;
         case 7:SetIndexStyle(7,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(7,m7);SetIndexLabel(7,"MA16");SetIndexEmptyValue(7,0);break;
         case 8:SetIndexStyle(8,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(8,m8);SetIndexLabel(8,"MA18");SetIndexEmptyValue(8,0);break;
         case 9:SetIndexStyle(9,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(9,m9);SetIndexLabel(9,"MA20");SetIndexEmptyValue(9,0);break;
         case 10:SetIndexStyle(10,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(10,m10);SetIndexLabel(10,"MA22");SetIndexEmptyValue(10,0);break;
         case 11:SetIndexStyle(11,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(11,m11);SetIndexLabel(11,"MA24");SetIndexEmptyValue(11,0);break;
         case 12:SetIndexStyle(12,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(12,m12);SetIndexLabel(12,"MA26");SetIndexEmptyValue(12,0);break;
         case 13:SetIndexStyle(13,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(13,m13);SetIndexLabel(13,"MA28");SetIndexEmptyValue(13,0);break;
         case 14:SetIndexStyle(14,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(14,m14);SetIndexLabel(14,"MA30");SetIndexEmptyValue(14,0);break;
         case 15:SetIndexStyle(15,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(15,m15);SetIndexLabel(15,"MA32");SetIndexEmptyValue(15,0);break;
         case 16:SetIndexStyle(16,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(16,m16);SetIndexLabel(16,"MA34");SetIndexEmptyValue(16,0);break;
         case 17:SetIndexStyle(17,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(17,m17);SetIndexLabel(17,"MA36");SetIndexEmptyValue(17,0);break;
         case 18:SetIndexStyle(18,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(18,m18);SetIndexLabel(18,"MA38");SetIndexEmptyValue(18,0);break;
         case 19:SetIndexStyle(19,DRAW_LINE,STYLE_SOLID,1,StringToColor(clr));SetIndexBuffer(19,m19);SetIndexLabel(19,"MA40");SetIndexEmptyValue(19,0);break;
      }
   }
   SetIndexStyle(20,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(20,buySignal);SetIndexArrow(20,ARROW_BUY);SetIndexEmptyValue(20,EMPTY_VALUE);
   SetIndexStyle(21,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(21,sellSignal);SetIndexArrow(21,ARROW_SELL);SetIndexEmptyValue(21,EMPTY_VALUE);
   SetIndexBuffer(22,strongBuy);SetIndexStyle(22,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexArrow(22,233);SetIndexEmptyValue(22,EMPTY_VALUE);
   SetIndexBuffer(23,strongSell);SetIndexStyle(23,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexArrow(23,234);SetIndexEmptyValue(23,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("RainbowMA_Safe");return(0);
}
int deinit(){return(0);}

// 计算单条EMA
double CalcE(double &p[],int per){double e=0;int j;for(j=100-per;j<100;j++)e+=p[j];e/=per;double a=2.0/(per+1);for(j=100-per-1;j>=0;j--)e=p[j]*a+e*(1-a);return e;}

int start() {
   int i, j, k;
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-150;if(limit<0)limit=0;

   for(i=limit;i>=1;i--) {
      double p[100];
      for(j=0;j<100&&(i+j<Bars);j++)p[j]=iClose(_Symbol,_Period,i+j);
      m0[i]=CalcE(p,2);m1[i]=CalcE(p,4);m2[i]=CalcE(p,6);m3[i]=CalcE(p,8);m4[i]=CalcE(p,10);
      m5[i]=CalcE(p,12);m6[i]=CalcE(p,14);m7[i]=CalcE(p,16);m8[i]=CalcE(p,18);m9[i]=CalcE(p,20);
      m10[i]=CalcE(p,22);m11[i]=CalcE(p,24);m12[i]=CalcE(p,26);m13[i]=CalcE(p,28);m14[i]=CalcE(p,30);
      m15[i]=CalcE(p,32);m16[i]=CalcE(p,34);m17[i]=CalcE(p,36);m18[i]=CalcE(p,38);m19[i]=CalcE(p,40);
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }

   if(InpShowSignals) for(i=limit;i>=2;i--) {
      if(m0[i+1]<=m19[i+1]&&m0[i]>m19[i]) {
         bool aligned=true;
         if(m0[i]<=m1[i]||m1[i]<=m2[i]||m2[i]<=m3[i]||m3[i]<=m4[i]||m4[i]<=m5[i]||m5[i]<=m6[i]||m6[i]<=m7[i]||m7[i]<=m8[i]||m8[i]<=m9[i])aligned=false;
         if(m9[i]<=m10[i]||m10[i]<=m11[i]||m11[i]<=m12[i]||m12[i]<=m13[i]||m13[i]<=m14[i]||m14[i]<=m15[i]||m15[i]<=m16[i]||m16[i]<=m17[i]||m17[i]<=m18[i]||m18[i]<=m19[i])aligned=false;
         if(aligned) strongBuy[i]=iLow(_Symbol,_Period,i)-30*Point;
         else buySignal[i]=iLow(_Symbol,_Period,i)-20*Point;
      }
      if(m0[i+1]>=m19[i+1]&&m0[i]<m19[i]) {
         aligned=true;
         if(m0[i]>=m1[i]||m1[i]>=m2[i]||m2[i]>=m3[i]||m3[i]>=m4[i]||m4[i]>=m5[i]||m5[i]>=m6[i]||m6[i]>=m7[i]||m7[i]>=m8[i]||m8[i]>=m9[i])aligned=false;
         if(m9[i]>=m10[i]||m10[i]>=m11[i]||m11[i]>=m12[i]||m12[i]>=m13[i]||m13[i]>=m14[i]||m14[i]>=m15[i]||m15[i]>=m16[i]||m16[i]>=m17[i]||m17[i]>=m18[i]||m18[i]>=m19[i])aligned=false;
         if(aligned) strongSell[i]=iHigh(_Symbol,_Period,i)+30*Point;
         else sellSignal[i]=iHigh(_Symbol,_Period,i)+20*Point;
      }
   }

   if(Bars>0){
      m0[0]=m0[1];m1[0]=m1[1];m2[0]=m2[1];m3[0]=m3[1];m4[0]=m4[1];
      m5[0]=m5[1];m6[0]=m6[1];m7[0]=m7[1];m8[0]=m8[1];m9[0]=m9[1];
      m10[0]=m10[1];m11[0]=m11[1];m12[0]=m12[1];m13[0]=m13[1];m14[0]=m14[1];
      m15[0]=m15[1];m16[0]=m16[1];m17[0]=m17[1];m18[0]=m18[1];m19[0]=m19[1];
      buySignal[0]=sellSignal[0]=strongBuy[0]=strongSell[0]=EMPTY_VALUE;
   }
   return(0);
}

//+------------------------------------------------------------------+
//|                                                GapAnalyzer_Safe   |
//|  缺口分析器 — 原创指标                                            |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  概念：检测四种缺口类型并评估回补概率                               |
//|  1. 普通缺口（Common）：盘整中产生，大概率回补                      |
//|  2. 突破缺口（Breakaway）：趋势启动，部分回补或不回补               |
//|  3. 持续缺口（Runaway）：趋势中加速，较少回补                       |
//|  4. 衰竭缺口（Exhaustion）：趋势末端，高概率回补+反转               |
//|  基于缺口位置+成交量+波动率进行缺口分类                             |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4

input double InpMinGapPct=0.1; // 最小缺口(%ATR)

double gapUp[],gapDn[],gapFilled[],gapUnfilled[];

int init() {
   SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,clrLimeGreen);SetIndexBuffer(0,gapUp);SetIndexArrow(0,ARROW_BUY);SetIndexLabel(0,"Gap Up");SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,clrTomato);SetIndexBuffer(1,gapDn);SetIndexArrow(1,ARROW_SELL);SetIndexLabel(1,"Gap Down");SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(2,gapFilled);SetIndexArrow(2,ARROW_BUY);SetIndexLabel(2,"Gap Filled");SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(3,gapUnfilled);SetIndexArrow(3,ARROW_SELL);SetIndexLabel(3,"Gap Holding");SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(0);IndicatorShortName("GapAnalyzer_Safe");return(0);
}
int deinit(){return(0);}

// 判断缺口类型：1=Common, 2=Breakaway, 3=Runaway, 4=Exhaustion
int ClassifyGap(int bar,bool isUp,double gapSize,double atr){
   double c=iClose(_Symbol,_Period,bar);
   // 计算趋势强度：之前5根bar的方向
   int trendDir=0;for(int j=1;j<=5;j++){if(iClose(_Symbol,_Period,bar+j)>iClose(_Symbol,_Period,bar+j+1))trendDir++;else trendDir--;}
   // 计算成交量
   double vR=SafeDivide((double)iVolume(_Symbol,_Period,bar),(double)iVolume(_Symbol,_Period,bar+10),1);
   // 计算ADX
   double trS=0,pS=0,mS=0;for(int j=0;j<10;j++){int s=bar+j;double h=iHigh(_Symbol,_Period,s),l=iLow(_Symbol,_Period,s),pc=iClose(_Symbol,_Period,s+1);trS+=MathMax(h-l,MathMax(MathAbs(h-pc),MathAbs(l-pc)));double up=h-iHigh(_Symbol,_Period,s+1),dn=iLow(_Symbol,_Period,s+1)-l;if(up>dn&&up>0)pS+=up;if(dn>up&&dn>0)mS+=dn;}
   double adx=SafeDivide(100*MathAbs(pS-mS),pS+mS,0);

   if(adx<20)return 1; // Common
   if(MathAbs(trendDir)<2&&vR>1.5)return 2; // Breakaway
   if(MathAbs(trendDir)>=3)return 3; // Runaway
   if(gapSize>atr*2&&vR>2)return 4; // Exhaustion
   return 1;
}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){gapUp[i]=EMPTY_VALUE;gapDn[i]=EMPTY_VALUE;gapFilled[i]=EMPTY_VALUE;gapUnfilled[i]=EMPTY_VALUE;}

   double atr=0;for(int j=0;j<14;j++)atr+=GetTrueRange(_Symbol,_Period,limit+10+j);atr/=14;

   for(int i=limit;i>=5;i--){
      double gap=iOpen(_Symbol,_Period,i)-iClose(_Symbol,_Period,i+1);
      double gapPct=SafeDivide(MathAbs(gap),atr,0)*100;

      if(gapPct>InpMinGapPct){
         int gType=ClassifyGap(i,gap>0,MathAbs(gap),atr);
         if(gap>0)gapUp[i]=iLow(_Symbol,_Period,i)-3*Point;
         else gapDn[i]=iHigh(_Symbol,_Period,i)+3*Point;

         // 判断是否已被回补（价格回到缺口内）
         bool filled=false;
         for(int j=0;j<i;j++){
            if(gap>0&&iLow(_Symbol,_Period,j)<=iClose(_Symbol,_Period,i+1))filled=true;
            else if(gap<0&&iHigh(_Symbol,_Period,j)>=iClose(_Symbol,_Period,i+1))filled=true;
         }
         if(filled){
            gapFilled[i]=(gap>0?iLow(_Symbol,_Period,i):iHigh(_Symbol,_Period,i))-(gap>0?3:-3)*Point;
            // 衰竭缺口的回补=反转信号
            if(gType==4)gapFilled[i]=iClose(_Symbol,_Period,i);
         }else gapUnfilled[i]=(gap>0?iLow(_Symbol,_Period,i):iHigh(_Symbol,_Period,i))+(gap>0?-8:8)*Point;
      }
   }
   return(0);
}

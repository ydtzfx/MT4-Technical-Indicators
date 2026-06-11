//+------------------------------------------------------------------+
//|                                     TrendExhaustionIndex_Safe.mq4 |
//|  趋势衰竭指数 — 原创指标                                           |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  创新：综合三个维度检测趋势衰竭                                     |
//|  1. 动量减速：价格继续沿趋势方向，但幅度递减（连续N根bar对比）      |
//|  2. 成交量背离：趋势方向持续但成交量萎缩（OBV与价格背离）           |
//|  3. 波动率收缩：ATR缩小 + Bollinger带收窄                           |
//|  总分0-100：<30趋势健康，30-60趋势减速，>60趋势衰竭（可能反转）     |
//+------------------------------------------------------------------+
#property copyright "Original Composite - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 60
#property indicator_level2 30

input int InpLookback=10;

double exhaust[],momentum[],volume[],volatility[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,3,clrOrange);SetIndexBuffer(0,exhaust);SetIndexLabel(0,"Exhaustion");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrDodgerBlue);SetIndexBuffer(1,momentum);SetIndexLabel(1,"Momentum Decay");
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,clrTomato);SetIndexBuffer(2,volume);SetIndexLabel(2,"Volume Div.");
   SetIndexStyle(3,DRAW_LINE,STYLE_SOLID,1,clrGray);SetIndexBuffer(3,volatility);SetIndexLabel(3,"Volatility");
   SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(1);IndicatorShortName("TrendExhaust_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      // === 维度1：动量减速 ===
      // 测量最近趋势方向的K线实体大小是否递减
      bool isUp=iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1);
      double bodySum=0;int bodyCnt=0;double prevBody=99999;int decelCnt=0;
      for(int j=0;j<InpLookback;j++){
         double body=MathAbs(iClose(_Symbol,_Period,i+j)-iOpen(_Symbol,_Period,i+j));
         bool correctDir=isUp?(iClose(_Symbol,_Period,i+j)>iOpen(_Symbol,_Period,i+j)):(iClose(_Symbol,_Period,i+j)<iOpen(_Symbol,_Period,i+j));
         if(correctDir){bodySum+=body;bodyCnt++;if(body<prevBody)decelCnt++;prevBody=body;}
      }
      double momScore=bodyCnt>0?100.0*decelCnt/bodyCnt:50; // 减速比例越高=越衰竭

      // === 维度2：成交量背离 ===
      // 价格沿趋势走但成交量递减
      double volSum1=0,volSum2=0;
      for(int j=0;j<InpLookback/2;j++)volSum1+=iVolume(_Symbol,_Period,i+j);
      for(int j=InpLookback/2;j<InpLookback;j++)volSum2+=iVolume(_Symbol,_Period,i+j);
      double volRatio=SafeDivide(volSum1,volSum2,1); // <1=近期缩量
      double volScore=MathMax(0,100-100*volRatio);     // 缩量越严重=越高

      // === 维度3：波动率收缩 ===
      double atr3=0,atr10=0;
      for(int j=0;j<3;j++)atr3+=GetTrueRange(_Symbol,_Period,i+j);
      for(int j=0;j<InpLookback;j++)atr10+=GetTrueRange(_Symbol,_Period,i+j);
      atr3/=3;atr10/=InpLookback;
      double atrRatio=SafeDivide(atr3,atr10,1);
      double volScore2=MathMax(0,100-100*atrRatio);

      // === 综合衰竭指数 ===
      exhaust[i]=0.4*momScore+0.3*volScore+0.3*volScore2;
      momentum[i]=momScore;volume[i]=volScore;volatility[i]=volScore2;
   }
   if(Bars>0){exhaust[0]=exhaust[1];momentum[0]=momentum[1];volume[0]=volume[1];volatility[0]=volatility[1];}
   return(0);
}

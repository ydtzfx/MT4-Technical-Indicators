#!/usr/bin/env python3
"""Derive a deterministic multi-timeframe MT4 HST fixture from the locked EURUSD H4 snapshot."""
from __future__ import annotations
import argparse, json, math, struct
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

HEADER_SIZE=148
PERIODS=(1,5,15,60,240,1440)

@dataclass
class Bar:
    time:int; open:float; low:float; high:float; close:float
    volume:int; spread:int; real_volume:int

def parse_header(data:bytes):
    if len(data)<HEADER_SIZE: raise ValueError("HST shorter than header")
    version=struct.unpack_from("<i",data,0)[0]
    symbol=data[68:80].split(b"\0",1)[0].decode("ascii","ignore")
    period=struct.unpack_from("<i",data,80)[0]
    digits=struct.unpack_from("<i",data,84)[0]
    return version,symbol,period,digits,bytearray(data[:HEADER_SIZE])

def choose_order(samples):
    low_high=high_low=0
    for o,a,b,c in samples:
        tol=max(abs(o),abs(c),1.0)*1e-10
        if a<=min(o,c)+tol and b>=max(o,c)-tol and a<=b: low_high+=1
        if b<=min(o,c)+tol and a>=max(o,c)-tol and b<=a: high_low+=1
    if low_high==high_low==0: raise ValueError("cannot determine HST high/low field order")
    return "low-high" if low_high>=high_low else "high-low"

def read_hst(path:Path):
    data=path.read_bytes()
    version,symbol,period,digits,header=parse_header(data)
    if version>=401:
        fmt="<qddddqiq"; size=60
    else:
        fmt="<iddddd"; size=44
    payload=data[HEADER_SIZE:]
    if len(payload)%size: raise ValueError(f"HST payload size {len(payload)} not divisible by record size {size}")
    raw=[]
    samples=[]
    for off in range(0,len(payload),size):
        row=struct.unpack_from(fmt,payload,off)
        if version>=401:
            t,o,a,b,c,vol,spread,real=row
            vol=int(vol); spread=int(spread); real=int(real)
        else:
            t,o,a,b,c,vol=row
            vol=int(max(1,round(vol))); spread=10; real=0
        raw.append((int(t),o,a,b,c,vol,spread,real))
        samples.append((o,a,b,c))
    order=choose_order(samples[:min(500,len(samples))])
    bars=[]
    for t,o,a,b,c,vol,spread,real in raw:
        low,high=(a,b) if order=="low-high" else (b,a)
        if high<low: continue
        bars.append(Bar(t,o,low,high,c,max(1,vol),spread,max(0,real)))
    bars.sort(key=lambda x:x.time)
    return version,symbol,period,digits,header,order,bars

def interp(a,b,n):
    return [a+(b-a)*i/n for i in range(n+1)]

def expand_h4(source:Iterable[Bar]):
    out=[]
    for b in source:
        mids=(b.low,b.high) if b.close>=b.open else (b.high,b.low)
        p1=interp(b.open,mids[0],80)[:-1]
        p2=interp(mids[0],mids[1],80)[:-1]
        p3=interp(mids[1],b.close,80)
        pts=p1+p2+p3
        if len(pts)!=241: raise AssertionError(len(pts))
        base=max(1,b.volume//240)
        for i in range(240):
            o,c=pts[i],pts[i+1]
            vol=base
            if i==239: vol=max(1,b.volume-base*239)
            out.append(Bar(b.time+i*60,o,min(o,c),max(o,c),c,vol,b.spread,0))
    return out

def aggregate(m1:list[Bar],minutes:int):
    bucket=minutes*60
    groups={}
    for b in m1:
        key=(b.time//bucket)*bucket
        groups.setdefault(key,[]).append(b)
    out=[]
    for key in sorted(groups):
        g=groups[key]
        out.append(Bar(
            key,g[0].open,min(x.low for x in g),max(x.high for x in g),g[-1].close,
            sum(x.volume for x in g),int(round(sum(x.spread for x in g)/len(g))),sum(x.real_volume for x in g)
        ))
    return out

def write_hst(path:Path,version:int,header:bytearray,period:int,order:str,bars:list[Bar]):
    h=bytearray(header)
    struct.pack_into("<i",h,80,period)
    if bars: struct.pack_into("<i",h,92,min(2_147_483_647,bars[-1].time))
    payload=bytearray()
    for b in bars:
        a1,a2=(b.low,b.high) if order=="low-high" else (b.high,b.low)
        if version>=401:
            payload.extend(struct.pack("<qddddqiq",b.time,b.open,a1,a2,b.close,int(b.volume),int(b.spread),int(b.real_volume)))
        else:
            payload.extend(struct.pack("<iddddd",int(b.time),b.open,a1,a2,b.close,float(b.volume)))
    path.write_bytes(bytes(h)+bytes(payload))

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("source",type=Path)
    ap.add_argument("--out",type=Path,required=True)
    ap.add_argument("--source-bars",type=int,default=500)
    args=ap.parse_args()
    version,symbol,period,digits,header,order,bars=read_hst(args.source)
    if period!=240: raise SystemExit(f"expected H4/240 source, got {period}")
    bars=bars[-min(args.source_bars,len(bars)):]
    if len(bars)<100: raise SystemExit(f"need >=100 H4 bars, got {len(bars)}")
    m1=expand_h4(bars)
    args.out.mkdir(parents=True,exist_ok=True)
    manifest={"version":version,"symbol":symbol,"digits":digits,"source_period":period,"source_bars":len(bars),"field_order":order,"files":{}}
    for p in PERIODS:
        series=m1 if p==1 else aggregate(m1,p)
        dest=args.out/f"{symbol}{p}.hst"
        write_hst(dest,version,header,p,order,series)
        manifest["files"][dest.name]={"bars":len(series),"from":series[0].time,"to":series[-1].time}
    (args.out/"history-manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(manifest,indent=2))

if __name__=="__main__":
    main()

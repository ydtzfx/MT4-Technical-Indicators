#!/usr/bin/env python3
from __future__ import annotations
import argparse, gzip, hashlib, json, shutil, urllib.request
from pathlib import Path

BASE="https://github.com/FX-Data/FX-Data-EURUSD-DS/releases/download/2019"
ASSETS={
    "EURUSD1.hst.gz":4786904,
    "EURUSD5.hst.gz":1236418,
    "EURUSD15.hst.gz":480793,
    "EURUSD60.hst.gz":137277,
    "EURUSD240.hst.gz":40357,
    "EURUSD1440.hst.gz":9809,
    "EURUSD60_2.fxt.gz":94027,
}

def sha256(path:Path)->str:
    h=hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda:f.read(1024*1024),b""):
            h.update(chunk)
    return h.hexdigest()

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--out",type=Path,required=True)
    args=ap.parse_args()
    args.out.mkdir(parents=True,exist_ok=True)
    manifest={"source_repo":"FX-Data/FX-Data-EURUSD-DS","release":"2019","assets":{}}
    for name,expected_size in ASSETS.items():
        gz=args.out/name
        req=urllib.request.Request(f"{BASE}/{name}",headers={"User-Agent":"P0.5-MT4-Verification"})
        with urllib.request.urlopen(req,timeout=120) as src, gz.open("wb") as dst:
            shutil.copyfileobj(src,dst)
        actual=gz.stat().st_size
        if actual!=expected_size:
            raise SystemExit(f"{name}: expected {expected_size} bytes, got {actual}")
        raw=args.out/name[:-3]
        with gzip.open(gz,"rb") as src, raw.open("wb") as dst:
            shutil.copyfileobj(src,dst)
        manifest["assets"][name]={
            "url":f"{BASE}/{name}",
            "compressed_bytes":actual,
            "compressed_sha256":sha256(gz),
            "output":raw.name,
            "output_bytes":raw.stat().st_size,
            "output_sha256":sha256(raw),
        }
        gz.unlink()
    (args.out/"fixture-manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(manifest,indent=2))

if __name__=="__main__":
    main()

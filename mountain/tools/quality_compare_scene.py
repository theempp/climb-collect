"""Compare complete mountain BasePart records across the native save/cold reopen."""
from pathlib import Path
import argparse,hashlib,json,math
from quality_evidence import load,EV

def normalized(rows):
    return sorted(rows,key=lambda r:(r['path'],r['class'],r['cf'][:3],r['size'],r['color']))

def compare(a,b):
    errors=[];max_delta=0.0
    def visit(x,y,path):
        nonlocal max_delta
        if isinstance(x,bool) or isinstance(y,bool):
            if x!=y: errors.append(path)
        elif isinstance(x,(int,float)) and isinstance(y,(int,float)):
            delta=abs(x-y);max_delta=max(max_delta,delta)
            if not math.isfinite(delta) or delta>0.00001:errors.append(path)
        elif isinstance(x,dict) and isinstance(y,dict):
            if x.keys()!=y.keys():errors.append(path+':keys');return
            for key in x:visit(x[key],y[key],path+'.'+key)
        elif isinstance(x,list) and isinstance(y,list):
            if len(x)!=len(y):errors.append(path+':length');return
            for i,(left,right) in enumerate(zip(x,y)):visit(left,right,path+f'[{i}]')
        elif x!=y:errors.append(path)
    visit(a,b,'mountain');return errors,max_delta

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('before');p.add_argument('after');args=p.parse_args()
    a,b=normalized(load(args.before)),normalized(load(args.after));errors,delta=compare(a,b)
    digest=lambda x:hashlib.sha256(json.dumps(x,sort_keys=True,separators=(',',':')).encode()).hexdigest()
    r={'before':args.before,'after':args.after,'parts_before':len(a),'parts_after':len(b),'exact':a==b,'before_sha256':digest(a),'after_sha256':digest(b),'maximum_numeric_delta':delta,'tolerance':0.00001,'differences':errors,'passed':not errors}
    (EV/'cold-scene-identity.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2));assert not errors

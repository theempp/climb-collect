-- Provisional local-review title thresholds; earned achievement is independent of paid frames.
local A={titles={{id='first_ascent',name='First Ascent',summits=1},{id='peak_regular',name='Peak Regular',summits=5},{id='summit_veteran',name='Summit Veteran',summits=25},{id='field_researcher',name='Field Researcher',percent=25},{id='master_naturalist',name='Master Naturalist',percent=75}}}
function A.total(routes) local n=0;for _,v in routes or {} do n+=v end;return n end
function A.unlocked(summary,routes)
 local out={};local n=A.total(routes)
 for _,t in A.titles do if (t.summits and n>=t.summits) or (t.percent and summary.obtainable>0 and summary.percent>=t.percent) then out[t.id]=true end end
 return out
end
function A.name(id) for _,t in A.titles do if t.id==id then return t.name end end return 'Explorer' end
return A

local R={timeout=25}
function R.state(sceneReady,assetsReady,elapsed,failures)
 if failures>0 then return 'retry' end
 if sceneReady and assetsReady then return 'ready' end
 if elapsed>=R.timeout then return 'retry' end
 return 'loading'
end
return R

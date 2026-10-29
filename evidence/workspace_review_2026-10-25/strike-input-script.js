
(() => {
 const root=document.getElementById('cc-strike-study');
 const probe=document.createElement('span');probe.hidden=true;root.appendChild(probe);
 const color=key=>{probe.style.color='var('+key+')';return getComputedStyle(probe).color;};
 const reduced=()=>matchMedia('(prefers-reduced-motion: reduce)').matches;
 const states=new Map();let holdTimer=null;
 root.querySelectorAll('section').forEach(el=>states.set(el,{hits:0,impact:0,sweep:null,raf:null,lastHit:0}));
 function draw(el){
  const s=states.get(el),canvas=el.querySelector('canvas');const w=Math.max(180,canvas.getBoundingClientRect().width),h=190,dpr=devicePixelRatio||1;
  canvas.width=w*dpr;canvas.height=h*dpr;const c=canvas.getContext('2d');c.scale(dpr,dpr);
  const cx=w*.45,cy=85;c.lineWidth=2;c.strokeStyle=color('--foreground');c.fillStyle=color('--viz-series-1');
  const shift=s.impact>0&&!reduced()?Math.sin(s.impact*Math.PI)*3:0;
  c.save();c.translate(cx+shift,cy);
  c.globalAlpha=.18;c.beginPath();c.moveTo(0,-46);c.bezierCurveTo(40,-42,46,30,22,42);c.bezierCurveTo(8,51,-32,45,-34,24);c.bezierCurveTo(-43,0,-25,-44,0,-46);c.fill();c.globalAlpha=1;c.stroke();
  if(s.hits>0){c.beginPath();c.moveTo(-4,-34);c.lineTo(7,-17);c.lineTo(-5,-3);c.lineTo(8,13);c.lineTo(-1,37);c.stroke();}
  if(s.hits>1){c.beginPath();c.moveTo(7,-17);c.lineTo(24,-22);c.moveTo(-5,-3);c.lineTo(-24,7);c.stroke();}
  if(s.hits>2){c.beginPath();c.moveTo(8,13);c.lineTo(27,20);c.moveTo(-4,-34);c.lineTo(-19,-27);c.stroke();}
  if(s.hits===4){c.clearRect(-43,-53,88,108);c.beginPath();c.moveTo(-34,17);c.lineTo(-23,8);c.lineTo(-15,21);c.lineTo(-4,11);c.lineTo(1,22);c.bezierCurveTo(2,49,-34,47,-34,17);c.stroke();c.beginPath();c.moveTo(15,-15);c.lineTo(29,-25);c.lineTo(39,-16);c.bezierCurveTo(44,-41,16,-52,15,-15);c.stroke();}
  if(s.impact>0){for(let i=0;i<4;i++){const x=38+i*6,y=-12+i*13;c.beginPath();c.moveTo(x,y);c.lineTo(x+6,y-3);c.lineTo(x+8,y+5);c.closePath();c.stroke();}}
  c.restore();
  if(s.hits<4){c.save();c.translate(cx+56,cy-43);c.rotate(-.65+s.impact*.8);c.beginPath();c.moveTo(0,0);c.lineTo(0,43);c.moveTo(-19,0);c.quadraticCurveTo(0,-10,20,0);c.stroke();c.restore();}
  if(el.dataset.mode==='timed'){
   const x=18,y=162,bw=w-36;c.fillStyle=color('--muted');c.fillRect(x,y,bw,8);c.fillStyle=color('--viz-series-1');c.fillRect(x+bw*.38,y,bw*.24,8);
   if(s.sweep!==null){c.fillStyle=color('--foreground');c.fillRect(x+bw*s.sweep-2,y-5,4,18);}
  }
 }
 function announce(el,msg){const s=states.get(el);el.querySelector('[data-status]').textContent=msg||(s.hits===4?'Shell open · preview complete':s.hits+' / 4 hits');}
 function hit(el){const s=states.get(el);if(s.hits===4)return;const now=performance.now();if(now-s.lastHit<160)return;s.lastHit=now;s.hits++;announce(el);s.impact=1;draw(el);
  if(reduced()){s.impact=0;draw(el);return;}
  const t=performance.now();function decay(now){s.impact=Math.max(0,1-(now-t)/180);draw(el);if(s.impact>0)requestAnimationFrame(decay);}requestAnimationFrame(decay);
 }
 function stopHold(){if(holdTimer!==null)clearInterval(holdTimer);holdTimer=null;}
 const hold=root.querySelector('[data-action="hold"]');const holdEl=hold.closest('section');
 function beginHold(){stopHold();hit(holdEl);if(states.get(holdEl).hits<4)holdTimer=setInterval(()=>{hit(holdEl);if(states.get(holdEl).hits===4)stopHold();},600);}
 hold.addEventListener('pointerdown',e=>{e.preventDefault();hold.setPointerCapture(e.pointerId);beginHold();});
 ['pointerup','pointercancel','lostpointercapture','blur'].forEach(event=>hold.addEventListener(event,stopHold));
 hold.addEventListener('keydown',e=>{if((e.key===' '||e.key==='Enter')&&!e.repeat){e.preventDefault();beginHold();}});
 hold.addEventListener('keyup',e=>{if(e.key===' '||e.key==='Enter'){e.preventDefault();stopHold();}});
 window.addEventListener('blur',stopHold);document.addEventListener('visibilitychange',()=>{if(document.hidden)stopHold();});
 root.querySelector('[data-action="hit"]').addEventListener('click',e=>hit(e.currentTarget.closest('section')));
 const timed=root.querySelector('[data-mode="timed"]'),start=timed.querySelector('[data-action="start"]'),strike=timed.querySelector('[data-action="timed-hit"]');
 function finishSweep(){const s=states.get(timed);if(s.raf!==null)cancelAnimationFrame(s.raf);s.raf=null;start.disabled=s.hits===4;strike.disabled=true;}
 start.addEventListener('click',()=>{const s=states.get(timed);if(s.hits===4)return;s.sweep=0;start.disabled=true;strike.disabled=false;const began=performance.now();
  function move(t){s.sweep=Math.min(1,(t-began)/2000);draw(timed);if(s.sweep<1)s.raf=requestAnimationFrame(move);else{finishSweep();announce(timed,'Sweep ended · start again');}}s.raf=requestAnimationFrame(move);
 });
 strike.addEventListener('click',()=>{const s=states.get(timed);if(s.sweep===null||strike.disabled)return;const good=s.sweep>=.38&&s.sweep<=.62;finishSweep();if(good)hit(timed);else announce(timed,'Miss · shell progress kept');start.disabled=s.hits===4;});
 const descriptions={A:'Tap each pickaxe strike',B:'Hold for repeated pickaxe swings',C:'Time each pickaxe hit with a target meter'};
 function applyState(v){if(v&&descriptions[v.strikeInput])root.querySelector('#cc-strike-choice').textContent='Selected: '+descriptions[v.strikeInput];}
 applyState(window.openai?.widgetState?.modelContent);window.addEventListener('openai:set_globals',e=>applyState(e.detail?.globals?.widgetState?.modelContent));
 root.querySelectorAll('[data-choice]').forEach(button=>button.addEventListener('click',async()=>{const choice=button.dataset.choice;applyState({strikeInput:choice});
  if(window.openai?.setWidgetState)window.openai.setWidgetState({modelContent:{strikeInput:choice},privateContent:null}).catch(()=>{});
  if(window.openai?.sendFollowUpMessage)await window.openai.sendFollowUpMessage({prompt:'For Climb & Collect pickaxe input I choose '+choice+': '+descriptions[choice]+'. Record this direction. The four-hit example and its speed are illustrative, not approved final balance. Continue the visual design questions without implementing game code.',title:'Choose '+descriptions[choice]});
 }));
 const ro=new ResizeObserver(()=>states.forEach((s,el)=>draw(el)));ro.observe(root);states.forEach((s,el)=>draw(el));
})();


(() => {
 const root=document.getElementById('cc-safety-review');const slider=root.querySelector('#cc-return-stage');
 const labels=['Nest','Checkpoint','Exit gate','Home'];const stages=['Mountain nest','Mountain checkpoint','Sanctuary exit gate','Owned home plot'];
 const descriptions={A:'The creature becomes permanently safe only when delivered to my own home plot. Mountain checkpoints do not secure it.',B:'The creature becomes permanently safe at a mountain checkpoint; I then carry it home for placement.',C:'The creature becomes permanently safe when crossing the mountain exit into the sanctuary; I then carry it home for placement.'};
 function draw(){const stage=Number(slider.value);root.querySelector('#cc-stage-name').textContent=stages[stage];
  root.querySelectorAll('section').forEach(section=>{
   const svg=section.querySelector('svg');const w=Math.max(280,svg.getBoundingClientRect().width);svg.setAttribute('viewBox','0 0 '+w+' 96');const margin=38;const x=i=>margin+(w-margin*2)*i/3;const safe=Number(section.dataset.safe);const protectedNow=stage>=safe;
   let marks='<title>'+section.querySelector('h3').textContent+'</title>';
   marks+='<line x1="'+x(0)+'" y1="43" x2="'+x(3)+'" y2="43" stroke="var(--border)" stroke-width="2"/>';
   if(safe<3)marks+='<line x1="'+x(safe)+'" y1="43" x2="'+x(3)+'" y2="43" stroke="var(--viz-series-1)" stroke-width="2"/>';
   for(let i=0;i<4;i++)marks+='<circle cx="'+x(i)+'" cy="43" r="5" fill="'+(i>=safe?'var(--viz-series-1)':'var(--muted-foreground)')+'"/><text x="'+x(i)+'" y="79" text-anchor="middle" fill="var(--foreground)" font-size="12">'+labels[i]+'</text>';
   marks+='<text x="'+x(safe)+'" y="16" text-anchor="middle" fill="var(--foreground)" font-size="12">Safe here</text>';
   marks+='<circle cx="'+x(stage)+'" cy="43" r="11" fill="var(--background)" stroke="var(--foreground)" stroke-width="2"/><circle cx="'+x(stage)+'" cy="43" r="4" fill="var(--foreground)"/>';
   svg.innerHTML=marks;section.querySelector('[data-result]').textContent=protectedNow?'Secured · permanently yours':'Unsecured · reach '+(safe===3?'home':safe===2?'the exit':'a checkpoint');
  });
 }
 function applyState(state){if(state&&descriptions[state.creatureSafeAt])root.querySelector('#cc-safety-choice').textContent='Selected: '+state.creatureSafeAt;}
 applyState(window.openai?.widgetState?.modelContent);window.addEventListener('openai:set_globals',e=>applyState(e.detail?.globals?.widgetState?.modelContent));
 slider.addEventListener('input',draw);new ResizeObserver(draw).observe(root);
 root.querySelectorAll('[data-pick]').forEach(button=>button.addEventListener('click',async()=>{const choice=button.dataset.pick;applyState({creatureSafeAt:choice});
  if(window.openai?.setWidgetState)window.openai.setWidgetState({modelContent:{creatureSafeAt:choice},privateContent:null}).catch(()=>{});
  if(window.openai?.sendFollowUpMessage)await window.openai.sendFollowUpMessage({prompt:'For Climb & Collect securing the revealed creature, I choose '+choice+': '+descriptions[choice]+' Record this direction. Fall recovery, travel/teleport rules and exact transport limits still need decisions; do not implement game code yet. Continue with visual design questions.',title:'Choose where the creature becomes safe'});
 }));draw();
})();

(function(root){
 'use strict';
 const tiers=[2,4,6,8,10,12],prices=[3,9,19,39,79,149];
 const products={
  bundle:{name:'Camp Glow bundle',price:19,art:'bundle',items:['lantern','banner'],detail:'Sunbeam lantern skin + camp banner. Two permanent cosmetics. 50% off versus buying both separately for 38 Robux (19 each).'},
  flag:{name:'Trail pennant',price:3,art:'flag',items:['flag'],detail:'A bright little pennant for your camp. Permanent cosmetic; no gameplay advantage.'},
  trail:{name:'Sparkle trail',price:5,art:'trail',items:['trail'],detail:'Leave a little starlight on the trail. Permanent cosmetic; no movement advantage.'},
  lantern:{name:'Sunbeam lantern skin',price:19,art:'lantern',items:['lantern'],detail:'A golden lantern skin for your camp. Permanent cosmetic; no change to gameplay lighting.'},
  banner:{name:'Sunbeam camp banner',price:19,art:'flag',items:['banner'],detail:'Fly the mountain colours at your cabin. Permanent cosmetic.'}
 };
 [100,350,900,2000].forEach((n,i)=>products['coins'+n]={name:n.toLocaleString('en-US')+' Cairn Coins',price:[9,25,59,119][i],art:i<2?'coins':'chest',coins:n,detail:`Adds exactly ${n.toLocaleString('en-US')} Cairn Coins. Purchased packs are never multiplied.`});
 tiers.forEach((n,i)=>products['upgrade'+i]={name:n+'× coin earnings',price:prices[i],art:'multiplier',tier:i+1,detail:`Permanently increase earned Cairn Coins from ${i?tiers[i-1]:1}× to ${n}× total. Not an additional ${n}×. Purchased coin packs are excluded.`});
 function initial(){return {version:1,tier:0,coins:1250,robux:500,owned:[],receipts:[],cabin:false};}
 function multiplier(s){return s.tier?tiers[s.tier-1]:1;}
 function status(s,id){const p=products[id];if(!p)return 'unavailable';if(p.tier)return p.tier===s.tier?'current':p.tier<s.tier?'owned':p.tier===s.tier+1?'next':'locked';if(p.items){const n=p.items.filter(x=>s.owned.includes(x)).length;return n===p.items.length?'owned':n?'partial':'available';}return 'available';}
 function quote(s,id){if(!['available','next'].includes(status(s,id)))return null;return {id,price:products[id].price,tier:s.tier};}
 function confirm(s,q,receipt){if(!q||!receipt||s.receipts.includes(receipt))return {ok:false,reason:'Receipt already handled or missing.'};const p=products[q.id],fresh=quote(s,q.id);if(!p||!fresh||q.price!==fresh.price||(p.tier&&q.tier!==s.tier))return {ok:false,reason:'Offer changed. Please select it again.'};if(s.robux<p.price)return {ok:false,reason:'Not enough simulated Robux.'};s.robux-=p.price;if(p.tier)s.tier=p.tier;if(p.coins)s.coins+=p.coins;if(p.items)s.owned.push(...p.items);s.receipts.push(receipt);return {ok:true,product:p};}
 function collect(s){const n=50*multiplier(s);s.coins+=n;return n;}
 function cabin(s){if(s.cabin||s.coins<1500)return false;s.coins-=1500;s.cabin=true;return true;}
 function restore(raw){try{const s=JSON.parse(raw);if(s.version!==1||!Number.isInteger(s.tier)||s.tier<0||s.tier>6||!Number.isSafeInteger(s.coins)||s.coins<0||!Number.isSafeInteger(s.robux)||s.robux<0||!Array.isArray(s.owned)||!s.owned.every(x=>['flag','trail','lantern','banner'].includes(x))||!Array.isArray(s.receipts)||typeof s.cabin!=='boolean')return initial();return s;}catch{return initial();}}
 const api={tiers,prices,products,initial,multiplier,status,quote,confirm,collect,cabin,restore};
 if(typeof module!=='undefined')module.exports=api;else root.Economy=api;
})(typeof window==='undefined'?globalThis:window);

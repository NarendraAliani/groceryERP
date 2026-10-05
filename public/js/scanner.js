(() => {
  const input=document.getElementById('barcodeInput');
  const status=document.getElementById('scannerStatus');
  const toggle=document.getElementById('cameraToggle');
  const reader=document.getElementById('reader');
  if(!input) return;
  let buffer=''; let last=0; let scanner=null; let running=false;
  const rapidMs=40;

  const lookup=(code)=>window.POSCart?.lookup(code);
  document.addEventListener('keydown',(e)=>{
    if(e.key==='Enter'){
      if(buffer.length>=4){ const code=buffer; buffer=''; e.preventDefault(); lookup(code); input.focus(); }
      return;
    }
    if(e.key.length!==1) return;
    const now=performance.now();
    if(now-last>rapidMs) buffer='';
    buffer+=e.key; last=now;
    if(document.activeElement!==input && /^[0-9A-Za-z-]+$/.test(e.key)) input.focus();
  });
  input.addEventListener('keydown',(e)=>{ if(e.key==='Enter'){e.preventDefault();const code=input.value.trim();if(code)lookup(code);input.value='';} });

  toggle?.addEventListener('click',async()=>{
    if(running){ await scanner.stop().catch(()=>{}); scanner.clear(); reader.hidden=true; running=false; toggle.textContent='Camera'; status.textContent='Hardware scanner ready'; input.focus(); return; }
    if(!window.Html5Qrcode){status.textContent='Camera library is still loading';return;}
    scanner=new Html5Qrcode('reader'); reader.hidden=false; running=true; toggle.textContent='Stop camera';
    try{
      await scanner.start({facingMode:'environment'},{fps:12,qrbox:{width:280,height:120}},code=>{lookup(code);},()=>{});
      status.textContent='Camera scanning';
    }catch(err){running=false;reader.hidden=true;toggle.textContent='Camera';status.textContent='Camera unavailable';}
  });
})();

(() => {
  const state={items:[],customerId:0};
  const csrf=()=>document.querySelector('meta[name="csrf-token"]')?.content||'';
  const money=n=>'₹'+Number(n||0).toFixed(2);
  const gstMode=()=>window.POS_CONFIG?.gstMode==='interstate'?'interstate':'local';
  const render=()=>{
    const body=document.querySelector('#cartTable tbody'); if(!body)return; body.innerHTML='';
    let sub=0,cgst=0,sgst=0,igst=0;
    state.items.forEach((x,i)=>{
      const taxable=Math.max(0,x.quantity*x.unit_price-x.discount_amount); const interstate=gstMode()==='interstate';
      const c=interstate?0:taxable*x.cgst_rate/100, s=interstate?0:taxable*x.sgst_rate/100, g=interstate?taxable*x.igst_rate/100:0;
      const total=taxable+c+s+g; sub+=taxable;cgst+=c;sgst+=s;igst+=g;
      const tr=document.createElement('tr');
      tr.innerHTML='<td>'+escapeHtml(x.name)+'</td><td><input data-qty="'+i+'" type="number" min="0.001" step="0.001" value="'+x.quantity.toFixed(3)+'"></td><td>'+money(x.unit_price)+'</td><td>'+money(c+s+g)+'</td><td>'+money(total)+'</td><td><button data-remove="'+i+'" type="button">×</button></td>';
      body.appendChild(tr);
    });
    document.getElementById('subtotal').textContent=money(sub);document.getElementById('cgst').textContent=money(cgst);document.getElementById('sgst').textContent=money(sgst);document.getElementById('igst').textContent=money(igst);document.getElementById('grandTotal').textContent=money(sub+cgst+sgst+igst);
    body.querySelectorAll('[data-qty]').forEach(el=>el.onchange=()=>{state.items[+el.dataset.qty].quantity=Math.max(.001,Number(el.value)||.001);render();});
    body.querySelectorAll('[data-remove]').forEach(el=>el.onclick=()=>{state.items.splice(+el.dataset.remove,1);render();});
  };
  const escapeHtml=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[c]));
  const lookup=async code=>{try{const r=await fetch('/api/pos/lookup?barcode='+encodeURIComponent(code));const j=await r.json();if(!j.success||!j.data.product){alert('Product not found');return;}const p=j.data.product;const q=Number(document.getElementById('quantityInput').value)||1;add(p,q);document.getElementById('uomLabel').textContent=p.unit_code;}catch(e){alert('Lookup failed; check connection.')}};
  const add=(p,q)=>{const old=state.items.find(x=>x.batch_id===Number(p.batch_id));if(old)old.quantity+=q;else state.items.push({...p,batch_id:Number(p.batch_id),quantity:q,unit_price:Number(p.selling_price),discount_amount:0,cgst_rate:Number(p.cgst_rate),sgst_rate:Number(p.sgst_rate),igst_rate:Number(p.igst_rate)});render();};
  const total=()=>Number(document.getElementById('grandTotal').textContent.replace(/[^0-9.]/g,''))||0;
  const checkout=()=>{if(!state.items.length){alert('Cart is empty');return;}document.getElementById('paymentPanel').hidden=false;};
  const confirm=async()=>{const amount=total();const payments=[...document.querySelectorAll('[data-payment]')].map(i=>({mode:i.dataset.payment,amount:Number(i.value)||0,reference_no:''})).filter(x=>x.amount>0);if(Math.abs(payments.reduce((a,x)=>a+x.amount,0)-amount)>.009){alert('Payment total must equal '+money(amount));return;}const payload={_csrf:csrf(),customer_id:state.customerId,items:state.items.map(x=>({batch_id:x.batch_id,quantity:Number(x.quantity.toFixed(3)),unit_price:Number(x.unit_price.toFixed(2)),discount_amount:Number(x.discount_amount.toFixed(2))})),payments};try{const r=await fetch('/api/pos/checkout',{method:'POST',headers:{'Content-Type':'application/json','X-CSRF-Token':csrf()},body:JSON.stringify(payload)});const j=await r.json();if(!r.ok||!j.success){alert(j.data?.message||'Checkout was rejected.');return;}showReceipt(j.data);state.items=[];render();document.getElementById('paymentPanel').hidden=true;}catch(e){await window.OfflineDB?.queue(payload);alert('Checkout could not reach the server. The transaction was queued locally.');}};
  const showReceipt=d=>{const el=document.getElementById('receipt');el.hidden=false;el.innerHTML='<strong>Paid</strong><br>Invoice '+escapeHtml(d.invoice_number)+'<br>Total '+money(d.grand_total);};
  document.getElementById('checkoutButton')?.addEventListener('click',checkout);document.getElementById('confirmPayment')?.addEventListener('click',confirm);document.getElementById('addLoose')?.addEventListener('click',()=>{const p=state.items.at(-1);if(p){p.quantity+=Number(document.getElementById('quantityInput').value)||1;render();}});
  document.getElementById('customerPhone')?.addEventListener('change',async e=>{const v=e.target.value.trim();if(!v)return;try{const r=await fetch('/api/customer/profile?phone='+encodeURIComponent(v));const j=await r.json();const c=j.data.customer;if(c){state.customerId=Number(c.customer_id);document.getElementById('customerInfo').textContent=c.name+' • '+c.loyalty_points+' pts • '+c.tier;}}catch(e){}});
  window.POSCart={lookup,render}; render();
})();

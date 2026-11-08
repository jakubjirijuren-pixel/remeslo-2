import EnergyBalance from './EnergyBalance.jsx';
import React,{useState} from 'react';
export default function EnergyFinance({db,org,meter,readings=[],manager,onSaved}){
 const [edit,setEdit]=useState(false),[busy,setBusy]=useState(false),[error,setError]=useState('');
 const [form,setForm]=useState({price:meter.unit_price_czk??'',advance:meter.monthly_advance_czk??'',fixed:meter.monthly_fixed_czk??0});
 const currency=n=>new Intl.NumberFormat('cs-CZ',{style:'currency',currency:'CZK',maximumFractionDigits:0}).format(n);
 const priced=meter.unit_price_czk!==null&&meter.unit_price_czk!==undefined;
 const advanceSet=meter.monthly_advance_czk!==null&&meter.monthly_advance_czk!==undefined;
 const sorted=[...readings].sort((a,b)=>new Date(a.read_at)-new Date(b.read_at));
 const first=sorted[0],last=sorted[sorted.length-1];
 const days=first&&last?(new Date(last.read_at)-new Date(first.read_at))/86400000:0;
 const months=days/(365.2425/12);
 const consumed=first&&last?Number(last.reading_value)-Number(first.reading_value):0;
 const quantity=meter.kind==='electricity'?consumed/1000:consumed;
 const cost=quantity*Number(meter.unit_price_czk||0)+months*Number(meter.monthly_fixed_czk||0);
 const paid=months*Number(meter.monthly_advance_czk||0);
 const balance=paid-cost;
 async function save(e){e.preventDefault();if(form.price===''||form.advance===''){setError('Vyplňte cenu i měsíční zálohu.');return}if([form.price,form.advance,form.fixed].some(x=>!Number.isFinite(Number(x))||Number(x)<0)){setError('Částky musí být nezáporná čísla.');return}setBusy(true);setError('');const {error}=await db.from('utility_meters').update({unit_price_czk:Number(form.price),monthly_advance_czk:Number(form.advance),monthly_fixed_czk:Number(form.fixed||0)}).eq('id',meter.id).eq('organization_id',org.id);setBusy(false);if(error){setError(error.message);return}setEdit(false);await onSaved()}
 return <section className="energy-finance"><div className="energy-finance-head"><div><strong>Vyúčtování energií</strong><small>Orientační přehled nákladů a záloh</small></div>{manager&&<button className="energy-finance-edit" type="button" onClick={()=>{setForm({price:meter.unit_price_czk??'',advance:meter.monthly_advance_czk??'',fixed:meter.monthly_fixed_czk??0});setEdit(v=>!v)}}>{edit?'Zrušit úpravy':'Upravit ceny a zálohy'}</button>}</div>{edit&&<form className="energy-finance-form" onSubmit={save}><div className="energy-finance-form-grid"><label><span>Cena za {meter.kind==='electricity'?'MWh':'m³'}</span><div className="energy-finance-input"><input required type="number" min="0" step="0.0001" placeholder="Např. 4500" value={form.price} onChange={e=>setForm(f=>({...f,price:e.target.value}))}/><span>Kč</span></div></label><label><span>Měsíční záloha</span><div className="energy-finance-input"><input required type="number" min="0" step="0.01" placeholder="Např. 2500" value={form.advance} onChange={e=>setForm(f=>({...f,advance:e.target.value}))}/><span>Kč</span></div></label><label className="energy-finance-form-wide"><span>Fixní měsíční poplatky</span><div className="energy-finance-input"><input type="number" min="0" step="0.01" value={form.fixed} onChange={e=>setForm(f=>({...f,fixed:e.target.value}))}/><span>Kč</span></div></label></div><button className="primary energy-finance-save" disabled={busy}>{busy?'Ukládám…':'Uložit nastavení'}</button>{error&&<p className="alert">{error}</p>}</form>}<EnergyBalance meter={meter} readings={readings}/></section>
}
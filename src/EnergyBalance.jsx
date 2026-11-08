import React from 'react';
export default function EnergyBalance({meter,readings=[],compact=false}){
 const money=n=>new Intl.NumberFormat('cs-CZ',{style:'currency',currency:'CZK',maximumFractionDigits:0}).format(n);
 const ready=meter.unit_price_czk!=null&&meter.monthly_advance_czk!=null;
 const rows=[...readings].map(r=>({value:Number(r.reading_value??r.value),date:r.read_at??r.date})).sort((a,b)=>new Date(a.date)-new Date(b.date));
 const first=rows[0],last=rows.at(-1),days=first&&last?(new Date(last.date)-new Date(first.date))/86400000:0;
 const months=days/(365.2425/12),consumption=first&&last?last.value-first.value:0;
 const units=meter.kind==='electricity'?consumption/1000:consumption;
 const cost=units*Number(meter.unit_price_czk||0)+months*Number(meter.monthly_fixed_czk||0);
 const advances=months*Number(meter.monthly_advance_czk||0),balance=advances-cost;
 return <div className={'energy-balance'+(compact?' energy-balance-compact':'')}>{!ready?<p className="energy-finance-muted">Cena a zálohy zatím nejsou nastavené.</p>:rows.length<2?<p className="energy-finance-muted">Pro finanční odhad jsou potřeba alespoň dva odečty.</p>:<><div className="energy-balance-top"><span>Orientační {balance>=0?'přeplatek':'nedoplatek'}</span><strong className={balance>=0?'positive':'negative'}>{balance>=0?'+':'−'}{money(Math.abs(balance))}</strong></div><div className="energy-balance-details"><div><span>Náklady</span><b>{money(cost)}</b></div><div><span>Odhad záloh</span><b>{money(advances)}</b></div><div><span>Spotřeba</span><b>{new Intl.NumberFormat('cs-CZ',{maximumFractionDigits:3}).format(units)} {meter.kind==='electricity'?'MWh':'m³'}</b></div><div><span>Měsíční záloha</span><b>{money(Number(meter.monthly_advance_czk))}</b></div></div><small className="energy-finance-muted">Od {new Date(first.date).toLocaleDateString('cs-CZ')} do {new Date(last.date).toLocaleDateString('cs-CZ')}. Odhad ze zadané ceny a poměrných měsíčních záloh, nikoliv skutečné vyúčtování nebo zaplacené platby.</small></>}</div>
}
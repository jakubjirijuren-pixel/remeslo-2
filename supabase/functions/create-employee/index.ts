import {createClient} from 'npm:@supabase/supabase-js@2.57.0';
const cors={'Access-Control-Allow-Origin':'https://jakubjirijuren-pixel.github.io','Access-Control-Allow-Headers':'authorization,apikey,content-type,x-client-info','Access-Control-Allow-Methods':'POST,OPTIONS'};
const out=(v,s=200)=>new Response(JSON.stringify(v),{status:s,headers:{...cors,'Content-Type':'application/json'}});
Deno.serve(async req=>{
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers:cors});
 if(req.method!=='POST')return out({error:'Method not allowed'},405);
 try{
 const token=req.headers.get('authorization')?.replace(/^Bearer\s+/i,'');
 if(!token)return out({error:'Přihlášení je povinné.'},401);
 const url=Deno.env.get('SUPABASE_URL')!,key=Deno.env.get('SUPABASE_ANON_KEY')||Deno.env.get('SUPABASE_PUBLISHABLE_KEY')!,secret=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
 const client=createClient(url,key,{global:{headers:{Authorization:'Bearer '+token}}});
 const {data:{user},error:authError}=await client.auth.getUser(token);
 if(authError||!user)return out({error:'Neplatné přihlášení.'},401);
 const input=await req.json(),org=String(input.organization_id||''),email=String(input.email||'').trim().toLowerCase(),password=String(input.password||''),role=String(input.role||'worker');
 if(!/^[0-9a-f-]{36}$/i.test(org)||!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)||!['worker','viewer','accountant'].includes(role))return out({error:'Neplatné údaje.'},400);
 if(password.length<12||password.length>128||!/[a-z]/.test(password)||!/[A-Z]/.test(password)||!/[0-9]/.test(password))return out({error:'Heslo musí mít 12–128 znaků, velké a malé písmeno a číslici.'},400);
 const {data:allowed,error:permissionError}=await client.rpc('can_manage_employees',{org});
 if(permissionError||allowed!==true)return out({error:'Nemáte oprávnění spravovat zaměstnance této organizace.'},403);
 const admin=createClient(url,secret,{auth:{autoRefreshToken:false,persistSession:false}});
 const {data:created,error:createError}=await admin.auth.admin.createUser({email,password,email_confirm:true});
 if(createError)return out({error:createError.message},400);
 const uid=created.user?.id;
 if(!uid)return out({error:'Uživatel nebyl vytvořen.'},500);
 const {error:membershipError}=await admin.from('memberships').insert({organization_id:org,user_id:uid,role});
 if(membershipError){await admin.auth.admin.deleteUser(uid);return out({error:'Členství se nepodařilo uložit. Účet nebyl ponechán aktivní.'},500)}
 return out({ok:true,email,role,user_id:uid});
 }catch{return out({error:'Účet se nepodařilo vytvořit.'},500)}
});
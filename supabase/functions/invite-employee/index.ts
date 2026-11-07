import { createClient } from 'npm:@supabase/supabase-js@2.57.0';
const cors={'Access-Control-Allow-Origin':'https://jakubjirijuren-pixel.github.io','Access-Control-Allow-Headers':'authorization,apikey,content-type,x-client-info','Access-Control-Allow-Methods':'POST,OPTIONS'};
const respond=(data,status=200)=>new Response(JSON.stringify(data),{status,headers:{...cors,'Content-Type':'application/json'}});
Deno.serve(async(req)=>{
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers:cors});
 if(req.method!=='POST')return respond({error:'Method not allowed'},405);
 try{
  const url=Deno.env.get('SUPABASE_URL')!;
  const pub=Deno.env.get('SUPABASE_ANON_KEY')||Deno.env.get('SUPABASE_PUBLISHABLE_KEY')!;
  const secret=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const token=req.headers.get('authorization')?.replace(/^Bearer\s+/i,'');
  if(!token)return respond({error:'Přihlášení je povinné.'},401);
  const userClient=createClient(url,pub,{global:{headers:{Authorization:'Bearer '+token}}});
  const {data:{user},error:authError}=await userClient.auth.getUser(token);
  if(authError||!user)return respond({error:'Neplatné přihlášení.'},401);
  const input=await req.json();
  const organization_id=String(input.organization_id||'');
  const email=String(input.email||'').trim().toLowerCase();
  const role=String(input.role||'worker');
  if(!/^[0-9a-f-]{36}$/i.test(organization_id)||!/^\S+@\S+\.\S+$/.test(email)||!['worker','viewer','accountant'].includes(role))return respond({error:'Neplatné údaje zaměstnance.'},400);
  const {data:allowed,error:permissionError}=await userClient.rpc('can_manage_employees',{org:organization_id});
  if(permissionError||allowed!==true)return respond({error:'Nemáte oprávnění spravovat zaměstnance této organizace.'},403);
  const admin=createClient(url,secret,{auth:{autoRefreshToken:false,persistSession:false}});
  const {data:invite,error:inviteError}=await admin.auth.admin.inviteUserByEmail(email,{redirectTo:'https://jakubjirijuren-pixel.github.io/remeslo-2/'});
  if(inviteError)return respond({error:inviteError.message},400);
  const invitedId=invite.user?.id;
  if(!invitedId)return respond({error:'Pozvánka nevrátila uživatele.'},500);
  const {error:membershipError}=await admin.from('memberships').upsert({organization_id,user_id:invitedId,role},{onConflict:'organization_id,user_id'});
  if(membershipError)return respond({error:'Účet byl pozván, ale nepodařilo se přidat členství. Kontaktujte správce.'},500);
  return respond({ok:true,email,role});
 }catch(e){return respond({error:'Pozvánku se nepodařilo odeslat.'},500)}
});
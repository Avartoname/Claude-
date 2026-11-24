export const can=(ctx,p)=>!!ctx.profile?.active && (ctx.profile.role==='owner'||ctx.permissions?.[p]===true);
export const manager=ctx=>!!ctx.profile?.active&&['owner','ops','lead'].includes(ctx.profile.role);
export const sees=(ctx,v)=>!!ctx.profile?.active&&(!v||can(ctx,'all_sites')||v===ctx.profile.venue_id);
export const approve=(ctx,kind)=>!!ctx.profile?.active&&(ctx.profile.role==='owner'||(ctx.permissions?.approve_kinds||[]).includes(kind));
export function canRead(ctx,key,row){
 if(!ctx.profile?.active)return false;
 if(key==='access_requests')return row.user_id===ctx.profile.id||can(ctx,'manage_people');
 if(['venues','profiles','role_permissions','integrations','automations'].includes(key))return true;
 if(key==='customers')return can(ctx,'contact');
 if(['vacancies','candidates'].includes(key))return can(ctx,'hr')&&sees(ctx,row.venue_id);
 if(key==='transactions')return can(ctx,'finance')&&sees(ctx,row.venue_id);
 if(['threads','activity_log'].includes(key))return can(ctx,'inbox')&&sees(ctx,row.venue_id);
 if(key==='approvals')return sees(ctx,row.venue_id)&&(approve(ctx,row.kind)||row.approver_id===ctx.profile.id);
 if(key==='tasks')return sees(ctx,row.venue_id)||row.owner_id===ctx.profile.id;
 if(key==='cases')return sees(ctx,row.venue_id)&&(!row.sensitive||approve(ctx,'complaint'));
 return sees(ctx,row.venue_id);
}
export function canWrite(ctx,key,row,action='update'){
 if(!ctx.profile?.active)return false;
 if(['activity_log','access_requests'].includes(key))return false;
 if(['venues','profiles','role_permissions','integrations','transactions'].includes(key))return ctx.profile.role==='owner';
 if(key==='automations')return can(ctx,'manage_automations');
 if(key==='knowledge')return can(ctx,'edit_knowledge')&&sees(ctx,row.venue_id);
 if(key==='customers')return can(ctx,'contact');
 if(['vacancies','candidates'].includes(key))return can(ctx,'hr')&&sees(ctx,row.venue_id);
 if(['threads','messages'].includes(key))return can(ctx,'inbox')&&sees(ctx,row.venue_id);
 if(key==='approvals')return action==='create'?sees(ctx,row.venue_id):sees(ctx,row.venue_id)&&(approve(ctx,row.kind)||row.approver_id===ctx.profile.id);
 if(key==='tasks')return sees(ctx,row.venue_id)&&(manager(ctx)||row.owner_id===ctx.profile.id);
 if(key==='cases')return manager(ctx)&&canRead(ctx,key,row);
 if(['bookings','parties'].includes(key))return manager(ctx)&&sees(ctx,row.venue_id);
 return sees(ctx,row.venue_id);
}
export function redact(ctx,key,row){
 const out={...row};
 if(!can(ctx,'finance'))for(const f of key==='bookings'?['total','paid','deposit']:key==='stock'?['unit_cost']:[])delete out[f];
 if(key==='profiles'&&!can(ctx,'manage_people')&&row.id!==ctx.profile.id)delete out.email;
 return out;
}

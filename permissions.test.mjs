import test from 'node:test';
import assert from 'node:assert/strict';
import {canRead,canWrite,redact,approve} from '../public/permissions.js';
import {validate} from '../netlify/server/validation.mjs';
const staff={profile:{id:'staff',active:true,role:'staff',venue_id:'mk'},permissions:{}};
const lead={profile:{id:'lead',active:true,role:'lead',venue_id:'mk'},permissions:{inbox:true,contact:true,approve_kinds:['reply','reminder']}};
const owner={profile:{id:'owner',active:true,role:'owner'},permissions:{}};
test('staff venue boundaries and finance redaction',()=>{
 assert.equal(canRead(staff,'bookings',{venue_id:'mk'}),true);
 assert.equal(canRead(staff,'bookings',{venue_id:'hat'}),false);
 assert.equal(canWrite(staff,'bookings',{venue_id:'mk'}),false);
 assert.deepEqual(redact(staff,'bookings',{venue_id:'mk',total:'400',paid:'200',deposit:'100'}),{venue_id:'mk'});
 assert.equal(canRead(staff,'customers',{}),false);
 assert.equal(canRead(staff,'candidates',{venue_id:'mk'}),false);
});
test('lead approvals cannot cross venue or approval kind',()=>{
 assert.equal(approve(lead,'refund'),false);
 assert.equal(canRead(lead,'approvals',{venue_id:'mk',kind:'refund'}),false);
 assert.equal(canRead(lead,'approvals',{venue_id:'hat',kind:'reply'}),false);
 assert.equal(canRead(lead,'approvals',{venue_id:'mk',kind:'reply'}),true);
 assert.equal(canRead(lead,'cases',{venue_id:'mk',sensitive:true}),false);
 assert.equal(canWrite(lead,'profiles',{}),false);
});
test('inactive users lose access including assigned tasks',()=>{
 const inactive={...lead,profile:{...lead.profile,active:false}};
 assert.equal(canRead(inactive,'tasks',{owner_id:'lead'}),false);
 assert.equal(canWrite(inactive,'stock',{venue_id:'mk'}),false);
});
test('owner gets company-wide operational permissions',()=>{
 assert.equal(canRead(owner,'candidates',{venue_id:'hat'}),true);
 assert.equal(canWrite(owner,'profiles',{}),true);
 assert.equal(approve(owner,'refund'),true);
});
test('validation rejects fields, invalid dates, enum values and financial numbers',()=>{
 assert.throws(()=>validate('tasks',{admin:true}),/Unknown field/);
 assert.throws(()=>validate('tasks',{due_date:'2026-02-30'}),/valid date/);
 assert.throws(()=>validate('tasks',{status:'approved'}),/valid choice/);
 assert.throws(()=>validate('stock',{level:-1}),/negative/);
 assert.throws(()=>validate('bookings',{guests:1.2}),/number/);
 assert.throws(()=>validate('tasks',{owner_id:'bogus'}),/valid ID/);
 assert.throws(()=>validate('tasks',{id:'abc'}),/Unknown field/);
 assert.throws(()=>validate('bookings',{start_time:'14:00',end_time:'13:00'}),/End time/);
});
test('creation defaults and structured values are validated',()=>{
 const task=validate('tasks',{title:'Open studio'},true);
 assert.equal(task.status,'open');assert.equal(task.kind,'task');
 assert.deepEqual(validate('parties',{activities:['Painting']}),{activities:['Painting']});
 assert.throws(()=>validate('candidates',{history:{}}),/array JSON/);
 assert.throws(()=>validate('knowledge',{},true),/Key is required/);
});

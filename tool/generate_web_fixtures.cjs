// Run against an esbuild bundle of the reference snapshot.
const fs = require('node:fs');
const {calcDamage} = require(process.argv[2]);
const cases = [
  {name:'normal single', type:'Normal', power:40, category:'physical'},
  {name:'rain spread water',type:'Water',power:90,category:'special',weather:'rain',format:'double',spread:true},
  {name:'sun fire life orb',type:'Fire',power:90,category:'special',weather:'sunlight',item:'LifeOrb'},
  {name:'physical choice band',type:'Normal',power:40,category:'physical',item:'ChoiceBand'},
  {name:'special assault vest',type:'Normal',power:40,category:'special',defenderItem:'AssaultVest'},
  {name:'burn',type:'Normal',power:40,category:'physical',status:'burn'},
  {name:'rock sand special',type:'Water',power:90,category:'special',defenderType:'Rock',weather:'sandstorm'},
  {name:'ice snow physical',type:'Normal',power:40,category:'physical',defenderType:'Ice',weather:'snow'},
];
function pokemon(type,item,status) {
  return {key:'test',types:[type],item:item??null,ability:null,teraType:null,
    status:{HP:200,Atk:100,Def:100,Spa:100,Spd:100,Spe:100},
    ranks:{Atk:0,Def:0,Spa:0,Spd:0,Spe:0},
    attackModifier:{statusCondition:status},defenseModifier:{isFullHp:true}};
}
for (const c of cases) {
  const m={key:'Tackle',type:c.type,power:c.power,category:c.category,target:c.spread?'allOpponents':'normal',contact:false,accuracy:100};
  c.expected=calcDamage(pokemon(c.type,c.item,c.status),pokemon(c.defenderType??'Normal',c.defenderItem),m,
    {rule:c.format??'single',weather:c.weather}).damages;
}
fs.writeFileSync('test/fixtures/web.json',JSON.stringify(cases,null,2)+'\n');

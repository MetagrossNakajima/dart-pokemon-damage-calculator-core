// Smogon reference: cf95cb685b6cbbda1ea5f9dc783f62e3c3e3e900.
// Bundle calc/src/index.ts from that revision and pass the bundle path here.
// Reference prerequisites are supplied independently; engine inputs omit them.
const fs = require('node:fs');
const calc = require(process.argv[2]);
const gen = calc.Generations.get(9);
function pokemon(p = {}) {
  const stats = {hp: 200, atk: 101, def: 103, spa: 101, spd: 103, spe: 100, ...p.stats};
  return new calc.Pokemon(gen, p.id || 'Mew', {
    level: 50, ivs: {hp: 0, atk: 0, def: 0, spa: 0, spd: 0, spe: 0},
    overrides: {baseStats: Object.fromEntries(Object.entries(stats).map(([k, v]) =>
      [k, v - (k === 'hp' ? 60 : 5)])), types: ['Normal']},
    ability: p.ability || 'Pressure', abilityOn: true, item: p.item,
    status: p.status, curHP: p.hp, boostedStat: p.boostedStat,
  });
}
const cases = [];
function add(ability, side, type, category, reference, engine = {}) {
  const p = {ability, ...engine};
  const a = side === 'attacker' ? p : {};
  const d = side === 'defender' ? p : {};
  const ref = {ability, ...reference.pokemon};
  const move = new calc.Move(gen, 'Pound', {hits: 1, overrides: {
    basePower: 83, type, category, flags: {}, target: 'normal',
  }});
  const result = calc.calculate(gen, pokemon(side === 'attacker' ? ref : a),
    pokemon(side === 'defender' ? ref : d), move, new calc.Field(reference.field));
  cases.push({id: `${ability}/${side}/${type}/${category}`, attacker: a, defender: d,
    type, category, power: 83, reference,
    rolls: Array.isArray(result.damage) ? result.damage : Array(16).fill(result.damage)});
}
for (const [ability, type] of [['Overgrow','Grass'], ['Blaze','Fire'], ['Torrent','Water'], ['Swarm','Bug']]) {
  for (const category of ['Physical','Special']) add(ability,'attacker',type,category,{pokemon:{hp:66}});
}
for (const category of ['Physical','Special']) {
  add('Defeatist','attacker','Normal',category,{pokemon:{hp:100}});
  add('Stakeout','attacker','Normal',category,{});
  add('Analytic','attacker','Normal',category,{});
  add('Flash Fire','attacker','Fire',category,{});
}
add('Guts','attacker','Normal','Physical',{pokemon:{status:'par'}});
add('Flare Boost','attacker','Normal','Special',{pokemon:{status:'brn'}});
add('Toxic Boost','attacker','Normal','Physical',{pokemon:{status:'psn'}});
add('Solar Power','attacker','Normal','Special',{field:{weather:'Sun'}});
add('Flower Gift','attacker','Normal','Physical',{pokemon:{id:'Cherrim'},field:{weather:'Sun'}});
add('Flower Gift','defender','Normal','Special',{pokemon:{id:'Cherrim'},field:{weather:'Sun'}});
for (const type of ['Ground','Rock','Steel']) add('Sand Force','attacker',type,'Physical',{field:{weather:'Sand'}});
add('Hadron Engine','attacker','Normal','Special',{field:{terrain:'Electric'}});
add('Orichalcum Pulse','attacker','Normal','Physical',{field:{weather:'Sun'}},{item:'Utility Umbrella'});
for (const ability of ['Plus','Minus']) add(ability,'attacker','Normal','Special',{});
add('Slow Start','attacker','Normal','Physical',{});
add('Marvel Scale','defender','Normal','Physical',{pokemon:{status:'psn'}});
add('Grass Pelt','defender','Normal','Physical',{field:{terrain:'Grassy'}});
for (const ability of ['Protosynthesis','Quark Drive']) {
  for (const [side, category, stat] of [['attacker','Physical','atk'],['attacker','Special','spa'],
    ['defender','Physical','def'],['defender','Special','spd']]) {
    // Booster Energy activates the reference without introducing weather/terrain modifiers.
    add(ability,side,'Normal',category,{pokemon:{item:'Booster Energy',boostedStat:stat,
      stats:{[stat]:150}}},{boostedStat:stat,stats:{[stat]:150}});
  }
}
for (const ability of ['Multiscale','Shadow Shield','Tera Shell']) {
  add(ability,'defender','Normal','Physical',{}, {hp:1});
}
fs.writeFileSync('test/fixtures/ability_activation.json', JSON.stringify({
  referenceCommit:'cf95cb685b6cbbda1ea5f9dc783f62e3c3e3e900',cases},null,2)+'\n');

// Bundle the pinned calc/src/index.ts with esbuild, then pass its path here.
const fs = require('node:fs');
const calc = require(process.argv[2]);
const gen = calc.Generations.get(9);
function pokemon(options = {}) {
  return new calc.Pokemon(gen, 'Mew', {
    level: 50,
    ivs: {hp: 0, atk: 0, def: 0, spa: 0, spd: 0, spe: 0},
    overrides: {
      baseStats: {hp: 140, atk: 95, def: 95, spa: 95, spd: 95, spe: 95},
      types: ['Normal'],
    },
    ...options,
  });
}
const cases = [];
function add(id, name, attacker, hp, weather, type, category, ability, item) {
  const result = calc.calculate(gen, attacker, pokemon({curHP: hp}),
    new calc.Move(gen, name), new calc.Field({weather}));
  cases.push({id, name: name.replaceAll(' ', ''), hp, weather: weather || null,
    type, category, ability: ability || null, item: item || null,
    power: result.rawDesc.moveBP, rolls: result.damage});
}
for (const name of ['Crush Grip', 'Wring Out', 'Hard Press']) {
  for (const hp of [1, 100, 104, 105, 106, 200]) {
    for (const ability of ['', 'Technician']) {
      add(`${name}/${hp}/${ability}`, name, pokemon({ability: ability || 'Synchronize'}),
        hp, undefined, name === 'Hard Press' ? 'Steel' : 'Normal',
        name === 'Wring Out' ? 'special' : 'physical', ability);
    }
  }
}
for (const weather of ['Sun', 'Rain', 'Sand', 'Snow', undefined]) {
  for (const ability of ['', 'Normalize', 'Aerilate', 'Mega Sol']) {
    for (const item of ['Utility Umbrella', undefined]) {
      add(`Weather Ball/${weather}/${ability}/${item}`, 'Weather Ball',
        pokemon({ability: ability || 'Synchronize', item}), 200, weather,
        'Normal', 'special', ability.replaceAll(' ', ''), item?.replaceAll(' ', ''));
    }
  }
}
fs.writeFileSync('test/fixtures/spec_audit.json', JSON.stringify(cases, null, 2) + '\n');

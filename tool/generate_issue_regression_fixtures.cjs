// Smogon reference: cf95cb685b6cbbda1ea5f9dc783f62e3c3e3e900.
// Bundle calc/src/index.ts from that revision and pass the bundle path here.
const fs = require('node:fs');
const calc = require(process.argv[2]);
const gen = calc.Generations.get(9);

function pokemon(p = {}) {
  const stats = {hp: 200, atk: 100, def: 100, spa: 100, spd: 100, spe: 100, ...p.stats};
  return new calc.Pokemon(gen, p.id || 'Mew', {
    level: 50, ivs: {hp: 0, atk: 0, def: 0, spa: 0, spd: 0, spe: 0},
    overrides: {
      baseStats: Object.fromEntries(Object.entries(stats).map(([k, v]) =>
        [k, v - (k === 'hp' ? 60 : 5)])),
      types: p.types || ['Normal'], weightkg: 50,
    },
    ability: p.ability || 'Pressure', item: p.item, status: p.status,
    boostedStat: ['Protosynthesis', 'Quark Drive'].includes(p.ability) ? 'auto' : undefined,
    boosts: p.ranks, curHP: p.hp, teraType: p.tera,
  });
}
const cases = [
  {
    "issue": 1,
    "case": 1,
    "attacker": {},
    "defender": {
      "types": [
        "Normal"
      ]
    },
    "move": {
      "id": "Collision Course",
      "power": 100,
      "type": "Fighting",
      "category": "Physical"
    },
    "field": {}
  },
  {
    "issue": 2,
    "case": 1,
    "attacker": {},
    "defender": {
      "types": [
        "Water"
      ]
    },
    "move": {
      "id": "Electro Drift",
      "power": 100,
      "type": "Electric",
      "category": "Special"
    },
    "field": {}
  },
  {
    "issue": 3,
    "case": 1,
    "attacker": {
      "stats": {
        "atk": 81
      }
    },
    "defender": {
      "stats": {
        "def": 81
      }
    },
    "move": {
      "id": "Metal Claw",
      "power": 50,
      "type": "Steel",
      "category": "Physical"
    },
    "field": {
      "attackerSide": {
        "isSteelySpirit": true
      }
    }
  },
  {
    "issue": 3,
    "case": 2,
    "attacker": {
      "stats": {
        "atk": 99
      }
    },
    "defender": {},
    "move": {
      "id": "Pound",
      "power": 43,
      "type": "Steel",
      "category": "Physical"
    },
    "field": {
      "attackerSide": {
        "isSteelySpirit": true
      }
    }
  },
  {
    "issue": 4,
    "case": 1,
    "attacker": {},
    "defender": {
      "ability": "Quark Drive",
      "boosted": "def",
      "stats": {
        "def": 75
      }
    },
    "move": {
      "id": "Pound",
      "power": 80,
      "type": "Normal",
      "category": "Physical"
    },
    "field": {
      "terrain": "Electric"
    }
  },
  {
    "issue": 4,
    "case": 2,
    "attacker": {},
    "defender": {
      "ability": "Quark Drive",
      "boosted": "def",
      "stats": {
        "def": 85
      }
    },
    "move": {
      "id": "Pound",
      "power": 80,
      "type": "Normal",
      "category": "Physical"
    },
    "field": {
      "terrain": "Electric"
    }
  },
  {
    "issue": 5,
    "case": 1,
    "attacker": {
      "ability": "Iron Fist",
      "charge": true
    },
    "defender": {},
    "move": {
      "id": "Thunder Punch",
      "power": 65,
      "type": "Electric",
      "category": "Physical",
      "flags": [
        "punch"
      ]
    },
    "field": {
      "terrain": "Electric",
      "attackerSide": {
        "isHelpingHand": true,
        "isPowerSpot": true,
        "isCharge": true
      }
    }
  },
  {
    "issue": 6,
    "case": 1,
    "attacker": {
      "ability": "Technician",
      "status": "brn"
    },
    "defender": {},
    "move": {
      "id": "Facade",
      "power": 40,
      "type": "Normal",
      "category": "Physical"
    },
    "field": {}
  },
  {
    "issue": 7,
    "case": 1,
    "attacker": {},
    "defender": {},
    "move": {
      "id": "Psychic Fangs",
      "power": 85,
      "type": "Psychic",
      "category": "Physical"
    },
    "field": {
      "defenderSide": {
        "isReflect": true
      }
    }
  },
  {
    "issue": 8,
    "case": 1,
    "attacker": {
      "ability": "Infiltrator"
    },
    "defender": {},
    "move": {
      "id": "Pound",
      "power": 40,
      "type": "Normal",
      "category": "Physical"
    },
    "field": {
      "defenderSide": {
        "isReflect": true
      }
    }
  },
  {
    "issue": 9,
    "case": 1,
    "attacker": {},
    "defender": {
      "ability": "Tera Shell"
    },
    "move": {
      "id": "Flamethrower",
      "power": 90,
      "type": "Fire",
      "category": "Special"
    },
    "field": {}
  },
  {
    "issue": 9,
    "case": 2,
    "attacker": {},
    "defender": {
      "ability": "Tera Shell",
      "types": [
        "Grass"
      ]
    },
    "move": {
      "id": "Flamethrower",
      "power": 90,
      "type": "Fire",
      "category": "Special"
    },
    "field": {}
  },
  {
    "issue": 10,
    "case": 1,
    "attacker": {},
    "defender": {
      "hp": 100
    },
    "move": {
      "id": "Brine",
      "power": 65,
      "type": "Water",
      "category": "Special"
    },
    "field": {}
  },
  {
    "issue": 11,
    "case": 1,
    "attacker": {
      "ranks": {
        "spa": 2
      }
    },
    "defender": {},
    "move": {
      "id": "Stored Power",
      "power": 20,
      "type": "Psychic",
      "category": "Special"
    },
    "field": {}
  },
  {
    "issue": 12,
    "case": 1,
    "attacker": {
      "ranks": {
        "atk": 2
      }
    },
    "defender": {},
    "move": {
      "id": "Power Trip",
      "power": 20,
      "type": "Dark",
      "category": "Physical"
    },
    "field": {}
  },
  {
    "issue": 13,
    "case": 1,
    "attacker": {},
    "defender": {
      "ability": "Klutz",
      "item": "Leftovers"
    },
    "move": {
      "id": "Knock Off",
      "power": 65,
      "type": "Dark",
      "category": "Physical",
      "flags": [
        "contact"
      ]
    },
    "field": {}
  },
  {
    "issue": 14,
    "case": 1,
    "attacker": {
      "ability": "Orichalcum Pulse",
      "item": "Utility Umbrella"
    },
    "defender": {},
    "move": {
      "id": "Pound",
      "power": 40,
      "type": "Normal",
      "category": "Physical"
    },
    "field": {
      "weather": "Sun"
    }
  },
  {
    "issue": 15,
    "case": 1,
    "attacker": {
      "stats": {
        "atk": 200,
        "spa": 100
      }
    },
    "defender": {},
    "move": {
      "id": "Photon Geyser",
      "power": 100,
      "type": "Psychic",
      "category": "Special"
    },
    "field": {}
  },
  {
    "issue": 15,
    "case": 2,
    "attacker": {
      "stats": {
        "atk": 100,
        "spa": 150
      },
      "ranks": {
        "atk": 2
      }
    },
    "defender": {},
    "move": {
      "id": "Photon Geyser",
      "power": 100,
      "type": "Psychic",
      "category": "Special"
    },
    "field": {}
  },
  {
    "issue": 18,
    "case": 1,
    "attacker": {
      "ability": "As One (Glastrier)"
    },
    "defender": {
      "types": [
        "Grass"
      ],
      "item": "Occa Berry"
    },
    "move": {
      "id": "Flamethrower",
      "power": 90,
      "type": "Fire",
      "category": "Special"
    },
    "field": {}
  },
  {
    "issue": 19,
    "case": 1,
    "attacker": {
      "ability": "As One (Spectrier)"
    },
    "defender": {
      "types": [
        "Grass"
      ],
      "item": "Occa Berry"
    },
    "move": {
      "id": "Flamethrower",
      "power": 90,
      "type": "Fire",
      "category": "Special"
    },
    "field": {}
  },
  {
    "issue": 20,
    "case": 1,
    "attacker": {},
    "defender": {
      "types": [
        "Flying",
        "Fire"
      ],
      "item": "Iron Ball"
    },
    "move": {
      "id": "Earthquake",
      "power": 100,
      "type": "Ground",
      "category": "Physical"
    },
    "field": {}
  },
  {
    "issue": 21,
    "case": 1,
    "attacker": {},
    "defender": {
      "types": [
        "Flying",
        "Fire"
      ]
    },
    "move": {
      "id": "Thousand Arrows",
      "power": 90,
      "type": "Ground",
      "category": "Physical"
    },
    "field": {}
  },
  {
    "issue": 22,
    "case": 1,
    "attacker": {
      "id": "Tauros-Paldea-Blaze",
      "ability": "Normalize"
    },
    "defender": {
      "types": [
        "Ghost"
      ]
    },
    "move": {
      "id": "Raging Bull",
      "power": 90,
      "type": "Normal",
      "category": "Physical"
    },
    "field": {}
  },
  {
    "issue": 23,
    "case": 1,
    "attacker": {
      "types": [
        "Flying"
      ],
      "ability": "Normalize"
    },
    "defender": {},
    "move": {
      "id": "Terrain Pulse",
      "power": 50,
      "type": "Normal",
      "category": "Special"
    },
    "field": {
      "terrain": "Electric"
    }
  },
  {
    "issue": 24,
    "case": 1,
    "attacker": {
      "ability": "Quark Drive",
      "stats": {
        "def": 150
      }
    },
    "defender": {},
    "move": {
      "id": "Body Press",
      "power": 80,
      "type": "Fighting",
      "category": "Physical"
    },
    "field": {
      "terrain": "Electric"
    }
  },
  {
    "issue": 24,
    "case": 2,
    "attacker": {
      "ability": "Quark Drive",
      "stats": {
        "atk": 150
      }
    },
    "defender": {},
    "move": {
      "id": "Body Press",
      "power": 80,
      "type": "Fighting",
      "category": "Physical"
    },
    "field": {
      "terrain": "Electric"
    }
  },
  {
    "issue": 25,
    "case": 1,
    "attacker": {
      "id": "Terapagos-Stellar",
      "tera": "Stellar",
      "stats": {
        "atk": 150
      }
    },
    "defender": {},
    "move": {
      "id": "Tera Starstorm",
      "power": 120,
      "type": "Normal",
      "category": "Special"
    },
    "field": {}
  },
  {
    "issue": 29,
    "case": 1,
    "attacker": {
      "ability": "Mold Breaker"
    },
    "defender": {
      "ability": "Aura Break"
    },
    "move": {
      "id": "Pound",
      "power": 40,
      "type": "Fairy",
      "category": "Physical"
    },
    "field": {
      "isFairyAura": true
    }
  },
  {
    "issue": 30,
    "case": 1,
    "attacker": {
      "stats": {
        "atk": 999
      },
      "ranks": {
        "atk": 6
      },
      "ability": "Huge Power",
      "item": "Choice Band"
    },
    "defender": {
      "stats": {
        "def": 1
      }
    },
    "move": {
      "id": "Pound",
      "power": 1000,
      "type": "Normal",
      "category": "Physical"
    },
    "field": {}
  },
  {
    "issue": 30,
    "case": 2,
    "attacker": {
      "stats": {
        "atk": 999
      }
    },
    "defender": {
      "stats": {
        "def": 1
      }
    },
    "move": {
      "id": "Pound",
      "power": 1000,
      "type": "Normal",
      "category": "Physical"
    },
    "field": {}
  },
  {
    "issue": 30,
    "case": 3,
    "attacker": {
      "stats": {
        "atk": 999
      },
      "ranks": {
        "atk": 6
      },
      "ability": "Huge Power",
      "item": "Choice Band"
    },
    "defender": {
      "stats": {
        "def": 1
      }
    },
    "move": {
      "id": "Flamethrower",
      "power": 1000,
      "type": "Fire",
      "category": "Physical"
    },
    "field": {
      "weather": "Sun",
      "attackerSide": {
        "isHelpingHand": true
      }
    }
  },
  {
    "issue": 30,
    "case": 4,
    "attacker": {
      "stats": {
        "atk": 999
      },
      "ranks": {
        "atk": 6
      },
      "ability": "Huge Power",
      "item": "Choice Band"
    },
    "defender": {
      "stats": {
        "def": 1
      }
    },
    "move": {
      "id": "Pound",
      "power": 1000,
      "type": "Normal",
      "category": "Physical",
      "crit": true
    },
    "field": {}
  },
  {
    "issue": 30,
    "case": 5,
    "attacker": {
      "stats": {
        "atk": 999
      },
      "ranks": {
        "atk": 6
      }
    },
    "defender": {
      "stats": {
        "def": 999
      },
      "ranks": {
        "def": -6
      }
    },
    "move": {
      "id": "Pound",
      "power": 1000,
      "type": "Normal",
      "category": "Physical"
    },
    "field": {}
  },
  {
    "issue": 30,
    "case": 6,
    "attacker": {
      "stats": {
        "atk": 999
      },
      "ranks": {
        "atk": 6
      },
      "ability": "Huge Power",
      "item": "Life Orb",
      "status": "brn"
    },
    "defender": {
      "stats": {
        "def": 1
      },
      "types": [
        "Grass",
        "Ice"
      ]
    },
    "move": {
      "id": "Pound",
      "type": "Fire",
      "power": 1000,
      "category": "Physical"
    },
    "field": {}
  }
];
for (const c of cases) {
  const m = c.move;
  const flags = {contact: 0, punch: 0, sound: 0, bite: 0, pulse: 0, slicing: 0, bullet: 0, wind: 0};
  for (const flag of m.flags || []) flags[flag === 'sharpness' ? 'slicing' : flag] = 1;
  const move = new calc.Move(gen, m.id, {
    hits: 1,
    isCrit: m.crit || false,
    overrides: {basePower: m.power, type: m.type, category: m.category,
      flags, target: 'normal', secondaries: m.flags?.includes('sheerForce') ? true : undefined},
  });
  const field = new calc.Field(c.field);
  // The core assumes a selected Orichalcum Pulse is activated, even under Umbrella.
  // Pound has no weather modifier, so removing Umbrella only activates the reference ability.
  const referenceAttacker = c.issue === 14 ? {...c.attacker, item: undefined} : c.attacker;
  const result = calc.calculate(gen, pokemon(referenceAttacker), pokemon(c.defender), move, field);
  c.rolls = Array.isArray(result.damage) ? result.damage : Array(16).fill(result.damage);
}
fs.writeFileSync('test/fixtures/issue_regressions.json', JSON.stringify(cases, null, 2) + '\n');

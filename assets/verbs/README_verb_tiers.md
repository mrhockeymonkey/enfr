# French Verb Conjugation Files — Documentation

## Overview

The verbs from the [Lefff](https://gitlab.inria.fr/almanach/alexina/lefff) lexicon (via the `french-verbs-lefff` npm package) have been split into 5 files by how common each verb is in everyday French, scored using [`wordfreq`](https://github.com/rspeer/wordfreq)'s Zipf frequency scale (roughly 0–7, log-scaled per-billion-word frequency).

| File | Tier | Criteria | Verb count |
|---|---|---|---|
| `verbs_essential.json` | Essential | zipf ≥ 5.0 | 46 |
| `verbs_common.json` | Common | 4.0 ≤ zipf < 5.0 | 431 |
| `verbs_moderate.json` | Moderate | 3.0 ≤ zipf < 4.0 | 1,129 |
| `verbs_uncommon.json` | Uncommon | 1.5 ≤ zipf < 3.0 | 2,503 |
| `verbs_rare.json` | Rare | zipf < 1.5 | 3,717 |

Each file shares the same top-level shape:

```json
{
  "tier": "essential",
  "criteria": "zipf >= 5.0",
  "source": "french-verbs-lefff conjugations, scored with wordfreq (fr)",
  "verb_count": 46,
  "verbs": {
    "parler": { "...": "see below" },
    "être": { "...": "see below" }
  }
}
```

## Per-verb structure

Each verb is keyed by its **infinitive** and maps to an object with single-letter tense/mood codes. Each code holds an array of forms ordered **je, tu, il/elle, nous, vous, ils/elles** (6 forms), except where noted.

```json
"parler": {
  "P": ["parle", "parles", "parle", "parlons", "parlez", "parlent"],
  "S": ["parle", "parles", "parle", "parlions", "parliez", "parlent"],
  "Y": ["NA", "parle", "NA", "parlons", "parlez", "NA"],
  "I": ["parlais", "parlais", "parlait", "parlions", "parliez", "parlaient"],
  "G": ["parlant"],
  "K": ["parlé", "parlés", "parlée", "parlées"],
  "J": ["parlai", "parlas", "parla", "parlâmes", "parlâtes", "parlèrent"],
  "T": ["parlasse", "parlasses", "parlât", "parlassions", "parlassiez", "parlassent"],
  "F": ["parlerai", "parleras", "parlera", "parlerons", "parlerez", "parleront"],
  "C": ["parlerais", "parlerais", "parlerait", "parlerions", "parleriez", "parleraient"],
  "W": ["parler"],
  "zipf": 5.52
}
```

## Tense/mood code key

| Code | Mood/Tense (French) | Mood/Tense (English) | Array length | Notes |
|---|---|---|---|---|
| `P` | Présent (indicatif) | Present (indicative) | 6 | je/tu/il/nous/vous/ils |
| `I` | Imparfait | Imperfect | 6 | |
| `F` | Futur (simple) | Future | 6 | |
| `J` | Passé simple | Simple past / preterite | 6 | Literary tense, rarely spoken |
| `C` | Conditionnel présent | Conditional | 6 | |
| `S` | Subjonctif présent | Subjunctive (present) | 6 | |
| `T` | Subjonctif imparfait | Subjunctive (imperfect) | 6 | Literary, rarely used today |
| `Y` | Impératif | Imperative | 6 | Only tu/nous/vous forms exist; je/il/ils slots are `"NA"` |
| `G` | Participe présent | Present participle | 1 | Single invariant form (e.g. "parlant") |
| `K` | Participe passé | Past participle | 4 | Order: masc. sg., masc. pl., fem. sg., fem. pl. |
| `W` | Infinitif | Infinitive | 1 | Same as the verb's dictionary key |
| `zipf` | — | Frequency score | — | Added by us, not part of original Lefff data; higher = more common |

### Notes on `Y` (imperative)
French imperative only has 2nd person singular, 1st person plural, and 2nd person plural forms (tu, nous, vous). The `"NA"` placeholders fill the je/il/ils slots so the array stays a consistent length of 6, aligned with the same person-index order as every other tense.

### Notes on `K` (past participle)
Unlike the other codes, `K` is not person-indexed — it's gender/number-indexed, since past participles agree with gender and number (especially relevant with être-auxiliary verbs and object agreement). Order is: masculine singular, masculine plural, feminine singular, feminine plural.

## What's NOT included: compound tenses

This dataset only contains **simple (one-word) tenses**. Compound tenses — passé composé, plus-que-parfait, futur antérieur, conditionnel passé, etc. — are not stored directly, because they're built by combining an auxiliary verb's conjugation (`avoir` or `être`) with the main verb's past participle (`K`).

Example: "j'ai parlé" (passé composé) = `avoir`'s `P` form for "je" (`"ai"`) + `parler`'s `K` masculine singular form (`"parlé"`).

To build these in your app, you'll need:
1. A rule (or a short static list) for which verbs take `être` vs `avoir` as auxiliary.
2. Gender/number agreement logic for `être`-auxiliary and object-preceding cases.

The companion npm package `french-verbs` implements exactly this logic on top of this same data, if you want a reference implementation.

## Person-index reference

For all 6-element arrays, the index order is always:

| Index | Pronoun |
|---|---|
| 0 | je |
| 1 | tu |
| 2 | il / elle |
| 3 | nous |
| 4 | vous |
| 5 | ils / elles |

## Sources

- Verb data: [Lefff](https://gitlab.inria.fr/almanach/alexina/lefff) (Lexique des Formes Fléchies du Français), via the [`french-verbs-lefff`](https://www.npmjs.com/package/french-verbs-lefff) npm package, distributed under LGPL-LR.
- Frequency scoring: [`wordfreq`](https://github.com/rspeer/wordfreq) Python package, French corpus data.

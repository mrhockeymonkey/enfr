# French Verb Conjugation Files — Documentation

## Overview

The five `verbs_*.json` files hold every verb of the [Lefff](https://gitlab.inria.fr/almanach/alexina/lefff)
lexicon, split by how common each verb is in everyday French, scored with
[`wordfreq`](https://github.com/rspeer/wordfreq)'s Zipf frequency scale (roughly 0–7,
log-scaled per-billion-word frequency). **Pronominal verbs are their own entries**:
`lever` and `se lever` are separate keys, and a verb that only exists pronominally
(`s'évanouir`, `se souvenir`) appears only in that form.

| File | Tier | Criteria | Entries | of which pronominal |
|---|---|---|---|---|
| `verbs_essential.json` | Essential | zipf ≥ 5.0 | 78 | 34 |
| `verbs_common.json` | Common | 4.0 ≤ zipf < 5.0 | 789 | 360 |
| `verbs_moderate.json` | Moderate | 3.0 ≤ zipf < 4.0 | 1,936 | 828 |
| `verbs_uncommon.json` | Uncommon | 1.5 ≤ zipf < 3.0 | 3,734 | 1,296 |
| `verbs_rare.json` | Rare | zipf < 1.5 | 4,786 | 1,130 |

The files are produced by `tool/lefff/build_lefff_verbs.py` from the raw Lefff
`.elex` file (see `tool/lefff/README.md`). A pronominal entry inherits the zipf of its
base verb, so the two always sit in the same file. Each file shares the same top-level
shape:

```json
{
  "tier": "essential",
  "criteria": "zipf >= 5.0",
  "source": "Lefff 3.4 (...) ...",
  "lefff_version": "3.4",
  "generated_by": "tool/lefff/build_lefff_verbs.py",
  "verb_count": 78,
  "counts": {"plain": 44, "pronominal": 34, "essential": 0, "lexicalised": 16, "reflexive": 18},
  "verbs": {
    "lever": { "...": "see below" },
    "se lever": { "...": "see below" }
  }
}
```

## Per-verb structure

Each verb is keyed by its **infinitive** and maps to an object with single-letter
tense/mood codes, a `zipf` score and a `meta` object. Each code holds an array of
forms ordered **je, tu, il/elle, nous, vous, ils/elles** (6 forms), except where noted.

```json
"se lever": {
  "P": ["me lève", "te lèves", "se lève", "nous levons", "vous levez", "se lèvent"],
  "S": ["me lève", "te lèves", "se lève", "nous levions", "vous leviez", "se lèvent"],
  "Y": ["NA", "lève-toi", "NA", "levons-nous", "levez-vous", "NA"],
  "I": ["me levais", "te levais", "se levait", "nous levions", "vous leviez", "se levaient"],
  "G": ["se levant"],
  "K": ["levé", "levés", "levée", "levées"],
  "J": ["me levai", "te levas", "se leva", "nous levâmes", "vous levâtes", "se levèrent"],
  "T": ["me levasse", "te levasses", "se levât", "nous levassions", "vous levassiez", "se levassent"],
  "F": ["me lèverai", "te lèveras", "se lèvera", "nous lèverons", "vous lèverez", "se lèveront"],
  "C": ["me lèverais", "te lèverais", "se lèverait", "nous lèverions", "vous lèveriez", "se lèveraient"],
  "W": ["se lever"],
  "zipf": 4.54,
  "meta": {
    "pronominal": true,
    "pronominal_kind": "lexicalised",
    "base": "lever",
    "pronoun_optional": false,
    "elides": false,
    "auxiliary": "être",
    "impersonal": false,
    "impersonal_only": false,
    "prepositions": ["de", "contre"],
    "glosses": [],
    "senses": {"pronominal": 4, "reflexive": 2},
    "inflection_class": "v-er:std",
    "zipf_source": "base:verbs_common.json",
    "tier": "common"
  }
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
| `zipf` | — | Frequency score | — | Added by us, not part of Lefff; higher = more common |

### Notes on `Y` (imperative)
French imperative only has 2nd person singular, 1st person plural, and 2nd person
plural forms (tu, nous, vous). The `"NA"` placeholders fill the je/il/ils slots so the
array stays a consistent length of 6, aligned with the same person-index order as
every other tense.

### Notes on `K` (past participle)
Unlike the other codes, `K` is not person-indexed — it's gender/number-indexed, since
past participles agree with gender and number (with être-auxiliary verbs, pronominal
verbs and preceding direct objects). Order is: masculine singular, masculine plural,
feminine singular, feminine plural.

## Pronominal entries

The reflexive pronoun is composed into the stored forms of a pronominal entry, so the
data can be used without knowing the elision rules:

| Code | Rule | Example |
|---|---|---|
| P I F J C S T | `me/te/se/nous/vous/se` + form, elided to `m'/t'/s'` before a vowel or mute h | `me lève`, `m'évanouis`, `me hâte` |
| Y | postposed stressed pronoun with hyphen in the tu/nous/vous slots | `lève-toi`, `levons-nous`, `levez-vous` |
| G | `se` / `s'` + present participle | `se levant`, `s'évanouissant` |
| W | the entry key | `se lever` |
| K | unchanged | `levé, levés, levée, levées` |

### `meta` fields on pronominal entries

| Field | Meaning |
|---|---|
| `pronominal` | always `true` |
| `pronominal_kind` | `essential`: the verb has no non-pronominal personal use (`s'évanouir`, `se souvenir`, `s'abstenir`). `lexicalised`: the plain verb exists but the pronominal form has its own lexicalised meaning(s) (`se lever` = get up, `se moquer`, `se plaindre`). `reflexive`: only the derived reflexive / reciprocal / middle / passive reading exists, the pronoun is the object (`se laver`, `se regarder`). |
| `base` | key of the regular verb in the same file, or `null` for `essential` verbs with no plain entry |
| `pronoun_optional` | Lefff marks the pronoun as optional for at least one sense (`(se) bagarrer`) |
| `elides` | the pronoun elides before this verb (`s'` rather than `se`) |
| `auxiliary` | always `être` |
| `impersonal`, `impersonal_only` | has an impersonal sense (`il s'agit de`); `impersonal_only` when no personal pronominal sense exists (`s'agir`) |
| `prepositions` | prepositions the verb governs, most frequent first (`se souvenir` → `de`, `s'attendre` → `à`) |
| `glosses` | English glosses Lefff attaches to a few senses |
| `senses` | number of `pronominal` (`@pron`) and `reflexive` (`se_moyen`) senses in Lefff |
| `inflection_class` | Lefff conjugation class (`v-er:std`, `v-ir2`, `v-re3`, ...) |
| `zipf_source` | `base:<tier file>`: the zipf is inherited from the base verb |
| `tier` | the tier the zipf falls in (same as the file) |

### `meta` fields on plain entries

| Field | Meaning |
|---|---|
| `pronominal` | always `false` |
| `pronominal_form` | key of the pronominal entry (`se lever`), or `null` if the verb has none |
| `auxiliary` | `avoir` or `être`, see below |
| `impersonal`, `impersonal_only` | as above (`falloir`, `pleuvoir` are `impersonal_only`) |
| `prepositions`, `glosses`, `inflection_class`, `tier` | as above |
| `senses` | number of `active`, `pronominal` and `reflexive` senses |
| `zipf_source` | the tier file the forms and zipf were originally taken from |

## Auxiliary (`meta.auxiliary`)

Every verb records the auxiliary it takes in compound tenses. Pronominal verbs always
take `être`. For plain verbs the value comes from a curated list in the generator
(`ETRE_VERBS`): the "maison d'être" verbs and their common derivatives — aller,
arriver, décéder, devenir, redevenir, entrer, rentrer, monter, remonter, descendre,
redescendre, mourir, naître, renaître, partir, repartir, passer, rester, retourner,
sortir, ressortir, tomber, retomber, venir, revenir, parvenir, survenir, intervenir,
advenir, provenir, accourir, éclore. Everything else is `avoir`.

Verbs that take être when intransitive and avoir when transitive (sortir, monter,
descendre, passer, rentrer, retourner) are recorded as `être`, the form learners meet
first ("je suis sorti"). Lefff's own per-sense `@être` marks are too sparse to rely on
(they mark only five verbs as être-only) and are used by the generator only as a
cross-check.

## Compound tenses are built in the app

The files only contain **simple (one-word) tenses**. Compound tenses are built at
runtime from the auxiliary's present tense and the past participle (`K`); see
`lib/models/auxiliary.dart` and `Verb.form` in `lib/models/verb.dart`. Currently the
app builds the **passé composé**:

- avoir verbs: `ai parlé`, ... — the participle never agrees with the subject.
- être verbs: `suis parti`, `est partie`, `sommes partis`, ... — the participle agrees
  with the subject; the quiz fixes the gender and number in the prompt.
- pronominal verbs: `me suis levé`, `t'es levé`, `s'est levée`, `nous sommes levés`,
  `vous êtes levé(e)(s)`, `se sont levées` — être with the reflexive pronoun, agreeing
  with the subject.

The persons offered for a compound tense are the ones the present tense has, so an
impersonal verb only offers "il a fallu".

## Design note: defective verbs are excluded

A handful of French verbs are genuinely defective: only the infinitive, and sometimes
the present participle, are ever used (`accroire`, `capeyer`, `clamecer`, `faseyer`,
`langueyer`, `parfaire`, `quérir`, `raire`, `ravoir`, `stupéfaire`, `avenir`). They
have no form in any of the nine tenses this data is quizzed on, so they are left out by
design, along with their pronominal forms (`se parfaire`, `se quérir`).

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

- Verb inventory and pronominal classification: [Lefff](https://gitlab.inria.fr/almanach/alexina/lefff)
  3.4 (Lexique des Formes Fléchies du Français), LGPL-LR, read directly from the
  `.elex` file by `tool/lefff/build_lefff_verbs.py`.
- Conjugation forms: Lefff, originally via the [`french-verbs-lefff`](https://www.npmjs.com/package/french-verbs-lefff)
  npm package and carried over from the previous version of these files.
- Frequency scoring: [`wordfreq`](https://github.com/rspeer/wordfreq) Python package,
  French corpus data.

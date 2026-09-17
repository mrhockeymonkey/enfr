# Lefff verb list generator

`build_lefff_verbs.py` builds `assets/verbs/experimental/verbs_lefff.json`, an
experimental verb list in which pronominal verbs get their own entry (`lever` and
`se lever` are two keys). It reads the raw Lefff lexicon, which is not committed
because it is 174 MB uncompressed.

## Getting the lexicon

1. Download `lefff-3.4.0.elex.tar.gz` from the Lefff project
   (<https://gitlab.inria.fr/almanach/alexina/lefff>, licence LGPL-LR).
2. Put it in `tool/lefff/data/` (git-ignored). The script accepts either the
   `.tar.gz` archive or the extracted `lefff-3.4.elex` file.

## Running

```bash
python3 tool/lefff/build_lefff_verbs.py \
  --elex tool/lefff/data/lefff-3.4.0.elex.tar.gz \
  --tiers assets/verbs \
  --out assets/verbs/experimental/verbs_lefff.json \
  --verify --report
```

Python 3.11+, standard library only. Runs in under ten seconds.

- `--verify` also reads the 946k inflected rows and checks every form in the
  existing `verbs_*.json` tier files against the lexicon. Expect exactly one
  mismatch (`vouloir` imperative `veuillons`, a quirk of the tier file).
- `--report` prints the mute/aspirated-h decision for every h-initial pronominal
  verb, and flags where Lefff's own spelling (`se h…` vs `s'h…`) disagrees with the
  script's aspirated-h list.

## What the script reads

Each `.elex` row is nine tab-separated columns, Latin-1 encoded:

```
form  weight  cat  features  lemma_id  morph_label  morph_tag  redistribution  inflection_class
```

Only `cat == v` rows matter. The infinitive rows (`morph_tag == W`) give one row per
verb *sense*, e.g.

```
lever  100  v  [pred="lever_____1<Suj:(cln|sn),Obj:(cla|sn)>",@pers,cat=v,@W]           lever_____1  Infinitive  W  %actif     v-er:std
lever  100  v  [pred="lever_____1<Suj:sn>se",@pers,@se_moyen,@être,cat=v,@W]           lever_____1  Infinitive  W  %se_moyen  v-er:std
lever  100  v  [pred="se lever_____2<Suj:(cln|sn)>",@pers,@pron,@être,cat=v,@W]        lever_____2  Infinitive  W  %actif     v-er:std
```

| Signal in the row | Meaning | Used for |
|---|---|---|
| `@pron` feature | inherently pronominal sense: the pronoun is part of the lexeme (`se lever` = get up, `se souvenir`) | `pronominal_kind` essential / lexicalised, `senses.pronominal` |
| `%se_moyen*` redistribution | reflexive / reciprocal / middle / passive reading derived from a transitive sense (`se laver`) | `pronominal_kind` reflexive, `senses.reflexive` |
| neither | ordinary active sense | whether a plain entry exists, `senses.active` |
| `@impers` | impersonal sense (`il s'agit`, `il faut`) | `impersonal`, `impersonal_only` |
| `@être`, `@être_possible` | auxiliary in compound tenses (per sense, sparsely marked) | `auxiliary` |
| `(se) X` spelling of the pred | pronoun optional for that sense | `pronoun_optional` |
| `s'h…` / `se h…` spelling of the pred | mute vs aspirated h | cross-checked against the script's aspirated-h list |
| `Objde:`, `Objà:`, `Obl:(sur-sn)` in the frame | governed preposition | `prepositions` |
| `lemma_id` like `aller___be_about_to__1` | English gloss (145 senses only) | `glosses` |

Conjugation forms are **not** re-derived from the lexicon. They come from the existing
`assets/verbs/verbs_*.json` files (themselves Lefff data), as does `zipf`. Pronominal
entries inherit the base verb's zipf.

## Pronoun composition

Lefff stores bare forms; the reflexive pronoun is added by rule:

| Code | Rule | Example |
|---|---|---|
| P I F J C S T | `me/te/se/nous/vous/se` + form, elided to `m'/t'/s'` before a vowel or mute h | `je me lève`, `je m'évanouis`, `je me hâte` |
| Y | postposed stressed pronoun with hyphen in the tu/nous/vous slots | `lève-toi`, `levons-nous`, `levez-vous` |
| G | `se` / `s'` + present participle | `se levant`, `s'évanouissant` |
| W | the entry key | `se lever` |
| K | unchanged | `levé, levés, levée, levées` |

Elision decision: vowel-initial verbs always elide; `y` never does (`se yodiser`);
h-initial verbs elide unless they are in the script's `ASPIRATED_H` set.

## Design note: defective verbs are excluded

A few Lefff verbs are genuinely defective in French: only the infinitive, and
sometimes the present participle, are ever used (`accroire`, `quérir`, `ravoir`,
`parfaire`, ...). `has_quizzable_form` checks whether a verb has at least one form
in the 9 tenses the app quizzes on (`QUIZZABLE_CODES`, mirroring
`lib/models/verb_tense.dart`); if not, both its plain and any pronominal entry are
skipped, since there's nothing for a conjugation quiz to ask.

## Known limitations

- `auxiliary` reflects Lefff's per-sense `@être` marks, which are incomplete. `partir`
  comes out as `both` because two of its four active senses are unmarked. Treat
  `être` and `both` as "takes être in at least one sense".
- Seven keys in the tier files (`voici`, `voilà`, `revoici`, `revoilà`, `pacser`, `uw`,
  `uwSe`) do not exist in the lexicon and are dropped. `_error` in the lexicon is skipped.
- Nine verbs carry `@pron` on a sense whose pred is not spelled with `se`
  (`attendre`, `tenir`, `étonner`, ...). The feature is trusted over the spelling.
- Lefff spells five h-initial verbs with `se h…` where standard usage elides
  (`s'hypertrophier`). The script's list wins; `--report` shows them.

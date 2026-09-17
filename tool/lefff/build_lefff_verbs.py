#!/usr/bin/env python3
"""Build the experimental verb list (with pronominal verbs) from the Lefff .elex lexicon.

Reads the raw Lefff 3.4 ``.elex`` file (Latin-1, tab-separated), classifies every
verb by whether it has an inherently pronominal sense (``@pron``) and/or a derived
reflexive reading (``%se_moyen*`` redistribution), and emits one entry per plain
verb (``lever``) plus one per pronominal verb (``se lever``). Conjugation forms and
zipf scores are taken from the existing ``assets/verbs/verbs_*.json`` tier files,
which are themselves Lefff data; the reflexive pronoun is composed in by rule.

Usage:
    python3 tool/lefff/build_lefff_verbs.py \
        --elex tool/lefff/data/lefff-3.4.0.elex.tar.gz \
        --tiers assets/verbs \
        --out assets/verbs/experimental/verbs_lefff.json [--verify] [--report]

Only the Python standard library is used. See tool/lefff/README.md.
"""

from __future__ import annotations

import argparse
import collections
import io
import json
import pathlib
import re
import sys
import tarfile
from dataclasses import dataclass, field

LEFFF_VERSION = "3.4"
TIER_FILES = [
    "verbs_essential.json",
    "verbs_common.json",
    "verbs_moderate.json",
    "verbs_uncommon.json",
    "verbs_rare.json",
]
TENSE_CODES = ["P", "S", "Y", "I", "G", "K", "J", "T", "F", "C", "W"]
PERSON_CODES = {"P", "I", "F", "J", "C", "S", "T"}

PRONOUNS = ["me", "te", "se", "nous", "vous", "se"]
PRONOUNS_ELIDED = ["m'", "t'", "s'", "nous ", "vous ", "s'"]
IMPERATIVE_PRONOUNS = {1: "toi", 3: "nous", 4: "vous"}

# Letters after which me/te/se elide. "y" is deliberately absent: French does not
# elide before y-initial words (le yaourt), and the one y-initial pronominal verb in
# Lefff (yodiser) behaves that way.
VOWELS = set("aeiouàâäéèêëîïôöùûü")

# Verbs starting with an aspirated h (no elision, no liaison: "je me hâte",
# "lève-toi" style postposition unaffected). This closed set is authoritative for the
# elision decision. Lefff also spells its lexicalised pronominal lemmas "se h…" /
# "s'h…"; the script reports every verb where that spelling disagrees with this set
# so the list can be reviewed (Lefff has "se hypertrophier", standard usage is
# "s'hypertrophier").
ASPIRATED_H = {
    "hacher", "hachurer", "haïr", "haler", "hâler", "halener", "haleter", "hancher",
    "handicaper", "hanter", "happer", "haranguer", "harasser", "harceler", "harder",
    "harnacher", "harpailler", "harper", "harponner", "hasarder", "hâter", "haubaner",
    "hausser", "haver", "hâbler", "héler", "hennir", "hérisser", "heurter",
    "hiérarchiser", "hisser", "hocher", "honnir", "hoqueter", "hotter", "houblonner",
    "houer", "houiller", "houillifier", "houspiller", "hucher", "huer", "humer",
    "hurler", "hululer",
}

LEMMA_ID_RE = re.compile(r"^(?P<lemma>.+?)___(?P<gloss>.*?)__(?P<sense>\d+)$")
PRED_RE = re.compile(r'pred="(?P<name>[^<"]*)(?:<(?P<frame>[^>]*)>)?(?P<suffix>[^"]*)"')
FEATURE_RE = re.compile(r"@([^,\]\s]+)")
FRAME_ARG_RE = re.compile(r"(?P<fn>[A-Za-zàé]+):\(?(?P<vals>[^,>)]+)")
PREP_VAL_RE = re.compile(r"^(?P<prep>[^-]+)-s(?:n|inf|compl|adj|qcompl)$")
NOT_PREPS = {"loc", "cln", "cla", "cld", "y", "en", "sn", "sinf", "scompl", "qcompl", "tps"}

ZIPF_TIERS = [(5.0, "essential"), (4.0, "common"), (3.0, "moderate"), (1.5, "uncommon")]


def tier_for(zipf: float) -> str:
    for threshold, name in ZIPF_TIERS:
        if zipf >= threshold:
            return name
    return "rare"


@dataclass
class VerbInfo:
    """Everything the infinitive (W) rows of the lexicon tell us about one verb."""

    infinitive: str
    active_senses: set = field(default_factory=set)
    active_personal: bool = False
    active_impersonal: bool = False
    aux: set = field(default_factory=set)
    pron_senses: set = field(default_factory=set)
    pron_personal: bool = False
    pron_impersonal: bool = False
    pron_optional: bool = False
    pron_unprefixed: bool = False
    pron_spelling: set = field(default_factory=set)
    reflexive_senses: set = field(default_factory=set)
    preps_active: collections.Counter = field(default_factory=collections.Counter)
    preps_pron: collections.Counter = field(default_factory=collections.Counter)
    glosses_active: set = field(default_factory=set)
    glosses_pron: set = field(default_factory=set)
    inflection_classes: set = field(default_factory=set)

    @property
    def has_plain(self) -> bool:
        return bool(self.active_senses)

    @property
    def has_pronominal(self) -> bool:
        return bool(self.pron_senses or self.reflexive_senses)

    @property
    def pronominal_kind(self) -> str | None:
        if not self.has_pronominal:
            return None
        if self.pron_senses:
            return "lexicalised" if self.active_personal else "essential"
        return "reflexive"


def open_elex(path: pathlib.Path) -> io.TextIOBase:
    """Open the .elex file as Latin-1 text, either directly or from inside a tarball."""
    if path.suffixes[-2:] == [".tar", ".gz"] or path.suffix in {".tgz", ".tar"}:
        tar = tarfile.open(path)
        member = next((m for m in tar.getmembers() if m.isfile() and m.name.endswith(".elex")), None)
        if member is None:
            sys.exit(f"no .elex member found in {path}")
        stream = tar.extractfile(member)
        assert stream is not None
        return io.TextIOWrapper(stream, encoding="latin-1", newline="\n")
    return open(path, encoding="latin-1", newline="\n")


def parse_frame_preps(frame: str | None) -> list[str]:
    """Extract governed prepositions (de, à, sur, …) from a subcategorisation frame."""
    if not frame:
        return []
    preps: list[str] = []
    for m in FRAME_ARG_RE.finditer(frame):
        fn, vals = m.group("fn"), m.group("vals")
        if fn == "Objde":
            preps.append("de")
        elif fn == "Objà":
            preps.append("à")
        elif fn in {"Obl", "Obl2", "Dloc"}:
            for v in vals.split("|"):
                pm = PREP_VAL_RE.match(v.strip("()"))
                if pm and pm.group("prep") not in NOT_PREPS:
                    preps.append(pm.group("prep").replace("_", " "))
    return preps


def split_lemma_id(lemma_id: str) -> tuple[str, str, int]:
    m = LEMMA_ID_RE.match(lemma_id)
    if not m:
        return lemma_id, "", 0
    return m.group("lemma"), m.group("gloss"), int(m.group("sense"))


def read_lexicon(path: pathlib.Path, verify: bool):
    """Return (verbs: dict[inf, VerbInfo], paradigms: dict[inf, dict[code, dict[slot, set]]])."""
    verbs: dict[str, VerbInfo] = {}
    lemma_to_inf: dict[str, str] = {}
    raw_rows: list[tuple[str, str, str]] = []  # (form, lemma_id, tag) for --verify

    with open_elex(path) as fh:
        for line in fh:
            cols = line.rstrip("\n").split("\t")
            if len(cols) < 9 or cols[2] != "v":
                continue
            form, features, lemma_id, tag, redistribution, infl = (
                cols[0], cols[3], cols[4], cols[6], cols[7], cols[8])
            if tag != "W":
                if verify:
                    raw_rows.append((form, lemma_id, tag))
                continue
            if form == "_error":
                continue
            info = verbs.setdefault(form, VerbInfo(form))
            lemma_to_inf[lemma_id] = form
            info.inflection_classes.add(infl)
            feats = set(FEATURE_RE.findall(features))
            pred = PRED_RE.search(features)
            name = pred.group("name") if pred else ""
            frame = pred.group("frame") if pred else None
            _, gloss, _ = split_lemma_id(lemma_id)
            preps = parse_frame_preps(frame)
            is_pron = "pron" in feats
            is_reflexive = "se_moyen" in redistribution
            impers = "impers" in feats
            if name.startswith("s'") or name.startswith("(s')"):
                info.pron_spelling.add("s'")
            elif name.startswith("se ") or name.startswith("(se)"):
                info.pron_spelling.add("se")

            if is_pron:
                info.pron_senses.add(lemma_id)
                info.preps_pron.update(preps)
                if gloss:
                    info.glosses_pron.add(gloss)
                if impers:
                    info.pron_impersonal = True
                else:
                    info.pron_personal = True
                if name.startswith("(se)") or name.startswith("(s')"):
                    info.pron_optional = True
                if not (name.startswith("s'") or name.startswith("(s')")
                        or name.startswith("se ") or name.startswith("(se)")):
                    info.pron_unprefixed = True
            elif is_reflexive:
                info.reflexive_senses.add(lemma_id)
                info.preps_pron.update(preps)
            else:
                info.active_senses.add(lemma_id)
                info.preps_active.update(preps)
                if gloss:
                    info.glosses_active.add(gloss)
                if impers:
                    info.active_impersonal = True
                else:
                    info.active_personal = True
                if "être" in feats:
                    info.aux.add("être")
                elif "être_possible" in feats:
                    info.aux.update({"avoir", "être"})
                else:
                    info.aux.add("avoir")

    paradigms: dict[str, dict[str, dict[int, set[str]]]] = {}
    if verify:
        for form, lemma_id, tag in raw_rows:
            inf = lemma_to_inf.get(lemma_id)
            if inf is None:
                continue
            for code, slot in expand_tag(tag):
                paradigms.setdefault(inf, {}).setdefault(code, {}).setdefault(slot, set()).add(form)
    return verbs, paradigms


TAG_RE = re.compile(r"^(?P<codes>[A-Z]+)(?P<rest>.*)$")


def expand_tag(tag: str) -> list[tuple[str, int]]:
    """Map a Lefff morph tag (P1s, PS13s, Kfp, G) to (tense_code, slot) pairs."""
    m = TAG_RE.match(tag)
    if not m:
        return []
    codes, rest = m.group("codes"), m.group("rest")
    out: list[tuple[str, int]] = []
    for code in codes:
        if code == "K":
            # K slots: masc sg, masc pl, fem sg, fem pl. A missing gender or number
            # letter means the form is shared (e.g. "Km" = mis, both numbers).
            genders = [g for g in "mf" if g in rest] or ["m", "f"]
            numbers = [n for n in "sp" if n in rest] or ["s", "p"]
            out.extend((code, (0 if g == "m" else 2) + (1 if n == "p" else 0))
                       for g in genders for n in numbers)
        elif code in {"G", "W"}:
            out.append((code, 0))
        elif code in PERSON_CODES or code == "Y":
            persons = [int(c) for c in rest if c.isdigit()] or [1, 2, 3]
            numbers = [n for n in "sp" if n in rest] or ["s", "p"]
            for p in persons:
                for n in numbers:
                    out.append((code, (p - 1) + (3 if n == "p" else 0)))
    return out


def load_tiers(tiers_dir: pathlib.Path) -> dict[str, tuple[dict, str]]:
    forms: dict[str, tuple[dict, str]] = {}
    for name in TIER_FILES:
        path = tiers_dir / name
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
        for inf, entry in data["verbs"].items():
            forms[inf] = (entry, name)
    return forms


def h_is_mute(info: VerbInfo, decisions: dict[str, str]) -> bool:
    inf = info.infinitive
    mute = inf not in ASPIRATED_H
    lefff = ("s'h" if info.pron_spelling == {"s'"} else
             "se h" if info.pron_spelling == {"se"} else
             "both" if info.pron_spelling else None)
    verdict = "mute" if mute else "aspirated"
    if lefff is None:
        decisions[inf] = f"{verdict} (no Lefff spelling hint)"
    elif (lefff == "s'h") == mute:
        decisions[inf] = f"{verdict} (Lefff agrees: {lefff}…)"
    else:
        decisions[inf] = f"{verdict} (DISAGREES with Lefff spelling {lefff}…)"
    return mute


def elides_before(form: str, h_mute: bool) -> bool:
    first = form[:1]
    return first in VOWELS or (first == "h" and h_mute)


def compose_pronominal_forms(key: str, base_entry: dict, h_mute: bool) -> dict:
    """Prepend / append the reflexive pronoun to each form of the base paradigm."""
    out: dict = {}
    for code in TENSE_CODES:
        raw = base_entry.get(code)
        if not isinstance(raw, list):
            continue
        if code in PERSON_CODES:
            composed = []
            for i, f in enumerate(raw):
                if not isinstance(f, str) or f in ("", "NA"):
                    composed.append("NA")
                elif elides_before(f, h_mute):
                    composed.append(PRONOUNS_ELIDED[i] + f)
                else:
                    composed.append(PRONOUNS[i] + " " + f)
            out[code] = composed
        elif code == "Y":
            composed = []
            for i, f in enumerate(raw):
                if not isinstance(f, str) or f in ("", "NA") or i not in IMPERATIVE_PRONOUNS:
                    composed.append("NA")
                else:
                    composed.append(f + "-" + IMPERATIVE_PRONOUNS[i])
            out[code] = composed
        elif code == "G":
            composed = []
            for f in raw:
                if not isinstance(f, str) or f in ("", "NA"):
                    composed.append("NA")
                elif elides_before(f, h_mute):
                    composed.append("s'" + f)
                else:
                    composed.append("se " + f)
            out[code] = composed
        elif code == "W":
            out[code] = [key]
        else:  # K: past participle stays bare, agreement is a compound-tense concern
            out[code] = list(raw)
    return out


def build_entries(verbs: dict[str, VerbInfo], tiers: dict[str, tuple[dict, str]], log: list[str]):
    entries: dict[str, dict] = {}
    h_decisions: dict[str, str] = {}
    counts = collections.Counter()
    missing_forms: list[str] = []

    for inf in sorted(verbs):
        info = verbs[inf]
        tier_entry, tier_file = tiers.get(inf, (None, None))
        if tier_entry is None:
            missing_forms.append(inf)
            continue
        zipf = float(tier_entry.get("zipf") or 0.0)
        tier = tier_for(zipf)
        base_forms = {
            c: [f if isinstance(f, str) and f else "NA" for f in tier_entry[c]]
            for c in TENSE_CODES if isinstance(tier_entry.get(c), list)
        }
        if not base_forms:
            missing_forms.append(inf)
            continue

        pron_key = None
        if info.has_pronominal:
            h_mute = h_is_mute(info, h_decisions) if inf.startswith("h") else False
            elide = elides_before(inf, h_mute)
            pron_key = ("s'" if elide else "se ") + inf

        if info.has_plain:
            aux = sorted(info.aux) or ["avoir"]
            entries[inf] = {
                **base_forms,
                "zipf": zipf,
                "meta": {
                    "pronominal": False,
                    "pronominal_form": pron_key,
                    "auxiliary": "both" if len(aux) > 1 else aux[0],
                    "impersonal": info.active_impersonal,
                    "impersonal_only": info.active_impersonal and not info.active_personal,
                    "prepositions": [p for p, _ in info.preps_active.most_common()],
                    "glosses": sorted(g.replace("_", " ") for g in info.glosses_active),
                    "senses": {
                        "active": len(info.active_senses),
                        "pronominal": len(info.pron_senses),
                        "reflexive": len(info.reflexive_senses),
                    },
                    "inflection_class": sorted(info.inflection_classes)[0],
                    "zipf_source": tier_file,
                    "tier": tier,
                },
            }
            counts["plain"] += 1

        if pron_key is not None:
            kind = info.pronominal_kind
            entries[pron_key] = {
                **compose_pronominal_forms(pron_key, base_forms, h_mute),
                "zipf": zipf,
                "meta": {
                    "pronominal": True,
                    "pronominal_kind": kind,
                    "base": inf if info.has_plain else None,
                    "pronoun_optional": info.pron_optional,
                    "elides": elide,
                    "auxiliary": "être",
                    "impersonal": info.pron_impersonal,
                    "impersonal_only": bool(info.pron_senses) and info.pron_impersonal
                    and not info.pron_personal and not info.reflexive_senses,
                    "prepositions": [p for p, _ in info.preps_pron.most_common()],
                    "glosses": sorted(g.replace("_", " ") for g in info.glosses_pron),
                    "senses": {
                        "pronominal": len(info.pron_senses),
                        "reflexive": len(info.reflexive_senses),
                    },
                    "inflection_class": sorted(info.inflection_classes)[0],
                    "zipf_source": f"base:{tier_file}",
                    "tier": tier,
                },
            }
            counts["pronominal"] += 1
            counts[kind] += 1

    if missing_forms:
        log.append(f"{len(missing_forms)} elex infinitive(s) have no usable forms in the tier files "
                   f"and were skipped: {', '.join(missing_forms[:20])}")
    unused = sorted(set(tiers) - set(verbs))
    if unused:
        log.append(f"{len(unused)} tier-file key(s) do not exist in the elex and were not carried over: "
                   f"{', '.join(unused)}")
    return entries, counts, h_decisions


def sort_key(key: str) -> tuple[str, int]:
    if key.startswith("se "):
        return key[3:], 1
    if key.startswith("s'"):
        return key[2:], 1
    return key, 0


def write_output(path: pathlib.Path, entries: dict[str, dict], counts: collections.Counter, elex_name: str):
    header = {
        "source": ("Lefff " + LEFFF_VERSION + " (" + elex_name + ") for the verb inventory and "
                   "pronominal classification; conjugation forms and zipf scores reused from "
                   "assets/verbs/verbs_*.json"),
        "lefff_version": LEFFF_VERSION,
        "generated_by": "tool/lefff/build_lefff_verbs.py",
        "verb_count": len(entries),
        "counts": {k: counts[k] for k in ("plain", "pronominal", "essential", "lexicalised", "reflexive")},
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    keys = sorted(entries, key=sort_key)
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("{\n")
        for k, v in header.items():
            fh.write(f"  {json.dumps(k)}: {json.dumps(v, ensure_ascii=False)},\n")
        fh.write('  "verbs": {\n')
        for i, key in enumerate(keys):
            sep = "," if i < len(keys) - 1 else ""
            fh.write(f"    {json.dumps(key, ensure_ascii=False)}: "
                     f"{json.dumps(entries[key], ensure_ascii=False)}{sep}\n")
        fh.write("  }\n}\n")


def verify_forms(verbs: dict[str, VerbInfo], paradigms: dict, tiers: dict, log: list[str]):
    """Check that every tier-file form is one the lexicon lists for that verb, tense and slot."""
    mismatches: list[str] = []
    checked = 0
    for inf in verbs:
        tier_entry = tiers.get(inf, (None, None))[0]
        para = paradigms.get(inf)
        if tier_entry is None or para is None:
            continue
        for code in TENSE_CODES:
            raw = tier_entry.get(code)
            if not isinstance(raw, list):
                continue
            for slot, f in enumerate(raw):
                if not isinstance(f, str) or f in ("", "NA"):
                    continue
                checked += 1
                expected = para.get(code, {}).get(slot, set())
                if code == "W":
                    expected = {inf}
                if f not in expected:
                    mismatches.append(f"{inf} {code}[{slot}] tier={f!r} lefff={sorted(expected)}")
    log.append(f"--verify: {checked} tier forms checked against the lexicon, {len(mismatches)} mismatch(es)")
    for m in mismatches[:40]:
        log.append("  " + m)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--elex", required=True, type=pathlib.Path,
                        help="lefff-3.4.elex, or the .tar.gz archive that contains it")
    parser.add_argument("--tiers", default="assets/verbs", type=pathlib.Path,
                        help="directory holding verbs_*.json (default: assets/verbs)")
    parser.add_argument("--out", default="assets/verbs/experimental/verbs_lefff.json", type=pathlib.Path)
    parser.add_argument("--verify", action="store_true",
                        help="also read the inflected rows and check the tier-file forms against them")
    parser.add_argument("--report", action="store_true",
                        help="print the mute/aspirated-h decision for every h-initial pronominal verb")
    args = parser.parse_args(argv)

    log: list[str] = []
    verbs, paradigms = read_lexicon(args.elex, args.verify)
    tiers = load_tiers(args.tiers)
    entries, counts, h_decisions = build_entries(verbs, tiers, log)
    write_output(args.out, entries, counts, args.elex.name)
    if args.verify:
        verify_forms(verbs, paradigms, tiers, log)

    print(f"elex infinitives: {len(verbs)}   tier-file verbs: {len(tiers)}")
    print(f"written {len(entries)} entries to {args.out}")
    for k in ("plain", "pronominal", "essential", "lexicalised", "reflexive"):
        print(f"  {k:12s} {counts[k]}")
    for line in log:
        print(line)
    if args.report:
        print("h-initial pronominal verbs:")
        for inf, why in sorted(h_decisions.items()):
            print(f"  {inf:20s} {why}")
    unprefixed = sorted(v.infinitive for v in verbs.values()
                        if v.pron_unprefixed)
    if unprefixed:
        print(f"{len(unprefixed)} verb(s) carry @pron on a sense whose pred is not spelled with se/s' "
              f"(flag trusted): {', '.join(unprefixed)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

# Semantic Sentence ID Contract

## Contract

| Property | Value |
| --- | --- |
| Backend JSON field | `semantic_sentence_id` |
| Flutter field | `FinalTouchSentenceDetail.semanticSentenceId` |
| Type | Non-empty string |
| Authority | Existing-app Backend |
| New-ID algorithm | UUID4 |
| Legacy fallback | UUID5 |
| Persistence | `AnalysisRecord.sentence_details` JSON |

`sentence_no` remains the display order and visible sentence number. It is not a
semantic identifier. List indexes, widget indexes, `ValueKey(index)`, text hashes,
and Dart `hashCode` are not semantic sentence IDs.

## Creation and preservation

- `/analyze/summary_flow` assigns a UUID4 when normalized sentence details are
  first built.
- Every Backend storage path normalizes `sentence_details` before persistence.
  This includes `/analysis-records`, which receives manual-import data.
- A non-empty, unique incoming string ID is preserved exactly.
- For duplicate incoming IDs, the first occurrence is preserved and each later
  occurrence receives a new UUID4 before storage.
- Reload does not regenerate IDs stored in the JSON column.
- Flutter parses the Backend value but never creates, hashes, or derives an ID.

## Legacy records

An old persisted record may have no ID. The Final Touch response derives a UUID5
from a fixed namespace plus:

```text
analysis_record_id + sentence_no + sentence position
```

The fallback is deterministic for repeated reads of the same record and distinct
between records. It is response normalization; it does not require a database
schema migration or an implicit write during GET. Duplicate legacy IDs are also
repaired deterministically.

Flutter treats a missing or non-string legacy field as an empty string. It does
not invent an identity. The Backend Final Touch endpoint is responsible for
supplying the deterministic legacy ID in production.

## Scope and limitations

`semantic_sentence_id` identifies one sentence instance within a persisted
analysis result. Re-analyzing identical passage text may create different IDs.
It is not a cross-analysis sentence-equivalence identifier.

The identifier is safe to expose in JSON and may be used as an internal Flutter
widget key. It is not authentication or authorization evidence. Any future Tutor
endpoint must authorize access through the owning analysis record and user, not
through possession of a sentence ID alone.

No database schema migration is required because `sentence_details` is already a
JSON column.

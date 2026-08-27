# Tutor Semantic Normalization Contract

## Scope and verification boundary

The source object is the verified existing-app Dart class
`FinalTouchSentenceDetail`. The AI Tutor repository is on another computer and
was not available for inspection during Step 16. Tutor fields below come from the
provided prior contract and every Tutor shape/type statement **requires Tutor-side
confirmation** before implementation.

This document defines normalization rules only. It does not implement a Tutor
adapter, Tutor API, or Tutor String-ID migration.

## Mapping matrix

| Tutor Target | Existing App Source | Status | Mapping Rule | Information Loss |
| --- | --- | --- | --- | --- |
| `sentence` | `original` | DIRECT | Copy the original sentence text. | None. |
| `sentence_id` | `semantic_sentence_id` / `semanticSentenceId` | TARGET CHANGE REQUIRED | Preserve the opaque string unchanged. Never hash or coerce it to an integer. Tutor type requires Tutor-side confirmation. | None if Tutor accepts String; identity loss if coerced. |
| `translation` | `translation` | DIRECT | Copy the sentence translation. | None. |
| `sentence_role` | `sentence_role` | DIRECT | Copy when non-empty; otherwise preserve missing/empty state. | None. |
| `question_points` | `question_point` | NORMALIZE | Non-empty string becomes a one-item list; empty becomes an empty list. Tutor list type requires Tutor-side confirmation. | No semantic loss under the supplied target shape. |
| `grammar_points` | `grammar_points[]` (`target`, `label`, `explanation`, `reference_no`) | NORMALIZE | Candidate mapping: `type <- label`, `description <- explanation`. Preserve source data until Tutor shape is confirmed. | `target` and `reference_no` may be lost in the supplied simpler Tutor shape. |
| `vocabulary` | `highlights[]` where `type == vocabulary` | PARTIAL | `text` can identify the expression. Do not map `memo` to meaning without an explicit contract. | Meaning/note fields are not reliably available. |
| `clauses` | `spans[]` where type is `noun_clause`, `adj_clause`, or `adv_clause` | PARTIAL | A future adapter may extract text from the original sentence only after offset-unit validation. Keep span type; do not infer grammatical sentence role. | Dedicated clause objects and grammatical roles are absent. |
| `important_expressions` | selected `highlights[]` | PARTIAL | Include only data explicitly marked as an important expression by a future contract; otherwise use an empty list. | Current highlights encode grammar/vocabulary/blank hints, not general importance. |
| `core_meaning` | no sentence-level field | MISSING | Keep missing. Do not copy passage topic/gist/summary. | Sentence-level core meaning is unavailable. |
| `syntax.subject` | no structured field | MISSING | No value may be invented. | Missing. |
| `syntax.verb` | no structured field | MISSING | No value may be invented. | Missing. |
| `syntax.objects` | no structured field | MISSING | No value may be invented. | Missing. |
| `syntax.complement` | no structured field | MISSING | No value may be invented. | Missing. |
| clause grammatical role | span `role` values such as noun/adjective/adverb/prepositional | MISSING | These are category roles, not subject/object/complement roles. | Grammatical clause role is unavailable. |

## Span and clause offset constraint

Backend `structure_analyzer.py` creates sentence-local `[start,end)` offsets from
the original sentence using Python string indexes. Dart `String.substring` uses
UTF-16 code units. The offsets normally coincide for ASCII/BMP English text, but
they are not universally equivalent for supplementary Unicode characters.

A future adapter must validate the exact substring or convert offset units before
creating clause text. Step 16 does not perform clause extraction.

## Existing-only rich semantic representation

| Existing field | Current status for Tutor |
| --- | --- |
| `bracketed` | Useful candidate for future structure explanation; no supplied Tutor field. |
| `translationBracketed` | Rich translated structure; no supplied Tutor field. |
| `spans` | Structured phrase/clause positions, subject to offset-unit validation. |
| `roleHighlightType` | Presentation concern; do not add automatically to Tutor semantics. |
| `isBlankCandidate` | Assessment signal requiring a later contract decision. |
| `highlights` | Structured grammar/vocabulary/blank-hint data; not fully consumed by current Final Touch UI. |

## Prohibited inference

- Do not infer subject or object from a noun/noun-phrase span.
- Do not choose the first verb token as the structured verb.
- Do not treat a noun clause as an object clause without explicit grammatical data.
- Do not copy passage gist/topic/summary into sentence-level `core_meaning`.
- Do not derive formal clause roles from bracket characters.
- Do not treat vocabulary `memo` as a definition without a confirmed contract.
- Do not convert UUID strings through `hashCode` or any integer hash.

## Data quality and provenance

Analyzer-generated records can contain spans, sentence roles, grammar points,
question points, and highlights. Manual imports intentionally use the same outer
shape but can contain empty lists/strings for all of those fields. A normalizer
must preserve that incompleteness and must not invent semantic content.

No `analysis_source` or `semantic_completeness` production fields are introduced
in Step 16.

## Blocker for Tutor-side step

The following require the AI Tutor computer and actual source-code inspection:

- actual `SemanticData.sentenceId` type and all constructor/copy/serialization uses;
- Tutor API request/response and path-parameter types;
- cache, state, and widget keys derived from sentence identity;
- exact grammar, vocabulary, syntax, clause, and question-point model shapes;
- Tutor tests affected by String-ID migration.

The next implementation step is **Phase 3 Step 17 — Tutor SemanticData String-ID
Migration**, after these shapes are confirmed on the Tutor host.

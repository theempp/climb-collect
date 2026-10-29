# Coordinated egg and offspring quality pass — October 26, 2026

## Authority and scope

Owner explicitly requested improving all eggs and offspring together after initial generation, for eventual polished Roblox use. New enhanced copies of the locked Floravelle baseline are authorized; originals remain protected. No paid generation, upload, publication, game catalog migration or gameplay tuning is authorized by this asset pass. Distinct eggs per species remain the current direction. Moss fox/crystal hare are optional; the Aquarune, Zenthari and Pyralune species pools remain candidates.

## Versioned production

Working package: `C:/Users/HOME!/Documents/Codex/2026-10-26/paired-collection-polish/Collection-v002/`.
Plan: `docs/superpowers/plans/2026-10-26-paired-collection-polish.md`.

Intake graph was CURRENT for tracked navigation/vault inputs; external assets and isolated runtime are excluded. Graph query and source inspection confirmed the existing species-egg decision and catalog mismatch. No current game implementation was changed.

First material checkpoint: all 25 offspring and 25 intact egg editable Blender sources generated, rendered and inspected through five paired family sheets. Source improvements include continuous selected anatomy, colored layered eyes, species-specific paws/gills/feathers/scutes, smooth intact eggs and local split-shell previews. Corrections and runtime preparation remain in progress at this checkpoint.

Preservation evidence: `evidence/original-hashes.json` covers 392 existing files across the three original packages; all matched in the checkpoint recheck. Vault note backups: `evidence/vault-backup-intake/`.

## Corrected assumptions and quality findings

- Smooth shading on independently split shell pieces did not remove visible joints. Intact shells now have a separate uninterrupted surface; jagged halves appear only in the hatch state.
- Joining meshes with differently named UV layers lost eye colors. Runtime palette mapping now uses exactly one consistently named UV layer and is checked by actual textured renders.
- Whole-mesh heavy reduction damaged tiny closed components. Component-aware reduction retains minimum closed detail geometry; all final LOD topology still requires full verification.
- Reimport caught a double-applied hatch pivot offset. Explicit parent dependency updates were added; final hatch reimport verification is pending.
- Initial serpent throat plates and turtle scutes sat proud of the body; surface-fitting corrections are being applied. Initial hatch review cameras cropped lids; final renders use full opened bounds.

## Readiness boundaries

The intended outputs include editable sources, GLB/FBX static runtime candidates, one-material UV palette atlases, three measured LODs, simple separate collision proxies, carry-center metadata and local rigid hatch previews. Palette UVs intentionally overlap; they are not unique paintable bakes. Creature rigs, deformation and locomotion are not supplied by this pass. Hatch node motion is not a verified Roblox skeletal clip or installed game adapter.

Owner visual acceptance, approved game scales, catalog compatibility/legacy saves/sixth family, actual Studio import and device/performance testing remain open. Do not label Blender renders or file round trips as publication readiness. Current platform reference: https://create.roblox.com/docs/art/modeling/specifications (20,000 triangles per mesh, closed volumes); lower production budgets are author proposals, not measured game limits.

Final evidence and post-record graph freshness will be appended after verification and packaging.

## Final verified local collection

The checkpoint pending statements above are superseded by this result: **325 final checks passed, zero failures**, after the last geometry/export corrections. The exact 25-species roster and required files are asserted. All **550 portable export files** were freshly reimported: 325 GLBs and 225 FBXs spanning full-detail sources, three static LODs, collision proxies, two-part closed hatch assemblies and rigid hatch previews. Saved source/LOD0 files were reopened; finite coordinates, triangle counts, bounds, UV/image presence and source-hash provenance were checked. All runtime mesh authoring audits report zero nonmanifold edges and fewer than 20,000 triangles per mesh. All 392 original package files remain hash-identical.

Evidence: external `Collection-v002/evidence/verification.json`, `visual-review.json`, `original-hashes.json`, per-species `runtime/*-audit.json`, and parent `verify-final.log`. Archive checksums, sizes and CRC results are recorded in parent `delivery-verification.json`. Full package: `Collection-v002.zip`; smaller export package: `Runtime-v002.zip`, both in `C:/Users/HOME!/Documents/Codex/2026-10-26/paired-collection-polish/`.

Measured static triangle ranges:

| Asset | LOD0 | LOD1 | LOD2 |
|---|---:|---:|---:|
| Offspring | 14,340–14,934 | 6,066–6,612 | 2,404–3,400 |
| Intact eggs | 6,032–15,048 | 2,974–3,148 | 1,328–1,568 |

Visual evidence: `review.html`, `all-25-pairs.jpg`, `all-hatch-previews.jpg`, five family paired sheets and five source-versus-runtime sheets. All 125 source views and 50 atlas LOD0 views inspected; four targeted lower-LOD serpent/eel renders inspected. Independent review found scute intersections and verification omissions; those were repaired. The serpent/eel thin connector was traced to abrupt tube-frame orientation changes and replaced with transported frames. Turtle scutes now use a tessellated conforming volume. Leaf-bearing egg LOD0s retain their original shell/leaf geometry to avoid rough reduction boundaries. Close-up simplification remains visible in distant LODs; no distance thresholds are approved.

The output is an **enhanced local art collection and technically checked static import candidate package**, not publication certification. Each asset has a single-material palette atlas, three LODs, separate simple oval collision proxy and carry-center metadata. UV palette sampling is intentionally overlapping, not unique painting UVs or sculpted normal/AO bakes. Hatch previews are rigid node animation with fixed bases and verified closed/open poses; they require a game adapter and are not Roblox skeletal clips. No creature rigs/locomotion, Studio import, physical-device performance or owner art acceptance is claimed. Catalog/save compatibility, sixth-family handling and actual scale remain unresolved. No current gameplay, upload or publication changed.

Production choices made under the owner's authorization: preserve all originals in place; use local procedural Blender refinement; separate smooth intact shells from jagged hatch states; use palette UVs and reduced static meshes; keep modeling dimensions illustrative. These are authoring choices, not new game balance decisions.

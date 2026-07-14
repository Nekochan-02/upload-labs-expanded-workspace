# Handoff (第2次実装工程への引き継ぎ資料)

第1次解析フェーズの完了に伴う、第2次実装工程（Modの試作・デバッグ）を担当する開発エンジニア向けの引き継ぎドキュメントです。

---

## 1. 現状のステータス要約

* **Phase 2C-F2 / v0.2.10 regression state**:
  * **Status: `FAILED_VERIFICATION_REGRESSION`**
  * `0.2.10` development artifact was tested by the user with only this Mod installed.
  * Position persistence is still `FAIL`: a node placed in the expanded area moved back to the old boundary after save, exit, restart, and load.
  * Deselection regression observed: empty-area click and the node state/options menu `x` control did not clear selected nodes.
  * Do not treat `0.2.10` as a Release Candidate. Do not create a Release, Draft Release, tag, Workshop upload, or replacement artifact from it.
  * `v0.2.9` Draft Release remains blocked and must not be published. The `v0.2.9` artifact must not be changed, replaced, or deleted.
  * The confirmed fact is that vanilla `WindowContainer._ready()` clamps restored positions through old `10000` bounds. The failed repair hypothesis is that overriding only `WindowContainer.get_position_snapped(to)` is sufficient.
  * Follow-up analysis is `docs/PHASE_2C_F2_0.2.10_REGRESSION_ANALYSIS.md`.
  * Next implementation must be based on a new approved plan, preferably a restoration-path-only diagnostic/fix rather than another global `WindowContainer` patch.
* **Phase 2C-F3 / v0.2.11 desktop restoration diagnostic**:
  * **Status: `DIAGNOSTIC_EVIDENCE_CAPTURED`**
  * F3 diagnostic plan is `docs/PHASE_2C_F3_DESKTOP_RESTORATION_DIAGNOSTIC_PLAN.md`.
  * Diagnostic report is `docs/PHASE_2C_F3_DESKTOP_RESTORATION_DIAGNOSTIC_REPORT.md`.
  * Runtime basis is `0.2.9` behavior plus Desktop restoration checkpoint logging only.
  * `WindowContainer` / `WindowBase` / `WindowIndexed` extensions are excluded and must remain excluded.
  * No position fix is implemented. The artifact only logs P2/P3/P3.5/P4 restoration evidence for up to 3 saved windows beyond the old `10000` threshold.
  * P3 immediately after `new_object.load(window_data)` is intentionally marked `UNOBSERVED` because observing it directly would require copying vanilla `Desktop._enter_tree()`.
  * User tested v0.2.11. Empty-area deselect and menu `x` deselect are both OK, confirming the v0.2.10 selection regression disappeared when `window_container.gd` was excluded.
  * F3 evidence target: `download_video0`, `window_download_video.tscn`, script `res://scenes/windows/window_download.gd`, size `(350.0, 272.0)`.
  * F3 checkpoint result: P2 saved `(19650.0, 19750.0)`, P3.5 after restore/child-entered `(19650.0, 19750.0)`, P4 deferred final `(9650.0, 9750.0)`.
  * Therefore the coordinate change occurs after P3.5 and before P4, not in save serialization and not in the immediate Desktop restoration loop.
  * Next work must still not implement a position fix without a new approved plan. The next diagnostic/fix plan should target the post-P3.5/pre-P4 lifecycle point.
* **Phase 2C-F4 / v0.2.12 restoration correction canary**:
  * **Status: `PARTIAL_FIX_RESIDUAL_POSITION_DRIFT`**
  * F4 plan is `docs/PHASE_2C_F4_RESTORATION_CORRECTION_PLAN.md`.
  * F4 report is `docs/PHASE_2C_F4_RESTORATION_CORRECTION_REPORT.md`.
  * Root cause classification is now `ROOT_CAUSE_CONFIRMED_LIFECYCLE_CLAMP`.
  * Runtime basis is `0.2.9` verified behavior plus Desktop restoration-only deferred correction and F4 low-frequency checkpoint logging.
  * `WindowContainer` / `WindowBase` / `WindowIndexed` extensions remain excluded. `get_position_snapped()` override remains forbidden.
  * Correction snapshots saved positions before `super._enter_tree()` and uses saved `window.name` to correlate to `Windows/<window.name>`. Duplicate or empty saved names disable correction with `[F4][STOP]`.
  * Correction targets only restored windows whose saved position exceeds `(Vector2.ONE * 10000) - restored_window.size`.
  * Desired position is saved position clamped to `WorkspaceAreaConfig.get_max_position(restored_window.size)` and snapped to 50.
  * Correction is one-shot deferred and uses `window.move(desired_position)`; no save schema, selection code, continuous monitor, or active gameplay movement patch is added.
  * User tested v0.2.12. Old-boundary warp was not reproduced, but exact position persistence still failed: residual drift was visible after restart.
  * F4 logs show SAVED/desired positions such as `server0 (19650.0, 19250.0)`, with BEFORE old-clamped to `(9650.0, 9250.0)`, then AFTER/STABILITY local position `(19560.07, 19059.62)`.
  * F5 analysis is `docs/PHASE_2C_F5_POSITION_DRIFT_GRID_GEOMETRY_ANALYSIS.md`.
  * F5 conclusion: F4 residual drift is caused by using `WindowContainer.move(saved_position)`, because vanilla `move(pos)` writes `global_position = pos` while save persistence writes local `position`.
  * User also observed grid density/snap mismatch. F5 classifies the grid issue as `GRID_DENSITY_SCALE_MISMATCH` with snap mismatch consequence: current `Lines` scale is `(2, 2)`, so visual 50-unit vanilla grid spacing becomes 100 while window snap remains 50.
  * v0.2.12 must not be treated as passing. Next implementation should first address exact local-position restoration, then restore vanilla-density grid coverage.
* **Phase 2C-F6 / v0.2.13 exact local restoration canary**:
  * **Status: `F6_SINGLE_NODE_EXACT_PERSISTENCE_VERIFIED`**
  * F6 plan is `docs/PHASE_2C_F6_EXACT_LOCAL_RESTORATION_PLAN.md`; implementation report is `docs/PHASE_2C_F6_EXACT_LOCAL_RESTORATION_REPORT.md`.
  * F5 confirmed that `WindowContainer.save()` persists local `position`, while F4 passed that local value to `WindowContainer.move()`, which writes `global_position`. This local/global coordinate mismatch caused F4 residual drift.
  * F6 retains the one-shot deferred Desktop restoration timing but assigns `window.position = desired_position` directly. `desired_position` is saved local position clamped only to `WorkspaceAreaConfig.get_max_position(window.size)`; it is not re-snapped.
  * F6 emits `window.moved` after assignment to retain the observed Desktop redraw/LOD update path. It does not use `move()`, `move_snapped()`, `global_position`, a WindowContainer/Base/Indexed extension, `get_position_snapped()`, or continuous correction.
  * `Nekochan-ExpandedWorkspace-0.2.13.zip` was built locally as a development canary. SHA-256: `88908fec32fce7d407cc971428c7682dfd05c57f7f6b184e38f1e5e466582933`; ZIP root `mods-unpacked`; 13 files. No release, tag, Workshop publish, public-master push, or v0.2.9 artifact operation occurred.
  * User verified empty-area deselect and menu x deselect as PASS. User also verified exact visual persistence for an individual node after save, exit, restart, and load.
  * Final F6 log evidence covers three non-group targets. For `download_manager0` `(18300.0, 18000.0)`, `download_text0` `(18700.0, 18800.0)`, and `network0` `(17850.0, 17700.0)`, `clamp_delta` is zero and both AFTER and STABILITY local positions exactly equal SAVED_LOCAL. Details are in the F6 report.
  * F6 has verified individual-node exact local persistence only. Group persistence is deliberately not a F6 PASS criterion. `GRID_DENSITY_SCALE_MISMATCH` remains isolated; grid code is unchanged. Do not start grid, group, full regression, or release integration without a new approved plan.
* **Phase 2C-F7 / v0.2.14 vanilla-density grid canary**:
  * **Status: `F7_GRID_DENSITY_VERIFIED_CLICK_ALIGNMENT_FAIL`**
  * F7 plan is `docs/PHASE_2C_F7_GRID_DENSITY_RESTORATION_PLAN.md`; canary report is `docs/PHASE_2C_F7_GRID_DENSITY_RESTORATION_REPORT.md`.
  * Root cause is `GRID_DENSITY_SCALE_MISMATCH`: the prior `(2, 2)` Lines scale rendered the vanilla 50-unit grid at a visible 100-unit interval while interaction snap stayed at 50.
  * F7 restores root Lines scale to `(1, 1)` and creates three fresh runtime renderer tiles at `(10000, 0)`, `(0, 10000)`, and `(10000, 10000)`. Together with the root tile, coverage is `20000 x 20000` with vanilla origin and 50-unit geometry. It does not copy vanilla renderer bodies, scenes, resources, or live RenderingServer RID state.
  * The instance count is a known 4x area multiplier. Expected counts range from 1600 Lines instances to 248704 Hexagon instances depending on the selected vanilla Lines type. No performance PASS is claimed.
  * F6 Desktop restoration source is unchanged from its verification commit. Placement/movement/connector snap, selection, group movement, save schema, node limit, space cap, camera, and background paths are unchanged.
  * `Nekochan-ExpandedWorkspace-0.2.14.zip` is a local development canary: SHA-256 `74043d10b5d455850be47ac0f3f7b6302f3764ec28d9ca6b4390f840256b7d49`, 12043 bytes, 13 files, ZIP root `mods-unpacked`. No release, tag, Workshop publication, public-master push, or v0.2.9 artifact operation occurred.
  * Runtime evidence confirms expected Lines geometry: `workspace_size=(20000,20000)`, `renderer_scale=(1,1)`, `lines_minor=50_major=500`, origin `(0,0)`, coverage `(20000,20000)`, four tiles, and 1600 total Lines instances for tested `lines_type=0`.
  * User verified old-area density, expanded-area density, and the old/new boundary as PASS. Drag placement and existing-node movement align to the visual grid; F6 single-node persistence also remains PASS.
  * Click placement alignment is FAIL: a clicked node initially does not align to a grid line, but aligns when moved. This is a remaining click-placement workflow alignment defect, not evidence to change snap intervals or F7 renderer geometry. Do not implement a correction without a dedicated approved diagnostic plan.
  * Startup is slightly heavier, while camera movement/zoom and grid display switching are PASS. Performance is acceptable for the tested Lines type only; higher-density renderer modes remain untested.
  * Do not proceed to group persistence, full regression, or release integration. The single next action is a dedicated click-placement alignment diagnostic plan.
* **Phase 2C-F8 / v0.2.15 click-placement coordinate diagnostic**:
  * **Status: `DIAGNOSTIC_EVIDENCE_CAPTURED`**
  * F8 plan: `docs/PHASE_2C_F8_CLICK_PLACEMENT_COORDINATE_DIAGNOSTIC_PLAN.md`; report: `docs/PHASE_2C_F8_CLICK_PLACEMENT_COORDINATE_DIAGNOSTIC_REPORT.md`.
  * User result: initial click-placement grid alignment FAIL; the same node after one manual movement PASS. Save/restart/load was not tested in F8.
  * F8 observed `download_text`: C3 target `(15400,18050)` is `TARGET_SNAP_CORRECT`; C8/C9 global position equals that target exactly. C5 global/local delta is approximately the window half-size, while the Windows parent transform origin is `(0,0)`.
  * Classification: `VISUAL_ORIGIN_MISMATCH`. The new window's vanilla opening pivot/scale lifecycle leaves a non-grid local layout coordinate while the visual transform is active; this is distinct from F6 saved-local-as-global persistence drift. The deferred `move()` corrects C7 global y by `10.5` to the target and does not create a subsequent global drift.
  * One unimplemented candidate for a separately approved canary: replace the click path's deferred global `move(target)` with a deferred local `position = target; moved.emit()` correction, using the F6-local-domain principle. Do not implement from F8 evidence alone because the settled opening-animation frame was not logged.
  * It preserves the F7 click target calculation and assignments exactly. F7 Lines, F6 Desktop restoration, drag placement, existing movement, 50-unit snap behavior, save schema, node limit, space cap, camera, and background paths are unchanged.
  * `Nekochan-ExpandedWorkspace-0.2.15.zip` is a local development diagnostic artifact: SHA-256 `4677776d803b53a13512f49434c691c2ec6dbc2e4790b1f6d9349903ea3eabe7`, 13113 bytes, 13 files, ZIP root `mods-unpacked`.
  * The user must test one expanded-area click-created node, manually move it once, then provide the visual results and `[F8]` logs. Do not implement a click correction, alter F7/F6, start group persistence/full regression/release integration, publish, tag, push public master, or operate on v0.2.9 until that evidence is analyzed.
* **Phase 2C-F9 / v0.2.16 click local-alignment canary**:
  * **Status: `F9_CLICK_ALIGNMENT_VERIFIED_DRAG_ALIGNMENT_REGRESSION_OBSERVED`**
  * F9 plan: `docs/PHASE_2C_F9_CLICK_LOCAL_ALIGNMENT_PLAN.md`; report: `docs/PHASE_2C_F9_CLICK_LOCAL_ALIGNMENT_REPORT.md`.
  * F9 preserves F8 target calculation and every initial/post-create global assignment. At the existing final deferred correction point only, it replaces global `move(target)` with `window.position = target; window.moved.emit()`.
  * One click-created window logs `F9_TARGET`, before/after local correction, next-deferred stability, and one 0.5-second opening-settle checkpoint. There is no `_process`, timer loop, or continuous correction.
  * F6 Desktop restoration, F7 Lines/grid, drag placement, existing-node movement, snap interval, save schema, node limit, space cap, camera/background, group behavior, and blocked Window script extensions are unchanged.
  * `Nekochan-ExpandedWorkspace-0.2.16.zip` is a local development canary: SHA-256 `24abbe45d5f407a3d3deed612a646621f015d8cad8d6709818a5a591fe5e0b4b`, 13004 bytes, 13 files, ZIP root `mods-unpacked`.
  * Runtime evidence for `download_sound0`: target `(10350,13350)` is `TARGET_SNAP_CORRECT`; AFTER, next-deferred, and opening-settle local positions all exactly equal the target. The opening-settle global position also equals the target.
  * User verified click alignment PASS immediately, after the opening tween, and after one manual movement. This verifies the F9 click local-domain correction.
  * User separately observed drag placement visually misaligned. Drag source has no F9 code diff, but its user-visible preservation gate is FAIL. Do not modify drag speculatively, proceed to group/full regression/release integration, publish, tag, push public master, or operate on v0.2.9. The single next action is a dedicated drag-placement coordinate-domain diagnostic plan.
* **Phase 2A 検証状態**:
  * **Status: `LIMIT_RELAXATION_COMPLETE_USER_VERIFIED`**
  * Phase 2A-R2で、通常の手動配置は500個を超えて配置できることをユーザー実機で確認済み。
  * Phase 2A-R3で、テンプレート/スキーマ配置とノード数表示を1000上限へ揃える候補を実装済み。
  * R3の3項目（通常配置、テンプレート/スキーマ配置、ノード数表示）はユーザー実機で動作確認済み。
  * Phase 2A-R4で、`space` アップグレード上限を100から200へ拡張する最小パッチを実装済み。ユーザー実機で想定通り動作することを確認済み。
  * 現在の「上限数の緩和」目標は完了扱い。
  * ただし、配置領域拡張、巨大セーブ、性能、設定UIは未完了。
  * したがって「拡張ワークスペース上限が完成」とは扱わない。
* **開発環境の整備**:
  * 専用ワークスペース (`upload-labs-expanded-workspace/`) を構築。
  * バニラゲーム本体のコードは `vanilla-reference/` ディレクトリに GDScript 2.0 形式で完全に復元済み。
  * `.gitignore` によりバニラコードや生成ログが絶対にGit管理下に混入しない隔離環境を確立。
* **解析の進捗**:
  * ノード総数上限（`MAX_WINDOW = 500`）および配置可能領域（ハードコードされた `10000` サイズの境界）の主要制御コード経路を特定。
  * 旧Phase 2Aの失敗を受け、全体500上限は `Utils.can_add_window()` ではなく、`scripts/windows_tab.gd`、`scenes/window_dragger.gd`、`scripts/desktop.gd` などの各配置経路に分散していることを再確認。
  * R1のMod Hook方式はログ上でhook packが生成されず失敗したため、R2では最小Script Extension方式へ切り替えた。
  * 配置領域拡張の再調査結果は `docs/PHASE_2B_AREA_EXPANSION_ANALYSIS.md` を参照。
  * Phase 2B-R1の実装計画は `docs/PHASE_2B_R1_IMPLEMENTATION_PLAN.md` を参照。
  * Phase 2B-R1 `0.2.0` は、カメラ移動とズーム時グリッド拡張は確認済み。ただしノード移動/クリック配置とズームアウト時の見た目は失敗。
  * Phase 2B-R2 `0.2.1` は、ノード配置不可、選択不可、既存ノード左上集約、接続解除、レベル/コスト破壊を起こしたため重大失敗としてロールバック済み。
  * 次の配置領域拡張は `docs/PHASE_2B_R3_SAFE_REDESIGN_PLAN.md` の段階的canary方式から再開する。
  * 現在ゲーム側に配置済みの安全版は `0.1.4`。
  * ロールバック後、ユーザーはノード配置が再び可能になったことを確認済み。
  * 影響を受けた既存セーブのノードは消失したが、ユーザーは復旧不要と明言済み。
  * 2026-07-12にStage 0安全確認を開始。live modsフォルダは `0.1.4` のみ、save/configバックアップは `C:\tmp\upload-labs-save-backups\20260712-102632`。
  * Stage 1静的レビューの結果、最初のcanaryは `scripts/main_2d.gd`、`scripts/lines.gd`、`scripts/paint.gd` のCamera/Visuals Onlyに決定。
  * ユーザー判断により、ゲーム起動時に読み込まれる現在セーブをテスト対象とする。ユーザー側ではセーブデータをローカル保持できないとのこと。
  * `0.2.2` Camera/Visuals Only canaryを作成し、live modsフォルダへ配置済み。liveには `Nekochan-ExpandedWorkspace-0.2.2.zip` のみ。
  * `0.1.4` zipは `C:\tmp\upload-labs-mod-backups\Nekochan-ExpandedWorkspace-0.1.4.zip` に退避済み。
  * `0.2.2` ユーザー実機結果: ノードには問題なし。ただしカメラ移動範囲とグリッド/背景の見た目はデフォルト仕様のままに見える。
  * 原因: 初回 `0.2.2` zipのrootが `Nekochan-ExpandedWorkspace/...` になっており、Mod Loader期待の `mods-unpacked/Nekochan-ExpandedWorkspace/...` ではなかったため、Modが読み込まれていなかった。
  * 修正版 `0.2.2` zipを正しい構造で再作成し、live modsフォルダへ再配置済み。壊れたzipは `C:\tmp\upload-labs-mod-backups\Nekochan-ExpandedWorkspace-0.2.2-bad-zip-20260712-111241.zip` に退避済み。
  * 修正版 `0.2.2` 再テスト結果: カメラ移動、グリッド/背景ともデフォルトのままに見える。ログ再確認が必要。
  * ログ再確認結果: 修正版zip自体は読み込まれていたが、`mod_user_profiles.json` で `Nekochan-ExpandedWorkspace` が `is_active: false` になっており、`mod_main.gd` が初期化されていなかった。
  * `mod_user_profiles.json` をバックアップ後に修復し、`Nekochan-ExpandedWorkspace` を `is_active: true` に変更。空ID `""` の壊れたエントリも削除済み。
  * プロファイル修復後のユーザー実機結果: 十分にズームインすると拡張エリアのグリッドが見えるが、ズームアウトすると旧エリアだけが描画される。
  * この結果から、`lines.gd` 自体は一部効いているが、親Control/Background/CanvasItem側の表示範囲またはクリップが残っている可能性が高い。
  * ログで `0.2.2`、`main_2d.gd`、`lines.gd`、`paint.gd` の適用を確認済み。
  * `Main.tscn`上で `Desktop/Background` が `10000 x 10000` 固定だったため、`0.2.3` ではCamera/Visuals Only範囲で `Desktop`、`Desktop/Background`、`Desktop/Lines` の表示サイズのみを20000へ拡張。`Connectors`、`Windows`、ノードscene rootは触っていない。
  * live modsフォルダは `Nekochan-ExpandedWorkspace-0.2.3.zip` のみ。Mod Loaderプロファイルも `0.2.3` を指すよう更新済み。
  * `0.2.3` ユーザー実機結果: カメラ移動とズームアウト時のグリッド/背景がどちらも成功。
  * Phase 2B-R3 status: `STAGE_2_CAMERA_VISUALS_VERIFIED`。
  * まだ新エリアへのノード配置・移動は検証/実装対象外。

---

## 2. 次工程への具体的な推奨パッチポイント

### 2.1 ノード上限の緩和パッチ
Phase 2A-R3の対象は、通常の手動配置経路、テンプレート/スキーマ配置経路、表示上限である。

* **対象ファイル**: `scripts/windows_tab.gd`
* **対象ファイル**: `scenes/window_dragger.gd`
* **対象ファイル**: `scripts/desktop.gd`
* **対象ファイル**: `scripts/schematics_tab.gd`
* **方式**: Godot Mod Loader v7.0.1 の最小Script Extension。
* **Mod側ファイル**:
  * `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/windows_tab.gd`
  * `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/window_dragger.gd`
  * `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/desktop.gd`
  * `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/schematics_tab.gd`
* **修正方針**: 500以上かつ拡張上限未満の間だけ、バニラ処理に渡す直前の総数を一時的にバニラ上限未満へ調整し、処理後に増分を反映して戻す。
* **未対応**: 配置領域拡張、巨大セーブ検証、性能検証。

### 2.1.1 `space` アップグレード上限の拡張パッチ
Phase 2A-R4では、種類別配置可能数に関わる `space` アップグレードの上限を100から200へ拡張する。

* **対象データ**: `Data.upgrades["space"].limit`
* **方式**: バニラJSONを同梱せず、Mod読み込み時にランタイムデータだけを上書きする。
* **Mod側ファイル**:
  * `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/boot.gd`
  * `mod/source/mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/space_upgrade_limit_patch.gd`
* **修正方針**: 既存の `cost`、`cost_e`、`inc_type`、`cost_inc`、効果量は変更せず、上限だけを200にする。
* **検証状態**: UI上の200表示、100超え購入、コスト進行はユーザー実機で想定通り動作確認済み。
* **未検証**: 100超え状態の長期セーブ/ロード、Mod無効化時のクランプ挙動。

### 2.2 配置領域の拡張パッチ
キャンバスサイズとして、`10000` がハードコードされている部分を、拡張サイズ（例: `20000`）に一括置換または変数参照に変更します。
1. **`main_2d.gd` (L6)**: `screen_size[0] = 20000` に上書きしてカメラ制限の限界を拡張。
2. **`windows/window_container.gd` (L156)**: `get_position_snapped` 内の `to.clamp(Vector2.ZERO, (Vector2.ONE * 20000) - size)` でウィンドウドラッグ時のクランプ範囲を広げる。
3. **`connector_point.gd` (L27)**: `pos = to.clampf(0, 20000)` に上書き。
4. **`desktop.gd` (L195)**: `paste` のクランプ範囲を `20000` に拡張する候補。ただしR1では本文コピー回避のため未対応。
5. **`lines.gd`**: R1ではバニラ描画結果を2倍スケールして20000範囲を覆う。将来的に必要なら密度維持の再生成方式を検討する。

---

## 3. 最優先で実行すべきネクストアクション

1. **Phase 2A / limit relaxation current state**:
   * R3により、手動配置、paste/schematic展開、UI上の総数表示が同じ拡張上限へ揃ったことをユーザー実機で確認済み。
   * R4により、`space` 上限200表示と100超え購入挙動もユーザー実機で想定通り確認済み。
2. **Phase 2B area expansion restart planning**:
   * `0.2.0` / `0.2.1` は再使用禁止。
   * 次に進む場合は、`docs/PHASE_2B_R3_SAFE_REDESIGN_PLAN.md` を確認し、ユーザー承認後にStage 0から進める。
   * `window_base.gd` / `window_indexed.gd` 直接拡張は禁止。
   * 次の検証は必ず使い捨てテストセーブで行う。今回消失したノードの復旧作業は不要。
   * ユーザー判断により現在起動セーブをテスト対象にするため、最初の `0.2.x` canaryはCamera/Visuals Onlyに限定する。
   * Stage 3計画を作成済み。次の候補は `0.2.4-click-placement-canary`。
   * Stage 3では `scripts/windows_tab.gd` のクリック配置入口だけを対象にする。`window_container.gd`、`window_base.gd`、`window_indexed.gd` は触らない。
   * 新規ノード生成直後にバニラ `window_container.gd::_ready()` が旧範囲へクランプするため、クリック配置で作った新規インスタンスだけを初期化後に目的座標へ戻す方針。
   * ユーザー承認後、`0.2.4-click-placement-canary` を実装・配置済み。
   * live modsフォルダは `Nekochan-ExpandedWorkspace-0.2.4.zip` のみ。Mod Loader profileも `0.2.4` を指す。
   * `0.2.4` では `windows_tab.gd::add_window(window)` だけを拡張し、クリック配置で新規作成されたインスタンスだけを初期化後に拡張エリア座標へ戻す。
   * `0.2.4` でも `window_container.gd`、`window_base.gd`、`window_indexed.gd`、`connector_point.gd` はパッケージしていない。
  * `0.2.4` ユーザー実機結果: 新エリアへのクリック配置は動作。配置位置が少し左上にずれるが大きな問題ではない。他の問題は報告なし。
  * Phase 2B-R3 status: `STAGE_3_CLICK_PLACEMENT_VERIFIED_WITH_MINOR_OFFSET`。
  * Stage 3C計画はユーザーの「進めてください」により承認済み。
  * `0.2.5-drag-placement-canary` を実装・live配置済み。対象は `scenes/window_dragger.gd` のみ。
  * live modsフォルダは `Nekochan-ExpandedWorkspace-0.2.5.zip` のみ。Mod Loader profileも `0.2.5` を指す。
  * `0.2.5` 配置前バックアップは `C:\tmp\upload-labs-save-backups\20260712-123849` と `C:\tmp\upload-labs-mod-backups\Nekochan-ExpandedWorkspace-0.2.4-before-0.2.5-20260712-123849.zip`。
  * `0.2.5` では、ドラッグ配置で新規作成されたインスタンスだけを初期化後に拡張エリア座標へ戻す。
  * `0.2.5` ユーザー実機結果: ドラッグ配置で新エリア側に配置できることを確認済み。
  * 既存ノード移動、テンプレート配置、接続点、base/indexed/window-container系はまだ触っていない。
  * Phase 2B-R3 status: `STAGE_3C_DRAG_PLACEMENT_VERIFIED`。
  * 次の計画は `0.2.6-existing-node-movement-canary`。対象は `scenes/windows/window_container.gd` の `get_position_snapped(to)` のみ。
  * `0.2.6` では、既存ノード単体移動と複数選択移動が新エリアへ入れるかだけを検証する。
  * `window_base.gd` / `window_indexed.gd` / `window_group.gd` / `connector_point.gd` / paste境界は引き続き対象外。
  * `0.2.6` 計画はユーザー承認済み。
  * `0.2.6` 実装済み。`mod_main.gd` に `extensions/scenes/windows/window_container.gd` の登録を追加した。
  * `0.2.6` live配置済み。live modsフォルダは `Nekochan-ExpandedWorkspace-0.2.6.zip` のみ。Mod Loader profileも `0.2.6` を指す。
  * `0.2.6` 配置前バックアップは `C:\tmp\upload-labs-save-backups\20260712-152221` と `C:\tmp\upload-labs-mod-backups\Nekochan-ExpandedWorkspace-0.2.5-before-0.2.6-20260712-152221.zip`。
  * Mod Loaderログ場所は `C:\Users\shian\AppData\Roaming\Upload Labs\logs\modloader.log`。
  * ログで `ExpandedWorkspace v0.2.6` の読み込みと `extensions/scenes/windows/window_container.gd` Script Extensionのインストールを確認済み。
  * `0.2.6` ユーザー実機結果: 既存ノードの選択・接続・レベル・コストは壊れていない。
  * `0.2.6` ユーザー実機結果: 既存ノード単体移動と複数選択移動はどちらも新エリアへ入れず、見えない旧境界で止まる。
  * `0.2.6` ユーザー実機結果: クリック配置とドラッグ新規配置は引き続きOK。
  * したがって `0.2.6` は状態破壊なしの機能失敗。`window_container.gd` extensionは読み込まれたが、実際の既存ノード移動クランプには効かなかった。
  * Phase 2B-R3 status: `STAGE_4A_FUNCTIONAL_FAILURE_STATE_SAFE`。
  * 次に検討する場合も `window_base.gd` / `window_indexed.gd` 直接拡張は禁止のまま。
  * Stage 4B計画を作成済み。次候補は `0.2.7-desktop-selection-drag-canary`。
  * Stage 4Bでは `scripts/desktop.gd` だけを対象にし、`Signals.begin_drag` / `Signals.drag_selection` を監視して、バニラ移動後に選択中ノードだけを拡張範囲へ補正移動する。
  * Stage 4Bでも `window_base.gd` / `window_indexed.gd` / `window_group.gd` / `connector_point.gd` / paste境界は対象外。
  * `0.2.7` 計画はユーザー承認済み。
  * `0.2.7` 実装済み。`extensions/scripts/desktop.gd` にDesktopレベルの選択ドラッグ補正を追加した。
  * `0.2.7` では失敗した `0.2.6` の `window_container.gd` 登録を外す。
  * `0.2.7` live配置済み。live modsフォルダは `Nekochan-ExpandedWorkspace-0.2.7.zip` のみ。Mod Loader profileも `0.2.7` を指す。
  * `0.2.7` 配置前バックアップは `C:\tmp\upload-labs-save-backups\20260712-160901` と `C:\tmp\upload-labs-mod-backups\Nekochan-ExpandedWorkspace-0.2.6-before-0.2.7-20260712-160901.zip`。
  * `0.2.7` zipには `window_container.gd` / `window_base.gd` / `window_indexed.gd` を含めていない。
  * `0.2.7` ユーザー実機結果: 概ねOK。
  * `0.2.7` ユーザー実機結果: 新たな問題として、ノード群をグループ管理できるノードが旧エリア境界から出られない。
  * `window_group.gd` は独自の `MAX_BOUNDS = Vector2(10000, 10000)` と `_process(delta)` の移動処理を持つため、Desktopレベルの通常ノード補正では対象外だったと判断。
  * Phase 2B-R3 status: `STAGE_4B_PARTIAL_VERIFIED_GROUP_MOVEMENT_BLOCKED`。
  * Stage 4C計画を作成済み。次候補は `0.2.8-group-window-movement-canary`。
  * Stage 4Cでは `scenes/windows/window_group.gd` だけを対象にし、グループ管理ノードの移動だけを拡張範囲へ補正する。
  * Stage 4Cでも `window_base.gd` / `window_indexed.gd` / `window_container.gd` / `connector_point.gd` / paste境界 / group resize は対象外。
  * `0.2.8` 計画はユーザー承認済み。
  * `0.2.8` 実装済み。`extensions/scenes/windows/window_group.gd` を追加し、グループ管理ノードの移動中だけ拡張範囲へ補正する。
  * `0.2.8` live配置済み。live modsフォルダは `Nekochan-ExpandedWorkspace-0.2.8.zip` のみ。Mod Loader profileも `0.2.8` を指す。
  * `0.2.8` 配置前バックアップは `C:\tmp\upload-labs-save-backups\20260712-161808` と `C:\tmp\upload-labs-mod-backups\Nekochan-ExpandedWorkspace-0.2.7-before-0.2.8-20260712-161808.zip`。
  * `0.2.8` zipには `window_container.gd` / `window_base.gd` / `window_indexed.gd` を含めていない。
  * `0.2.8` ユーザー実機結果: グループを選択して旧境界を超えるように右下へ移動すると、中身のノードだけ境界を超えられる。
  * `0.2.8` ユーザー実機結果: その他の問題は報告なし。
  * 原因推定: `0.2.7` Desktop補正が `window_group.gd` を明示的に除外しているため、グループ選択に含まれる通常ノードだけが補正され、グループ枠は対象外になっている。
  * Phase 2B-R3 status: `STAGE_4C_PARTIAL_FAILURE_GROUP_SELECTION_DESYNC`。
  * Stage 4D計画を作成済み。次候補は `0.2.9-group-selection-sync-canary`。
  * Stage 4Dでは `scripts/desktop.gd` のグループ除外を外し、選択中のグループ枠も通常ノードと同じDesktop補正に乗せる。
  * Stage 4Dでも `window_base.gd` / `window_indexed.gd` / `window_container.gd` / `connector_point.gd` / paste境界 / group resize は対象外。
  * `0.2.9` 計画はユーザー承認済み。
  * `0.2.9` 実装済み。`extensions/scripts/desktop.gd` のグループ除外を削除した。
  * `0.2.9` live配置済み。live modsフォルダは `Nekochan-ExpandedWorkspace-0.2.9.zip` のみ。Mod Loader profileも `0.2.9` を指す。
  * `0.2.9` 配置前バックアップは `C:\tmp\upload-labs-save-backups\20260712-162640` と `C:\tmp\upload-labs-mod-backups\Nekochan-ExpandedWorkspace-0.2.8-before-0.2.9-20260712-162640.zip`。
  * `0.2.9` zipには `window_container.gd` / `window_base.gd` / `window_indexed.gd` / `vanilla-reference` / `.exe` / `.pck` / game assets / recovered vanilla source / save files / obvious secret-name entries を含めていない。
  * `0.2.9` ユーザー実機結果: 成功。グループ枠と中身ノードが一緒に旧境界を越えて移動でき、通常ノード移動・クリック配置・ドラッグ新規配置も壊れていない。
  * Phase 2B-R3 status: `STAGE_4D_GROUP_SELECTION_MOVEMENT_VERIFIED`。
  * 基本的な配置領域拡張操作は、カメラ移動、ズームアウト時グリッド/背景、クリック配置、ドラッグ新規配置、既存ノード移動、グループ選択移動までユーザー実機で確認済み。
  * Phase 2Cでは新機能を追加せず、ユーザー実機で確認済みの `0.2.9` をRelease Candidateとして固定する。
  * `tools/build_release.ps1 -Version 0.2.9` により、公開repository sourceから `dist/Nekochan-ExpandedWorkspace-0.2.9.zip` を再生成できる。
  * 生成済みRC artifact: SHA-256 `fc8ddab1a3f73c468eb5a1fbb2702a683629c703d67498c983ad0e52f8a038af`, size `9770 bytes`, file count `13`, ZIP root `mods-unpacked/`。
  * RC ZIP安全監査では、vanilla-reference、game binary、`.pck`、scene/resource実ファイル、save、secret、third-party Mod code、generated hook packの混入は検出0。
  * Phase 2C-F1 clean install verificationでrelease blockerを確認。拡張領域へ配置した単体ノードおよびグループ配置/移動ノードが、save・終了・再起動・load後に旧領域と新領域の境界付近へ移動する。
  * 現在のrelease decisionは `BLOCKED_POSITION_PERSISTENCE`。v0.2.9 Draft Releaseをpublishしてはならない。v0.2.9 RC artifactはfailed RC evidenceとして保持する。
  * root causeは `docs/PHASE_2C_F1_POSITION_PERSISTENCE_ROOT_CAUSE.md` を参照。保存側では `position` を直接保存し、load時にraw positionを代入した後、`scenes/windows/window_container.gd::_ready()` が旧 `10000` boundsで共通clampする可能性が高い。
  * 修正する場合は `docs/PHASE_2C_F1_IMPLEMENTATION_PLAN.md` に従う。v0.2.9を再利用せず、`0.2.10` development buildで検証する。
  * `0.2.10` development artifactを作成済み。`extensions/scenes/windows/window_container.gd` で `get_position_snapped(to)` のみを拡張boundsへ差し替える。artifactは `dist/Nekochan-ExpandedWorkspace-0.2.10.zip`、SHA-256 `ded8cd9f17ef30c088b7a8bb33272e2aae187c61830b409fdaf07c73d64f4e4f`。ユーザー実機検証は未実施。
3. **パフォーマンスフットプリントの計測**:
   * グリッドを `MultiMesh` で描画する際、インスタンス数が16万個に増えたとき（2倍サイズ）の起動時プチフリーズの有無を確認する。

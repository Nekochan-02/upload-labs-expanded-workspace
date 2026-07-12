# Patch Strategy (パッチ方式の評価と設計)

Upload Labs向けMod「Expanded Workspace」を実装するための設計、パッチアーキテクチャ、および検証・ロールバック戦略の計画です。

---

## 1. Mod コンセプト

* **Mod名称 (仮称)**: `Expanded Workspace`
* **動作形態**: `Godot Mod Loader` 準拠のパッケージ形式。ゲーム本体ファイルを直接変更せず、起動時に動的にパッチを適用する。
* **主要機能**:
  1. **配置ノード制限の緩和**: 最大配置数（バニラ: 500）を、Mod設定ファイル（JSON）または設定画面から「Vanilla (500) / 2x (1000) / 5x (2500) / Custom」に動的に変更可能にする。
  2. **キャンバス領域の拡張**: 配置可能範囲（バニラ: 10000）を「Vanilla (10000) / 2x (20000) / 4x (40000)」に拡張。カメラ移動範囲、グリッド描画、座標クランプ処理を連動させて追従させる。

---

## 2. Phase 2A-R2 / R3 / R4 パッチアーキテクチャ

旧Phase 2AのScript Extension方式は、バニラ関数本文を実質的に複製していたため不採用とします。

Phase 2A-R1では `install_script_hooks()` を試したが、実ログ上でhook packが生成されなかったため不採用とする。

Phase 2A-R2では最小Script Extension方式へ切り替えた。Mod側にはバニラ関数本文を複製せず、500以上のときだけ総数カウントを一時調整してバニラ処理へ委譲する小さなwrapperを置く。

現在の状態:
* 手動配置の501個超えはR2で確認済み。
* テンプレート/スキーマ配置とUI表示はR3で確認済み。
* `space` アップグレード上限100から200への拡張はR4で確認済み。
* 現在の上限数緩和目標は `LIMIT_RELAXATION_COMPLETE_USER_VERIFIED` として扱う。

### 2.1 Phase 2A-R2 対象

| 元スクリプトファイル | 拡張方法 | 変更内容 |
| :--- | :--- | :--- |
| `scripts/windows_tab.gd` | Minimal Script Extension | 手動クリック追加時、500以上かつ拡張上限未満の間だけ一時的に総数カウントをバニラ上限未満へ調整してからバニラ処理へ委譲する。 |
| `scenes/window_dragger.gd` | Minimal Script Extension | ドラッグ配置時、同じ一時カウント調整でバニラ処理へ委譲する。 |

R2で触らないもの:
* `scripts/desktop.gd` のpaste/schematic展開。
* `scripts/schematics_tab.gd` の必要数表示。
* workspace bounds、camera、grid、save schema、設定UI。

### 2.2 Phase 2A-R3 対象候補

| 元スクリプトファイル | 目的 | 注意 |
| :--- | :--- | :--- |
| `scripts/desktop.gd` | `paste(data)` 経路のテンプレート/スキーマ配置制限を拡張上限へ揃える。 | バニラ関数本文コピーは禁止。既存paste処理へ委譲できる最小wrapperを優先する。 |
| `scripts/schematics_tab.gd` | テンプレート/スキーマUIの必要数表示と配置可否表示を拡張上限へ揃える。 | 表示だけを変えて実配置が失敗する状態を避ける。 |
| `scripts/windows_tab.gd` | ノードパレットの総数表示を `500` から拡張上限へ揃える。 | 表示と実上限の不一致をなくす。 |

### 2.3 旧候補の棄却

| 方式 | 判定 | 理由 |
| :--- | :--- | :--- |
| バニラ関数本文を丸ごと含むScript Extension | Reject | publish-unsafe。履歴内commit `55d75f42f3f5853d676fd2efaaa97823e7990b63` の旧実装が該当。 |
| `Utils.MAX_WINDOW` 定数自体の変更 | Reject for R1 | `const`の直接変更に固執すると、複数経路の実行時判定を見落とす。 |
| `scripts/utils.gd::can_add_window()`のみのhook | Reject for R1 | この関数は種別上限と属性条件を扱い、全体500上限の直接判定ではない。 |
| `scripts/windows_tab.gd` hook | Selected candidate | 実測された501個目拒否を説明できるクリック追加経路を、バニラ本文コピーなしで最小限に扱える。 |
| Mod Hook方式 | Reject for current build | ログ上でhook登録はされたが、`No new hooks were created` となり実処理へ差し込まれなかった。 |

### 2.4 将来の拡張候補

次の主対象はPhase 2Bの配置領域拡張である。初回ターゲットはバニラ2倍の20000領域とする。

ただし、Phase 2B-R1 `0.2.0` は部分失敗、Phase 2B-R2 `0.2.1` は重大失敗としてロールバック済みである。今後は `docs/PHASE_2B_R3_SAFE_REDESIGN_PLAN.md` の段階的canary方式から再開する。

Hard rules:
* `0.2.0` / `0.2.1` を再使用・再パッケージしない。
* `scenes/windows/window_base.gd` / `scenes/windows/window_indexed.gd` を直接Script Extensionしない。
* 使い捨てテストセーブでのみ検証する。
* 各経路は独立して検証し、バニラ本文コピーを禁止する。

---

## 3. テスト計画 (Test Strategy)

Modの安全性と整合性を保証するため、以下のテストマトリクスを実行します。

### 3.1 起動および整合性テスト
* **Modなし起動**: バニラ状態で通常通りゲームが動作し、制限（500ノード、10000境界）が正常に効いていることを確認。
* **Modあり起動**: Mod適用状態で、エラーログ（`modloader.log`）なしにUIが起動することを確認。

### 3.2 ノード上限の検証
* R2では通常の手動配置で500個超えを確認済み。
* R3ではテンプレート/スキーマ配置で500個超えを確認済み。
* UI表示が拡張上限を示すことを確認済み。
* R4では `space` アップグレード上限200を確認済み。

### 3.3 境界拡張の検証
Phase 2B-R3では、以下を一度に実装・検証しない。Stageごとのcanaryとして分離する。

* Stage 0: stable `0.1.4` baseline, live mods folder, save backup, disposable save.
* Stage 1: static route review.
* Stage 2: camera and visuals only.
* Stage 3: one placement entry only.
* Stage 4: movement bounds research gate.

Full success criteria remain:

* カメラを `10000` 以上の領域までスクロールさせ、問題なく移動できることを確認。
* `15000` などの拡張領域へノードをドラッグして配置・移動・クランプができることを確認。
* 拡張した全領域でグリッド線、ドット、星空などの背景レンダリングが途切れずに描画されることを確認。
* 拡張領域内のノード同士が正しく接続線で結ばれ、データや流体が転送されるかシミュレーションテストを実行。

### 3.4 セーブ＆ロード検証
* 拡張領域にノードを多数配置し、500ノードを超えた状態でセーブを実行。
* ゲームを再起動し、該当のセーブスロットからデータをロードした際に、ノードの位置がズレたりクランプされたりせずに正しく復元されることを確認。

---

## 4. ロールバック戦略 (Rollback Strategy)

ユーザーがModを途中で無効化（アンインストール）した場合、バニラの制限領域（10000外）に配置されたノードはロード時に強制的に `10000` の境界内にクランプされてしまい、ノードが1箇所に密集して重なるという破壊的現象（コリジョン・重なり問題）が発生します。

### 4.1 対策設計
* **セーブ保護警告**: Mod適用状態でセーブデータを作成する際、メタデータまたはセーブ名にMod適用済みのフラグを付加する。
* **ロード時警告**: Modが無効化された状態で「拡張領域にノードがあるセーブ」をロードしようとした場合、ロードを中止するか、あるいは警告ダイアログを表示して安全な別スロットへの保存を促す機構の導入を検討する。

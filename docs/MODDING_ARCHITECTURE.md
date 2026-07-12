# Modding Architecture (Modアーキテクチャ調査)

Upload LabsにおけるMod導入の仕組み、動作モデル、および利用可能なインターフェースについての調査報告です。

---

## 1. Mod Loader の基本仕様

ゲーム本体には Godot Mod Loader (v7.x 互換) が内包されています。ゲーム起動時に `mods-unpacked/` または Steam Workshop の配信フォルダからModを検出し、自動的にロードします。

### 1.1 命名規則と名前空間
* **Namespace (名前空間)**: 各Modは一意の `namespace` (例: `asouy`) と `name` (例: `ModManager`) を持ちます。
* **Mod ID**: `namespace-name` (例: `asouy-ModManager`) が実質的な識別IDとなります。
* **フォルダ構造**: `mods-unpacked/namespace-name/` ディレクトリ内にMod資材を格納します。

### 1.2 manifest.json の仕様
各Modのルートに配置する `manifest.json` は、Mod名、namespace、version、website URL、description、dependencies、Godot互換情報、config schemaを持ちます。公開候補では、ゲーム本体や抽出assetへの参照をmanifestに含めない。

---

## 2. Modライフサイクルとエントリーポイント

* **エントリーポイント**: 各Modのルートフォルダ直下にある `mod_main.gd` (Node型を継承)。
* **初期化フェーズ**:
  1. `mod_main.gd` インスタンスがゲームのメインツリーにノードとして登録され、`_init()` が呼び出されます。この段階でScript ExtensionまたはMod Hookの登録を行います。
  2. シーンツリーへの追加後、`_ready()` が実行され、ゲーム本体のシグナル接続やUIフックなどの処理を開始します。

---

## 3. Modパッチ方法の評価

Godot Mod Loaderが提供する以下のパッチ方法について検証しました。

### 3.1 Script Extension (スクリプト拡張)
* **概要**: 元のスクリプトを継承した拡張スクリプトを作成し、特定のメソッドのみオーバーライドして挙動を書き換える手法。
* **API**: `ModLoaderMod.install_script_extension("res://mods-unpacked/namespace-name/extensions/path/to/target.gd")`
* **機能**: 元の処理を呼び出したい場合は `super()` を呼び出すことで、差分のみを上書き可能。
* **信頼度**: **Medium**。APIとしては利用可能だが、対象関数の小さな差分だけを安全に表現できない場合、バニラ関数本文コピーに陥りやすい。Phase 2A-R1では不採用。

### 3.2 Mod Hooks
* **概要**: Mod側hook scriptを登録し、Mod Loaderが対象メソッドのhook chainを構築する手法。
* **API**: `ModLoaderMod.install_script_hooks(vanilla_script_path, hook_script_path)`
* **機能**: hook関数内で次の処理へ委譲するか、Mod側処理で置き換えるかを選べる。
* **重要な制約**: exported gameではhook pack生成と次回起動時の読み込みが関係するため、ログで生成/読み込みを確認する必要がある。生成済みhook packはバニラスクリプト由来の加工物なので公開候補に含めない。
* **信頼度**: **Medium-High**。公開物にバニラ関数本文を含めずに済むため、Phase 2A-R1の候補方式とする。

### 3.3 Scene / Resource Replacement (シーン/リソース置換)
* **概要**: バニラの `.tscn` や `.tres` などのアセット全体をMod側のファイルと完全に置換する手法。
* **API**: `ModLoaderMod.register_translation(...)` などの各種アセットマッピング。
* **注意**: バニラシーン全体を丸ごと上書きするため、他のModとの競合リスクが非常に高い。
* **信頼度**: **Medium** (今回の「配置範囲拡張」や「ノード上限緩和」では競合を避けるため、可能な限り使用しない)

---

## 4. 構成要素の動作と連携

### 4.1 Mod設定の保存 (Mod Config)
* **機能**: `ModLoaderConfig` クラスを介し、`manifest.json` の `config_schema` から設定可能なUIオプションを構築可能。
* **保存先**: ユーザーデータ領域である `user://configs/namespace-name.json` に保存されます。

### 4.2 ログ出力
* **ログAPI**: `ModLoaderLog.info()`, `ModLoaderLog.warning()`, `ModLoaderLog.error()`
* **ログファイル出力先**: `user://logs/modloader.log`

---

## 5. 各仕様の判定証拠と確信度

### Finding 1: Script ExtensionとMod Hooksが利用可能
* **Evidence**: ゲーム内 `addons/mod_loader/` にScript Extension用APIとMod Hooks用APIが搭載されている。
* **Confidence**: **High**

### Finding 2: 設定ファイルシステム
* **Evidence**: 既存Mod `asouy-ModManager` 内で `ModLoaderConfig.get_current_config(mod_id)` が利用され、ゲームに設定フックが機能していることを確認。
* **Confidence**: **High**

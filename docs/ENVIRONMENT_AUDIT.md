# Environment Audit (環境監査結果)

Upload Labs Mod開発のための開発環境およびゲーム動作環境に関する監査ログです。

---

## 1. 開発マシン環境

* **OS (オペレーティングシステム)**: Windows (x64)
* **Git**: `git version 2.53.0.windows.1` (利用可能)
* **GitHub CLI**: 未インストール (検出されず)
* **Python環境**: `Python 3.14.3`, `pip 26.0.1` (利用可能)
* **Godot Engine (グローバル)**: システムパスには未登録 (ゲーム同梱版またはGDRE Toolsを使用)

---

## 2. Steam & ゲーム本体環境

* **Steamインストール先**: `C:\Program Files (x86)\Steam`
* **Upload Labs AppID**: `3606890` (E:\SteamLibrary\steamapps\appmanifest_3606890.acf より)
* **ゲームインストールディレクトリ**: `E:\SteamLibrary\steamapps\common\Upload Labs`
* **ゲーム実行ファイル**: `Upload Labs.exe` (165,880,816 bytes)
  * PCKファイルは実行ファイル本体に内包されている（Self-contained）。
* **Godotバージョン**: Godot 4.x
  * GDRE Toolsによる逆コンパイルレポートにて `Godot editor version 4.6.1` 互換（GDScript 2.0形式）と確認。
* **主要な同梱ライブラリ**:
  * `libgodotsteam.windows.template_release.x86_64.dll` (GodotSteam統合)
  * `steam_api64.dll` (Steam連携用)
  * `discord_game_sdk.dll` / `discord_game_sdk_binding.dll` (Discord連携用)

---

## 3. Mod Loader 基盤

* **Mod Loaderの実装**: `Godot Mod Loader` (アドオンとしてゲーム本体に同梱)
  * 展開結果から `res://addons/mod_loader/` がゲーム内に内蔵されていることを確認。
  * 既存Modのメタデータより、Mod Loader互換バージョンは `7.0.1` 相当（Godot 4.x対応版）と特定。
* **Modディレクトリ**:
  * ゲームディレクトリ内: `E:\SteamLibrary\steamapps\common\Upload Labs\mods-unpacked` (初期状態では空)

---

## 4. Steam Workshop 環境

* **Workshopコンテンツ保存先**: `E:\SteamLibrary\steamapps\workshop\content\3606890`
* **既存導入Modの調査成果**:
  * Mod ID/フォルダ: `3737244308`
  * 実体: `asouy-ModManager-1.2.0.zip`
  * 展開構造:
    ```text
    mods-unpacked/
    └─ asouy-ModManager/
       ├─ manifest.json  (Mod名、バージョン、名前空間、Mod Loader互換バージョンの定義)
       └─ mod_main.gd    (ゲーム内UIに介入しMod一覧を描画するGDScript 2.0)
    ```
  * 知見:
    * Mod名空間は `asouy`。
    * Modのエントリーポイントは `mod_main.gd`。
    * 既存Modのコードはコピーせず、構造・インターフェース設計の参考情報としてのみ取り扱う。

---

## 5. セキュリティおよび個人情報保護

本ドキュメントおよびその他のドキュメントにおいては、Steamの個人認証トークン、プライベートパス、ユーザーの個人名などの秘匿情報を一切記録しない設計を厳守しています。
また、バニラゲームのバイナリやデコンパイル済みソースコードはすべてGit管理外（`.gitignore` による除外）としてローカル分析環境に分離しています。

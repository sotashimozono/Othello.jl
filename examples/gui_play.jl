#!/usr/bin/env julia
# GUI でリバーシを遊ぶサンプルスクリプト
#
# 起動方法:
#   julia --project=. examples/gui_play.jl
#
# 対戦モードは launch_gui の引数で指定できます:
#   launch_gui(GUIPlayer(), RandomPlayer())    # 人間(黒) vs ランダムAI(白)  [デフォルト]
#   launch_gui(RandomPlayer(), GUIPlayer())    # ランダムAI(黒) vs 人間(白)
#   launch_gui(GUIPlayer(), GUIPlayer())       # 人間 vs 人間
#   launch_gui(RandomPlayer(), RandomPlayer()) # AI vs AI 観戦
#
# カスタムプレイヤー（機械学習モデル等）を渡す場合:
#   include("my_player.jl")
#   launch_gui(MyMLPlayer(model), GUIPlayer())

using Reversi, GLMakie

# ウィンドウを起動（デフォルト: 人間(黒) vs ランダムAI(白)）
fig = launch_gui()

# Julia REPL 上で実行した場合はウィンドウが閉じるまで待機
if !isinteractive()
    display(fig)
    wait(GLMakie.Screen(fig.scene))
end

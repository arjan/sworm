NODE=$1
ERL_AFLAGS="-name $NODE@127.0.0.1 -setcookie cookiexyz" iex -S mix

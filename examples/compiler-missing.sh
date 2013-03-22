( cd working; ls *.ey ) | sed -e 's/.ey/.test/' | while read n; do
  [ ! -r working-compiler/"$n" ] && echo $n
done

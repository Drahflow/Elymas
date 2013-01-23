{( cd working-compiler; ls *.test ); (cd working; ls *.ey)} | sed -e 's/\..*//g' | sort | uniq -c | sort -nr

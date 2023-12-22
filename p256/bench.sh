TO_CHERRY_PICK_FILE="to_cherry_pick.log"
COMPLETE_LOG_FILE="complete.log"
rm $TO_CHERRY_PICK_FILE
LAST_COMMIT_EXCLUDING=$1
NUM_COMMITS=$(git rev-list "$LAST_COMMIT_EXCLUDING"..HEAD --count)

RUSTFLAGS='-C target-cpu=native' taskset -c 0 cargo bench --features expose-field -- "point-scalar" > bench_HEAD.log

for ((i=1;i<=$NUM_COMMITS;i++)); do
  PREV_COMMIT=$(git rev-parse --short HEAD)
  git checkout HEAD~1
  CURRENT_COMMIT=$(git rev-parse --short HEAD)
  BENCH_LOG_FILE="bench_""$PREV_COMMIT"".log"
  echo "ITERATION ""$i""/""$NUM_COMMITS"": for commit ""$CURRENT_COMMIT"
  RUSTFLAGS='-C target-cpu=native' taskset -c 0 cargo bench --features expose-field -- "point-scalar" > $BENCH_LOG_FILE
  echo $BENCH_LOG_FILE > $COMPLETE_LOG_FILE
  cat $BENCH_LOG_FILE > $COMPLETE_LOG_FILE
  echo " "  > $COMPLETE_LOG_FILE
  res=$(grep "Performance has regressed" "$BENCH_LOG_FILE" | wc -l)
  if [ "$res" -ne "0" ]; then echo $PREV_COMMIT >> to_cherry_pick.log; fi;
done

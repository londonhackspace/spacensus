HOST=localhost
PORT=4242

function execCommand {
  PAGE=`curl -s "http://$HOST:$PORT/$1"`
  if [ $? -ne 0 ]; then
    FAIL=1
  fi;
}

function event {
  EVENT=`echo $PAGE | cut -c2`

  case "$EVENT" in
    I)
      echo "Someone walked in"
      ;;
    O)
      echo "Someone walked out"
      ;;
    N)
      echo "No-one has come in or out"
      ;;  
    *)
      echo "Unknown response"
  esac
}

function beamStatus {
  BEAM=`echo $PAGE | cut -c3`

  case "$BEAM" in
    L)
      echo "Beams are enabled"
      ;;
    X)
      echo "Beams are disabled"
      ;;    
    *)
      echo "Unknown response"
  esac
}

function alarmStatus {
  ALARM=`echo $PAGE | cut -c1`

  case "$ALARM" in
    K)
      echo "Beams are not obstructed"
      ;;
    A)
      echo "Beams are obstructed"
      ;;    
    *)
      echo "Unknown response"
  esac
}

function people {
  PEOPLE=`echo $PAGE | cut -c4-`
}
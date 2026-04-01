WIDTH=1548
HALF=$((WIDTH/2))

echo "#BUS_SORT"
echo ""
echo "#N"
for ((i=WIDTH-1; i>=HALF; i--)); do
  echo "mstream_o\\[$i\\]"
done

echo ""
echo "#E"
for ((i=HALF-1; i>=0; i--)); do
  echo "mstream_o\\[$i\\]"
done

echo ""
echo "#S"
echo "mstream_i.*"
echo "sstream_i.*"
echo "sstream_o.*"

echo ""
echo "#W"
echo "clk_i"
echo "nrst_i"
echo "force_mail_i"
echo "cores_mailed_o.*"
echo "empty_o"
echo "full_o"
echo "done_mailing_o"
echo "clear_i"
